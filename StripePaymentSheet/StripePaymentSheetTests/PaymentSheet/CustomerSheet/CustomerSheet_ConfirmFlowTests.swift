//
//  CustomerSheet_ConfirmFlowTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore

@MainActor
final class CustomerSheet_ConfirmFlowTests: STPNetworkStubbingTestCase {
    enum MerchantCountry: String {
        case US = "us"
        case FR = "fr"

        var publishableKey: String {
            switch self {
            case .US:
                return STPTestingDefaultPublishableKey
            case .FR:
                return STPTestingFRPublishableKey
            }
        }
    }
    override func setUp() async throws {
        await withCheckedContinuation { continuation in
            Task {
                AddressSpecProvider.shared.loadAddressSpecs {
                    FormSpecProvider.shared.load { _ in
                        continuation.resume()
                    }
                }
            }
        }
        self.followRedirects = false
    }

    func testCardConfirmation() async throws {
        let merchantCountry = MerchantCountry.US
        let apiClient = STPAPIClient(publishableKey: merchantCountry.publishableKey)
        let newCustomer = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: nil,
                                                                                              merchantCountry: merchantCountry.rawValue.lowercased())
        try await _testConfirm(
            apiClient: apiClient,
            merchantCountry: merchantCountry,
            paymentMethodType: .card,
            elementsSession: ._testCardValue(),
            customerID: newCustomer.customer) { form in
            form.getTextFieldElement("Card number")?.setText("4242424242424242")
            form.getTextFieldElement("MM / YY").setText("1232")
            form.getTextFieldElement("CVC").setText("123")
            form.getTextFieldElement("ZIP").setText("65432")
        }
    }
    func testCardConfirmation_FR() async throws {
        let merchantCountry = MerchantCountry.FR
        let apiClient = STPAPIClient(publishableKey: merchantCountry.publishableKey)
        let newCustomer = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: nil,
                                                                                              merchantCountry: merchantCountry.rawValue.lowercased())
        try await _testConfirm(
            apiClient: apiClient,
            merchantCountry: merchantCountry,
            paymentMethodType: .card,
            elementsSession: ._testCardValue(),
            customerID: newCustomer.customer) { form in
            form.getTextFieldElement("Card number")?.setText("4242424242424242")
            form.getTextFieldElement("MM / YY").setText("1232")
            form.getTextFieldElement("CVC").setText("123")
            form.getTextFieldElement("ZIP").setText("65432")
        }
    }

    func testSepaConfirmation() async throws {
        let merchantCountry = MerchantCountry.US
        let apiClient = STPAPIClient(publishableKey: merchantCountry.publishableKey)
        let newCustomer = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: nil,
                                                                                              merchantCountry: merchantCountry.rawValue.lowercased())
        try await _testConfirm(
            apiClient: apiClient,
            merchantCountry: merchantCountry,
            paymentMethodType: .SEPADebit,
            elementsSession: ._testCardValue(),
            customerID: newCustomer.customer) { form in
                form.getTextFieldElement("Full name")?.setText("John Doe")
                form.getTextFieldElement("Email")?.setText("test@example.com")
                form.getTextFieldElement("IBAN")?.setText("DE89370400440532013000")
                form.getTextFieldElement("Address line 1")?.setText("123 Main")
                form.getTextFieldElement("City")?.setText("San Francisco")
                form.getTextFieldElement("ZIP")?.setText("65432")
        }
    }

    func testUSBankAccount() async throws {
        let expectation = expectation(description: "params validated")
        let customer = "cus_QWYdNyavE2M5ah" // A hardcoded customer on acct_1G6m1pFY0qyl6XeW

        let merchantCountry: MerchantCountry = .US
        let apiClient = STPAPIClient(publishableKey: merchantCountry.publishableKey)
        let customerSheetConfiguration: CustomerSheet.Configuration = {
            var config = CustomerSheet.Configuration()
            config.allowsRemovalOfLastSavedPaymentMethod = true
            config.returnURL =  "https://foo.com"
            return config
        }()

        try await _testUSBankAccountFields(
            apiClient: apiClient,
            customerSheetConfiguration: customerSheetConfiguration,
            merchantCountry: merchantCountry,
            paymentMethodType: .USBankAccount,
            customerID: customer,
            formCompleter: { form in
                form.getTextFieldElement("Full name")?.setText("John Doe")
                form.getTextFieldElement("Email").setText("test@example.com")
            },
            intentConfirmParamsValidator: { intentConfirmParams in
                XCTAssertEqual(intentConfirmParams.paymentMethodType, .stripe(.USBankAccount))
                XCTAssertEqual(intentConfirmParams.financialConnectionsLinkedBank?.bankName, "Test Bank")
                XCTAssertEqual(intentConfirmParams.financialConnectionsLinkedBank?.last4, "1234")
                XCTAssertEqual(intentConfirmParams.financialConnectionsLinkedBank?.sessionId, "las_123")
                XCTAssertEqual(intentConfirmParams.financialConnectionsLinkedBank?.accountId, "fca_123")
                XCTAssertEqual(intentConfirmParams.financialConnectionsLinkedBank?.displayName, "Test Bank")
                XCTAssertTrue(intentConfirmParams.financialConnectionsLinkedBank?.instantlyVerified ?? false)
                XCTAssertEqual(intentConfirmParams.paymentMethodParams.usBankAccount?.linkAccountSessionID, "las_123")
                expectation.fulfill()
            })
        await fulfillment(of: [expectation], timeout: 25)
    }

    func testUSBankAccountAttachDefaults() async throws {
        let expectation = expectation(description: "params validated")
        let customer = "cus_QWYdNyavE2M5ah" // A hardcoded customer on acct_1G6m1pFY0qyl6XeW

        let merchantCountry: MerchantCountry = .US
        let apiClient = STPAPIClient(publishableKey: merchantCountry.publishableKey)
        let customerSheetConfiguration: CustomerSheet.Configuration = {
            var config = CustomerSheet.Configuration()
            config.allowsRemovalOfLastSavedPaymentMethod = true
            config.returnURL =  "https://foo.com"

            var defaultBillingDetails = PaymentSheet.BillingDetails()
            defaultBillingDetails.name = "John Do"
            defaultBillingDetails.email = "test@example.co"
            config.defaultBillingDetails = defaultBillingDetails

            var billingDetailsCollectionConfiguration = PaymentSheet.BillingDetailsCollectionConfiguration()
            billingDetailsCollectionConfiguration.address = .never
            billingDetailsCollectionConfiguration.email = .never
            billingDetailsCollectionConfiguration.name = .never
            billingDetailsCollectionConfiguration.phone = .never
            billingDetailsCollectionConfiguration.attachDefaultsToPaymentMethod = true
            config.billingDetailsCollectionConfiguration = billingDetailsCollectionConfiguration
            return config
        }()

        try await _testUSBankAccountFields(
            apiClient: apiClient,
            customerSheetConfiguration: customerSheetConfiguration,
            merchantCountry: merchantCountry,
            paymentMethodType: .USBankAccount,
            customerID: customer,
            formCompleter: { _ in
                // Intentionally nil since we are setting fields via defaultBillingDetails
            },
            intentConfirmParamsValidator: { intentConfirmParams in
                XCTAssertEqual(intentConfirmParams.paymentMethodType, .stripe(.USBankAccount))
                XCTAssertEqual(intentConfirmParams.financialConnectionsLinkedBank?.bankName, "Test Bank")
                XCTAssertEqual(intentConfirmParams.financialConnectionsLinkedBank?.last4, "1234")
                XCTAssertEqual(intentConfirmParams.financialConnectionsLinkedBank?.sessionId, "las_123")
                XCTAssertEqual(intentConfirmParams.financialConnectionsLinkedBank?.accountId, "fca_123")
                XCTAssertEqual(intentConfirmParams.financialConnectionsLinkedBank?.displayName, "Test Bank")
                XCTAssertTrue(intentConfirmParams.financialConnectionsLinkedBank?.instantlyVerified ?? false)
                XCTAssertEqual(intentConfirmParams.paymentMethodParams.usBankAccount?.linkAccountSessionID, "las_123")
                expectation.fulfill()
            })
        await fulfillment(of: [expectation], timeout: 25)
    }

    func testAllowRedisplay_legacy() async throws {
        let merchantCountry = MerchantCountry.US
        let apiClient = STPAPIClient(publishableKey: merchantCountry.publishableKey)
        let newCustomer = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: nil,
                                                                                              merchantCountry: merchantCountry.rawValue.lowercased())
        guard let clientSecret = try await _testConfirm(apiClient: apiClient,
                                                        merchantCountry: merchantCountry,
                                                        paymentMethodType: .card,
                                                        elementsSession: ._testCardValue(),
                                                        customerID: newCustomer.customer,
                                                        formCompleter: ({ form in
            form.getTextFieldElement("Card number")?.setText("4242424242424242")
            form.getTextFieldElement("MM / YY").setText("1232")
            form.getTextFieldElement("CVC").setText("123")
            form.getTextFieldElement("ZIP").setText("65432")
        })) else {
            XCTFail("Failed on confirm")
            return
        }
        try await assertAllowRedisplayValue(apiClient: apiClient,
                                            confirmedPaymentIntentClientSecret: clientSecret,
                                            customerResponse: newCustomer,
                                            expectedAllowRedisplay: .unspecified)
    }
    func testAllowRedisplay_customerSession() async throws {
        let merchantCountry = MerchantCountry.US
        let apiClient = STPAPIClient(publishableKey: merchantCountry.publishableKey)
        let newCustomer = try await STPTestingAPIClient.shared().fetchCustomerAndEphemeralKey(customerID: nil,
                                                                                              merchantCountry: merchantCountry.rawValue.lowercased())
        let elementsSession = STPElementsSession._testValue(paymentMethodTypes: ["card"],
                                                            customerSessionData: [
                                                               "mobile_payment_element": [
                                                                   "enabled": false,
                                                               ],
                                                               "customer_sheet": [
                                                                   "enabled": true,
                                                                   "features": ["payment_method_remove": "enabled"],
                                                               ],
                                                            ])
        guard let clientSecret = try await _testConfirm(apiClient: apiClient,
                                                        merchantCountry: merchantCountry,
                                                        paymentMethodType: .card,
                                                        elementsSession: elementsSession,
                                                        customerID: newCustomer.customer,
                                                        formCompleter: ({ form in
            form.getTextFieldElement("Card number")?.setText("4242424242424242")
            form.getTextFieldElement("MM / YY").setText("1232")
            form.getTextFieldElement("CVC").setText("123")
            form.getTextFieldElement("ZIP").setText("65432")
        })) else {
            XCTFail("Failed on confirm")
            return
        }
        try await assertAllowRedisplayValue(apiClient: apiClient,
                                            confirmedPaymentIntentClientSecret: clientSecret,
                                            customerResponse: newCustomer,
                                            expectedAllowRedisplay: .always)
    }
}

