//
//  PaymentSheetPaymentMethodTypeTest.swift
//  StripeiOS Tests
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripePaymentsUI

class PaymentSheetPaymentMethodTypeTest: XCTestCase {
    private func availability(_ paymentMethodTypes: [String]) -> PaymentMethodAvailabilityV1 {
        PaymentMethodAvailabilityV1(
            entries: paymentMethodTypes.map {
                PaymentMethodAvailabilityEntryV1(paymentMethodType: $0, available: true)
            }
        )
    }

    func makeConfiguration(
        hasReturnURL: Bool = false
    ) -> PaymentSheet.Configuration {
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = hasReturnURL ? "foo://bar" : nil
        return configuration
    }

    // MARK: - Server-driven PaymentSheet

    func testServerDrivenPaymentSheetConsumesGeneratedResponse() throws {
        let icon = SelectorIconV1(
            lightThemePng: "https://js.stripe.com/v3/fingerprinted/img/card-light.png",
            darkThemePng: "https://js.stripe.com/v3/fingerprinted/img/card-dark.png"
        )
        let generated = MobilePaymentElementV1(
            contract: ContractMetadataV1(
                major: MobileSessionContractV1.contractMajor,
                revision: MobileSessionContractV1.contractRevision
            ),
            paymentMethodAvailability: availability(["sepa_debit", "card"]),
            features: MobilePaymentElementFeaturesV1(
                financialConnectionsLite: "preferred",
                linkGlobalHoldbackLookup: true,
                forceVerticalPaymentMethodLayout: true,
                cardFundingFiltering: true
            ),
            assets: MobilePaymentElementAssetsV1(paymentMethods: [
                PaymentMethodAssetV1(
                    paymentMethodType: "sepa_debit",
                    displayName: "SEPA Direct Debit",
                    selectorIcon: SelectorIconV1(
                        lightThemePng: "https://js.stripe.com/v3/fingerprinted/img/sepa_debit-light.png"
                    )
                ),
                PaymentMethodAssetV1(
                    paymentMethodType: "card",
                    displayName: "Card from server",
                    selectorIcon: icon
                ),
            ]),
            formSpecs: [
                PaymentMethodFormSpecV1(type: "sepa_debit"),
                PaymentMethodFormSpecV1(
                    type: "card",
                    fields: [FormElementSpecV1(type: "native_component", component: "card_details")],
                    requiresFormScreen: true,
                    selectorIcon: icon
                ),
            ]
        )

        let response = try ServerDrivenPaymentSheetResponse(mobilePaymentElement: generated)

        XCTAssertEqual(response.contractMajor, MobileSessionContractV1.contractMajor)
        XCTAssertEqual(response.contractRevision, MobileSessionContractV1.contractRevision)
        XCTAssertEqual(response.paymentMethodTypes, ["sepa_debit", "card"])
        XCTAssertEqual(response.features.financialConnectionsLite, .preferred)
        XCTAssertEqual(response.features.forceVerticalPaymentMethodLayout, true)
        XCTAssertEqual(response.features.cardFundingFiltering, true)
        XCTAssertEqual(response.assets.paymentMethodDisplayNames["card"], "Card from server")
        let cardFields = response.formSpecs.first?["fields"] as? [[String: Any]]
        XCTAssertEqual(cardFields?.first?["type"] as? String, "native_component")
        XCTAssertEqual(cardFields?.first?["component"] as? String, "card_details")
        let cardFormSpec = response.formSpecs.first { $0["type"] as? String == "card" }
        XCTAssertEqual(cardFormSpec?["requires_form_screen"] as? Bool, true)
    }

    func testServerDrivenPaymentSheetRejectsUnsupportedContractMajor() {
        let generated = MobilePaymentElementV1(
            contract: ContractMetadataV1(major: MobileSessionContractV1.contractMajor + 1, revision: "0000000000000000"),
            paymentMethodAvailability: availability([])
        )

        XCTAssertThrowsError(try ServerDrivenPaymentSheetResponse(mobilePaymentElement: generated)) { error in
            let analytics = error.serializeForV1Analytics()
            XCTAssertEqual(analytics["error_type"] as? String, "mobile_session_contract_error")
            XCTAssertEqual(analytics["error_code"] as? String, "unsupported_contract_major")
        }
    }

    func testServerDrivenPaymentSheetRejectsCollectionBounds() {
        let generated = MobilePaymentElementV1(
            contract: ContractMetadataV1(
                major: MobileSessionContractV1.contractMajor,
                revision: MobileSessionContractV1.contractRevision
            ),
            paymentMethodAvailability: availability(Array(repeating: "card", count: 101))
        )

        XCTAssertThrowsError(try ServerDrivenPaymentSheetResponse(mobilePaymentElement: generated)) { error in
            XCTAssertEqual(
                (error as? ServerDrivenPaymentSheetResponse.Error)?.analyticsErrorCode,
                "collection_bounds"
            )
        }
    }

