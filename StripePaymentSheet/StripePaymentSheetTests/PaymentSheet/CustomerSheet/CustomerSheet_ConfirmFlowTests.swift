//
//  CustomerSheet_ConfirmFlowTests.swift
//  StripePaymentSheetTests
//

import StripeCoreTestUtils
import XCTest

@testable@_spi(STP) import StripeCore
@testable@_spi(STP) import StripePayments
@testable import StripePaymentSheet
@testable@_spi(STP) import StripePaymentSheet
@testable@_spi(STP) import StripePaymentsTestUtils
@testable@_spi(STP) import StripeUICore

@MainActor
final class CustomerSheet_ConfirmFlowTests: XCTestCase {
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
    }

    func testCardConfirmation() async throws {
        let customer = "cus_QWYdNyavE2M5ah" // A hardcoded customer on acct_1G6m1pFY0qyl6XeW
        try await _testConfirm(
            merchantCountry: .US,
            paymentMethodType: .card,
            customerID: customer) { form in
            form.getTextFieldElement("Card number")?.setText("4242424242424242")
            form.getTextFieldElement("MM / YY").setText("1232")
            form.getTextFieldElement("CVC").setText("123")
            form.getTextFieldElement("ZIP").setText("65432")
        }
    }
    func testCardConfirmation_FR() async throws {
        let customer = "cus_QWYglNu3orU2Yb" // A hardcoded customer on acct_acct_1JtgfQKG6vc7r7YC
        try await _testConfirm(
            merchantCountry: .FR,
            paymentMethodType: .card,
            customerID: customer) { form in
            form.getTextFieldElement("Card number")?.setText("4242424242424242")
            form.getTextFieldElement("MM / YY").setText("1232")
            form.getTextFieldElement("CVC").setText("123")
            form.getTextFieldElement("ZIP").setText("65432")
        }
    }

    func testSepaConfirmation() async throws {
        let customer = "cus_QWYdNyavE2M5ah" // A hardcoded customer on acct_1G6m1pFY0qyl6XeW
        try await _testConfirm(
            merchantCountry: .US,
            paymentMethodType: .SEPADebit,
            customerID: customer) { form in
                form.getTextFieldElement("Full name")?.setText("John Doe")
                form.getTextFieldElement("Email")?.setText("test@example.com")
                form.getTextFieldElement("IBAN")?.setText("DE89370400440532013000")
                form.getTextFieldElement("Address line 1")?.setText("123 Main")
                form.getTextFieldElement("City")?.setText("San Francisco")
                form.getTextFieldElement("ZIP")?.setText("65432")
        }
    }
}

extension CustomerSheet_ConfirmFlowTests {
    @MainActor
    func _testConfirm(merchantCountry: MerchantCountry = .US,
                      paymentMethodType: STPPaymentMethodType,
                      customerID: String,
                      formCompleter: (PaymentMethodElement) -> Void) async throws {
        let apiClient = STPAPIClient(publishableKey: merchantCountry.publishableKey)
        let csConfiguration: CustomerSheet.Configuration = {
            var config = CustomerSheet.Configuration()
            config.apiClient = apiClient
            config.allowsRemovalOfLastSavedPaymentMethod = true
            config.returnURL =  "https://foo.com"
            return config
        }()
        let psPaymentMethodType: PaymentSheet.PaymentMethodType = .stripe(paymentMethodType)
        let configuration = PaymentSheetFormFactoryConfig.customerSheet(csConfiguration)
        let formFactory = PaymentSheetFormFactory(configuration: configuration,
                                                  paymentMethod: psPaymentMethodType,
                                                  previousCustomerInput: nil,
                                                  addressSpecProvider: .shared,
                                                  offerSaveToLinkWhenSupported: false,
                                                  linkAccount: nil,
                                                  cardBrandChoiceEligible: false,
                                                  supportsLinkCard: false,
                                                  isPaymentIntent: false,
                                                  isSettingUp: true,
                                                  currency: nil,
                                                  amount: nil,
                                                  countryCode: nil,
                                                  savePaymentMethodConsentBehavior: .legacy)
        let paymentMethodForm = formFactory.make()
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 1000))
        view.addAndPinSubview(paymentMethodForm.view)

        //Fill out the form
        sendEventToSubviews(.viewDidAppear, from: paymentMethodForm.view) // Simulate view appearance. This makes SimpleMandateElement mark its mandate as having been displayed.
        formCompleter(paymentMethodForm)

        // Generate params from the form
        guard let intentConfirmParams = paymentMethodForm.updateParams(params: IntentConfirmParams(type: psPaymentMethodType)) else {
            XCTFail("Form failed to create params. Validation state: \(paymentMethodForm.validationState)")
            return
        }
        let paymentOption: PaymentSheet.PaymentOption = .new(confirmParams: intentConfirmParams)

        let setupIntent: STPSetupIntent =  try await {
            let clientSecret = try await setupIntentClientSecretProvider(paymentMethodType: paymentMethodType,
                                                                         merchantCountry: merchantCountry,
                                                                         customerID: customerID)
            return try await apiClient.retrieveSetupIntent(clientSecret: clientSecret)
        }()
        let intent = Intent.setupIntent(elementsSession: ._testCardValue(),
                                        setupIntent: setupIntent)


        let e = expectation(description: "Confirm")
        let paymentHandler = STPPaymentHandler(apiClient: apiClient)
        var redirectShimCalled = false
        paymentHandler._redirectShim = { _, _, _ in
            // This gets called instead of the PaymentSheet.confirm callback if the Intent is successfully confirmed and requires next actions.
            print("✅ Successfully confirmed the intent and saw a redirect attempt.")
            paymentHandler._handleWillForegroundNotification()
            redirectShimCalled = true
        }


        // Confirm the intent with the form details
        CustomerSheet.confirm(
            intent: intent,
            paymentOption: paymentOption,
            configuration: csConfiguration,
            paymentHandler: paymentHandler,
            authenticationContext: self) { result in
                switch result {
                case .failed(let error):
                    XCTFail("PaymentSheet.confirm failed - \(error.nonGenericDescription)")
                case .canceled:
                    XCTAssertTrue(redirectShimCalled, "❌: PaymentSheet.confirm canceled")
                case .completed:
                    print("✅ PaymentSheet.confirm completed")
                }
                e.fulfill()
            }
        await fulfillment(of: [e], timeout: 25)
    }

    func setupIntentClientSecretProvider(paymentMethodType: STPPaymentMethodType,
                                         merchantCountry: MerchantCountry,
                                         customerID: String) async throws -> String {
        let types = [paymentMethodType.identifier].compactMap { $0 }
        return try await STPTestingAPIClient.shared.fetchSetupIntent(types: types,
                                                                     merchantCountry: merchantCountry.rawValue,
                                                                     customerID: customerID)

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