extension CustomerSheet_ConfirmFlowTests {
    @MainActor
    @discardableResult
    func _testConfirm(apiClient: STPAPIClient,
                      merchantCountry: MerchantCountry = .US,
                      paymentMethodType: STPPaymentMethodType,
                      elementsSession: STPElementsSession,
                      customerID: String,
                      formCompleter: (PaymentMethodElement) -> Void) async throws -> String? {
        let customerSheetConfiguration: CustomerSheet.Configuration = {
            var config = CustomerSheet.Configuration()
            config.apiClient = apiClient
            config.allowsRemovalOfLastSavedPaymentMethod = true
            config.returnURL =  "https://foo.com"
            return config
        }()

        let (clientSecret, intent, paymentMethodForm) = try await _createElementAndIntent(apiClient: apiClient,
                                                                                          customerSheetConfiguration: customerSheetConfiguration,
                                                                                          merchantCountry: merchantCountry,
                                                                                          paymentMethodType: paymentMethodType,
                                                                                          customerID: customerID,
                                                                                          formCompleter: formCompleter)
        // Generate params from the form
        let psPaymentMethodType: PaymentSheet.PaymentMethodType = .stripe(paymentMethodType)
        guard let intentConfirmParams = paymentMethodForm.updateParams(params: IntentConfirmParams(type: psPaymentMethodType)) else {
            XCTFail("Form failed to create params. Validation state: \(paymentMethodForm.validationState)")
            return nil
        }
        let paymentOption: PaymentSheet.PaymentOption = .new(confirmParams: intentConfirmParams)

        let expectation = expectation(description: "Confirm")
        let paymentHandler = STPPaymentHandler(apiClient: apiClient)

        // Confirm the intent with the form details
        CustomerSheet.confirm(
            intent: intent,
            elementsSession: elementsSession,
            paymentOption: paymentOption,
            configuration: customerSheetConfiguration,
            paymentHandler: paymentHandler,
            authenticationContext: self) { result in
                switch result {
                case .failed(let error):
                    XCTFail("PaymentSheet.confirm failed - \(error.nonGenericDescription)")
                case .canceled:
                    XCTFail("Unexpected canceled state")
                case .completed:
                    print("✅ PaymentSheet.confirm completed")
                }
                expectation.fulfill()
            }
        await fulfillment(of: [expectation], timeout: 25)
        return clientSecret
    }