    func testServerDrivenPaymentSheetRejectsFieldBounds() {
        let generated = MobilePaymentElementV1(
            contract: ContractMetadataV1(
                major: MobileSessionContractV1.contractMajor,
                revision: MobileSessionContractV1.contractRevision
            ),
            paymentMethodAvailability: availability(["card"]),
            assets: MobilePaymentElementAssetsV1(paymentMethods: [
                PaymentMethodAssetV1(
                    paymentMethodType: "card",
                    displayName: String(repeating: "x", count: 201)
                ),
            ]),
            formSpecs: [PaymentMethodFormSpecV1(type: "card")]
        )

        XCTAssertThrowsError(try ServerDrivenPaymentSheetResponse(mobilePaymentElement: generated)) { error in
            XCTAssertEqual(
                (error as? ServerDrivenPaymentSheetResponse.Error)?.analyticsErrorCode,
                "field_bounds"
            )
        }
    }

    func testServerDrivenPaymentSheetRejectsMissingFormSpec() {
        let generated = MobilePaymentElementV1(
            contract: ContractMetadataV1(
                major: MobileSessionContractV1.contractMajor,
                revision: MobileSessionContractV1.contractRevision
            ),
            paymentMethodAvailability: availability(["card"]),
            assets: MobilePaymentElementAssetsV1(paymentMethods: [
                PaymentMethodAssetV1(
                    paymentMethodType: "card",
                    displayName: "Card",
                    selectorIcon: SelectorIconV1(
                        lightThemePng: "https://js.stripe.com/v3/fingerprinted/img/card-light.png"
                    )
                ),
            ]),
            formSpecs: []
        )

        XCTAssertThrowsError(try ServerDrivenPaymentSheetResponse(mobilePaymentElement: generated)) { error in
            guard case ServerDrivenPaymentSheetResponse.Error.missingFormSpec("card") = error else {
                return XCTFail("Expected missing card form spec, got \(error)")
            }
        }
    }

    func testServerDrivenPaymentSheetRejectsUnknownFormElementAndUnapprovedAssetHost() {
        let contract = ContractMetadataV1(
            major: MobileSessionContractV1.contractMajor,
            revision: MobileSessionContractV1.contractRevision
        )
        let unknownElement = MobilePaymentElementV1(
            contract: contract,
            paymentMethodAvailability: availability(["card"]),
            formSpecs: [
                PaymentMethodFormSpecV1(type: "card", fields: [FormElementSpecV1(type: "future_code")]),
            ]
        )
        let unapprovedAsset = MobilePaymentElementV1(
            contract: contract,
            paymentMethodAvailability: availability(["card"]),
            assets: MobilePaymentElementAssetsV1(paymentMethods: [
                PaymentMethodAssetV1(
                    paymentMethodType: "card",
                    displayName: "Card",
                    selectorIcon: SelectorIconV1(lightThemePng: "https://example.com/card.png")
                ),
            ])
        )
        let malformedMandateTemplate = MobilePaymentElementV1(
            contract: contract,
            paymentMethodAvailability: availability(["card"]),
            formSpecs: [
                PaymentMethodFormSpecV1(
                    type: "card",
                    fields: [
                        FormElementSpecV1(
                            type: "mandate_text",
                            localizedTextTemplate: "Authorize {{customer_email}}"
                        ),
                    ]
                ),
            ]
        )

        XCTAssertThrowsError(try ServerDrivenPaymentSheetResponse(mobilePaymentElement: unknownElement))
        XCTAssertThrowsError(try ServerDrivenPaymentSheetResponse(mobilePaymentElement: unapprovedAsset))
        XCTAssertThrowsError(
            try ServerDrivenPaymentSheetResponse(mobilePaymentElement: malformedMandateTemplate)
        )
    }

    func testServerDrivenPaymentSheetAcceptsCustomPaymentMethodAssetHost() throws {
        let paymentMethodType = "cpmt_123"
        let generated = MobilePaymentElementV1(
            contract: ContractMetadataV1(
                major: MobileSessionContractV1.contractMajor,
                revision: MobileSessionContractV1.contractRevision
            ),
            paymentMethodAvailability: availability([paymentMethodType]),
            assets: MobilePaymentElementAssetsV1(paymentMethods: [
                PaymentMethodAssetV1(
                    paymentMethodType: paymentMethodType,
                    displayName: "Custom Pay",
                    selectorIcon: SelectorIconV1(
                        lightThemePng: "https://files.stripe.com/files/custom-logo"
                    )
                ),
            ]),
            formSpecs: [
                PaymentMethodFormSpecV1(
                    type: paymentMethodType,
                    fields: [
                        FormElementSpecV1(
                            type: "native_component",
                            component: "external_confirmation"
                        ),
                    ]
                ),
            ]
        )

        let response = try ServerDrivenPaymentSheetResponse(mobilePaymentElement: generated)

        XCTAssertEqual(
            response.assets.selectorIconURLs[paymentMethodType]?.lightThemePNG,
            "https://files.stripe.com/files/custom-logo"
        )
        XCTAssertNil(response.assets.selectorIconURLs[paymentMethodType]?.darkThemePNG)
    }

