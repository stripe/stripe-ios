//
//  PaymentSheetClientAttributionMetadataTests.swift
//  StripePaymentSheetTests
//
//  Created by Joyce Qin on 10/22/25.
//

@testable@_spi(STP) @_spi(CustomerSessionBetaAccess) @_spi(ConfirmationTokensPublicPreview) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils

class ClientAttributionMetadataCoverageTests: STPNetworkStubbingTestCase {

    enum IntentKind: CaseIterable {
        case paymentIntent_intentFirst_csc
        case paymentIntent_deferredIntent_csc
        case paymentIntent_deferredIntent_ssc
        case paymentIntent_deferredIntent_csc_ct
        case paymentIntent_deferredIntent_ssc_ct

        case setupIntent_intentFirst_csc
        case setupIntent_deferredIntent_csc
        case setupIntent_deferredIntent_ssc
        case setupIntent_deferredIntent_csc_ct
        case setupIntent_deferredIntent_ssc_ct
    }

    var apiClient: STPAPIClient!

    override func setUp() {
        super.setUp()
        self.apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        AnalyticsHelper.shared.generateSessionID()
    }
    let paramsForServerSideConfirmation: [String: Any] = [ // We require merchants to set some extra parameters themselves for server-side confirmation
        "return_url": "foo://bar",
        "mandate_data": [
            "customer_acceptance": [
                "type": "online",
                "online": [
                    "user_agent": "123",
                    "ip_address": "172.18.117.125",
                ],
            ] as [String: Any],
        ],
    ]
    lazy var newCardPaymentOption: PaymentSheet.PaymentOption = {
        let cardParams = STPPaymentMethodCardParams()
        cardParams.number = "4242424242424242"
        cardParams.cvc = "123"
        cardParams.expYear = 32
        cardParams.expMonth = 12
        let confirmParams: IntentConfirmParams = .init(
            params: .init(
                card: cardParams,
                billingDetails: .init(),
                metadata: nil
            ),
            type: .stripe(.card)
        )
        let newCardPaymentOption: PaymentSheet.PaymentOption = .new(
            confirmParams: confirmParams
        )

        return newCardPaymentOption
    }()
    func savedCardPaymentOption() async throws -> PaymentSheet.PaymentOption {
        return await .saved(paymentMethod: try apiClient.createPaymentMethod(with: ._testValidCardValue()), confirmParams: nil)
    }
    enum Endpoint: String {
        case confirm
        case paymentMethods = "payment_methods"
        case confirmationTokens = "confirmation_tokens"
    }

    enum Nested: String {
        case paymentMethodData = "payment_method_data"
        case paymentMethodOptions = "payment_method_options"
    }
    // MARK: - CAM Tests: New Payment Method
    func testNewCard_IntentFirst_PaymentIntent() async throws {
        try await _testConfirm(
            intentKind: .paymentIntent_intentFirst_csc,
            paymentOption: newCardPaymentOption
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirm,
            nestedUnder: .paymentMethodData,
            expectedPaymentIntentCreationFlow: "standard",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
    }

    func testNewCard_DeferredClientSide_PaymentIntent() async throws {
        try await _testConfirm(
            intentKind: .paymentIntent_deferredIntent_csc,
            paymentOption: newCardPaymentOption
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .paymentMethods,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "automatic"
        )
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirm,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "automatic"
        )
    }

    func testNewCard_DeferredServerSide_PaymentIntent() async throws {
        try await _testConfirm(
            intentKind: .paymentIntent_deferredIntent_ssc,
            paymentOption: newCardPaymentOption
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .paymentMethods,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "automatic"
        )
    }