    @MainActor
    func _testUSBankAccountFields(apiClient: STPAPIClient,
                                  customerSheetConfiguration: CustomerSheet.Configuration,
                                  merchantCountry: MerchantCountry = .US,
                                  paymentMethodType: STPPaymentMethodType,
                                  customerID: String,
                                  formCompleter: (PaymentMethodElement) -> Void,
                                  intentConfirmParamsValidator: (IntentConfirmParams) -> Void) async throws {
        let (clientSecret, _, paymentMethodForm) = try await _createElementAndIntent(apiClient: apiClient,
                                                                                     customerSheetConfiguration: customerSheetConfiguration,
                                                                                     merchantCountry: merchantCountry,
                                                                                     paymentMethodType: paymentMethodType,
                                                                                     customerID: customerID,
                                                                                     formCompleter: formCompleter)
        await linkBankAccount(apiClient: apiClient,
                              clientSecret: clientSecret,
                              returnURL: customerSheetConfiguration.returnURL!,
                              paymentMethodForm: paymentMethodForm)

        // Generate params from the form
        let psPaymentMethodType: PaymentSheet.PaymentMethodType = .stripe(paymentMethodType)
        guard let intentConfirmParams = paymentMethodForm.updateParams(params: IntentConfirmParams(type: psPaymentMethodType)) else {
            XCTFail("Form failed to create params. Validation state: \(paymentMethodForm.validationState)")
            return
        }
        intentConfirmParamsValidator(intentConfirmParams)
    }