    func testServerDrivenPaymentSheetRequiresExactAssetAndFormCatalogs() {
        let contract = ContractMetadataV1(
            major: MobileSessionContractV1.contractMajor,
            revision: MobileSessionContractV1.contractRevision
        )
        let cardForm = PaymentMethodFormSpecV1(
            type: "card",
            fields: [FormElementSpecV1(type: "native_component", component: "card_details")]
        )
        let cardAsset = PaymentMethodAssetV1(
            paymentMethodType: "card",
            displayName: "Card",
            selectorIcon: SelectorIconV1(
                lightThemePng: "https://js.stripe.com/v3/fingerprinted/img/card-light.png"
            )
        )

        XCTAssertThrowsError(
            try ServerDrivenPaymentSheetResponse(
                mobilePaymentElement: MobilePaymentElementV1(
                    contract: contract,
                    paymentMethodAvailability: availability(["card"]),
                    formSpecs: [cardForm]
                )
            )
        ) { error in
            guard case ServerDrivenPaymentSheetResponse.Error.missingAsset("card") = error else {
                return XCTFail("Expected missing card asset, got \(error)")
            }
        }

        XCTAssertThrowsError(
            try ServerDrivenPaymentSheetResponse(
                mobilePaymentElement: MobilePaymentElementV1(
                    contract: contract,
                    paymentMethodAvailability: availability(["card"]),
                    assets: MobilePaymentElementAssetsV1(paymentMethods: [cardAsset]),
                    formSpecs: [cardForm, PaymentMethodFormSpecV1(type: "future_payment_method")]
                )
            )
        )
    }

    func testServerDrivenPaymentMethodTypesTrustServerAvailabilityAndAssets() {
        let elementsSession = STPElementsSession._testValue(orderedPaymentMethodTypes: [.card])
        let response = ServerDrivenPaymentSheetResponse._testValue(
            features: .init(
                financialConnectionsLite: .disabled,
                linkGlobalHoldbackLookup: true,
                forceVerticalPaymentMethodLayout: true,
                cardFundingFiltering: false
            ),
            paymentMethodTypes: ["klarna"],
            assets: .init(
                paymentMethodDisplayNames: ["klarna": "Pay later from server"],
                selectorIconURLs: [:]
            ),
            formSpecs: []
        )
        elementsSession.serverDrivenPaymentSheet = response
        ServerDrivenPaymentSheetAssetStore.shared.install(response.assets)

        let paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: elementsSession,
            configuration: PaymentSheet.Configuration()
        )

