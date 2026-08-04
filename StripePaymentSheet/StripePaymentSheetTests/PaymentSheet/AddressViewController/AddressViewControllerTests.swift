//
//  AddressViewControllerTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 8/4/26.
//

@_spi(STP) @testable import StripeCore
@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import XCTest

@MainActor
final class AddressViewControllerTests: XCTestCase {
    override func setUp() {
        super.setUp()
        STPAnalyticsClient.sharedClient._testLogHistory = []
    }

    func testDidContinuePassesValidAddressToIntegrationDelegate() async {
        // Given an AddressViewController with a valid address and a custom integration delegate
        let merchantDelegate = MerchantDelegate()
        let integrationDelegate = IntegrationDelegate()
        integrationDelegate.saveExpectation = expectation(description: "Save address")
        let viewController = makeViewController(
            configuration: makeConfiguration(defaultAddress: .init(
                city: "San Francisco",
                country: "US",
                line1: "354 Oyster Point Blvd",
                postalCode: "94080",
                state: "CA"
            )),
            merchantDelegate: merchantDelegate,
            integrationDelegate: integrationDelegate
        )
        viewController.loadViewIfNeeded()

        // When address collection completes
        viewController.didContinue()
        await fulfillment(of: [integrationDelegate.saveExpectation!])

        // Then only the integration delegate receives the valid address
        XCTAssertEqual(integrationDelegate.receivedAddressDetails.count, 1)
        let addressDetails = integrationDelegate.receivedAddressDetails[0]
        XCTAssertEqual(addressDetails?.address.city, "San Francisco")
        XCTAssertEqual(addressDetails?.address.country, "US")
        XCTAssertEqual(addressDetails?.address.line1, "354 Oyster Point Blvd")
        XCTAssertEqual(addressDetails?.address.postalCode, "94080")
        XCTAssertEqual(addressDetails?.address.state, "CA")
        XCTAssertTrue(merchantDelegate.receivedAddressDetails.isEmpty)
    }

    func testDidContinuePassesNilAddressToIntegrationDelegate() async {
        // Given an AddressViewController with an invalid address and a custom integration delegate
        let merchantDelegate = MerchantDelegate()
        let integrationDelegate = IntegrationDelegate()
        integrationDelegate.saveExpectation = expectation(description: "Save nil address")
        let viewController = makeViewController(
            configuration: makeConfiguration(),
            merchantDelegate: merchantDelegate,
            integrationDelegate: integrationDelegate
        )
        viewController.loadViewIfNeeded()

        // When address collection completes
        viewController.didContinue()
        await fulfillment(of: [integrationDelegate.saveExpectation!])

        // Then only the integration delegate receives the nil address
        XCTAssertEqual(integrationDelegate.receivedAddressDetails.count, 1)
        XCTAssertNil(integrationDelegate.receivedAddressDetails[0])
        XCTAssertTrue(merchantDelegate.receivedAddressDetails.isEmpty)
    }

    func testDefaultIntegrationDelegateLogsAndForwardsValidAddress() async {
        // Given an AddressViewController using the default integration delegate
        let merchantDelegate = MerchantDelegate()
        merchantDelegate.completionExpectation = expectation(description: "Merchant completion")
        let viewController = makeViewController(
            configuration: makeConfiguration(defaultAddress: .init(
                city: "San Francisco",
                country: "US",
                line1: "354 Oyster Point Blvd",
                postalCode: "94080",
                state: "CA"
            )),
            merchantDelegate: merchantDelegate
        )
        viewController.loadViewIfNeeded()

        // When address collection completes
        viewController.didContinue()
        await fulfillment(of: [merchantDelegate.completionExpectation!])

        // Then the merchant receives the address and completion is logged
        XCTAssertEqual(merchantDelegate.receivedAddressDetails.count, 1)
        XCTAssertEqual(merchantDelegate.receivedAddressDetails[0]?.address.line1, "354 Oyster Point Blvd")
        XCTAssertNotNil(addressCompletionEvent)
    }

