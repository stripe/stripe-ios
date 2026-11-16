//
//  CheckoutTests.swift
//  StripePaymentSheetTests
//
//  Created by Nick Porter on 2/25/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import OHHTTPStubs
@testable @_spi(InternalOnlyAPI) import StripeCore
@testable @_spi(InternalOnlyAPI) import StripeCoreTestUtils
@testable @_spi(InternalOnlyAPI) import StripePayments
@testable @_spi(InternalOnlyAPI) import StripePaymentSheet
@testable @_spi(InternalOnlyAPI) import StripePaymentsTestUtils
@testable @_spi(InternalOnlyAPI) import StripeUICore
import UIKit
import XCTest

@MainActor
final class CheckoutTests: STPNetworkStubbingTestCase {

    func testLiveRemovedSavedCardStaysRemovedAfterLocalShippingUpdate() async throws {
        // Given a disposable customer with one saved card on the real playground backend
        HTTPStubs.removeAllStubs()
        let checkout = try await makeCustomerLogicCheckout(withSavedCard: true)
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        let card = try XCTUnwrap(embedded.savedPaymentMethods.first)
        XCTAssertTrue(checkout.session.canDetachPaymentMethod)
        let updateConfiguration = UpdatePaymentMethodViewController.Configuration(
            paymentMethod: card,
            appearance: embedded.configuration.appearance,
            billingDetailsCollectionConfiguration: embedded.configuration.billingDetailsCollectionConfiguration,
            hostedSurface: .paymentSheet,
            checkoutSessionID: checkout.session.id,
            canRemove: true,
            canUpdate: true,
            isCBCEligible: false
        )
        let updateController = UpdatePaymentMethodViewController(
            removeSavedPaymentMethodMessage: nil,
            configuration: updateConfiguration
        )

        // When the normal removal delegate runs and the backend finishes detaching the card
        embedded.didRemove(viewController: updateController, paymentMethod: card)
        XCTAssertTrue(embedded.savedPaymentMethods.isEmpty)
        let deadline = Date().addingTimeInterval(15)
        var backendRemovedCard = false
        repeat {
            let backendSession = try await checkout.apiClient.initCheckoutSession(
                checkoutSessionId: checkout.session.id,
                clientSecret: checkout.clientSecret,
                adaptivePricingAllowed: false
            )
            backendRemovedCard = backendSession.customer?.paymentMethods.contains {
                $0.stripeId == card.stripeId
            } == false
            if !backendRemovedCard {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        } while !backendRemovedCard && Date() < deadline
        XCTAssertTrue(backendRemovedCard, "The live backend must confirm removal before the local update")
        guard backendRemovedCard else { return }

        // ...and an unrelated, local-only shipping change rebuilds Payment Element
        try await checkout.updateShippingAddress(
            name: "Jenny Rosen",
            address: .init(country: "US", line1: "354 Oyster Point Blvd")
        )

        // Then the removed card must stay absent from the same embedded presentation.
        XCTAssertFalse(embedded.savedPaymentMethods.contains { $0.stripeId == card.stripeId })
    }

    func testLiveGuestCanOptIntoSavingCardWhenCustomerWillBeCreated() async throws {
        // Given a live guest session explicitly configured to create a customer and offer saving
        HTTPStubs.removeAllStubs()
        let checkout = try await makeCustomerLogicCheckout(withSavedCard: false)
        XCTAssertNil(checkout.session.customerId)
        XCTAssertEqual(checkout.session.savedPaymentMethodsOfferSave?.enabled, true)
        // Exclude the separate Link experiment that intentionally hides this checkbox.
        XCTAssertFalse(checkout.session.elementsSession.linkSignupOptInFeatureEnabled)

        // When the card form is built through the loaded Payment Element
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        let presentingViewController = UIViewController()
        embedded.presentingViewController = presentingViewController
        let cardRow = try XCTUnwrap(embedded.embeddedPaymentMethodsView.rowButtons.first {
            $0.type == .new(paymentMethodType: .stripe(.card))
        })
        embedded.embeddedPaymentMethodsView.didTap(rowButton: cardRow)
        let form = try XCTUnwrap(embedded.formCache[.stripe(.card)])
        let saveCheckbox = form.getAllUnwrappedSubElements().compactMap { $0 as? CheckboxElement }
            .first { $0.label.hasPrefix("Save") }

        // Then the guest must be able to consent to saving their card for the new customer.
        XCTAssertNotNil(saveCheckbox)
    }

    func testLiveEditedSavedCardKeepsEditsAfterLocalShippingUpdate() async throws {
        // Given a disposable customer with one saved card (exp 12/2040, no billing address) on the real playground backend
        HTTPStubs.removeAllStubs()
        let checkout = try await makeCustomerLogicCheckout(withSavedCard: true)
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        let card = try XCTUnwrap(embedded.savedPaymentMethods.first)
        XCTAssertEqual(card.card?.expMonth, 12, "The saved card must start with the expiry it was created with")
        XCTAssertEqual(card.card?.expYear, 2040, "The saved card must start with the expiry it was created with")
        // The shipping change below must take the local-only path rather than refreshing the session from the server.
        XCTAssertFalse(checkout.session.shouldSendTaxRegion(for: "shipping"), "The shipping update must be local-only")
        let canUpdate = embedded.loadResult.customerProvider.allowsPaymentMethodUpdate(
            elementsSession: embedded.elementsSession
        )
        XCTAssertTrue(canUpdate, "Checkout must allow editing saved cards")
        // ...and the saved card editor configured the way Embedded configures it
        let updateController = UpdatePaymentMethodViewController(
            removeSavedPaymentMethodMessage: nil,
            configuration: .init(
                paymentMethod: card,
                appearance: embedded.configuration.appearance,
                billingDetailsCollectionConfiguration: embedded.configuration.billingDetailsCollectionConfiguration,
                hostedSurface: .paymentSheet,
                checkoutSessionID: checkout.session.id,
                canRemove: true,
                canUpdate: canUpdate,
                isCBCEligible: false
            )
        )

        // When the customer changes the expiry to 11/41 and enters the billing ZIP the editor requires
        var textFields: [String: UITextField] = [:]
        var views: [UIView] = [updateController.view]
        while let view = views.popLast() {
            if let textField = view as? UITextField, let identifier = textField.accessibilityIdentifier {
                textFields[identifier] = textField
            }
            views.append(contentsOf: view.subviews)
        }
        let expiryField = try XCTUnwrap(textFields["MM / YY"], "The editor must show an editable expiry field")
        let postalCodeField = try XCTUnwrap(textFields["ZIP"], "The editor must show a US billing ZIP field")
        expiryField.text = "1141"
        expiryField.sendActions(for: .editingChanged)
        postalCodeField.text = "94107"
        postalCodeField.sendActions(for: .editingChanged)
        XCTAssertNotNil(updateController.updateParams, "The edited form must be valid so Save is enabled")
        // ...and saves through Embedded's normal update delegate
        let result = await embedded.didUpdate(viewController: updateController, paymentMethod: card)
        guard case .success = result else {
            return XCTFail("The live backend must accept the saved card edit: \(result)")
        }
        let editedCard = embedded.savedPaymentMethods.first { $0.stripeId == card.stripeId }
        XCTAssertEqual(editedCard?.card?.expMonth, 11, "Embedded must show the edited expiry before the local update")
        XCTAssertEqual(editedCard?.card?.expYear, 2041, "Embedded must show the edited expiry before the local update")
        // ...and a separate backend session response confirms that the server stored the edit
        let backendSession = try await checkout.apiClient.initCheckoutSession(
            checkoutSessionId: checkout.session.id,
            clientSecret: checkout.clientSecret,
            adaptivePricingAllowed: false
        )
        let backendCard = backendSession.customer?.paymentMethods.first { $0.stripeId == card.stripeId }
        let backendStoredEdit = backendCard?.card?.expMonth == 11
            && backendCard?.card?.expYear == 2041
            && backendCard?.billingDetails?.address?.postalCode == "94107"
        XCTAssertTrue(backendStoredEdit, "The live backend must store the edit before the local update")
        guard backendStoredEdit else { return }

        // ...and an unrelated, local-only shipping change rebuilds Payment Element
        try await checkout.updateShippingAddress(
            name: "Jenny Rosen",
            address: .init(country: "US", line1: "354 Oyster Point Blvd")
        )

        // Then the saved card in the same embedded presentation must keep the edits the backend stored.
        let cardAfterLocalUpdate = embedded.savedPaymentMethods.first { $0.stripeId == card.stripeId }
        XCTAssertEqual(cardAfterLocalUpdate?.card?.expMonth, 11, "The saved card's edited expiry month reverted")
        XCTAssertEqual(cardAfterLocalUpdate?.card?.expYear, 2041, "The saved card's edited expiry year reverted")
        XCTAssertEqual(
            cardAfterLocalUpdate?.billingDetails?.address?.postalCode,
            "94107",
            "The saved card's edited billing ZIP reverted"
        )
    }

    func testLiveSavedCardRemovedInEmbeddedViewIsNotListedInSheet() async throws {
        // Given a disposable customer with one saved card on the real playground backend
        HTTPStubs.removeAllStubs()
        let checkout = try await makeCustomerLogicCheckout(withSavedCard: true)
        let paymentElement = checkout.getPaymentElement()
        let embedded = paymentElement.embeddedPaymentElement
        // present(from:) shows this FlowController's existing view controller when no Checkout update is in flight.
        let flowController = paymentElement.paymentSheetFlowController
        let card = try XCTUnwrap(embedded.savedPaymentMethods.first)
        XCTAssertTrue(checkout.session.canDetachPaymentMethod, "Checkout must allow removing saved cards")
        XCTAssertTrue(
            flowController.viewController.savedPaymentMethods.contains { $0.stripeId == card.stripeId },
            "The sheet must initially list the saved card"
        )
        let updateController = UpdatePaymentMethodViewController(
            removeSavedPaymentMethodMessage: nil,
            configuration: .init(
                paymentMethod: card,
                appearance: embedded.configuration.appearance,
                billingDetailsCollectionConfiguration: embedded.configuration.billingDetailsCollectionConfiguration,
                hostedSurface: .paymentSheet,
                checkoutSessionID: checkout.session.id,
                canRemove: true,
                canUpdate: true,
                isCBCEligible: false
            )
        )

        // When the customer removes the card in the embedded view and the backend finishes detaching it
        embedded.didRemove(viewController: updateController, paymentMethod: card)
        XCTAssertTrue(embedded.savedPaymentMethods.isEmpty, "The embedded view must drop the removed card")
        let deadline = Date().addingTimeInterval(15)
        var backendRemovedCard = false
        repeat {
            let backendSession = try await checkout.apiClient.initCheckoutSession(
                checkoutSessionId: checkout.session.id,
                clientSecret: checkout.clientSecret,
                adaptivePricingAllowed: false
            )
            backendRemovedCard = backendSession.customer?.paymentMethods.contains {
                $0.stripeId == card.stripeId
            } == false
            if !backendRemovedCard {
                try await Task.sleep(nanoseconds: 100_000_000)
            }
        } while !backendRemovedCard && Date() < deadline
        XCTAssertTrue(backendRemovedCard, "The live backend must confirm removal before checking the sheet")
        guard backendRemovedCard else { return }
        // ...and the client has had time to apply the detach response, in case it does so asynchronously
        let sheetDeadline = Date().addingTimeInterval(5)
        while flowController.viewController.savedPaymentMethods.contains(where: { $0.stripeId == card.stripeId }),
              Date() < sheetDeadline {
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        // Then presenting the same PaymentElement as a sheet must not list the removed card.
        XCTAssertFalse(
            flowController.viewController.savedPaymentMethods.contains { $0.stripeId == card.stripeId },
            "The sheet still lists the card the customer removed in the embedded view"
        )
    }

    func testLiveSavedCoBrandedCardNetworkEditIsNotSilentlyDropped() async throws {
        // Given a French merchant, whose EUR Checkout Sessions are eligible for card brand choice, on the real playground backend
        HTTPStubs.removeAllStubs()
        let keyResponse = try await customerLogicBackendRequest(endpoint: "publishable_key?merchant=FR")
        let apiClient = STPAPIClient(publishableKey: try XCTUnwrap(keyResponse["publishable_key"] as? String))
        // ...and a disposable customer with one saved Cartes Bancaires / Visa co-branded card.
        // Its French billing country means the editor's billing section only asks for a country, which is already filled in.
        let customerID = try await STPTestingAPIClient.shared.createCheckoutCustomer(
            email: "customer@example.com",
            merchantCountry: "fr"
        )
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4000002500001001"
        cardParams.expMonth = 12
        cardParams.expYear = 2040
        cardParams.cvc = "123"
        let billingDetails = STPPaymentMethodBillingDetails()
        billingDetails.address = STPPaymentMethodAddress()
        billingDetails.address?.country = "FR"
        let createdPaymentMethod = try await apiClient.createPaymentMethod(with: .init(
            card: cardParams,
            billingDetails: billingDetails,
            allowRedisplay: .always,
            metadata: nil
        ))
        _ = try await customerLogicBackendRequest(endpoint: "attach_payment_method", parameters: [
            "merchant": "FR",
            "payment_method_id": createdPaymentMethod.stripeId,
            "request_params": ["customer": customerID],
        ])
        let sessionResponse = try await customerLogicBackendRequest(endpoint: "create_checkout_session", parameters: [
            "merchant": "FR",
            "stripe_version": STPTestingAPIClient.checkoutMobileElementsAPISettings,
            "request_params": [
                "ui_mode": "mobile_elements",
                "currency": "eur",
                "allowed_payment_method_types": ["card"],
                "customer": customerID,
                "items": [
                    [
                        "type": "one_time_price",
                        "one_time_price": [
                            "items": [
                                [
                                    "price_data": [
                                        "currency": "eur",
                                        "unit_amount": 2000,
                                        "product_data": ["name": "Card brand choice repro"],
                                    ],
                                    "quantity": 1,
                                ],
                            ],
                        ],
                    ],
                ],
                "saved_payment_method_options": [
                    "payment_method_save": "enabled",
                    "payment_method_remove": "enabled",
                    "allow_redisplay_filters": ["always", "limited", "unspecified"],
                ],
            ] as [String: Any],
        ])
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: try XCTUnwrap(sessionResponse["client_secret"] as? String),
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = apiClient
        configuration.paymentElement = .init()
        let checkout = try await CheckoutElementsController(configuration: configuration)
        let embedded = checkout.getPaymentElement().embeddedPaymentElement
        // With exactly one saved card, the row's Edit button opens the card editor directly.
        XCTAssertEqual(
            embedded.savedPaymentMethods.map(\.stripeId),
            [createdPaymentMethod.stripeId],
            "Payment Element must list exactly the one saved card"
        )
        let card = try XCTUnwrap(embedded.savedPaymentMethods.first)
        let availableNetworks = card.card?.networks?.available ?? []
        XCTAssertTrue(card.isCoBrandedCard, "The saved card must be co-branded, but its networks are \(availableNetworks)")
        XCTAssertTrue(
            embedded.elementsSession.isCardBrandChoiceEligible,
            "The FR merchant's EUR Checkout Session must be eligible for card brand choice"
        )
        guard card.isCoBrandedCard, embedded.elementsSession.isCardBrandChoiceEligible else { return }
        let originalBrand = try XCTUnwrap(card.card?.preferredDisplayBrand)
        let selectedBrand = try XCTUnwrap(
            availableNetworks.map { STPCard.brand(from: $0) }.first { $0 != originalBrand },
            "The co-branded card must have a network other than \(originalBrand) to switch to"
        )
        // ...and a merchant screen in a key window that Payment Element presents its sheets from
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let window = UIWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        let merchantViewController = UIViewController()
        window.rootViewController = merchantViewController
        window.makeKeyAndVisible()
        defer {
            merchantViewController.dismiss(animated: false)
            window.isHidden = true
        }
        embedded.presentingViewController = merchantViewController

        // When the customer taps Edit on the saved card's row
        var embeddedViews: [UIView] = [embedded.embeddedPaymentMethodsView]
        var editButton: RowButton.RightAccessoryButton?
        while let view = embeddedViews.popLast() {
            if let button = view as? RowButton.RightAccessoryButton, button.accessoryType == .edit {
                editButton = button
                break
            }
            embeddedViews.append(contentsOf: view.subviews)
        }
        try XCTUnwrap(editButton, "The saved card's row must show an Edit button").handleTap()
        // ...which presents the saved-card editor in a sheet
        let presentationDeadline = Date().addingTimeInterval(5)
        while merchantViewController.presentedViewController == nil, Date() < presentationDeadline {
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        let editor = try XCTUnwrap(
            merchantViewController.presentedViewController?.bottomSheetController?.contentStack.first
                as? UpdatePaymentMethodViewController,
            "Tapping Edit must open the saved-card editor"
        )
        var editorViews: [UIView] = [editor.view]
        var brandSelectorView: SegmentedSelectorView?
        while let view = editorViews.popLast() {
            if let selectorView = view as? SegmentedSelectorView {
                brandSelectorView = selectorView
                break
            }
            editorViews.append(contentsOf: view.subviews)
        }
        guard let brandSelectorView else {
            // The editor doesn't offer network selection for Checkout saved cards, so there's no edit to drop.
            return
        }
        // ...and taps the card's other network in the editor's brand selector, the same path a tap on its icon takes
        brandSelectorView.delegate?.didTap(selectedBrand.makeCardBrandItem())
        guard case .card(let editedCardParams, _) = editor.updateParams else {
            return XCTFail("Selecting the other network must enable Save")
        }
        XCTAssertEqual(
            editedCardParams.networks?.preferred,
            STPCardBrandUtilities.apiValue(from: selectedBrand),
            "The editor must capture the selected network"
        )
        // ...and taps Save, which hands the edit to Payment Element through the editor's delegate
        let editorDelegate = try XCTUnwrap(editor.delegate, "The editor must save through Payment Element")
        let result = await editorDelegate.didUpdate(viewController: editor, paymentMethod: card)
        guard case .success = result else {
            // A failed save tells the customer their network choice wasn't stored, so the edit isn't silently dropped.
            return
        }

        // Then a save reported as successful must have stored the selected network, both in Payment Element...
        let displayedCard = embedded.savedPaymentMethods.first { $0.stripeId == card.stripeId }
        XCTAssertEqual(
            displayedCard?.card?.preferredDisplayBrand,
            selectedBrand,
            "The save reported success, but Payment Element still shows the card's original network"
        )
        // ...and on the server, as seen by a separate backend session response
        let backendSession = try await checkout.apiClient.initCheckoutSession(
            checkoutSessionId: checkout.session.id,
            clientSecret: checkout.clientSecret,
            adaptivePricingAllowed: false
        )
        let backendCard = backendSession.customer?.paymentMethods.first { $0.stripeId == card.stripeId }
        XCTAssertEqual(
            backendCard?.card?.networks?.preferred,
            STPCardBrandUtilities.apiValue(from: selectedBrand),
            "The save reported success, but the server didn't store the selected network"
        )
    }

    func makeCustomerLogicCheckout(withSavedCard: Bool) async throws -> CheckoutElementsController {
        let keyResponse = try await customerLogicBackendRequest(endpoint: "publishable_key?merchant=US")
        let apiClient = STPAPIClient(publishableKey: try XCTUnwrap(keyResponse["publishable_key"] as? String))
        var sessionParameters: [String: Any] = [
            "ui_mode": "mobile_elements",
            "currency": "usd",
            "allowed_payment_method_types": ["card"],
            "items": [
                [
                    "type": "one_time_price",
                    "one_time_price": [
                        "items": [
                            [
                                "price_data": [
                                    "currency": "usd",
                                    "unit_amount": 2000,
                                    "product_data": ["name": "Customer logic repro"],
                                ],
                                "quantity": 1,
                            ],
                        ],
                    ],
                ],
            ],
            "saved_payment_method_options": [
                "payment_method_save": "enabled",
                "payment_method_remove": "enabled",
                "allow_redisplay_filters": ["always", "limited", "unspecified"],
            ],
        ]
        if withSavedCard {
            let customerID = try await STPTestingAPIClient.shared.createCheckoutCustomer(email: "customer@example.com")
            let card = STPPaymentMethodCardParams()
            card.number = "4242424242424242"
            card.expMonth = 12
            card.expYear = 2040
            card.cvc = "123"
            let paymentMethod = try await apiClient.createPaymentMethod(with: .init(
                card: card,
                billingDetails: nil,
                allowRedisplay: .always,
                metadata: nil
            ))
            _ = try await customerLogicBackendRequest(endpoint: "attach_payment_method", parameters: [
                "merchant": "US",
                "payment_method_id": paymentMethod.stripeId,
                "request_params": ["customer": customerID],
            ])
            sessionParameters["customer"] = customerID
        } else {
            sessionParameters["customer_creation"] = "always"
        }
        let response = try await customerLogicBackendRequest(endpoint: "create_checkout_session", parameters: [
            "merchant": "US",
            "stripe_version": STPTestingAPIClient.checkoutMobileElementsAPISettings,
            "request_params": sessionParameters,
        ])
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: try XCTUnwrap(response["client_secret"] as? String),
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = apiClient
        configuration.paymentElement = .init()
        return try await CheckoutElementsController(configuration: configuration)
    }

    func customerLogicBackendRequest(
        endpoint: String,
        parameters: [String: Any]? = nil
    ) async throws -> [String: Any] {
        let url = try XCTUnwrap(URL(string: STPTestingAPIClient.STPTestingPlaygroundBackendURL + endpoint))
        var request = URLRequest(url: url)
        request.httpMethod = parameters == nil ? "GET" : "POST"
        if let parameters {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = try XCTUnwrap(response as? HTTPURLResponse)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertTrue((200..<300).contains(httpResponse.statusCode), "Playground request failed: \(json)")
        return json
    }

    func testLoadCheckoutSession() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession()
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        let session = checkout.session
        XCTAssertEqual(session.id, checkoutSessionResponse.id)
        XCTAssertEqual(session.status, .open)
        XCTAssertEqual(session.currency, "usd")
        XCTAssertFalse(session.livemode)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 2000)
        XCTAssertFalse(checkout.isUpdating)
    }

    func testCheckoutSessionWithEmailOnCustomer() async throws {
        // Given a Checkout Session whose Customer has an email
        let customerID = try await STPTestingAPIClient.shared.createCheckoutCustomer(
            email: "customer@example.com"
        )
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            customerID: customerID
        )
        var configuration = CheckoutElementsController.Configuration(
            clientSecret: checkoutSessionResponse.clientSecret,
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)

        // When initializing CheckoutElementsController
        let checkout = try await CheckoutElementsController(configuration: configuration)

        // Then Customer.email becomes the server-backed effective Session email
        XCTAssertEqual(checkout.session.serverEmail, "customer@example.com")
        XCTAssertNil(checkout.session.localState.email)
        XCTAssertEqual(checkout.session.email, "customer@example.com")
    }

    // TODO(porter): unified mode does not yet support promo codes.
    func disabled_testPromotionCodeApplyEmitsSessionUpdates() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            allowPromotionCodes: true
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        let recorder = CheckoutEmissionRecorder(checkout)

        try await checkout.applyPromotionCode("SAVE25")

        // Applying the promotion code emits once for the server-backed Checkout session update
        // and once when PaymentElement re-syncs its local payment option.
        XCTAssertEqual(recorder.sessions.count, 2)
        XCTAssertEqual(promotionCode(in: recorder.sessions.last), "SAVE25")
        XCTAssertEqual(recorder.loading, [true, false])
    }

