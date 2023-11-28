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
    } catch let error as ConfigLogic.TriggerRuleError {
      XCTAssertEqual(error, ConfigLogic.TriggerRuleError.noVariantsFound)
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
      XCTAssertEqual(options.first!.toVariant(), variant)
    } catch let error as ConfigLogic.TriggerRuleError {
      XCTAssertEqual(error, ConfigLogic.TriggerRuleError.invalidState)
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
      XCTAssertEqual(options.first!.toVariant(), variant)
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
      XCTAssertEqual(options.last!.toVariant(), variant)
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
      XCTAssertEqual(options[1].toVariant(), variant)
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
      XCTAssertEqual(options.first!.toVariant(), variant)
    } catch {
      XCTFail("Should have produced a no variant error")
    }
  }

  // MARK: - getRulesPerTriggerGroup

  func test_getRulesPerTriggerGroup_noTriggers() {
    let rules = ConfigLogic.getRulesPerCampaign(from: [])
    XCTAssertTrue(rules.isEmpty)
  }

  func test_getRulesPerTriggerGroup_noRules() {
    let rules = ConfigLogic.getRulesPerCampaign(from: [
      .stub()
      .setting(\.rules, to: [])
    ])
    XCTAssertTrue(rules.isEmpty)
  }

  func test_getRulesPerTriggerGroup_threeTriggersTwoWithSameGroupId() {
    let trigger1 = Trigger.stub()
      .setting(\.rules, to: [
        .stub()
        .setting(\.experiment.groupId, to: "1")
      ])
    let trigger2 = Trigger.stub()
      .setting(\.rules, to: [
        .stub()
        .setting(\.experiment.groupId, to: "1")
      ])
    let trigger3 = Trigger.stub()
      .setting(\.rules, to: [
        .stub()
        .setting(\.experiment.groupId, to: "2")
      ])
    let rules = ConfigLogic.getRulesPerCampaign(from: [
      trigger1, trigger2, trigger3
    ])
    XCTAssertEqual(rules.count, 2)
    XCTAssertTrue(rules.contains(trigger3.rules))
    XCTAssertTrue(rules.contains(trigger1.rules))
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
        .setting(\.rules, to: [])
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
        .setting(\.rules, to: [
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
    XCTAssertEqual(variant.unconfirmed[experimentId], variantOption.toVariant())
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
        .setting(\.rules, to: [
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
      confirmedAssignments: [experimentId: variantOption.toVariant()]
    )

    // Then
    XCTAssertEqual(variant.confirmed.count, 1)
    XCTAssertEqual(variant.confirmed[experimentId], variantOption.toVariant())
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
        .setting(\.rules, to: [
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
      confirmedAssignments: [experimentId: oldVariantOption.toVariant()]
    )

    // Then
    XCTAssertEqual(variant.unconfirmed.count, 1)
    XCTAssertEqual(variant.unconfirmed[experimentId], newVariantOption.toVariant())
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
        .setting(\.rules, to: [
          .stub()
          .setting(\.experiment, to: .stub()
            .setting(\.id, to: experimentId)
            .setting(\.groupId, to: experimentGroupId)
            .setting(\.variants, to: [])
          )
        ])
      ],
      confirmedAssignments: [experimentId: oldVariantOption.toVariant()]
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
      .setting(\.rules, to: [
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
      confirmedAssignments: [experimentId: oldVariantOption.toVariant()],
      unconfirmedAssignments: ["jkl": .init(id: "mno", type: .treatment, paywallId: "pqr")]
    )

    XCTAssertEqual(result.confirmed[experimentId], variantOption.toVariant())
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
      .setting(\.rules, to: [
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
    XCTAssertEqual(result.confirmed[experimentId1], variantOption1.toVariant())
    XCTAssertEqual(result.confirmed[experimentId2], variantOption2.toVariant())
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
      .setting(\.rules, to: [
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

    let evaluator = ExpressionEvaluatorMock(outcome: .match(rule: .stub()))

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
      .setting(\.rules, to: [
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

    let evaluator = ExpressionEvaluatorMock(outcome: .match(rule: .stub()))

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
      .setting(\.rules, to: [
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
      .setting(\.rules, to: [
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
      .setting(\.rules, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.id, to: experiment1)
        )
      ]),
      .stub()
      .setting(\.rules, to: [
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
    let evaluator = ExpressionEvaluatorMock(outcome: .match(rule: .stub()))

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
      .setting(\.rules, to: [
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
    let evaluator = ExpressionEvaluatorMock(outcome: .match(rule: .stub()))

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
      .setting(\.rules, to: [
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
    let evaluator = ExpressionEvaluatorMock(outcome: .match(rule: .stub()))

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
      .setting(\.rules, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.groupId, to: "a")
            .setting(\.id, to: experiment1)
        )
      ]),
      .stub()
      .setting(\.rules, to: [
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
    let evaluator = ExpressionEvaluatorMock(outcome: .match(rule: .stub()))

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
      .setting(\.rules, to: [
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
      .setting(\.rules, to: [
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
      .setting(\.rules, to: [
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
      .setting(\.rules, to: [
        .stub()
        .setting(
          \.experiment,
           to: .stub()
            .setting(\.groupId, to: "abc")
            .setting(\.id, to: experiment1)
        )
      ]),
      .stub()
      .setting(\.rules, to: [
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
      .setting(\.eventName, to: "abc")
    
    let secondTrigger: Trigger = .stub()
      .setting(\.eventName, to: "def")
    
    let triggers: Set<Trigger> = [
      firstTrigger, secondTrigger
    ]
    let dictionary = ConfigLogic.getTriggersByEventName(from: triggers)
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
      Trigger(eventName: "app_open", rules: []),
      Trigger(eventName: "campaign_trigger", rules: [.stub()])
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
      Trigger(eventName: "app_open", rules: []),
      Trigger(eventName: "campaign_trigger", rules: [.stub()])
    ]
    let filteredTriggers = ConfigLogic.filterTriggers(
      triggers,
      removing: disabled
    )
    XCTAssertEqual(filteredTriggers.count, 1)
    XCTAssertEqual(filteredTriggers.first!.eventName, "campaign_trigger")
  }

  func test_filterTriggers_disableNone() {
    let disabled = PreloadingDisabled(
      all: false,
      triggers: []
    )
    let triggers: Set<Trigger > = [
      Trigger(eventName: "app_open", rules: []),
      Trigger(eventName: "campaign_trigger", rules: [.stub()])
    ]
    let filteredTriggers = ConfigLogic.filterTriggers(
      triggers,
      removing: disabled
    )
    XCTAssertEqual(filteredTriggers.count, 2)
  }
}