        XCTAssertEqual(paymentMethodTypes, [.stripe(.klarna)])
        XCTAssertEqual(paymentMethodTypes.first?.displayName, "Pay later from server")
        XCTAssertEqual(elementsSession.serverDrivenFeatures.financialConnectionsLite, .disabled)
        XCTAssertEqual(
            PaymentSheet.Configuration().resolveLayout(elementsSession: elementsSession, paymentMethodTypes: paymentMethodTypes),
            .vertical
        )
    }

    func testServerDrivenInstantDebitsUsesPaymentMethodCodeInsteadOfNativeComponent() {
        let elementsSession = STPElementsSession._testValue(orderedPaymentMethodTypes: [.card])
        elementsSession.serverDrivenPaymentSheet = ._testValue(
            paymentMethodTypes: ["instant_debits"],
            paymentMethodCodes: ["instant_debits": "link"],
            formSpecs: [[
                "type": "instant_debits",
                "fields": [[
                    "type": "native_component",
                    "component": "link_card_collection",
                ]],
            ]]
        )

        let paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: elementsSession,
            configuration: PaymentSheet.Configuration()
        )

        XCTAssertEqual(paymentMethodTypes, [.instantDebits])
    }

    func testServerDrivenLinkCardUsesPaymentMethodCodeInsteadOfNativeComponent() {
        let elementsSession = STPElementsSession._testValue(orderedPaymentMethodTypes: [.card])
        elementsSession.serverDrivenPaymentSheet = ._testValue(
            paymentMethodTypes: ["link_card_brand"],
            paymentMethodCodes: ["link_card_brand": "link"],
            formSpecs: [[
                "type": "link_card_brand",
                "fields": [[
                    "type": "native_component",
                    "component": "instant_debits_collection",
                ]],
            ]]
        )

        let paymentMethodTypes = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: elementsSession,
            configuration: PaymentSheet.Configuration()
        )

        XCTAssertEqual(paymentMethodTypes, [.linkCardBrand])
    }

    @MainActor
    func testServerDrivenAvailabilityControlsSavedPaymentMethodsWithoutClientEligibilityFiltering() {
        let elementsSession = STPElementsSession._testValue(orderedPaymentMethodTypes: [.card])
        elementsSession.serverDrivenPaymentSheet = ._testValue(
            paymentMethodTypes: ["sepa_debit"],
            formSpecs: []
        )
        let card = STPPaymentMethod(stripeId: "pm_card", created: Date(), type: .card)
        let sepaDebit = STPPaymentMethod(stripeId: "pm_sepa", created: Date(), type: .SEPADebit)

        let filtered = PaymentSheetLoader.filterSavedPaymentMethods(
            intent: ._testPaymentIntent(paymentMethodTypes: [.card]),
            elementsSession: elementsSession,
            configuration: PaymentSheet.Configuration(),
            prefetchedSPMs: [card, sepaDebit],
            loadTimings: PaymentSheetLoader.LoadTimings()
        )

        XCTAssertEqual(filtered.map(\.stripeId), ["pm_sepa"])
    }

    // MARK: - Images

    func testMakeImage_with_client_asset_and_form_spec() {
        let e = expectation(description: "Load specs")
        FormSpecProvider.shared.load { _ in
            e.fulfill()
        }
        DownloadManager.sharedManager.resetCache()
        waitForExpectations(timeout: 10)
        // A Payment methods with a client-side asset and a form spec image URL...
        let loadExpectation = expectation(description: "Load form spec image")
        let clientImage = STPPaymentMethodType.cashApp.makeImage()!
        let image = PaymentSheet.PaymentMethodType.stripe(.cashApp).makeImage(forDarkBackground: false) { image in
            // ...should update to the form spec image
            XCTAssertNotEqual(image, clientImage)
            XCTAssertTrue(image.size.width > 1) // Sanity check
            loadExpectation.fulfill()
        }
        // ...should default to the client-side asset
        XCTAssertEqual(image, clientImage)
        waitForExpectations(timeout: 10)
    }

    func testMakeImage_with_client_asset_but_no_form_spec() {
        // A Payment methods with a client-side asset but without a form spec image URL...
        let e = expectation(description: "Load form spec image")
        e.isInverted = true
        let usBankAccountImage = PaymentSheet.PaymentMethodType.stripe(.USBankAccount).makeImage(forDarkBackground: false) { _ in
            // This shouldn't be called
            XCTFail()
            e.fulfill()
        }
        // ...should default to the client-side asset
        XCTAssertEqual(usBankAccountImage, STPPaymentMethodType.USBankAccount.makeImage())
        waitForExpectations(timeout: 0.1)
    }

    // MARK: - Cards

    /// Returns false, card not in `supportedPaymentMethods`
    func testSupportsAdding_notInSupportedList_noRequirementsNeeded() {
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .card,
                configuration: PaymentSheet.Configuration(),
                intent: ._testValue(), elementsSession: ._testCardValue(),
                supportedPaymentMethods: []
            ),
            .notSupported
        )
    }

    /// Returns true, card in `supportedPaymentMethods` and has no additional requirements
    func testSupportsAdding_inSupportedList_noRequirementsNeeded() {
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .card,
                configuration: PaymentSheet.Configuration(),
                intent: ._testPaymentIntent(paymentMethodTypes: [.card], setupFutureUsage: .offSession),
                elementsSession: ._testCardValue(),
                supportedPaymentMethods: [.card]
            ),
            .supported
        )
    }

    /// Returns true, card in `supportedPaymentMethods` and has no additional requirements
    func testSupportsAdding_inSupportedList_noRequirementsNeededButProvided() {
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .card,
                configuration: makeConfiguration(hasReturnURL: true),
                intent: ._testValue(), elementsSession: ._testCardValue(),
                supportedPaymentMethods: [.card]
            ),
            .supported
        )
    }

    // MARK: - iDEAL

    /// Returns true, iDEAL in `supportedPaymentMethods` and URL requirement and not setting up requirement are met
    func testSupportsAdding_inSupportedList_urlConfiguredRequired() {
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .iDEAL,
                configuration: makeConfiguration(hasReturnURL: true),
                intent: ._testValue(), elementsSession: ._testCardValue(),
                supportedPaymentMethods: [.iDEAL]
            ),
            .supported
        )
    }

    /// Returns true, iDEAL in `supportedPaymentMethods` but URL requirement not is met
    func testSupportsAdding_inSupportedList_urlConfiguredRequiredButNotProvided() {
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .iDEAL,
                configuration: makeConfiguration(),
                intent: ._testValue(), elementsSession: ._testCardValue(),
                supportedPaymentMethods: [.iDEAL]
            ),
            .missingRequirements([.returnURL])
        )
    }

    /// Returns true, iDEAL in `supportedPaymentMethods` and URL and delayed payment method support requirements for setting up are met
    func testSupportsAdding_inSupportedList_urlConfiguredRequiredDelayedRequired() {
        var configuration = makeConfiguration(hasReturnURL: true)
        configuration.allowsDelayedPaymentMethods = true
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .iDEAL,
                configuration: configuration,
                intent: ._testPaymentIntent(paymentMethodTypes: [.iDEAL], paymentMethodOptionsSetupFutureUsage: [.iDEAL: "off_session"]), elementsSession: ._testValue(paymentMethodTypes: ["iDEAL"]),
                supportedPaymentMethods: [.iDEAL]
            ),
            .supported
        )
    }

    /// Returns true, iDEAL in `supportedPaymentMethods` and URL requirement is met but delayed payment method support requirement for setting up is not met
    func testSupportsAdding_inSupportedList_urlConfiguredRequiredDelayedRequiredButNotProvided() {
        let configuration = makeConfiguration(hasReturnURL: true)
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .iDEAL,
                configuration: configuration,
                intent: ._testPaymentIntent(paymentMethodTypes: [.iDEAL], paymentMethodOptionsSetupFutureUsage: [.iDEAL: "off_session"]), elementsSession: ._testValue(paymentMethodTypes: ["iDEAL"]),
                supportedPaymentMethods: [.iDEAL]
            ),
            .missingRequirements([.userSupportsDelayedPaymentMethods])
        )
    }

    /// Returns true, iDEAL in `supportedPaymentMethods` and URL requirement and not setting up requirement are met
    func testSupportsAdding_inSupportedList_urlConfiguredRequiredDelayedNotRequired() {
        let configuration = makeConfiguration(hasReturnURL: true)
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .iDEAL,
                configuration: configuration,
                intent: ._testPaymentIntent(paymentMethodTypes: [.iDEAL], setupFutureUsage: .offSession, paymentMethodOptionsSetupFutureUsage: [.iDEAL: "none"]), elementsSession: ._testValue(paymentMethodTypes: ["iDEAL"]),
                supportedPaymentMethods: [.iDEAL]
            ),
            .supported
        )
    }

    // MARK: - SEPA family

    let sepaFamily: [STPPaymentMethodType] = [.SEPADebit, .iDEAL, .bancontact]

    func testCanAddSEPAFamily() {
        // iDEAL and bancontact can be added if returnURL provided
        let sepaFamilySynchronous: [STPPaymentMethodType] = [.iDEAL, .bancontact]
        for pm in sepaFamilySynchronous {
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: pm,
                    configuration: makeConfiguration(hasReturnURL: true),
                    intent: ._testValue(),
                    elementsSession: ._testCardValue(),
                    supportedPaymentMethods: sepaFamily.map { $0 }
                ),
                .supported
            )
        }

        let sepaFamilyAsynchronous: [STPPaymentMethodType] = [.SEPADebit]
        // ...SEPA also need allowsDelayedPaymentMethod:
        for pm in sepaFamilyAsynchronous {
            var config = makeConfiguration(hasReturnURL: true)
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: pm,
                    configuration: config,
                    intent: ._testValue(),
                    elementsSession: ._testCardValue(),
                    supportedPaymentMethods: sepaFamily.map { $0 }
                ),
                .missingRequirements([.userSupportsDelayedPaymentMethods])
            )
            config.allowsDelayedPaymentMethods = true
            XCTAssertEqual(
                PaymentSheet.PaymentMethodType.supportsAdding(
                    paymentMethod: pm,
                    configuration: config,
                    intent: ._testValue(),
                    elementsSession: ._testCardValue(),
                    supportedPaymentMethods: sepaFamily.map { $0 }
                ),
                .supported
            )
        }
    }

    func testCanAddMultibanco() {
        var config = makeConfiguration(hasReturnURL: true)
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .multibanco,
                configuration: config,
                intent: ._testValue(), elementsSession: ._testCardValue(),
                supportedPaymentMethods: [.multibanco]
            ),
            .missingRequirements([.userSupportsDelayedPaymentMethods])
        )
        config.allowsDelayedPaymentMethods = true
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: .multibanco,
                configuration: config,
                intent: ._testValue(), elementsSession: ._testCardValue(),
                supportedPaymentMethods: [.multibanco]
            ),
            .supported
        )
    }

    // US Bank Account
    func testCanAddUSBankAccountBasedOnVerificationMethod() {
        var configuration = PaymentSheet.Configuration()
        configuration.allowsDelayedPaymentMethods = true
        for verificationMethod in STPPaymentMethodOptions.USBankAccount.VerificationMethod.allCases {
            let usBankOptions = STPPaymentMethodOptions.USBankAccount(
                setupFutureUsage: nil,
                verificationMethod: verificationMethod,
                allResponseFields: [:]
            )
            let paymentMethodOptions = STPPaymentMethodOptions(
                usBankAccount: usBankOptions,
                card: nil,
                allResponseFields: [:]
            )
            let pi = STPFixtures.makePaymentIntent(
                paymentMethodTypes: [.USBankAccount],
                setupFutureUsage: nil,
                paymentMethodOptions: paymentMethodOptions,
                shippingProvided: false
            )
            switch verificationMethod {
            case .automatic, .instantOrSkip, .instant:
                XCTAssertEqual(
                    PaymentSheet.PaymentMethodType.supportsAdding(
                        paymentMethod: .USBankAccount,
                        configuration: configuration,
                        intent: .paymentIntent(pi),
                        elementsSession: .makeBackupElementsSession(with: pi),
                        supportedPaymentMethods: [.USBankAccount]
                    ),
                    .supported
                )

            case .skip, .microdeposits, .unknown:
                XCTAssertEqual(
                    PaymentSheet.PaymentMethodType.supportsAdding(
                        paymentMethod: .USBankAccount,
                        configuration: configuration,
                        intent: .paymentIntent(pi),
                        elementsSession: .makeBackupElementsSession(with: pi),
                        supportedPaymentMethods: [.USBankAccount]
                    ),
                    .missingRequirements([.validUSBankVerificationMethod])
                )
            }
        }
    }

    func testDisplayName() {
        XCTAssertEqual(PaymentSheet.PaymentMethodType.stripe(.card).displayName, "Card")
    }

    func testPaymentIntentRecommendedPaymentMethodTypes() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card", "klarna", "us_bank_account", "futurePaymentMethod"])
        XCTAssertEqual(elementsSession.orderedPaymentMethodTypes, [.card, .klarna, .USBankAccount, .unknown])
    }

    func testSetupIntentRecommendedPaymentMethodTypes() {
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["klarna", "card"])
        XCTAssertEqual(elementsSession.orderedPaymentMethodTypes, [.klarna, .card])
    }

    // MARK: - Payment Method Types

    func testPaymentIntentFilteredPaymentMethodTypes() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .klarna, .przelewy24])
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"
        configuration.allowsDelayedPaymentMethods = true
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: configuration
        )

        XCTAssertEqual(types, [.stripe(.card), .stripe(.klarna), .stripe(.przelewy24)])
    }

    func testPaymentIntentFilteredPaymentMethodTypes_withUnfulfilledRequirements() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .klarna, .przelewy24])
        let configuration = PaymentSheet.Configuration()
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: configuration
        )

        XCTAssertEqual(types, [.stripe(.card)])
    }

    func testPaymentIntentFilteredPaymentMethodTypes_withSetupFutureUsage() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .cashApp, .mobilePay, .amazonPay, .klarna], setupFutureUsage: .onSession)
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"
        configuration.allowsDelayedPaymentMethods = true
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: configuration
        )

        XCTAssertEqual(types, [.stripe(.card), .stripe(.cashApp), .stripe(.amazonPay), .stripe(.klarna)])
    }

    func testSetupIntentFilteredPaymentMethodTypes() {
        let setupIntent = STPFixtures.makeSetupIntent(paymentMethodTypes: [.card, .cashApp, .amazonPay, .klarna])
        let intent = Intent.setupIntent(setupIntent)
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: configuration
        )

        XCTAssertEqual(types, [.stripe(.card), .stripe(.cashApp), .stripe(.amazonPay), .stripe(.klarna)])
    }

    func testSetupIntentFilteredPaymentMethodTypes_withoutOrderedPaymentMethodTypes() {
        let setupIntent = STPFixtures.makeSetupIntent(paymentMethodTypes: [.card, .klarna, .przelewy24])
        let intent = Intent.setupIntent(setupIntent)
        let configuration = PaymentSheet.Configuration()
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(intent: intent),
            configuration: configuration
        )

        XCTAssertEqual(types, [.stripe(.card)])
    }

    func testPaymentMethodTypesLinkCardBrand() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(
                intent: intent,
                linkMode: .linkCardBrand,
                linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
                linkSupportedPaymentMethodsOnboardingEnabled: ["CARD", "INSTANT_DEBITS"]
            ),
            configuration: configuration
        )
        XCTAssertEqual(types, [.stripe(.card), .linkCardBrand])
    }

    func testPaymentMethodTypesLinkCardBrand_noDefaults() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod = false
        configuration.defaultBillingDetails.email = nil
        let types = PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(
            from: intent,
            elementsSession: ._testValue(
                intent: intent,
                linkMode: .linkCardBrand,
                linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)]
            ),
            configuration: configuration
        )
        // This configuration should not show the bank tab.
        XCTAssertEqual(types, [.stripe(.card)])
    }

    // MARK: SupportsInstantBankPayments

    func testSupportsInstantBankPayments() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .link])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            linkSupportedPaymentMethodsOnboardingEnabled: ["CARD", "INSTANT_DEBITS"]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )
        XCTAssertEqual(availability, .supported)
    }

    func testSupportsInstantBankPayments_onboardingDisabled() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .link])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkCardBrand,
            linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            linkSupportedPaymentMethodsOnboardingEnabled: ["CARD"]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case let .missingRequirements(requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        XCTAssertEqual(requirements.count, 1)
        XCTAssertEqual(requirements.first, .instantDebitsDisabledForOnboarding)
    }

    func testSupportsInstantBankPayments_missingLink() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            linkSupportedPaymentMethodsOnboardingEnabled: ["CARD", "INSTANT_DEBITS"]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        XCTAssertEqual(availability, .notSupported)
    }

    func testSupportsInstantBankPayments_invalidEmailCollectionConfiguration() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .link])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.defaultBillingDetails.email = nil
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            linkSupportedPaymentMethodsOnboardingEnabled: ["CARD", "INSTANT_DEBITS"]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case let .missingRequirements(requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        XCTAssertEqual(requirements.count, 1)
        XCTAssertEqual(requirements.first, .invalidEmailCollectionConfiguration)
    }

    func testSupportsInstantBankPayments_multipleMissingNonPrimaryRequirements() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .link, .USBankAccount])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.defaultBillingDetails.email = nil
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [ParsedEnum(.card)],
            linkSupportedPaymentMethodsOnboardingEnabled: ["CARD"]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case let .missingRequirements(requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        let expectedMissingRequirements: Set<PaymentSheet.PaymentMethodTypeRequirement> = [
            .instantDebitsDisabledForOnboarding,
            .invalidEmailCollectionConfiguration,
        ]
        XCTAssertEqual(requirements.count, 2)
        XCTAssertEqual(requirements, expectedMissingRequirements)
    }

    func testSupportsInstantBankPayments_multipleMissingRequirements() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .USBankAccount])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.defaultBillingDetails.email = nil
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [ParsedEnum(.card)]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        XCTAssertEqual(availability, .notSupported)
    }

    func testSupportsInstantBankPayments_linkDisplayNever() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .link])
        var configuration = PaymentSheet.Configuration()
        configuration.link = .init(display: .never)
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [ParsedEnum(.card)]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        XCTAssertEqual(availability, .notSupported)
    }

    func testSupportsInstantBankPayments_primaryRequirementPresent_debugDescription() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .link])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [ParsedEnum(.card)]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        let expectedDebugDescription = """
        \t* The Bank tab is configured to be hidden for your account.
        """
        XCTAssertEqual(availability.debugDescription, expectedDebugDescription)
    }

    func testSupportsInstantBankPayments_primaryRequirementMissing_debugDescription() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        let expectedDebugDescription = """
        This payment method is not currently supported by PaymentSheet.
        """
        XCTAssertEqual(availability.debugDescription, expectedDebugDescription)
    }

    // MARK: SupportsLinkCardIntegration

    func testSupportsLinkCardIntegration() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkCardBrand,
            linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            linkSupportedPaymentMethodsOnboardingEnabled: ["CARD", "INSTANT_DEBITS"]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )
        XCTAssertEqual(availability, .supported)
    }

    func testSupportsLinkCardIntegration_onboardingDisabled() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkCardBrand,
            linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            linkSupportedPaymentMethodsOnboardingEnabled: ["CARD"]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case let .missingRequirements(requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        XCTAssertEqual(requirements.count, 1)
        XCTAssertEqual(requirements.first, .instantDebitsDisabledForOnboarding)
    }

    func testSupportsLinkCardIntegration_missingLink() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        XCTAssertEqual(availability, .notSupported)
    }

    func testSupportsLinkCardIntegration_invalidEmailCollectionConfiguration() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.defaultBillingDetails.email = nil
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkCardBrand,
            linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)],
            linkSupportedPaymentMethodsOnboardingEnabled: ["CARD", "INSTANT_DEBITS"]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case let .missingRequirements(requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        XCTAssertEqual(requirements.count, 1)
        XCTAssertEqual(requirements.first, .invalidEmailCollectionConfiguration)
    }

    func testSupportsLinkCardIntegration_multipleMissingNonPrimaryRequirements() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .USBankAccount])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.defaultBillingDetails.email = nil
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkCardBrand,
            linkFundingSources: [ParsedEnum(.card)],
            linkSupportedPaymentMethodsOnboardingEnabled: ["CARD"]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        guard case let .missingRequirements(requirements) = availability else {
            XCTFail("Unexpected availability: \(availability)")
            return
        }

        let expectedMissingRequirements: Set<PaymentSheet.PaymentMethodTypeRequirement> = [
            .instantDebitsDisabledForOnboarding,
            .invalidEmailCollectionConfiguration,
        ]
        XCTAssertEqual(requirements.count, 2)
        XCTAssertEqual(requirements, expectedMissingRequirements)
    }

    func testSupportsLinkCardIntegration_multipleMissingRequirements() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card, .USBankAccount])
        var configuration = PaymentSheet.Configuration()
        configuration.billingDetailsCollectionConfiguration.email = .never
        configuration.defaultBillingDetails.email = nil
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [ParsedEnum(.card)]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        XCTAssertEqual(availability, .notSupported)
    }

    func testSupportsLinkCardIntegration_linkDisplayNever() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        var configuration = PaymentSheet.Configuration()
        configuration.link = .init(display: .never)
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkCardBrand,
            linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsInstantBankPayments(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        XCTAssertEqual(availability, .notSupported)
    }

    func testSupportsLinkCardIntegration_primaryRequirementPresent_debugDescription() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkCardBrand,
            linkFundingSources: [ParsedEnum(.card)]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        let expectedDebugDescription = """
        \t* The Bank tab is configured to be hidden for your account.
        """
        XCTAssertEqual(availability.debugDescription, expectedDebugDescription)
    }

    func testSupportsLinkCardIntegration_primaryRequirementMissing_debugDescription() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.card])
        let configuration = PaymentSheet.Configuration()
        let elementsSession = STPElementsSession._testValue(
            intent: intent,
            linkMode: .linkPaymentMethod,
            linkFundingSources: [ParsedEnum(.card), ParsedEnum(.bankAccount)]
        )

        let availability = PaymentSheet.PaymentMethodType.supportsLinkCardIntegration(
            configuration: configuration,
            intent: intent,
            elementsSession: elementsSession
        )

        let expectedDebugDescription = """
        This payment method is not currently supported by PaymentSheet.
        """
        XCTAssertEqual(availability.debugDescription, expectedDebugDescription)
    }

    // MARK: Other

    func testUnknownPMTypeIsUnsupported() {
        let setupIntent = STPFixtures.makeSetupIntent(paymentMethodTypes: [.unknown])
        let paymentMethod = STPPaymentMethod.type(from: "luxe_bucks")
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"

        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: paymentMethod,
                configuration: configuration,
                intent: Intent.setupIntent(setupIntent),
                elementsSession: ._testCardValue()
            ),
            .notSupported
        )

        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.supportsAdding(
                paymentMethod: paymentMethod,
                configuration: configuration,
                intent: ._testPaymentIntent(paymentMethodTypes: [.unknown]),
                elementsSession: .emptyElementsSession
            ),
            .notSupported
        )
    }

    func testSupport() {
        let intent = Intent._testPaymentIntent(paymentMethodTypes: [.unknown])
        var configuration = PaymentSheet.Configuration()
        configuration.returnURL = "http://return-to-url"

        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.configurationSatisfiesRequirements(
                requirements: [.returnURL],
                configuration: configuration,
                intent: intent
            ),
            .supported
        )
    }

    func testPaymentMethodOrder() {
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.externalPaymentMethodConfiguration = .init(externalPaymentMethods: ["external_paypal"], externalPaymentMethodConfirmHandler: { _, _ in
            XCTFail()
            return .canceled
        })

        func callFilteredPaymentMethodTypes(withIntentTypes paymentMethodTypes: [String], externalPMTypes: [String]) -> [PaymentSheet.PaymentMethodType] {
            let intent = Intent.deferredIntent(
                intentConfig: .init(mode: .payment(amount: 1010, currency: "USD"), confirmHandler: { _, _ in "" })
            )
            // Note: 👇 `filteredPaymentMethodTypes` is the function we are testing
            return PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(from: intent, elementsSession: ._testValue(paymentMethodTypes: paymentMethodTypes, externalPaymentMethodTypes: externalPMTypes), configuration: configuration)
        }

        // Ordering is respected
        configuration.paymentMethodOrder = ["card", "external_paypal"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["card"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["card", "external_paypal"]
        )
        configuration.paymentMethodOrder = ["external_paypal", "card"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["card"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["external_paypal", "card"]
        )
        // Omitted PMs are ordered afterwards in their original order
        configuration.paymentMethodOrder = ["card", "external_paypal"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["card", "external_paypal", "ideal", "bancontact"]
        )
        // Invalid PM types are ignored
        configuration.paymentMethodOrder = ["foo", "card", "bar", "external_paypal", "zoo"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["card", "external_paypal", "ideal", "bancontact"]
        )
        // Duplicate PMs are ignored
        configuration.paymentMethodOrder = ["card", "card", "external_paypal", "card"]
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["card", "external_paypal", "ideal", "bancontact"]
        )
        // Empty paymentMethodOrder -> uses default ordering on the Intent
        configuration.paymentMethodOrder = []
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["ideal", "card", "bancontact", "external_paypal"]
        )
        // Nil paymentMethodOrder -> uses default ordering on the Intent
        configuration.paymentMethodOrder = nil
        XCTAssertEqual(
            callFilteredPaymentMethodTypes(withIntentTypes: ["ideal", "card", "bancontact"], externalPMTypes: ["external_paypal"]).map { $0.identifier },
            ["ideal", "card", "bancontact", "external_paypal"]
        )
    }

    func testPaymentMethodOrderWithCustomPaymentMethods() {
        let cpmId = "cpmt_1Qzj4rFY0qyl6XeWoHB842bf"
        var configuration = PaymentSheet.Configuration._testValue_MostPermissive()
        configuration.customPaymentMethodConfiguration = .init(
            customPaymentMethods: [.init(id: cpmId)],
            customPaymentMethodConfirmHandler: { _, _ in
                XCTFail()
                return .canceled
            }
        )

        let elementsSession = STPElementsSession._testValue(
            orderedPaymentMethodTypes: [.card],
            customPaymentMethods: [
                CustomPaymentMethod(
                    displayName: "Test CPM",
                    type: cpmId,
                    logoUrl: URL(string: "https://test.com")!,
                    isPreset: false,
                    error: nil
                ),
            ]
        )

        let intent = Intent.deferredIntent(
            intentConfig: .init(mode: .payment(amount: 1010, currency: "USD"), confirmHandler: { _, _ in "" })
        )

        // Mixed-case CPM id in paymentMethodOrder is matched correctly
        configuration.paymentMethodOrder = [cpmId, "card"]
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(from: intent, elementsSession: elementsSession, configuration: configuration).map { $0.identifier },
            [cpmId, "card"]
        )

        // Reversed order works too
        configuration.paymentMethodOrder = ["card", cpmId]
        XCTAssertEqual(
            PaymentSheet.PaymentMethodType.filteredPaymentMethodTypes(from: intent, elementsSession: elementsSession, configuration: configuration).map { $0.identifier },
            ["card", cpmId]
        )
    }
}