    // TODO(porter): see disabled_testPromotionCodeApplyEmitsSessionUpdates above.
    func disabled_testApplyPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            allowPromotionCodes: true
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        XCTAssertTrue(checkout.session.discountAmounts.isEmpty)
        XCTAssertNil(promotionCode(in: checkout.session))
        XCTAssertEqual(2000, checkout.session.totals.total.minorUnitsAmount)

        try await checkout.applyPromotionCode("SAVE25")

        let session = checkout.session
        XCTAssertFalse(session.discountAmounts.isEmpty)
        XCTAssertEqual(promotionCode(in: session), "SAVE25")
        XCTAssertEqual(1500, session.totals.total.minorUnitsAmount)
    }

    // TODO(porter): see disabled_testPromotionCodeApplyEmitsSessionUpdates above.
    func disabled_testRemovePromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            allowPromotionCodes: true
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        // Apply first
        try await checkout.applyPromotionCode("SAVE25")
        XCTAssertFalse(checkout.session.discountAmounts.isEmpty)
        XCTAssertEqual(promotionCode(in: checkout.session), "SAVE25")
        XCTAssertEqual(1500, checkout.session.totals.total.minorUnitsAmount)

        // Then remove
        try await checkout.removePromotionCode()
        let session = checkout.session
        XCTAssertTrue(session.discountAmounts.isEmpty)
        XCTAssertNil(promotionCode(in: session))
        XCTAssertEqual(2000, session.totals.total.minorUnitsAmount)
    }

    // TODO(porter): see disabled_testPromotionCodeApplyEmitsSessionUpdates above.
    func disabled_testApplyInvalidPromotionCode() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            allowPromotionCodes: true
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        do {
            try await checkout.applyPromotionCode("BOGUS_CODE_123")
            XCTFail("Expected CheckoutError.apiError")
        } catch let error as CheckoutError {
            guard case .apiError = error else {
                XCTFail("Expected .apiError, got \(error)")
                return
            }
        }
    }

    func testUpdateBillingTaxRegionIfNecessary() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            amount: 5050,
            merchantCountry: "us_tax",
            collectBillingAddress: true,
            automaticTax: true
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        // Pre-tax price, CA sales has not yet been applied
        XCTAssertEqual(checkout.session.totals.subtotal.minorUnitsAmount, 5050)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 5050)

        // Update the billing tax region to get tax applied
        try await checkout.updateBillingTaxRegionIfNecessary(
            address: .init(
                country: "US",
                line1: "123 Main St",
                city: "San Francisco",
                state: "CA",
                postalCode: "94105"
            )
        )

        // Session should be refreshed (tax_region was sent to the server)
        XCTAssertEqual(checkout.session.status, .open)

        // Post-tax price, CA sales tax was applied; subtotal unchanged proves the increase is purely tax
        XCTAssertEqual(checkout.session.totals.subtotal.minorUnitsAmount, 5050)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 5486)

        // When the billing address is removed, let CheckoutClient resolve the default tax country.
        try await checkout.updateBillingTaxRegionIfNecessary(address: nil)

        // Then the previous street address no longer supplies the tax calculation.
        XCTAssertEqual(checkout.session.status, .open)
        XCTAssertEqual(checkout.session.tax?.status, .requiresBillingAddress)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 5050)
    }

    func testLoadUnifiedModeCheckoutSession() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax"
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        let session = checkout.session
        XCTAssertEqual(session.id, checkoutSessionResponse.id)
        XCTAssertEqual(session.status, .open)
        XCTAssertEqual(session.totals.total.minorUnitsAmount, 2000)
        XCTAssertEqual(session.amount, 2000)
        XCTAssertEqual(session.orderSummaryItems.count, 1)
        guard case .oneTimePrice(let oneTimePrice) = session.orderSummaryItems.first else {
            return XCTFail("Expected one-time price order summary item")
        }
        XCTAssertFalse(oneTimePrice.key.isEmpty)
        XCTAssertNil(oneTimePrice.description)
        XCTAssertEqual(oneTimePrice.items.count, 1)
        let item = try XCTUnwrap(oneTimePrice.items.first)
        XCTAssertFalse(item.key.isEmpty)
        XCTAssertEqual(item.displayName, "Test")
        XCTAssertEqual(item.images, [])
        XCTAssertEqual(item.unitAmount.minorUnitsAmount, 2000)
        XCTAssertEqual(item.unitAmountDecimal?.minorUnitsAmount, 2000)
        XCTAssertNil(item.unitLabel)
        XCTAssertEqual(item.quantity, 1)
        XCTAssertNil(item.adjustableQuantity)
        XCTAssertEqual(item.amountDetails.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(item.amountDetails.total.minorUnitsAmount, 2000)
        XCTAssertNil(item.amountDetails.taxAmounts)
        XCTAssertEqual(item.amountDetails.taxInclusive.minorUnitsAmount, 0)
        XCTAssertEqual(item.amountDetails.taxExclusive.minorUnitsAmount, 0)
    }

    func testUpdateShippingAddress() async throws {
        let checkoutSessionResponse = try await STPTestingAPIClient.shared.createCheckoutSession(
            merchantCountry: "us_tax",
            automaticTax: true,
            allowedShippingCountries: ["US"]
        )
        var configuration = CheckoutElementsController.Configuration(clientSecret: checkoutSessionResponse.clientSecret, returnURL: "stripe-ios-test://checkout-return")
        configuration.apiClient = STPAPIClient(publishableKey: checkoutSessionResponse.publishableKey)
        let checkout = try await CheckoutElementsController(configuration: configuration)

        XCTAssertNil(checkout.session.shippingAddress)
        XCTAssertEqual(checkout.session.totals.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 2000)
        XCTAssertNotNil(checkout.session.taxAmounts)
        XCTAssertTrue(checkout.session.taxAmounts?.isEmpty == true)

        try await checkout.updateShippingAddress(
            name: "John Smith",
            address: .init(
                country: "US",
                line1: "456 Oak Ave",
                city: "Los Angeles",
                state: "CA",
                postalCode: "90001"
            )
        )

        // Address should be stored on the session
        let storedShipping = checkout.session.shippingAddress
        XCTAssertNotNil(storedShipping)
        XCTAssertEqual(storedShipping?.name, "John Smith")
        XCTAssertEqual(storedShipping?.address.country, "US")
        XCTAssertEqual(storedShipping?.address.line1, "456 Oak Ave")
        XCTAssertEqual(storedShipping?.address.city, "Los Angeles")
        XCTAssertEqual(storedShipping?.address.state, "CA")
        XCTAssertEqual(storedShipping?.address.postalCode, "90001")

        // Session should be refreshed (tax_region was sent to the server)
        XCTAssertEqual(checkout.session.status, .open)

        XCTAssertEqual(checkout.session.totals.subtotal.minorUnitsAmount, 2000)
        XCTAssertEqual(checkout.session.taxAmounts?.count, 1)
        let taxAmount = try XCTUnwrap(checkout.session.taxAmounts?.first?.minorUnitsAmount)
        XCTAssertGreaterThan(taxAmount, 0)
        XCTAssertEqual(
            checkout.session.totals.total.minorUnitsAmount,
            checkout.session.totals.subtotal.minorUnitsAmount + taxAmount
        )

        // When the shipping address is removed, let CheckoutClient resolve the default tax country.
        try await checkout.updateShippingAddress(name: nil, address: nil)

        // Then local shipping and the previous address's tax calculation are cleared together.
        XCTAssertNil(checkout.session.shippingAddress)
        XCTAssertEqual(checkout.session.status, .open)
        XCTAssertEqual(checkout.session.tax?.status, .requiresShippingAddress)
        XCTAssertEqual(checkout.session.totals.total.minorUnitsAmount, 2000)
    }

    func testClearLocalCustomerDataClearsLinkState() {
        // Given a customer who has used Link
        UserDefaults.standard.markLinkAsUsed()
        XCTAssertTrue(UserDefaults.standard.customerHasUsedLink)
        // ...and has a Link account in memory
        LinkAccountContext.shared.account = PaymentSheetLinkAccount(
            email: "user@example.com",
            session: nil,
            publishableKey: nil,
            displayablePaymentDetails: nil,
            apiClient: STPAPIClient(publishableKey: STPTestingDefaultPublishableKey),
            useMobileEndpoints: false,
            canSyncAttestationState: false
        )
        defer {
            LinkAccountContext.shared.account = nil
        }

        // When the customer is reset
        CheckoutElementsController.clearLocalCustomerData()

        // Then the persisted Link state is cleared
        XCTAssertFalse(UserDefaults.standard.customerHasUsedLink)
        // ...and the in-memory Link account is cleared
        XCTAssertNil(LinkAccountContext.shared.account)
    }

    func testClearLocalCustomerDataLogsAnalytic() {
        let analyticsClient = STPAnalyticsClient.sharedClient
        let previousLogHistory = analyticsClient._testLogHistory
        analyticsClient._testLogHistory = []
        defer { analyticsClient._testLogHistory = previousLogHistory }

        CheckoutElementsController.clearLocalCustomerData()

        let events = analyticsClient._testLogHistory.filter {
            $0["event"] as? String == "checkout_elements.clear_local_customer_data"
        }
        XCTAssertEqual(events.count, 1)
    }

    private func promotionCode(in session: CheckoutElementsController.Session?) -> String? {
        session?.discountAmounts.first(where: { $0.promotionCode != nil })?.promotionCode
    }
}
