//
//  File.swift
//  
//
//  Created by Yusuf Tör on 21/07/2022.
//
// swiftlint:disable array_constructor type_body_length

import Foundation

enum ConfigLogic {
  enum TriggerAudienceError: Error {
    case noVariantsFound
    case invalidState
  }

  struct AssignmentOutcome {
    let confirmed: [Experiment.ID: Experiment.Variant]
    let unconfirmed: [Experiment.ID: Experiment.Variant]
  }

  static func chooseVariant(
    from variants: [VariantOption],
    randomiser: (Range<Int>) -> Int = Int.random(in:)
  ) throws -> Experiment.Variant {
    if variants.isEmpty {
      throw TriggerAudienceError.noVariantsFound
    }

    // If there's only one variant, return it.
    // This could have a zero percentage.
    if variants.count == 1,
      let variant = variants.first {
      return variant.toExperimentVariant()
    }

    // Calculate the total sum of variant percentages.
    let totalPercentage = variants.reduce(0) { $0 + $1.percentage }

    // Something went wrong on the dashboard, where all variants
    // have 0% set. Choose a random one.
    if totalPercentage == 0 {
      // Choose a random variant
      let randomIndex = randomiser(0..<variants.count)
      return variants[randomIndex].toExperimentVariant()
    }

    // Choose a random percentage e.g. 21
    let randomPercentage = randomiser(0..<totalPercentage)

    // Select the variant based on cumulative percentage
    var cumulativePercentage = 0

    for variant in variants {
      // Add to total variant percentage
      cumulativePercentage += variant.percentage

      // See if selected is less than total. If it is then return.
      // e.g. Loop 1: 21 < (0 + 20) = nope, Loop 2: 21 < (20 + 30) = match
      if randomPercentage < cumulativePercentage {
        return variant.toExperimentVariant()
      }
    }

    throw TriggerAudienceError.invalidState
  }

  /// Gets the audiences per unique experiment group. If any trigger belongs to an experiment whose audience has
  /// already been retrieved, it gets skipped.
  ///
  /// - Parameters:
  ///   - triggers: A set of triggers
  ///
  /// - Returns: A `Set` of `TriggerRule` arrays.
  static func getAudienceFiltersPerCampaign(
    from triggers: Set<Trigger>
  ) -> Set<[TriggerRule]> {
    var campaignIds: Set<String> = []
    var uniqueTriggerAudiences: Set<[TriggerRule]> = []
    for trigger in triggers {
      guard let firstAudience = trigger.audiences.first else {
        continue
      }
      let campaignId = firstAudience.experiment.groupId

      if campaignIds.contains(campaignId) {
        continue
      }

      campaignIds.insert(campaignId)
      uniqueTriggerAudiences.insert(trigger.audiences)
    }
    return uniqueTriggerAudiences
  }

  static func chooseAssignments(
    fromTriggers triggers: Set<Trigger>,
    confirmedAssignments: [Experiment.ID: Experiment.Variant]
  ) -> AssignmentOutcome {
    var confirmedAssignments = confirmedAssignments
    var unconfirmedAssignments: [Experiment.ID: Experiment.Variant] = [:]

    let groupedTriggerAudiences = getAudienceFiltersPerCampaign(from: triggers)

    // Loop through each trigger and each of its audiences.
    for audienceGroup in groupedTriggerAudiences {
      for audience in audienceGroup {
        let availableVariantIds = Set(audience.experiment.variants.map { $0.id })

        // Check whether we have already chosen a variant for the experiment on disk.
        if let confirmedVariant = confirmedAssignments[audience.experiment.id] {
          // If one exists, check it's still in the available variants of the experiment's audiences, otherwise reroll.
          if !availableVariantIds.contains(confirmedVariant.id) {
            // If we couldn't choose a variant, because of an invalid state, such as no variants available, delete the confirmed assignment.
            guard let variant = try? Self.chooseVariant(from: audience.experiment.variants) else {
              confirmedAssignments[audience.experiment.id] = nil
              continue
            }
            unconfirmedAssignments[audience.experiment.id] = variant
            confirmedAssignments[audience.experiment.id] = nil
          }
        } else {
          // No variant found on disk so dice roll to choose a variant and store in memory as an unconfirmed assignment.
          guard let variant = try? Self.chooseVariant(from: audience.experiment.variants) else {
            continue
          }
          unconfirmedAssignments[audience.experiment.id] = variant
        }
      }
    }

    return AssignmentOutcome(
      confirmed: confirmedAssignments,
      unconfirmed: unconfirmedAssignments
    )
  }