extension STPFixtures {
    static func makePaymentIntent(
        amount: Int = 2345,
        currency: String = "USD",
        paymentMethodTypes: [STPPaymentMethodType]? = nil,
        setupFutureUsage: STPPaymentIntentSetupFutureUsage? = nil,
        paymentMethodOptions: STPPaymentMethodOptions? = nil,
        captureMethod: String = "automatic",
        confirmationMethod: String = "automatic",
        shippingProvided: Bool = false,
        paymentMethodJson: [String: Any]? = nil
    ) -> STPPaymentIntent {
        var json = STPTestUtils.jsonNamed(STPTestJSONPaymentIntent)!
        if let setupFutureUsage = setupFutureUsage {
            json["setup_future_usage"] = setupFutureUsage.stringValue
        }
        json["amount"] = amount
        json["currency"] = currency
        json["capture_method"] = captureMethod
        json["confirmation_method"] = confirmationMethod
        if let paymentMethodTypes = paymentMethodTypes {
            json["payment_method_types"] = paymentMethodTypes.map {
                STPPaymentMethod.string(from: $0) ?? "unknown"
            }
        }
        if !shippingProvided {
            // The payment intent json already has shipping on it, so just remove it if needed
            json["shipping"] = nil
        }
        if let paymentMethodJson = paymentMethodJson {
            json["payment_method"] = paymentMethodJson
        }
        if let paymentMethodOptions = paymentMethodOptions {
            json["payment_method_options"] = paymentMethodOptions.dictionaryValue
        }
        return STPPaymentIntent.decodedObject(fromAPIResponse: json)!
    }

    static func makeSetupIntent(
        paymentMethodTypes: [STPPaymentMethodType] = [.card],
        usage: String = "off_session",
        paymentMethodJson: [String: Any]? = nil
    ) -> STPSetupIntent {
        var json = STPTestUtils.jsonNamed(STPTestJSONSetupIntent)!
        json["usage"] = usage
        json["payment_method_types"] = paymentMethodTypes.map {
            STPPaymentMethod.string(from: $0)
        }
        if let paymentMethodJson = paymentMethodJson {
            json["payment_method"] = paymentMethodJson
        }
        return STPSetupIntent.decodedObject(fromAPIResponse: json)!
    }
}