    func testNewCard_DeferredClientSideCT_PaymentIntent() async throws {
        try await _testConfirm(
            intentKind: .paymentIntent_deferredIntent_csc_ct,
            paymentOption: newCardPaymentOption
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirmationTokens,
            nestedUnder: .paymentMethodData,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirm,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
    }

    func testNewCard_DeferredServerSideCT_PaymentIntent() async throws {
        try await _testConfirm(
            intentKind: .paymentIntent_deferredIntent_ssc_ct,
            paymentOption: newCardPaymentOption
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirmationTokens,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
    }

    func testNewCard_IntentFirst_SetupIntent() async throws {
        try await _testConfirm(
            intentKind: .setupIntent_intentFirst_csc,
            paymentOption: newCardPaymentOption
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirm,
            nestedUnder: .paymentMethodData,
            expectedPaymentIntentCreationFlow: "standard",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
    }

    func testNewCard_DeferredClientSide_SetupIntent() async throws {
        try await _testConfirm(
            intentKind: .setupIntent_deferredIntent_csc,
            paymentOption: newCardPaymentOption
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .paymentMethods,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "automatic"
        )
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirm,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "automatic"
        )
    }

    func testNewCard_DeferredServerSide_SetupIntent() async throws {
        try await _testConfirm(
            intentKind: .setupIntent_deferredIntent_ssc,
            paymentOption: newCardPaymentOption
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .paymentMethods,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "automatic"
        )
    }

    func testNewCard_DeferredClientSideCT_SetupIntent() async throws {
        try await _testConfirm(
            intentKind: .setupIntent_deferredIntent_csc_ct,
            paymentOption: newCardPaymentOption
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirmationTokens,
            nestedUnder: .paymentMethodData,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirm,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
    }

    func testNewCard_DeferredServerSideCT_SetupIntent() async throws {
        try await _testConfirm(
            intentKind: .setupIntent_deferredIntent_ssc_ct,
            paymentOption: newCardPaymentOption
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirmationTokens,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
    }
    // MARK: - CAM Tests: Saved Payment Method
    func testSavedCard_IntentFirst_PaymentIntent() async throws {
        try await _testConfirm(
            intentKind: .paymentIntent_intentFirst_csc,
            paymentOption: savedCardPaymentOption()
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirm,
            expectedPaymentIntentCreationFlow: "standard",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
    }

    func testSavedCard_DeferredClientSide_PaymentIntent() async throws {
        try await _testConfirm(
            intentKind: .paymentIntent_deferredIntent_csc,
            paymentOption: savedCardPaymentOption()
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirm,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "automatic"
        )
    }

    func testSavedCard_DeferredClientSideCT_PaymentIntent() async throws {
        try await _testConfirm(
            intentKind: .paymentIntent_deferredIntent_csc_ct,
            paymentOption: savedCardPaymentOption()
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirmationTokens,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirm,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
    }

    func testSavedCard_DeferredServerSideCT_PaymentIntent() async throws {
        try await _testConfirm(
            intentKind: .paymentIntent_deferredIntent_ssc_ct,
            paymentOption: savedCardPaymentOption()
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirmationTokens,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
    }

    func testSavedCard_IntentFirst_SetupIntent() async throws {
        try await _testConfirm(
            intentKind: .setupIntent_intentFirst_csc,
            paymentOption: savedCardPaymentOption()
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirm,
            expectedPaymentIntentCreationFlow: "standard",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
    }

    func testSavedCard_DeferredClientSide_SetupIntent() async throws {
        try await _testConfirm(
            intentKind: .setupIntent_deferredIntent_csc,
            paymentOption: savedCardPaymentOption()
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirm,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "automatic"
        )
    }

    func testSavedCard_DeferredClientSideCT_SetupIntent() async throws {
        try await _testConfirm(
            intentKind: .setupIntent_deferredIntent_csc_ct,
            paymentOption: savedCardPaymentOption()
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirmationTokens,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirm,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
    }

    func testSavedCard_DeferredServerSideCT_SetupIntent() async throws {
        try await _testConfirm(
            intentKind: .setupIntent_deferredIntent_ssc_ct,
            paymentOption: savedCardPaymentOption()
        )

        // Verify CAM in recorded stubs
        try verifyClientAttributionMetadataInStubs(
            testName: self.name,
            endpoint: .confirmationTokens,
            expectedPaymentIntentCreationFlow: "deferred",
            expectedPaymentMethodSelectionFlow: "merchant_specified"
        )
    }

    // MARK: - CAM Verification Helper

    /// Verifies that client_attribution_metadata appears in recorded network stubs with expected values
    func verifyClientAttributionMetadataInStubs(
        testName: String,
        endpoint: Endpoint,
        nestedUnder: Nested? = nil,
        expectedPaymentIntentCreationFlow: String?,
        expectedPaymentMethodSelectionFlow: String?
    ) throws {
        // The test name comes in format like "-[PaymentSheetClientAttributionMetadataTests testNewCard_IntentFirst_PaymentIntent]"
        // We need to extract just the test method name and remove underscores
        var testMethodName = testName.components(separatedBy: " ").last?
            .trimmingCharacters(in: CharacterSet(charactersIn: "[]")) ?? testName

        // Remove underscores to match directory naming convention
        testMethodName = testMethodName.replacingOccurrences(of: "_", with: "")

        // Construct the path to the recorded network traffic directory
        let testClass = "ClientAttributionMetadataCoverageTests"

        // The stubs are stored in the source tree relative to the repository root
        let fileManager = FileManager.default
        let currentFile = #file
        let currentDir = URL(fileURLWithPath: currentFile).deletingLastPathComponent()

        // Navigate from test file to stripe-ios root, then to StripePayments/StripePaymentsTestUtils/Resources
        let baseURL = currentDir
            .deletingLastPathComponent() // up from PaymentSheet/
            .deletingLastPathComponent() // up from StripePaymentSheetTests/
            .deletingLastPathComponent() // up from StripePaymentSheet/ -> now at stripe-ios/
            .appendingPathComponent("StripePayments")
            .appendingPathComponent("StripePaymentsTestUtils")
            .appendingPathComponent("Resources")
            .appendingPathComponent("recorded_network_traffic")
            .appendingPathComponent(testClass)
            .appendingPathComponent(testMethodName)

        // Find all .tail files for this test
        guard let enumerator = fileManager.enumerator(atPath: baseURL.path) else {
            XCTFail("❌ Could not enumerate files at path: \(baseURL.path)")
            return
        }

        var foundCAM = false
        var checkedFiles = 0

        for case let fileName as String in enumerator {
            guard fileName.hasSuffix("\(endpoint.rawValue).tail") else {
                continue
            }

            checkedFiles += 1
            let filePath = baseURL.appendingPathComponent(fileName)

            guard let fileContents = try? String(contentsOf: filePath, encoding: .utf8) else {
                XCTFail("❌ Could not read file: \(fileName)")
                continue
            }

            // Find the X-Stripe-Mock-Request header line
            let lines = fileContents.components(separatedBy: .newlines)
            guard let mockRequestLine = lines.first(where: { $0.hasPrefix("X-Stripe-Mock-Request:") }) else {
                continue
            }

            // Extract the request parameters
            let requestParams = mockRequestLine.replacingOccurrences(of: "X-Stripe-Mock-Request: ", with: "")

            // Check for client_attribution_metadata parameters
            let hasCAM = requestParams.contains("client_attribution_metadata")

            if hasCAM {
                foundCAM = true

                // Verify expected values are present
                XCTAssertTrue(
                    requestParams.contains("client_attribution_metadata\\[merchant_integration_source]=elements"),
                    "❌ Missing or incorrect merchant_integration_source in \(fileName)"
                )
                XCTAssertTrue(
                    requestParams.contains("client_attribution_metadata\\[merchant_integration_subtype]=mobile"),
                    "❌ Missing or incorrect merchant_integration_subtype in \(fileName)"
                )

                // Verify payment_intent_creation_flow if specified
                if let expectedFlow = expectedPaymentIntentCreationFlow {
                    XCTAssertTrue(
                        requestParams.contains("client_attribution_metadata\\[payment_intent_creation_flow]=\(expectedFlow)"),
                        "❌ Missing or incorrect payment_intent_creation_flow (expected: \(expectedFlow)) in \(fileName)"
                    )
                }

                // Verify payment_method_selection_flow if specified
                if let expectedSelection = expectedPaymentMethodSelectionFlow {
                    XCTAssertTrue(
                        requestParams.contains("client_attribution_metadata\\[payment_method_selection_flow]=\(expectedSelection)"),
                        "❌ Missing or incorrect payment_method_selection_flow (expected: \(expectedSelection)) in \(fileName)"
                    )
                }

                // Verify other required fields exist (with regex patterns for dynamic values)
                XCTAssertTrue(
                    requestParams.contains("client_attribution_metadata\\[client_session_id]="),
                    "❌ Missing client_session_id in \(fileName)"
                )
                XCTAssertTrue(
                    requestParams.contains("client_attribution_metadata\\[elements_session_config_id]="),
                    "❌ Missing elements_session_config_id in \(fileName)"
                )
                XCTAssertTrue(
                    requestParams.contains("client_attribution_metadata\\[merchant_integration_version]="),
                    "❌ Missing merchant_integration_version in \(fileName)"
                )

                if let nestedString = nestedUnder?.rawValue {
                    // Verify expected values are present
                    XCTAssertTrue(
                        requestParams.contains("\(nestedString)\\[client_attribution_metadata]\\[merchant_integration_source]=elements"),
                        "❌ Missing or incorrect merchant_integration_source in \(fileName)"
                    )
                    XCTAssertTrue(
                        requestParams.contains("\(nestedString)\\[client_attribution_metadata]\\[merchant_integration_subtype]=mobile"),
                        "❌ Missing or incorrect merchant_integration_subtype in \(fileName)"
                    )

                    // Verify payment_intent_creation_flow if specified
                    if let expectedFlow = expectedPaymentIntentCreationFlow {
                        XCTAssertTrue(
                            requestParams.contains("\(nestedString)\\[client_attribution_metadata]\\[payment_intent_creation_flow]=\(expectedFlow)"),
                            "❌ Missing or incorrect payment_intent_creation_flow (expected: \(expectedFlow)) in \(fileName)"
                        )
                    }

                    // Verify payment_method_selection_flow if specified
                    if let expectedSelection = expectedPaymentMethodSelectionFlow {
                        XCTAssertTrue(
                            requestParams.contains("\(nestedString)\\[client_attribution_metadata]\\[payment_method_selection_flow]=\(expectedSelection)"),
                            "❌ Missing or incorrect payment_method_selection_flow (expected: \(expectedSelection)) in \(fileName)"
                        )
                    }

                    // Verify other required fields exist (with regex patterns for dynamic values)
                    XCTAssertTrue(
                        requestParams.contains("\(nestedString)\\[client_attribution_metadata]\\[client_session_id]="),
                        "❌ Missing client_session_id in \(fileName)"
                    )
                    XCTAssertTrue(
                        requestParams.contains("\(nestedString)\\[client_attribution_metadata]\\[elements_session_config_id]="),
                        "❌ Missing elements_session_config_id in \(fileName)"
                    )
                    XCTAssertTrue(
                        requestParams.contains("\(nestedString)\\[client_attribution_metadata]\\[merchant_integration_version]="),
                        "❌ Missing merchant_integration_version in \(fileName)"
                    )
                }

                print("✅ Verified client_attribution_metadata in \(fileName)")
            }
        }

        XCTAssertTrue(foundCAM, "❌ No client_attribution_metadata found in any request stubs (checked \(checkedFiles) files at \(baseURL.path))")
    }
}

// MARK: - Test Helpers
extension ClientAttributionMetadataCoverageTests {
    func _testConfirm(intentKind: IntentKind,
                      paymentOption: PaymentOption,
                      paymentMethodTypes: [String] = ["card"]) async throws {
        let apiClient = STPAPIClient(publishableKey: STPTestingDefaultPublishableKey)
        let newCustomer = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: nil,
                                                                                              merchantCountry: "us")

        let clientSecretResolved = expectation(description: "clientSecretResolved")
        let intent = try await createIntent(intentKind: intentKind,
                                            apiClient: apiClient,
                                            customerID: newCustomer.customer,
                                            paymentMethodTypes: paymentMethodTypes) { _ in
            clientSecretResolved.fulfill()
        }
        try await _testConfirm(intent: intent,
                               elementsSession: ._testValue(intent: intent),
                               customerId: newCustomer.customer,
                               apiClient: apiClient,
                               paymentOption: paymentOption)
        await fulfillment(of: [clientSecretResolved])
    }

    @MainActor
    func _testConfirm(
        intent: Intent,
        elementsSession: STPElementsSession,
        customerId: String,
        apiClient: STPAPIClient,
        paymentOption: PaymentOption
    ) async throws {
        let paymentHandler = STPPaymentHandler(apiClient: apiClient)
        let configuration: PaymentSheet.Configuration = {
            var config = PaymentSheet.Configuration()
            config.returnURL = "https://foo.com"
            config.apiClient = apiClient
            config.customer = PaymentSheet.CustomerConfiguration(id: customerId, customerSessionClientSecret: "cuss_123")
            return config
        }()
        let e = expectation(description: "Confirm")
        PaymentSheet.confirm(
            configuration: configuration,
            authenticationContext: self,
            intent: intent,
            elementsSession: elementsSession,
            paymentOption: paymentOption,
            paymentHandler: paymentHandler,
            analyticsHelper: ._testValue()
        ) { result, _  in
            switch result {
            case .failed(error: let error):
                XCTFail("❌ PaymentSheet.confirm failed - \(error.nonGenericDescription)")
            case .canceled:
                print("❌ PaymentSheet.confirm canceled")
            case .completed:
                print("✅ PaymentSheet.confirm completed")
            }
            e.fulfill()
        }
        await fulfillment(of: [e], timeout: 25)
    }
}

// MARK: - Creation Helpers
extension ClientAttributionMetadataCoverageTests {
    func elementsSession() -> STPElementsSession {
        return STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                             customerSessionData: [
                                                "mobile_payment_element": [
                                                    "enabled": true,
                                                    "features": [],
                                                ],
                                                "customer_sheet": [
                                                    "enabled": false
                                                ],
                                             ])
    }

    func createIntent(intentKind: IntentKind,
                      apiClient: STPAPIClient,
                      customerID: String,
                      paymentMethodTypes: [String],
                      clientSecretCallback: @escaping (String) -> Void ) async throws -> Intent {
        let currency = "USD"
        let merchantCountry = "us"
        switch intentKind {
        // MARK: - Payment Intent
        case .paymentIntent_intentFirst_csc:
            let paymentIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    merchantCountry: merchantCountry,
                    customerID: customerID
                )
                clientSecretCallback(clientSecret)
                return try await apiClient.retrievePaymentIntent(clientSecret: clientSecret)
            }()
            return .paymentIntent(paymentIntent)
        case .paymentIntent_deferredIntent_csc:
            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency)) { _, _ in
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    merchantCountry: merchantCountry,
                    customerID: customerID
                )
                clientSecretCallback(clientSecret)
                return clientSecret
            }
            return .deferredIntent(intentConfig: deferredCSC)
        case .paymentIntent_deferredIntent_ssc:
            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency)) { paymentMethod, shouldSavePM in
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    merchantCountry: merchantCountry,
                    paymentMethodID: paymentMethod.stripeId,
                    shouldSavePM: shouldSavePM,
                    customerID: customerID,
                    confirm: true,
                    otherParams: self.paramsForServerSideConfirmation
                )
                clientSecretCallback(clientSecret)
                return clientSecret
            }
            return .deferredIntent(intentConfig: deferredSSC)
        case .paymentIntent_deferredIntent_csc_ct:
            let deferredCSCWithConfirmationToken = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency), paymentMethodTypes: paymentMethodTypes, confirmationTokenConfirmHandler2: { _ in
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    amount: 1099,
                    merchantCountry: merchantCountry,
                    customerID: customerID
                )
                clientSecretCallback(clientSecret)
                return clientSecret
            })
            return .deferredIntent(intentConfig: deferredCSCWithConfirmationToken)
        case .paymentIntent_deferredIntent_ssc_ct:
            let deferredSSCWithConfirmationToken = PaymentSheet.IntentConfiguration(mode: .payment(amount: 1099, currency: currency), paymentMethodTypes: paymentMethodTypes, confirmationTokenConfirmHandler2: { confirmationToken in
                let clientSecret = try await STPTestingAPIClient.shared.fetchPaymentIntent(
                    types: paymentMethodTypes,
                    currency: currency,
                    amount: 1099,
                    merchantCountry: merchantCountry,
                    customerID: customerID,
                    confirm: true,
                    otherParams: ["confirmation_token": confirmationToken.stripeId]
                )
                clientSecretCallback(clientSecret)
                return clientSecret
            })
            return .deferredIntent(intentConfig: deferredSSCWithConfirmationToken)
        // MARK: - Setup Intent
        case .setupIntent_intentFirst_csc:
            let setupIntent = try await {
                let clientSecret = try await STPTestingAPIClient.shared.fetchSetupIntent(
                    types: paymentMethodTypes,
                    merchantCountry: merchantCountry,
                    customerID: customerID
                )
                clientSecretCallback(clientSecret)
                return try await apiClient.retrieveSetupIntent(clientSecret: clientSecret)
            }()
            return .setupIntent(setupIntent)
        case .setupIntent_deferredIntent_csc:
            let deferredCSC = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession)) { _, _ in
                let clientSecret = try await STPTestingAPIClient.shared.fetchSetupIntent(types: paymentMethodTypes,
                                                                                         merchantCountry: merchantCountry,
                                                                                         customerID: customerID)
                clientSecretCallback(clientSecret)
                return clientSecret
            }
            return .deferredIntent(intentConfig: deferredCSC)
        case .setupIntent_deferredIntent_ssc:
            let deferredSSC = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession)) { paymentMethod, _ in

                let clientSecret = try await STPTestingAPIClient.shared.fetchSetupIntent(types: paymentMethodTypes,
                                                                                         merchantCountry: merchantCountry,
                                                                                         paymentMethodID: paymentMethod.stripeId,
                                                                                         customerID: customerID,
                                                                                         confirm: true,
                                                                                         otherParams: self.paramsForServerSideConfirmation)
                clientSecretCallback(clientSecret)
                return clientSecret
            }
            return .deferredIntent(intentConfig: deferredSSC)
        case .setupIntent_deferredIntent_csc_ct:
            let deferredCSCWithConfirmationToken = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession), paymentMethodTypes: paymentMethodTypes, confirmationTokenConfirmHandler2: { _ in
                let clientSecret = try await STPTestingAPIClient.shared.fetchSetupIntent(
                    types: paymentMethodTypes,
                    merchantCountry: merchantCountry,
                    customerID: customerID
                )
                clientSecretCallback(clientSecret)
                return clientSecret
            })
            return .deferredIntent(intentConfig: deferredCSCWithConfirmationToken)
        case .setupIntent_deferredIntent_ssc_ct:
            let deferredSSCWithConfirmationToken = PaymentSheet.IntentConfiguration(mode: .setup(setupFutureUsage: .offSession), paymentMethodTypes: paymentMethodTypes, confirmationTokenConfirmHandler2: { confirmationToken in
                let clientSecret = try await STPTestingAPIClient.shared.fetchSetupIntent(
                    types: paymentMethodTypes,
                    merchantCountry: merchantCountry,
                    customerID: customerID,
                    confirm: true,
                    otherParams: ["confirmation_token": confirmationToken.stripeId]
                )
                clientSecretCallback(clientSecret)
                return clientSecret
            })
            return .deferredIntent(intentConfig: deferredSSCWithConfirmationToken)
        }
    }
}

extension ClientAttributionMetadataCoverageTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()
    }
}
