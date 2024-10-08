//
//  ExpressionEvaluator.swift
//  Superwall
//
//  Created by Yusuf Tör on 02/03/2022.
//

import Foundation
import JavaScriptCore
import SuperCEL

protocol ExpressionEvaluating {
  func evaluateExpression(
    fromAudienceFilter audience: TriggerRule,
    placementData: PlacementData?
  ) async -> TriggerAudienceOutcome
}

struct ExpressionEvaluator: ExpressionEvaluating {
  private let storage: Storage
  private unowned let factory: AudienceFilterAttributesFactory
  private let expressionLogic: ExpressionLogic

  init(
    storage: Storage,
    factory: AudienceFilterAttributesFactory
  ) {
    self.storage = storage
    self.factory = factory
    self.expressionLogic = ExpressionLogic(storage: storage)
  }

  func evaluateExpression(
    fromAudienceFilter audience: TriggerRule,
    placementData: PlacementData?
  ) async -> TriggerAudienceOutcome {
    // Expression matches all
    if audience.expressionJs == nil && audience.expression == nil {
      let audienceMatched = await expressionLogic.tryToMatchOccurrence(
        from: audience,
        expressionMatched: true
      )
      return audienceMatched
    }

    guard let jsCtx = JSContext() else {
      return .noMatch(source: .expression, experimentId: audience.experiment.id)
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
        scope: .placements,
        message: "JS ERROR: \(String(describing: value)) \(moreInfo)",
        info: nil,
        error: nil
      )
    }

    guard let base64Params = await getBase64Params(
      from: audience,
      withPlacementData: placementData
    ) else {
      return .noMatch(source: .expression, experimentId: audience.experiment.id)
    }

    let result = jsCtx.evaluateScript(script + "\n " + base64Params)
    if result?.isString == nil {
      return .noMatch(source: .expression, experimentId: audience.experiment.id)
    }

    let expressionMatched = result?.toString() == "true"

    let audienceMatched = await expressionLogic.tryToMatchOccurrence(
      from: audience,
      expressionMatched: expressionMatched
    )

    return audienceMatched
  }

  private func getBase64Params(
    from audience: TriggerRule,
    withPlacementData placementData: PlacementData?
  ) async -> String? {
    let attributes = await factory.makeAudienceFilterAttributes(
      forPlacement: placementData,
      withComputedProperties: audience.computedPropertyRequests
    )
    let jsonAttributes = JSON(attributes)

    if let expressionJs = audience.expressionJs {
      if let base64Params = JsExpressionEvaluatorParams(
        expressionJs: expressionJs,
        values: jsonAttributes
      ).toBase64Input() {
        let postfix = "\n SuperwallSDKJS.evaluateJS64('\(base64Params)');"
        return postfix
      }
      return nil
    } else if let expression = audience.expression {
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
}