  static func move(
    _ newAssignment: ConfirmableAssignment,
    from unconfirmedAssignments: [Experiment.ID: Experiment.Variant],
    to confirmedAssignments: [Experiment.ID: Experiment.Variant]
  ) -> AssignmentOutcome {
    var confirmedAssignments = confirmedAssignments
    confirmedAssignments[newAssignment.experimentId] = newAssignment.variant

    var unconfirmedAssignments = unconfirmedAssignments
    unconfirmedAssignments[newAssignment.experimentId] = nil

    return ConfigLogic.AssignmentOutcome(
      confirmed: confirmedAssignments,
      unconfirmed: unconfirmedAssignments
    )
  }

  /// Removes any triggers whose preloading has been remotely disabled.
  static func filterTriggers(
    _ triggers: Set<Trigger>,
    removing preloadingDisabled: PreloadingDisabled
  ) -> Set<Trigger> {
    if preloadingDisabled.all {
      return []
    }

    return triggers.filter {
      !preloadingDisabled.triggers.contains($0.placementName)
    }
  }

  /// Loops through assignments retrieved from the server to get variants by id.
  /// Returns updated confirmed/unconfirmed assignments to save.
  static func transferAssignmentsFromServerToDisk(
    assignments: [Assignment],
    triggers: Set<Trigger>,
    confirmedAssignments: [Experiment.ID: Experiment.Variant],
    unconfirmedAssignments: [Experiment.ID: Experiment.Variant]
  ) -> AssignmentOutcome {
    var confirmedAssignments = confirmedAssignments
    var unconfirmedAssignments = unconfirmedAssignments

    for assignment in assignments {
      // Get the trigger with the matching experiment ID
      guard let trigger = triggers.first(
        where: { $0.audiences.contains(where: { $0.experiment.id == assignment.experimentId }) }
      ) else {
        continue
      }
      // Get the variant with the matching variant ID
      guard let variantOption = trigger.audiences.compactMap({
        $0.experiment.variants.first { $0.id == assignment.variantId }
      }).first else {
        continue
      }

      // Save this to disk, remove any unconfirmed assignments with the same experiment ID.
      confirmedAssignments[assignment.experimentId] = variantOption.toExperimentVariant()
      unconfirmedAssignments[assignment.experimentId] = nil
    }

    return .init(
      confirmed: confirmedAssignments,
      unconfirmed: unconfirmedAssignments
    )
  }

  static func getStaticPaywall(
    withId paywallId: String?,
    config: Config?,
    deviceLocale: String
  ) -> Paywall? {
    guard let paywallId = paywallId else {
      return nil
    }
    guard let config = config else {
      return nil
    }

    // If the available locales contains the exact device locale, load the response the old way.
    if config.locales.contains(deviceLocale) {
      return nil
    } else {
      guard let shortLocaleElement = deviceLocale.split(separator: "_").first else {
        return nil
      }
      let shortLocale = String(shortLocaleElement)

      // Otherwise, if the shortened locale contains "en", load the paywall responses from static config.
      // Same if we can't find any matching locale in available locales.
      if shortLocale == "en" || !config.locales.contains(shortLocale) {
        return config.paywalls.first { $0.identifier == paywallId }
      } else {
        return nil
      }
    }
  }

