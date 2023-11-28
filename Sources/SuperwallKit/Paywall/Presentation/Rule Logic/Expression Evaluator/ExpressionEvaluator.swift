//
//  ExpressionEvaluator.swift
//  Superwall
//
//  Created by Yusuf Tör on 02/03/2022.
//

import Foundation
import JavaScriptCore

protocol ExpressionEvaluating {
  func evaluateExpression(
    fromRule rule: TriggerRule,
    eventData: EventData?
  ) async -> TriggerRuleOutcome
}

struct ExpressionEvaluator: ExpressionEvaluating {
  private var storage: Storage {
    return factory.storage
  }
  private let factory: DependencyContainer

  init(factory: DependencyContainer) {
    self.factory = factory
  }

  func evaluateExpression(
    fromRule rule: TriggerRule,
    eventData: EventData?
  ) async -> TriggerRuleOutcome {
    // Expression matches all
    if rule.expressionJs == nil && rule.expression == nil {
      let ruleMatched = await tryToMatchOccurrence(
        from: rule,
        expressionMatched: true
      )
      return ruleMatched
    }

    guard let jsCtx = JSContext() else {
      return .noMatch(source: .expression, experimentId: rule.experiment.id)
    }
    jsCtx.exceptionHandler = { (_, value: JSValue?) in
      guard let value = value else {
        return
      }
      let stackTraceString = value
        .objectForKeyedSubscript("stack")
        .toString()
      let lineNumber = value.objectForKeyedSubscript("line")
      let columnNumber = value.objectForKeyedSubscript("column")

      // swiftlint:disable:next line_length
      let moreInfo = "In method \(String(describing: stackTraceString)), Line number in file: \(String(describing: lineNumber)), column: \(String(describing: columnNumber))"
      Logger.debug(
        logLevel: .error,
        scope: .events,
        message: "JS ERROR: \(String(describing: value)) \(moreInfo)",
        info: nil,
        error: nil
      )
    }

    guard let base64Params = await getBase64Params(
      from: rule,
      withEventData: eventData
    ) else {
      return .noMatch(source: .expression, experimentId: rule.experiment.id)
    }

    let result = jsCtx.evaluateScript(script + "\n " + base64Params)
    if result?.isString == nil {
      return .noMatch(source: .expression, experimentId: rule.experiment.id)
    }

    let expressionMatched = result?.toString() == "true"

    let ruleMatched = await tryToMatchOccurrence(
      from: rule,
      expressionMatched: expressionMatched
    )

    return ruleMatched
  }

  private func getBase64Params(
    from rule: TriggerRule,
    withEventData eventData: EventData?
  ) async -> String? {
    let attributes = await factory.makeRuleAttributes(
      forEvent: eventData,
      withComputedProperties: rule.computedPropertyRequests
    )
    let jsonAttributes = JSON(attributes)

    if let expressionJs = rule.expressionJs {
      if let base64Params = JsExpressionEvaluatorParams(
        expressionJs: expressionJs,
        values: jsonAttributes
      ).toBase64Input() {
        let postfix = "\n SuperwallSDKJS.evaluateJS64('\(base64Params)');"
        return postfix
      }
      return nil
    } else if let expression = rule.expression {
      if let base64Params = LiquidExpressionEvaluatorParams(
        expression: expression,
        values: jsonAttributes
      ).toBase64Input() {
        let postfix = "\n SuperwallSDKJS.evaluate64('\(base64Params)');"
        return postfix
      }
      return nil
    }
    return nil
  }

  func tryToMatchOccurrence(
    from rule: TriggerRule,
    expressionMatched: Bool
  ) async -> TriggerRuleOutcome {
    if expressionMatched {
      guard let occurrence = rule.occurrence else {
        Logger.debug(
          logLevel: .debug,
          scope: .paywallPresentation,
          message: "No occurrence parameter found for trigger rule."
        )

        return .match(rule: rule)
      }

      let count = await storage
        .coreDataManager
        .countTriggerRuleOccurrences(
          for: occurrence
        ) + 1
      let shouldFire = count <= occurrence.maxCount
      var unsavedOccurrence: TriggerRuleOccurrence?

      if shouldFire {
        unsavedOccurrence = occurrence
        return .match(rule: rule, unsavedOccurrence: unsavedOccurrence)
      } else {
        return .noMatch(source: .occurrence, experimentId: rule.experiment.id)
      }
    }

    return .noMatch(source: .expression, experimentId: rule.experiment.id)
  }
}
