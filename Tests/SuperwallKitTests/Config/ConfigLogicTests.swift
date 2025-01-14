//
//  File.swift
//  
//
//  Created by Yusuf Tör on 16/08/2022.
//
// swiftlint:disable all

@testable import SuperwallKit
import XCTest

final class ConfigLogicTests: XCTestCase {
  // MARK: - Choose Variant
  func test_chooseVariant_noVariants() {
    do {
      let _ = try ConfigLogic.chooseVariant(from: [])
      XCTFail("Should have produced an error")
    } catch let error as ConfigLogic.TriggerAudienceError {
      XCTAssertEqual(error, ConfigLogic.TriggerAudienceError.noVariantsFound)
    } catch {
      XCTFail("Should have produced a no variant error")
    }
  }

  func test_chooseVariant_onlyOneVariant_zeroSum() {
    do {
      let options: [VariantOption] = [
        .stub()
        .setting(\.percentage, to: 0)
      ]
      let variant = try ConfigLogic.chooseVariant(from: options)
      XCTAssertEqual(options.first!.toExperimentVariant(), variant)
    } catch let error as ConfigLogic.TriggerAudienceError {
      XCTAssertEqual(error, ConfigLogic.TriggerAudienceError.invalidState)
    } catch {
      XCTFail("Should have produced a no variant error")
    }
  }

  func test_chooseVariant_manyVariants_zeroSum() {
    do {
      let options: [VariantOption] = [
        .stub()
        .setting(\.percentage, to: 0),
        .stub()
        .setting(\.percentage, to: 0)
      ]
      let variant = try ConfigLogic.chooseVariant(
        from: options,
        randomiser: { range in
          // Force choosing the first variant
          return 0
        }
      )
    } catch {
      XCTFail("Shouldn't fail")
    }
  }

  func test_chooseVariant_oneActiveVariant_chooseFirst() {
    do {
      let options: [VariantOption] = [
        .stub()
        .setting(\.percentage, to: 100),
        .stub()
        .setting(\.percentage, to: 0),
        .stub()
        .setting(\.percentage, to: 0)
      ]
      let variant = try ConfigLogic.chooseVariant(from: options)
      XCTAssertEqual(options.first!.toExperimentVariant(), variant)
    } catch {
      XCTFail("Should have produced a no variant error")
    }
  }

  func test_chooseVariant_99PercentSumVariants_chooseLast() {
    do {
      let options: [VariantOption] = [
        .stub()
        .setting(\.percentage, to: 33),
        .stub()
        .setting(\.percentage, to: 33),
        .stub()
        .setting(\.percentage, to: 33)
      ]
      let variant = try ConfigLogic.chooseVariant(
        from: options,
        randomiser: { range in
          XCTAssertEqual(range, 0..<99)
          return 98
        }
      )
      XCTAssertEqual(options.last!.toExperimentVariant(), variant)
    } catch {
      XCTFail("Should have produced a no variant error")
    }
  }

  func test_chooseVariant_99PercentSumVariants_chooseMiddle() {
    do {
      let options: [VariantOption] = [
        .stub()
        .setting(\.percentage, to: 33),
        .stub()
        .setting(\.percentage, to: 33),
        .stub()
        .setting(\.percentage, to: 33)
      ]
      let variant = try ConfigLogic.chooseVariant(
        from: options,
        randomiser: { range in
          XCTAssertEqual(range, 0..<99)
          return 65
        }
      )
      XCTAssertEqual(options[1].toExperimentVariant(), variant)
    } catch {
      XCTFail("Should have produced a no variant error")
    }
  }

  func test_chooseVariant_99PercentSumVariants_chooseFirst() {
    do {
      let options: [VariantOption] = [
        .stub()
        .setting(\.percentage, to: 33),
        .stub()
        .setting(\.percentage, to: 33),
        .stub()
        .setting(\.percentage, to: 33)
      ]
      let variant = try ConfigLogic.chooseVariant(
        from: options,
        randomiser: { range in
          XCTAssertEqual(range, 0..<99)
          return 0
        }
      )
      XCTAssertEqual(options.first!.toExperimentVariant(), variant)
    } catch {
      XCTFail("Should have produced a no variant error")
    }
  }

  // MARK: - getRulesPerTriggerGroup