  static func getAllActiveTreatmentPaywallIds(
    fromTriggers triggers: Set<Trigger>,
    confirmedAssignments: [Experiment.ID: Experiment.Variant],
    unconfirmedAssignments: [Experiment.ID: Experiment.Variant],
    expressionEvaluator: ExpressionEvaluating
  ) async -> Set<String> {
    var confirmedAssignments = confirmedAssignments

    let confirmedExperimentIds = Set(confirmedAssignments.keys)
    let audienceFiltersPerCampaign = getAudienceFiltersPerCampaign(from: triggers)

    // Loop through all the audiences and check their preloading behaviour.
    // If they should never preload or set to ifTrue but don't match,
    // skip the experiment.
    var allExperimentIds: Set<String> = []
    var skippedExperimentIds: Set<String> = []

    for campaignAudienceFilters in audienceFiltersPerCampaign {
      for audienceFilter in campaignAudienceFilters {
        allExperimentIds.insert(audienceFilter.experiment.id)

        switch audienceFilter.preload.behavior {
        case .ifTrue:
          let outcome = await expressionEvaluator.evaluateExpression(
            fromAudienceFilter: audienceFilter,
            placementData: nil
          )
          switch outcome {
          case .noMatch:
            skippedExperimentIds.insert(audienceFilter.experiment.id)
          case .match:
            continue
          }
        case .always:
          continue
        case .never:
          skippedExperimentIds.insert(audienceFilter.experiment.id)
        }
      }
    }

    // Remove any confirmed experiment IDs that are no
    // longer part of a trigger. This could happen when a campaign
    // has been archived.
    let unusedExperimentIds = confirmedExperimentIds.subtracting(allExperimentIds)
    for id in unusedExperimentIds {
      confirmedAssignments.removeValue(forKey: id)
    }

    // Remove any assignments whose variants we don't want to preload.
    var mergedAssignments = confirmedAssignments + unconfirmedAssignments
    for id in skippedExperimentIds {
      mergedAssignments.removeValue(forKey: id)
    }
    let preloadableVariants = mergedAssignments.values

    // Only select the variants that will result in a paywall rather
    // than a holdout.
    var identifiers = Set<String>()

    for variant in preloadableVariants {
      if variant.type == .treatment,
        let paywallId = variant.paywallId {
        identifiers.insert(paywallId)
      }
    }

    return identifiers
  }

  static func getActiveTreatmentPaywallIds(
    forTriggers triggers: Set<Trigger>,
    confirmedAssignments: [Experiment.ID: Experiment.Variant],
    unconfirmedAssignments: [Experiment.ID: Experiment.Variant]
  ) -> Set<String> {
    let mergedAssignments = confirmedAssignments.merging(unconfirmedAssignments)
    let groupedTriggerAudiences = getAudienceFiltersPerCampaign(from: triggers)
    let triggerExperimentIds = groupedTriggerAudiences.flatMap { $0.map { $0.experiment.id } }

    var identifiers = Set<String>()
    for experimentId in triggerExperimentIds {
      guard let variant = mergedAssignments[experimentId] else {
        continue
      }
      if variant.type == .treatment,
        let paywallId = variant.paywallId {
        identifiers.insert(paywallId)
      }
    }

    return identifiers
  }

  static func getTriggersByPlacementName(from triggers: Set<Trigger>) -> [String: Trigger] {
    let triggersDictionary = triggers.reduce([String: Trigger]()) { result, trigger in
      var result = result
      result[trigger.placementName] = trigger
      return result
    }
    return triggersDictionary
  }

  /// Gets the paywall IDs that no longer exist in the newly retrieved config.
  static func getRemovedOrChangedPaywallIds(
    oldConfig: Config,
    newConfig: Config
  ) -> Set<String> {
    let oldPaywalls = oldConfig.paywalls
    let newPaywalls = newConfig.paywalls

    let oldPaywallIds = Set(oldPaywalls.map { $0.identifier })
    let newPaywallIds = Set(newPaywalls.map { $0.identifier })

    // Create dictionary for quick lookup of cacheKeys
    let oldPaywallCacheKeys = Dictionary(uniqueKeysWithValues: oldPaywalls.map { ($0.identifier, $0.cacheKey) })

    let removedPaywallIds = oldPaywallIds.subtracting(newPaywallIds)

    // Find identifiers that are no longer in the new configuration or whose cacheKey has changed
    let removedOrChangedPaywallIds = removedPaywallIds
      .union(
        newPaywalls.filter { paywall in
          let cacheKeyExists = oldPaywallCacheKeys[paywall.identifier] != nil
          let cacheKeyChanged = oldPaywallCacheKeys[paywall.identifier] != paywall.cacheKey
          return cacheKeyExists && cacheKeyChanged
        }
        .map { $0.identifier }
      )

    return removedOrChangedPaywallIds
  }

  /// Returns the entitlements mapped to a product ID.
  static func extractEntitlements(
    from config: Config
  ) -> [String: Set<Entitlement>] {
    return Dictionary(
      uniqueKeysWithValues: config.products.map { ($0.id, $0.entitlements) }
    )
  }
}
