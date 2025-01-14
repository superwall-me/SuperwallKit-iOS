//
//  SurveyManager.swift
//  Superwall-UIKit-Swift
//
//  Created by Yusuf Tör on 25/07/2023.
//
// swiftlint:disable function_body_length

import UIKit

final class SurveyManager {
  static private var otherAlertController: UIAlertController?

  static func presentSurveyIfAvailable(
    _ surveys: [Survey],
    paywallResult: PaywallResult,
    paywallCloseReason: PaywallCloseReason,
    using presenter: PaywallViewController,
    loadingState: PaywallLoadingState,
    isDebuggerLaunched: Bool,
    paywallInfo: PaywallInfo,
    storage: Storage,
    factory: TriggerFactory,
    completion: @escaping (SurveyPresentationResult) -> Void
  ) {
    guard let survey = selectSurvey(
      from: surveys,
      paywallResult: paywallResult,
      paywallCloseReason: paywallCloseReason
    ) else {
      completion(.noShow)
      return
    }

    guard
      loadingState == .ready || loadingState == .loadingPurchase
    else {
      completion(.noShow)
      return
    }
    if survey.hasSeenSurvey(storage: storage) {
      completion(.noShow)
      return
    }

    let isHoldout = survey.shouldAssignHoldout(
      isDebuggerLaunched: isDebuggerLaunched,
      storage: storage
    )

    if !isDebuggerLaunched {
      // Make sure we don't assess this survey with this assignment key again.
      storage.save(survey.assignmentKey, forType: SurveyAssignmentKey.self)
    }

    if isHoldout {
      Logger.debug(
        logLevel: .info,
        scope: .paywallViewController,
        message: "The survey will not present."
      )
      completion(.holdout)
      return
    }

    let options = survey.options.shuffled()

    // Create alert controller and add options.
    let alertController = UIAlertController(
      title: survey.title,
      message: survey.message,
      preferredStyle: .actionSheet
    )
    alertController.popoverPresentationController?.sourceView = presenter.view
    // Calculate the center of the view
    let centerX = presenter.view.bounds.midX
    let centerY = presenter.view.bounds.minY

    // Set the sourceRect to center the popover
    alertController.popoverPresentationController?.sourceRect = CGRect(x: centerX, y: centerY, width: 0, height: 0)
    alertController.isModalInPresentation = true

    for option in options {
      let action = UIAlertAction(
        title: option.title,
        style: .default
      ) { _ in
        selectedOption(
          option,
          fromSurvey: survey,
          withCustomResponse: nil,
          paywallInfo: paywallInfo,
          factory: factory,
          paywallViewController: presenter,
          alertController: alertController,
          completion: completion
        )
      }
      alertController.addAction(action)
    }

    if survey.includeOtherOption {
      let otherAction = UIAlertAction(
        title: "Other",
        style: .default
      ) { _ in
        let option = SurveyOption(id: "000", title: "Other")

        let otherAlertController = UIAlertController(
          title: survey.title,
          message: survey.message,
          preferredStyle: .alert
        )
        self.otherAlertController = otherAlertController
        otherAlertController.popoverPresentationController?.sourceView = presenter.view
        otherAlertController.addTextField { textField in
          textField.addTarget(
            self,
            action: #selector(alertTextFieldDidChange(_:)),
            for: .editingChanged
          )
          textField.placeholder = "Your response"
        }

        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
          let textField = otherAlertController.textFields?[0]
          let response = textField?.text
          selectedOption(
            option,
            fromSurvey: survey,
            withCustomResponse: response,
            paywallInfo: paywallInfo,
            factory: factory,
            paywallViewController: presenter,
            alertController: otherAlertController,
            completion: completion
          )
        }
        submitAction.isEnabled = false

        otherAlertController.addAction(submitAction)

        alertController.dismiss(animated: true) {
          presenter.present(otherAlertController, animated: true)
        }
      }
      alertController.addAction(otherAction)
    }

    if survey.includeCloseOption {
      let closeButton = UIAlertAction(title: "Close", style: .cancel) { _ in
        Task {
          let surveyClose = InternalSuperwallPlacement.SurveyClose()
          await Superwall.shared.track(surveyClose)
        }
        completion(.show)
      }
      alertController.addAction(closeButton)
    }

    presenter.present(alertController, animated: true)
  }

  static private func selectedOption(
    _ option: SurveyOption,
    fromSurvey survey: Survey,
    withCustomResponse customResponse: String?,
    paywallInfo: PaywallInfo,
    factory: TriggerFactory,
    paywallViewController: PaywallViewController,
    alertController: UIAlertController,
    completion: @escaping (SurveyPresentationResult) -> Void
  ) {
    alertController.dismiss(animated: true) {
      // Always complete without tracking if debugger launched.
      Task {
        let surveyResponse = InternalSuperwallPlacement.SurveyResponse(
          survey: survey,
          selectedOption: option,
          customResponse: customResponse,
          paywallInfo: paywallInfo
        )
        await Superwall.shared.track(surveyResponse)

        let outcome = TrackingLogic.canTriggerPaywall(
          surveyResponse,
          triggers: factory.makeTriggers(),
          paywallViewController: paywallViewController
        )

        // If we are going to implicitly show another paywall, we don't call the completion
        // block as this will call didDismiss, which is going to be called
        // implicitly anyway.
        if outcome == .dontTriggerPaywall {
          await MainActor.run {
            completion(.show)
          }
        }
      }
    }
    otherAlertController = nil
  }

  private static func selectSurvey(
    from surveys: [Survey],
    paywallResult: PaywallResult,
    paywallCloseReason: PaywallCloseReason
  ) -> Survey? {
    let isPurchased: Bool
    switch paywallResult {
    case .purchased:
      isPurchased = true
    default:
      isPurchased = false
    }
    let isDeclined = paywallResult == .declined
    let isManualClose = paywallCloseReason == .manualClose

    let onManualClose = isDeclined && isManualClose
    let onPurchase = isPurchased

    for survey in surveys {
      switch survey.presentationCondition {
      case .onManualClose:
        if onManualClose {
          return survey
        }
      case .onPurchase:
        if onPurchase {
          return survey
        }
      }
    }

    return nil
  }

  @objc
  static private func alertTextFieldDidChange(_ sender: UITextField) {
    if let text = sender.text {
      let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
      otherAlertController?.actions[0].isEnabled = !text.isEmpty
    }
  }
}