    @MainActor
    func _createElementAndIntent(apiClient: STPAPIClient,
                                 customerSheetConfiguration: CustomerSheet.Configuration,
                                 merchantCountry: MerchantCountry,
                                 paymentMethodType: STPPaymentMethodType,
                                 customerID: String,
                                 formCompleter: (PaymentMethodElement) -> Void) async throws -> (String, Intent, PaymentMethodElement) {
        let psPaymentMethodType: PaymentSheet.PaymentMethodType = .stripe(paymentMethodType)
        let configuration = PaymentSheetFormFactoryConfig.customerSheet(customerSheetConfiguration)
        let formFactory = PaymentSheetFormFactory(configuration: configuration,
                                                  paymentMethod: psPaymentMethodType,
                                                  previousCustomerInput: nil,
                                                  addressSpecProvider: .shared,
                                                  showLinkInlineCardSignup: false,
                                                  linkAccount: nil,
                                                  accountService: LinkAccountService._testValue(),
                                                  cardBrandChoiceEligible: false,
                                                  isPaymentIntent: false,
                                                  isSettingUp: true,
                                                  countryCode: nil,
                                                  savePaymentMethodConsentBehavior: .legacy,
                                                  analyticsHelper: ._testValue(),
                                                  paymentMethodIncentive: nil)
        let paymentMethodForm = formFactory.make()
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 1000))
        view.addAndPinSubview(paymentMethodForm.view)

        // Fill out the form
        sendEventToSubviews(.viewDidAppear, from: paymentMethodForm.view) // Simulate view appearance. This makes SimpleMandateElement mark its mandate as having been displayed.
        formCompleter(paymentMethodForm)

        let clientSecret = try await setupIntentClientSecretProvider(paymentMethodType: paymentMethodType,
                                                                     merchantCountry: merchantCountry,
                                                                     customerID: customerID)
        let setupIntent = try await apiClient.retrieveSetupIntent(clientSecret: clientSecret)
        let intent = Intent.setupIntent(setupIntent)
        return (clientSecret, intent, paymentMethodForm)
    }

    func linkBankAccount(apiClient: STPAPIClient,
                         clientSecret: String,
                         returnURL: String,
                         paymentMethodForm: PaymentMethodElement) async {
        await withCheckedContinuation { continuation in
            let client = STPBankAccountCollector(apiClient: apiClient)
            let additionalParameters: [String: Any] = [
                "hosted_surface": "payment_element",
            ]
            let params = STPCollectBankAccountParams.collectUSBankAccountParams(
                with: "John Doe",
                email: "test@example.com"
            )

            client.collectBankAccountForSetup(clientSecret: clientSecret,
                                              returnURL: returnURL,
                                              additionalParameters: additionalParameters,
                                              onEvent: nil,
                                              params: params,
                                              from: UIViewController()) { result, _, error in
                if error != nil {
                    XCTFail("Failed to create linked bank account")
                    continuation.resume()
                    return
                }
                guard let financialConnectionsResult = result else {
                    XCTFail("Failed to get result")
                    continuation.resume()
                    return
                }
                switch financialConnectionsResult {
                case .cancelled:
                    XCTFail("Unexpected Cancel")
                case .completed(let completedResult):
                    if case .financialConnections(let linkedBank) = completedResult {
                        if let usBankElement = paymentMethodForm as? USBankAccountPaymentMethodElement {
                            usBankElement.linkedBank = linkedBank
                        }
                    } else {
                        XCTFail("no linked account")
                    }
                case .failed:
                    XCTFail("Failed")
                }
                continuation.resume()
            }
        }
    }

    func setupIntentClientSecretProvider(paymentMethodType: STPPaymentMethodType,
                                         merchantCountry: MerchantCountry,
                                         customerID: String) async throws -> String {
        let types = [paymentMethodType.identifier].compactMap { $0 }
        return try await STPTestingAPIClient.shared.fetchSetupIntent(types: types,
                                                                     merchantCountry: merchantCountry.rawValue,
                                                                     customerID: customerID)

    }

    func assertAllowRedisplayValue(apiClient: STPAPIClient,
                                   confirmedPaymentIntentClientSecret clientSecret: String,
                                   customerResponse: STPTestingAPIClient.CreateEphemeralKeyResponse,
                                   expectedAllowRedisplay: STPPaymentMethodAllowRedisplay) async throws {
        let updatedSetupIntent = try await apiClient.retrieveSetupIntent(clientSecret: clientSecret)
        guard let confirmedPaymentMethodId = updatedSetupIntent.paymentMethodID else {
            XCTFail("No payment method attached to confirmed Intent")
            return
        }

        let expect = expectation(description: "Allow_redisplay value matches expected")
        apiClient.listPaymentMethods(forCustomer: customerResponse.customer,
                                     using: customerResponse.ephemeralKeySecret) { paymentMethods, error in
            guard error == nil else {
                XCTFail("Failed to fetch paymentMethods, error: \(String(describing: error))")
                return
            }
            guard let fetchedPaymentMethod = paymentMethods?.filter({ paymentMethod in
                paymentMethod.stripeId == confirmedPaymentMethodId
            }).first else {
                XCTFail("Failed to fetch paymentMethod: \(confirmedPaymentMethodId)")
                return
            }
            XCTAssertEqual(fetchedPaymentMethod.allowRedisplay, expectedAllowRedisplay)
            expect.fulfill()
        }
        await fulfillment(of: [expect], timeout: 10)
    }

}
extension CustomerSheet_ConfirmFlowTests: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return UIViewController()

    }
    func present(_ authenticationViewController: UIViewController, completion: @escaping () -> Void) {
        // no-op
    }

    func dismiss(_ authenticationViewController: UIViewController, completion: (() -> Void)?) {
        completion?()
    }
}