  func test_getRulesPerTriggerGroup_noTriggers() {
    let rules = ConfigLogic.getAudienceFiltersPerCampaign(from: [])
    XCTAssertTrue(rules.isEmpty)
  }

  func test_getRulesPerTriggerGroup_noRules() {
    let rules = ConfigLogic.getAudienceFiltersPerCampaign(from: [
      .stub()
      .setting(\.audiences, to: [])
    ])
    XCTAssertTrue(rules.isEmpty)
  }

  func test_getRulesPerTriggerGroup_threeTriggersTwoWithSameGroupId() {
    let trigger1 = Trigger.stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(\.experiment.groupId, to: "1")
      ])
    let trigger2 = Trigger.stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(\.experiment.groupId, to: "1")
      ])
    let trigger3 = Trigger.stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(\.experiment.groupId, to: "2")
      ])
    let rules = ConfigLogic.getAudienceFiltersPerCampaign(from: [
      trigger1, trigger2, trigger3
    ])
    XCTAssertEqual(rules.count, 2)
    XCTAssertTrue(rules.contains(trigger3.audiences))
    XCTAssertTrue(rules.contains(trigger1.audiences))
  }

  // MARK: - Choose Variants
  func test_assignVariants_noTriggers() {
    // Given
    let confirmedAssignments = [
      "exp1": Experiment.Variant(
        id: "1",
        type: .treatment,
        paywallId: "abc"
      )
    ]

    // When
    let variant = ConfigLogic.chooseAssignments(
      fromTriggers: [],
      confirmedAssignments: confirmedAssignments
    )

    // Then
    XCTAssertTrue(variant.unconfirmed.isEmpty)
    XCTAssertEqual(variant.confirmed, confirmedAssignments)
  }

  func test_chooseVariant_1Percent99Percent_choose1Percent() {
      do {
        let options: [VariantOption] = [
          .stub()
          .setting(\.percentage, to: 1),
          .stub()
          .setting(\.percentage, to: 99)
        ]
        let variant = try ConfigLogic.chooseVariant(
          from: options,
          randomiser: { range in
            XCTAssertEqual(range, 0..<100)
            return 0
          }
        )
        XCTAssertEqual(options.first!.toExperimentVariant(), variant)
      } catch {
        XCTFail("Should have produced a no variant error")
      }
    }

  func test_chooseAssignments_noRules() {
    // Given
    let confirmedAssignments = [
      "exp1": Experiment.Variant(
        id: "1",
        type: .treatment,
        paywallId: "abc"
      )
    ]
    // When
    let variant = ConfigLogic.chooseAssignments(
      fromTriggers: [
        .stub()
        .setting(\.audiences, to: [])
      ],
      confirmedAssignments: confirmedAssignments
    )

    // Then
    XCTAssertTrue(variant.unconfirmed.isEmpty)
    XCTAssertEqual(variant.confirmed, confirmedAssignments)
  }

  func test_chooseAssignments_variantAsOfYetUnconfirmed() {
    // Given
    let variantId = "abc"
    let paywallId = "edf"
    let experimentId = "3"
    let experimentGroupId = "13"
    let variantOption: VariantOption = .stub()
      .setting(\.id, to: variantId)
      .setting(\.paywallId, to: paywallId)
      .setting(\.type, to: .treatment)

    // When
    let variant = ConfigLogic.chooseAssignments(
      fromTriggers: [
        .stub()
        .setting(\.audiences, to: [
          .stub()
          .setting(\.experiment, to: .stub()
            .setting(\.id, to: experimentId)
            .setting(\.groupId, to: experimentGroupId)
            .setting(\.variants, to: [
              variantOption
            ])
          )
        ])
      ],
      confirmedAssignments: [:]
    )

    // When
    XCTAssertEqual(variant.unconfirmed.count, 1)
    XCTAssertEqual(variant.unconfirmed[experimentId], variantOption.toExperimentVariant())
    XCTAssertTrue(variant.confirmed.isEmpty)
  }

  func test_chooseAssignments_variantAlreadyConfirmed() {
    // Given
    let variantId = "abc"
    let paywallId = "edf"
    let experimentId = "3"
    let experimentGroupId = "13"
    let variantOption: VariantOption = .stub()
      .setting(\.id, to: variantId)
      .setting(\.paywallId, to: paywallId)
      .setting(\.type, to: .treatment)

    // When
    let variant = ConfigLogic.chooseAssignments(
      fromTriggers: [
        .stub()
        .setting(\.audiences, to: [
          .stub()
          .setting(\.experiment, to: .stub()
            .setting(\.id, to: experimentId)
            .setting(\.groupId, to: experimentGroupId)
            .setting(\.variants, to: [
              variantOption
            ])
          )
        ])
      ],
      confirmedAssignments: [experimentId: variantOption.toExperimentVariant()]
    )

    // Then
    XCTAssertEqual(variant.confirmed.count, 1)
    XCTAssertEqual(variant.confirmed[experimentId], variantOption.toExperimentVariant())
    XCTAssertTrue(variant.unconfirmed.isEmpty)
  }

  func test_chooseAssignments_variantAlreadyConfirmed_nowUnavailable() {
    // Given
    let paywallId = "edf"
    let experimentId = "3"
    let experimentGroupId = "13"
    let newVariantOption: VariantOption = .stub()
      .setting(\.id, to: "newVariantId")
      .setting(\.paywallId, to: paywallId)
      .setting(\.type, to: .treatment)
    let oldVariantOption: VariantOption = .stub()
      .setting(\.id, to: "oldVariantId")
      .setting(\.paywallId, to: paywallId)
      .setting(\.type, to: .treatment)

    // When
    let variant = ConfigLogic.chooseAssignments(
      fromTriggers: [
        .stub()
        .setting(\.audiences, to: [
          .stub()
          .setting(\.experiment, to: .stub()
            .setting(\.id, to: experimentId)
            .setting(\.groupId, to: experimentGroupId)
            .setting(\.variants, to: [
              newVariantOption
            ])
          )
        ])
      ],
      confirmedAssignments: [experimentId: oldVariantOption.toExperimentVariant()]
    )

    // Then
    XCTAssertEqual(variant.unconfirmed.count, 1)
    XCTAssertEqual(variant.unconfirmed[experimentId], newVariantOption.toExperimentVariant())
    XCTAssertTrue(variant.confirmed.isEmpty)
  }

  func test_chooseAssignments_variantAlreadyConfirmed_nowNoVariants() {
    // Given
    let paywallId = "edf"
    let experimentId = "3"
    let experimentGroupId = "13"
    let oldVariantOption: VariantOption = .stub()
      .setting(\.id, to: "oldVariantId")
      .setting(\.paywallId, to: paywallId)
      .setting(\.type, to: .treatment)

    // When
    let variant = ConfigLogic.chooseAssignments(
      fromTriggers: [
        .stub()
        .setting(\.audiences, to: [
          .stub()
          .setting(\.experiment, to: .stub()
            .setting(\.id, to: experimentId)
            .setting(\.groupId, to: experimentGroupId)
            .setting(\.variants, to: [])
          )
        ])
      ],
      confirmedAssignments: [experimentId: oldVariantOption.toExperimentVariant()]
    )

    // Then
    XCTAssertTrue(variant.unconfirmed.isEmpty)
    XCTAssertTrue(variant.confirmed.isEmpty)
  }

  // MARK: - processAssignmentsFromServer

  func test_processAssignmentsFromServer_noAssignments() {
    let confirmedVariant: Experiment.Variant = .init(id: "def", type: .treatment, paywallId: "ghi")
    let unconfirmedVariant: Experiment.Variant = .init(id: "mno", type: .treatment, paywallId: "pqr")
    let result = ConfigLogic.transferAssignmentsFromServerToDisk(
      assignments: [],
      triggers: [.stub()],
      confirmedAssignments: ["abc": .init(id: "def", type: .treatment, paywallId: "ghi")],
      unconfirmedAssignments: ["jkl": .init(id: "mno", type: .treatment, paywallId: "pqr")]
    )
    XCTAssertEqual(result.confirmed["abc"], confirmedVariant)
    XCTAssertEqual(result.unconfirmed["jkl"], unconfirmedVariant)
  }

  func test_processAssignmentsFromServer_overwriteConfirmedAssignment() {
    let experimentId = "abc"
    let variantId = "def"

    let assignments: [Assignment] = [
      Assignment(
        experimentId: experimentId,
        variantId: variantId
      )
    ]
    let oldVariantOption: VariantOption = .stub()
    let variantOption: VariantOption = .stub()
      .setting(\.id, to: variantId)
    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experimentId)
            .setting(\.variants, to: [variantOption])
        )
      ])
    ]

    let unconfirmedVariant: Experiment.Variant = .init(id: "mno", type: .treatment, paywallId: "pqr")
    let result = ConfigLogic.transferAssignmentsFromServerToDisk(
      assignments: assignments,
      triggers: triggers,
      confirmedAssignments: [experimentId: oldVariantOption.toExperimentVariant()],
      unconfirmedAssignments: ["jkl": .init(id: "mno", type: .treatment, paywallId: "pqr")]
    )

    XCTAssertEqual(result.confirmed[experimentId], variantOption.toExperimentVariant())
    XCTAssertEqual(result.unconfirmed["jkl"], unconfirmedVariant)
  }

  func test_processAssignmentsFromServer_multipleAssignments() {
    let experimentId1 = "abc"
    let variantId1 = "def"

    let experimentId2 = "ghi"
    let variantId2 = "klm"

    let assignments: [Assignment] = [
      Assignment(
        experimentId: experimentId1,
        variantId: variantId1
      ),
      Assignment(
        experimentId: experimentId2,
        variantId: variantId2
      )
    ]
    let unusedVariantOption1: VariantOption = .stub()
      .setting(\.id, to: "unusedOption1")
    let variantOption1: VariantOption = .stub()
      .setting(\.id, to: variantId1)
    let variantOption2: VariantOption = .stub()
      .setting(\.id, to: variantId2)
    let unusedVariantOption2: VariantOption = .stub()
      .setting(\.id, to: "unusedOption2")

    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experimentId1)
            .setting(\.variants, to: [variantOption1, unusedVariantOption1])
        ),
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experimentId2)
            .setting(\.variants, to: [variantOption2, unusedVariantOption2])
        )
      ])
    ]

    let unconfirmedVariant: Experiment.Variant = .init(id: "mno", type: .treatment, paywallId: "pqr")
    let result = ConfigLogic.transferAssignmentsFromServerToDisk(
      assignments: assignments,
      triggers: triggers,
      confirmedAssignments: [:],
      unconfirmedAssignments: ["jkl": .init(id: "mno", type: .treatment, paywallId: "pqr")]
    )
    XCTAssertEqual(result.confirmed.count, 2)
    XCTAssertEqual(result.confirmed[experimentId1], variantOption1.toExperimentVariant())
    XCTAssertEqual(result.confirmed[experimentId2], variantOption2.toExperimentVariant())
    XCTAssertEqual(result.unconfirmed["jkl"], unconfirmedVariant)
  }

  // MARK: - getStaticPaywall

  func test_getStaticPaywall_noPaywallId() {
    let response = ConfigLogic.getStaticPaywall(
      withId: nil,
      config: .stub(),
      deviceLocale: "en_GB"
    )
    XCTAssertNil(response)
  }

  func test_getStaticPaywall_noConfig() {
    let response = ConfigLogic.getStaticPaywall(
      withId: "abc",
      config: nil,
      deviceLocale: "en_GB"
    )
    XCTAssertNil(response)
  }

  func test_getStaticPaywall_deviceLocaleSpecifiedInConfig() {
    let locale = "en_GB"
    let dependencyContainer = DependencyContainer()
    let response = ConfigLogic.getStaticPaywall(
      withId: "abc",
      config: .stub()
        .setting(\.locales, to: [locale]),
      deviceLocale: locale
    )
    XCTAssertNil(response)
  }

  func test_getStaticPaywall_shortLocaleContainsEn() {
    let paywallId = "abc"
    let locale = "en_GB"
    let config: Config = .stub()
      .setting(\.locales, to: ["de_DE"])
      .setting(\.paywalls, to: [
        .stub(),
        .stub()
        .setting(\.identifier, to: paywallId)
      ])

    let response = ConfigLogic.getStaticPaywall(
      withId: paywallId,
      config: config,
      deviceLocale: locale
    )

    XCTAssertEqual(response, config.paywalls[1])
  }

  func test_getStaticPaywall_shortLocaleNotContainedInConfig() {
    let paywallId = "abc"
    let locale = "de_DE"
    let config: Config = .stub()
      .setting(\.locales, to: [])
      .setting(\.paywalls, to: [
        .stub(),
        .stub()
        .setting(\.identifier, to: paywallId)
      ])

    let response = ConfigLogic.getStaticPaywall(
      withId: paywallId,
      config: config,
      deviceLocale: locale
    )

    XCTAssertEqual(response, config.paywalls[1])
  }

  func test_getStaticPaywallResponse_shortLocaleContainedInConfig() {
    let paywallId = "abc"
    let locale = "de_DE"
    let config: Config = .stub()
      .setting(\.locales, to: ["de"])
      .setting(\.paywalls, to: [
        .stub(),
        .stub()
        .setting(\.identifier, to: paywallId)
      ])

    let response = ConfigLogic.getStaticPaywall(
      withId: paywallId,
      config: config,
      deviceLocale: locale
    )

    XCTAssertNil(response)
  }

  // MARK: - getAllActiveTreatmentPaywallIds
  func test_getAllActiveTreatmentPaywallIds_onlyConfirmedAssignments_treatment_alwaysPreload() async {
    let paywallId1 = "abc"
    let experiment1 = "def"

    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experiment1)
        )
        .setting(\.preload, to: .init(behavior: .always))
      ])
    ]
    let confirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment1: .init(id: paywallId1, type: .treatment, paywallId: paywallId1)
    ]

    let evaluator = ExpressionEvaluatorMock(outcome: .match(audience: .stub()))

    let ids = await ConfigLogic.getAllActiveTreatmentPaywallIds(
      fromTriggers: triggers,
      confirmedAssignments: confirmedAssignments,
      unconfirmedAssignments: [:],
      expressionEvaluator: evaluator
    )
    XCTAssertEqual(ids, [paywallId1])
  }

  func test_getAllActiveTreatmentPaywallIds_onlyConfirmedAssignments_treatment_neverPreload() async {
    let paywallId1 = "abc"
    let experiment1 = "def"

    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experiment1)
        )
        .setting(\.preload, to: .init(behavior: .never))
      ])
    ]
    let confirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment1: .init(id: paywallId1, type: .treatment, paywallId: paywallId1)
    ]

    let evaluator = ExpressionEvaluatorMock(outcome: .match(audience: .stub()))

    let ids = await ConfigLogic.getAllActiveTreatmentPaywallIds(
      fromTriggers: triggers,
      confirmedAssignments: confirmedAssignments,
      unconfirmedAssignments: [:], 
      expressionEvaluator: evaluator
    )
    XCTAssertTrue(ids.isEmpty)
  }

  func test_getAllActiveTreatmentPaywallIds_onlyConfirmedAssignments_treatment_ifTrue_evaluatesFalse() async {
    let paywallId1 = "abc"
    let experiment1 = "def"

    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experiment1)
        )
        .setting(\.preload, to: .init(behavior: .ifTrue))
      ])
    ]
    let confirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment1: .init(id: paywallId1, type: .treatment, paywallId: paywallId1)
    ]

    let evaluator = ExpressionEvaluatorMock(outcome: .noMatch(.stub()))

    let ids = await ConfigLogic.getAllActiveTreatmentPaywallIds(
      fromTriggers: triggers,
      confirmedAssignments: confirmedAssignments,
      unconfirmedAssignments: [:],
      expressionEvaluator: evaluator
    )
    XCTAssertTrue(ids.isEmpty)
  }

  func test_getAllActiveTreatmentPaywallIds_onlyConfirmedAssignments_treatment_ifTrue_evaluatesTrue() async {
    let paywallId1 = "abc"
    let experiment1 = "def"

    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experiment1)
        )
        .setting(\.preload, to: .init(behavior: .ifTrue))
      ])
    ]
    let confirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment1: .init(id: paywallId1, type: .treatment, paywallId: paywallId1)
    ]

    let evaluator = ExpressionEvaluatorMock(outcome: .match(.stub()))

    let ids = await ConfigLogic.getAllActiveTreatmentPaywallIds(
      fromTriggers: triggers,
      confirmedAssignments: confirmedAssignments,
      unconfirmedAssignments: [:],
      expressionEvaluator: evaluator
    )
    XCTAssertEqual(ids, [paywallId1])
  }

  func test_getAllActiveTreatmentPaywallIds_onlyConfirmedAssignments_treatment_multipleTriggerSameGroupId() async {
    let paywallId1 = "abc"
    let experiment1 = "def"

    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experiment1)
        )
      ]),
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experiment1)
        )
      ])
    ]
    let confirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment1: .init(id: paywallId1, type: .treatment, paywallId: paywallId1)
    ]
    let evaluator = ExpressionEvaluatorMock(outcome: .match(audience: .stub()))

    let ids = await ConfigLogic.getAllActiveTreatmentPaywallIds(
      fromTriggers: triggers,
      confirmedAssignments: confirmedAssignments,
      unconfirmedAssignments: [:],
      expressionEvaluator: evaluator
    )
    XCTAssertEqual(ids, [paywallId1])
  }

  func test_getAllActiveTreatmentPaywallIds_onlyConfirmedAssignments_holdout() async {
    let experiment1 = "def"

    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experiment1)
        )
      ])
    ]
    let confirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment1: .init(id: "variantId1", type: .holdout, paywallId: nil)
    ]
    let evaluator = ExpressionEvaluatorMock(outcome: .match(audience: .stub()))

    let ids = await ConfigLogic.getAllActiveTreatmentPaywallIds(
      fromTriggers: triggers,
      confirmedAssignments: confirmedAssignments,
      unconfirmedAssignments: [:],
      expressionEvaluator: evaluator
    )
    XCTAssertTrue(ids.isEmpty)
  }

  func test_getAllActiveTreatmentPaywallIds_onlyConfirmedAssignments_filterOldOnes() async {
    let paywallId1 = "abc"
    let experiment1 = "def"
    let paywallId2 = "efg"
    let experiment2 = "ghi"

    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experiment1)
        )
      ])
    ]
    let confirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment1: .init(id: "variantId1", type: .treatment, paywallId: paywallId1),
      experiment2: .init(id: "variantId2", type: .treatment, paywallId: paywallId2)
    ]
    let evaluator = ExpressionEvaluatorMock(outcome: .match(audience: .stub()))

    let ids = await ConfigLogic.getAllActiveTreatmentPaywallIds(
      fromTriggers: triggers,
      confirmedAssignments: confirmedAssignments,
      unconfirmedAssignments: [:],
      expressionEvaluator: evaluator
    )
    XCTAssertEqual(ids, [paywallId1])
  }

  func test_getAllActiveTreatmentPaywallIds_confirmedAndUnconfirmedAssignments_filterOldOnes() async {
    let paywallId1 = "abc"
    let experiment1 = "def"
    let paywallId2 = "efg"
    let experiment2 = "ghi"
    let paywallId3 = "jik"
    let experiment3 = "klo"

    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.groupId, to: "a")
            .setting(\.id, to: experiment1)
        )
      ]),
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.groupId, to: "b")
            .setting(\.id, to: experiment3)
        )
      ])
    ]
    let confirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment1: .init(id: "variantId1", type: .treatment, paywallId: paywallId1),
      experiment2: .init(id: "variantId2", type: .treatment, paywallId: paywallId2)
    ]
    let evaluator = ExpressionEvaluatorMock(outcome: .match(audience: .stub()))

    let ids = await ConfigLogic.getAllActiveTreatmentPaywallIds(
      fromTriggers: triggers,
      confirmedAssignments: confirmedAssignments,
      unconfirmedAssignments: [experiment3: .init(id: "variantId3", type: .treatment, paywallId: paywallId3)],
      expressionEvaluator: evaluator
    )
    XCTAssertEqual(ids, [paywallId1, paywallId3])
  }

  // MARK: - getActiveTreatmentPaywallIds
  func test_getActiveTreatmentPaywallIds() {
    let paywallId1 = "abc"
    let experiment1 = "def"
    let experiment2 = "sdf"
    let paywallId2 = "wer"

    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experiment1)
        )
      ])
    ]
    let confirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment1: .init(id: experiment2, type: .treatment, paywallId: paywallId1),
      experiment2: .init(id: experiment2, type: .treatment, paywallId: paywallId2)
    ]
    let ids = ConfigLogic.getActiveTreatmentPaywallIds(
      forTriggers: triggers,
      confirmedAssignments: confirmedAssignments,
      unconfirmedAssignments: [:]
    )
    XCTAssertEqual(ids, [paywallId1])
  }

  func test_getActiveTreatmentPaywallIds_holdout() {
    let paywallId1 = "abc"
    let experiment1 = "def"
    let experiment2 = "sdf"
    let paywallId2 = "wer"

    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experiment1)
        )
      ])
    ]
    let confirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment1: .init(id: experiment2, type: .holdout, paywallId: paywallId1),
      experiment2: .init(id: experiment2, type: .treatment, paywallId: paywallId2)
    ]
    let ids = ConfigLogic.getActiveTreatmentPaywallIds(
      forTriggers: triggers,
      confirmedAssignments: confirmedAssignments,
      unconfirmedAssignments: [:]
    )
    XCTAssertTrue(ids.isEmpty)
  }

  func test_getActiveTreatmentPaywallIds_confirmedAndUnconfirmedAssignments() {
    let paywallId1 = "abc"
    let experiment1 = "def"
    let experiment2 = "sdf"
    let paywallId2 = "wer"

    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experiment1)
        )
      ])
    ]
    let confirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment1: .init(id: experiment2, type: .treatment, paywallId: paywallId1)
    ]
    let unconfirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment2: .init(id: experiment2, type: .treatment, paywallId: paywallId2)
    ]
    let ids = ConfigLogic.getActiveTreatmentPaywallIds(
      forTriggers: triggers,
      confirmedAssignments: confirmedAssignments,
      unconfirmedAssignments: unconfirmedAssignments
    )
    XCTAssertEqual(ids, [paywallId1])
  }

  func test_getActiveTreatmentPaywallIds_confirmedAndUnconfirmedAssignments_removeDuplicateRules() {
    let paywallId1 = "abc"
    let experiment1 = "def"
    let experiment2 = "sdf"
    let paywallId2 = "wer"

    let triggers: Set<Trigger> = [
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.groupId, to: "abc")
            .setting(\.id, to: experiment1)
        )
      ]),
      .stub()
      .setting(\.audiences, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.groupId, to: "abc")
            .setting(\.id, to: experiment1)
        )
      ])
    ]
    let confirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment1: .init(id: experiment2, type: .treatment, paywallId: paywallId1)
    ]
    let unconfirmedAssignments: [Experiment.ID: Experiment.Variant] = [
      experiment2: .init(id: experiment2, type: .treatment, paywallId: paywallId2)
    ]
    let ids = ConfigLogic.getActiveTreatmentPaywallIds(
      forTriggers: triggers,
      confirmedAssignments: confirmedAssignments,
      unconfirmedAssignments: unconfirmedAssignments
    )
    XCTAssertEqual(ids, [paywallId1])
  }

  func test_getTriggerDictionary() {
    let firstTrigger: Trigger = .stub()
      .setting(\.placementName, to: "abc")
    
    let secondTrigger: Trigger = .stub()
      .setting(\.placementName, to: "def")
    
    let triggers: Set<Trigger> = [
      firstTrigger, secondTrigger
    ]
    let dictionary = ConfigLogic.getTriggersByPlacementName(from: triggers)
    XCTAssertEqual(dictionary["abc"], firstTrigger)
    XCTAssertEqual(dictionary["def"], secondTrigger)
  }
  // MARK: - Filter Triggers

  func test_filterTriggers_noTriggers() {
    let disabled = PreloadingDisabled(
      all: true,
      triggers: ["app_open"]
    )
    let triggers = ConfigLogic.filterTriggers(
      [],
      removing: disabled
    )
    XCTAssertTrue(triggers.isEmpty)
  }

  func test_filterTriggers_disableAll() {
    let disabled = PreloadingDisabled(
      all: true,
      triggers: []
    )
    let triggers: Set<Trigger > = [
      Trigger(placementName: "app_open", audiences: []),
      Trigger(placementName: "campaign_trigger", audiences: [.stub()])
    ]
    let filteredTriggers = ConfigLogic.filterTriggers(
      triggers,
      removing: disabled
    )
    XCTAssertTrue(filteredTriggers.isEmpty)
  }

  func test_filterTriggers_disableSome() {
    let disabled = PreloadingDisabled(
      all: false,
      triggers: ["app_open"]
    )
    let triggers: Set<Trigger > = [
      Trigger(placementName: "app_open", audiences: []),
      Trigger(placementName: "campaign_trigger", audiences: [.stub()])
    ]
    let filteredTriggers = ConfigLogic.filterTriggers(
      triggers,
      removing: disabled
    )
    XCTAssertEqual(filteredTriggers.count, 1)
    XCTAssertEqual(filteredTriggers.first!.placementName, "campaign_trigger")
  }

  func test_filterTriggers_disableNone() {
    let disabled = PreloadingDisabled(
      all: false,
      triggers: []
    )
    let triggers: Set<Trigger > = [
      Trigger(placementName: "app_open", audiences: []),
      Trigger(placementName: "campaign_trigger", audiences: [.stub()])
    ]
    let filteredTriggers = ConfigLogic.filterTriggers(
      triggers,
      removing: disabled
    )
    XCTAssertEqual(filteredTriggers.count, 2)
  }

  // MARK: - getRemovedOrChangedPaywalls

  func test_getRemovedOrChangedPaywallIds_allPaywallsRemoved() {
    let paywall = Paywall.stub()
    let oldConfig = Config.stub()
      .setting(\.paywalls, to: [paywall])
    let newConfig = Config.stub()
      .setting(\.paywalls, to: [])

    let result = ConfigLogic.getRemovedOrChangedPaywallIds(
      oldConfig: oldConfig,
      newConfig: newConfig
    )

    XCTAssertEqual(result, Set([paywall.identifier]))
  }

  func test_getRemovedOrChangedPaywallIds_noPaywallsRemoved() {
    let oldConfig = Config.stub()
    let newConfig = Config.stub()

    let result = ConfigLogic.getRemovedOrChangedPaywallIds(
      oldConfig: oldConfig,
      newConfig: newConfig
    )

    XCTAssertTrue(result.isEmpty)
  }

  func test_getRemovedOrChangedPaywallIds_cacheKeyChanged() {
    let oldPaywall = Paywall.stub()
    let newPaywall = Paywall.stub()
      .setting(\.cacheKey, to: "444")

    let oldConfig = Config.stub()
      .setting(\.paywalls, to: [oldPaywall])
    let newConfig = Config.stub()
      .setting(\.paywalls, to: [newPaywall])

    let result = ConfigLogic.getRemovedOrChangedPaywallIds(
      oldConfig: oldConfig,
      newConfig: newConfig
    )

    XCTAssertEqual(result, Set([oldPaywall.identifier]))
  }

  func test_getRemovedOrChangedPaywallIds_cacheKeyChanged_andOneRemoved() {
    let removedPaywall = Paywall.stub()
      .setting(\.identifier, to: "3368")
    let oldPaywall = Paywall.stub()
    let newPaywall = Paywall.stub()
      .setting(\.cacheKey, to: "444")

    let oldConfig = Config.stub()
      .setting(\.paywalls, to: [removedPaywall, oldPaywall])
    let newConfig = Config.stub()
      .setting(\.paywalls, to: [newPaywall])

    let result = ConfigLogic.getRemovedOrChangedPaywallIds(
      oldConfig: oldConfig,
      newConfig: newConfig
    )

    XCTAssertEqual(result, Set([oldPaywall.identifier, removedPaywall.identifier]))
  }

  // MARK: - extractEntitlements

  func test_extractEntitlements_noEntitlements() {
    let productId = "123"
    let entitlement = Entitlement.stub()
    let config = Config(
      buildId: "poWduJZYQbCA8QbWLrjJC",
      triggers: [.stub()],
      paywalls: [.stub()],
      logLevel: 0,
      locales: [],
      appSessionTimeout: 3600000,
      featureFlags: .stub(),
      preloadingDisabled: .stub(),
      attribution: .init(appleSearchAds: .init(enabled: true)),
      products: [
        .init(
          name: "test",
          type: .appStore(.init(id: productId)),
          entitlements: [entitlement]
        )
      ]
    )
    let entitlements = ConfigLogic.extractEntitlements(from: config)

    XCTAssertEqual(entitlements[productId], [entitlement])
  }
}