    func testDefaultIntegrationDelegateLogsAndForwardsNilAddress() async {
        // Given an AddressViewController using the default integration delegate with an invalid address
        let merchantDelegate = MerchantDelegate()
        merchantDelegate.completionExpectation = expectation(description: "Merchant completion")
        let viewController = makeViewController(
            configuration: makeConfiguration(),
            merchantDelegate: merchantDelegate
        )
        viewController.loadViewIfNeeded()

        // When address collection completes
        viewController.didContinue()
        await fulfillment(of: [merchantDelegate.completionExpectation!])

        // Then the merchant receives nil and completion is logged
        XCTAssertEqual(merchantDelegate.receivedAddressDetails.count, 1)
        XCTAssertNil(merchantDelegate.receivedAddressDetails[0])
        XCTAssertNotNil(addressCompletionEvent)
    }

    func testDidContinueDisplaysIntegrationDelegateError() async {
        // Given an AddressViewController whose integration delegate fails to save
        let expectedError = NSError(
            domain: "AddressViewControllerTests",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Unable to save the address."]
        )
        let merchantDelegate = MerchantDelegate()
        let integrationDelegate = IntegrationDelegate(error: expectedError)
        integrationDelegate.saveExpectation = expectation(description: "Save address")
        let viewController = makeViewController(
            configuration: makeConfiguration(),
            merchantDelegate: merchantDelegate,
            integrationDelegate: integrationDelegate
        )
        viewController.loadViewIfNeeded()

        // When address collection completes
        viewController.didContinue()
        await fulfillment(of: [integrationDelegate.saveExpectation!])

        // Then the error is displayed without notifying the merchant
        XCTAssertEqual(viewController.errorLabel.text, expectedError.localizedDescription)
        XCTAssertFalse(viewController.errorLabel.isHidden)
        XCTAssertTrue(merchantDelegate.receivedAddressDetails.isEmpty)
    }

    private var addressCompletionEvent: [String: Any]? {
        STPAnalyticsClient.sharedClient._testLogHistory.first {
            $0["event"] as? String == "mc_address_completed"
        }
    }

    private func makeConfiguration(
        defaultAddress: PaymentSheet.Address? = nil
    ) -> AddressViewController.Configuration {
        var configuration = AddressViewController.Configuration()
        configuration.allowedCountries = ["US"]
        configuration.apiClient = STPAPIClient(publishableKey: "pk_test_123")
        if let defaultAddress {
            configuration.defaultValues = .init(address: defaultAddress)
        }
        return configuration
    }

    private func makeViewController(
        configuration: AddressViewController.Configuration,
        merchantDelegate: AddressViewControllerDelegate,
        integrationDelegate: AddressViewController.IntegrationDelegate? = nil
    ) -> AddressViewController {
        AddressViewController(
            addressSpecProvider: makeAddressSpecProvider(),
            configuration: configuration,
            delegate: merchantDelegate,
            integrationDelegate: integrationDelegate
        )
    }

    private func makeAddressSpecProvider() -> AddressSpecProvider {
        let addressSpecProvider = AddressSpecProvider()
        addressSpecProvider.addressSpecs = [
            "US": AddressSpec(
                format: "NOACSZ",
                require: "ACSZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "",
                zipNameType: .zip
            ),
        ]
        return addressSpecProvider
    }
}

@MainActor
private final class MerchantDelegate: AddressViewControllerDelegate {
    var completionExpectation: XCTestExpectation?
    var receivedAddressDetails: [AddressViewController.AddressDetails?] = []

    func addressViewControllerDidFinish(
        _ addressViewController: AddressViewController,
        with address: AddressViewController.AddressDetails?
    ) {
        receivedAddressDetails.append(address)
        completionExpectation?.fulfill()
    }
}

@MainActor
private final class IntegrationDelegate: AddressViewController.IntegrationDelegate {
    var saveExpectation: XCTestExpectation?
    var receivedAddressDetails: [AddressViewController.AddressDetails?] = []
    private let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func save(
        addressDetails: AddressViewController.AddressDetails?,
        setLoading: (Bool) -> Void
    ) async throws {
        receivedAddressDetails.append(addressDetails)
        saveExpectation?.fulfill()
        if let error {
            throw error
        }
    }
}
