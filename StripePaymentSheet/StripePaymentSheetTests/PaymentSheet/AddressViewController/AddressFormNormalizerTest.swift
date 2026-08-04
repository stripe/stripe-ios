//
//  AddressFormNormalizerTest.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 8/4/26.

@_spi(STP) @testable import StripePaymentSheet
@_spi(STP) @testable import StripeUICore
import UIKit
import XCTest

final class AddressFormNormalizerTest: XCTestCase {
    private let addressSpecProvider: AddressSpecProvider = {
        let addressSpecProvider = AddressSpecProvider()
        addressSpecProvider.addressSpecs = [
            "BR": AddressSpec(
                format: "AS",
                require: "AS",
                cityNameType: .city,
                stateNameType: .state,
                zip: nil,
                zipNameType: .postal_code,
                subKeys: ["RO"],
                subLabels: ["Rondônia"]
            ),
            "CA": AddressSpec(
                format: "ACSZ",
                require: "A",
                cityNameType: .city,
                stateNameType: .province,
                zip: "",
                zipNameType: .postal_code
            ),
            "FR": AddressSpec(
                format: "ACZ",
                require: "ACZ",
                cityNameType: .city,
                stateNameType: .province,
                zip: "",
                zipNameType: .postal_code
            ),
            "US": AddressSpec(
                format: "ACSZ",
                require: "AZ",
                cityNameType: .city,
                stateNameType: .state,
                zip: "",
                zipNameType: .zip
            ),
        ]
        return addressSpecProvider
    }()

    func testNormalizeDefaultAddress() {
        // Given
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "",
            postalCode: "94103",
            state: "CA"
        )

        // When
        let result = AddressFormNormalizer.normalize(
            defaultAddress: defaultAddress,
            fallbackAddress: nil,
            allowedCountries: [],
            addressSpecProvider: addressSpecProvider
        )

        // Then
        XCTAssertEqual(
            result,
            PaymentSheet.Address(
                city: "San Francisco",
                country: "US",
                line1: "510 Townsend St.",
                postalCode: "94103",
                state: "CA"
            )
        )
    }

    func testNormalizeUsesFallbackWhenDefaultAddressIsEmpty() {
        // Given
        let fallbackAddress = PaymentSheet.Address(
            country: "US",
            line1: "123 Main St.",
            postalCode: "10001"
        )

        // When
        let result = AddressFormNormalizer.normalize(
            defaultAddress: .init(),
            fallbackAddress: fallbackAddress,
            allowedCountries: [],
            addressSpecProvider: addressSpecProvider
        )

        // Then
        XCTAssertEqual(result, fallbackAddress)
    }

    func testNormalizeUsesFallbackWhenDefaultCountryIsNotAllowed() {
        // Given
        let defaultAddress = PaymentSheet.Address(
            country: "CA",
            line1: "123 Front St."
        )
        let fallbackAddress = PaymentSheet.Address(
            country: "US",
            line1: "123 Main St.",
            postalCode: "10001"
        )

        // When
        let result = AddressFormNormalizer.normalize(
            defaultAddress: defaultAddress,
            fallbackAddress: fallbackAddress,
            allowedCountries: ["US"],
            addressSpecProvider: addressSpecProvider
        )

        // Then
        XCTAssertEqual(result, fallbackAddress)
    }

    func testNormalizeReturnsNilWhenNeitherAddressIsCompatible() {
        // Given
        let defaultAddress = PaymentSheet.Address(country: "CA", line1: "123 Front St.")
        let fallbackAddress = PaymentSheet.Address(country: "CA", line1: "456 Front St.")

        // When
        let result = AddressFormNormalizer.normalize(
            defaultAddress: defaultAddress,
            fallbackAddress: fallbackAddress,
            allowedCountries: ["US"],
            addressSpecProvider: addressSpecProvider
        )

        // Then
        XCTAssertNil(result)
    }

    func testNormalizeAppliesCountrySpecificValidation() {
        // Given
        let addressWithoutPostalCode = PaymentSheet.Address(line1: "123 Main St.")

        // When
        let usResult = AddressFormNormalizer.normalize(
            defaultAddress: .init(
                country: "US",
                line1: addressWithoutPostalCode.line1
            ),
            fallbackAddress: nil,
            allowedCountries: [],
            addressSpecProvider: addressSpecProvider
        )
        let caResult = AddressFormNormalizer.normalize(
            defaultAddress: .init(
                country: "CA",
                line1: addressWithoutPostalCode.line1
            ),
            fallbackAddress: nil,
            allowedCountries: [],
            addressSpecProvider: addressSpecProvider
        )

        // Then
        XCTAssertNil(usResult)
        XCTAssertEqual(caResult, PaymentSheet.Address(country: "CA", line1: "123 Main St."))
    }

    func testNormalizeDropsStateWhenCountryDoesNotCollectState() {
        // Given
        let defaultAddress = PaymentSheet.Address(
            city: "Paris",
            country: "FR",
            line1: "1 Rue de Rivoli",
            postalCode: "75001",
            state: "Île-de-France"
        )

        // When
        let result = AddressFormNormalizer.normalize(
            defaultAddress: defaultAddress,
            fallbackAddress: nil,
            allowedCountries: [],
            addressSpecProvider: addressSpecProvider
        )

        // Then
        XCTAssertEqual(
            result,
            PaymentSheet.Address(
                city: "Paris",
                country: "FR",
                line1: "1 Rue de Rivoli",
                postalCode: "75001"
            )
        )
    }

    func testNormalizeReturnsNilWhenStateDoesNotMatchDropdownOption() {
        // Given
        let matchingAddress = PaymentSheet.Address(
            country: "BR",
            line1: "123 Avenida Principal",
            state: "Rondônia"
        )
        let nonmatchingAddress = PaymentSheet.Address(
            country: "BR",
            line1: "123 Avenida Principal",
            state: "Rondonia"
        )

        // When
        let matchingResult = AddressFormNormalizer.normalize(
            defaultAddress: matchingAddress,
            fallbackAddress: nil,
            allowedCountries: [],
            addressSpecProvider: addressSpecProvider
        )
        let nonmatchingResult = AddressFormNormalizer.normalize(
            defaultAddress: nonmatchingAddress,
            fallbackAddress: nil,
            allowedCountries: [],
            addressSpecProvider: addressSpecProvider
        )

        // Then
        XCTAssertEqual(
            matchingResult,
            PaymentSheet.Address(
                country: "BR",
                line1: "123 Avenida Principal",
                state: "RO"
            )
        )
        XCTAssertNil(nonmatchingResult)
    }

    func testAddressViewControllerReturnsNormalizedAddress() throws {
        // Given
        let defaultAddress = PaymentSheet.Address(
            city: "San Francisco",
            country: "US",
            line1: "510 Townsend St.",
            line2: "",
            postalCode: "94103",
            state: "CA"
        )
        var configuration = AddressViewController.Configuration(
            defaultValues: .init(address: defaultAddress, name: "Jane Doe")
        )
        configuration.apiClient = .init(publishableKey: "pk_test_1234")
        let delegate = AddressViewControllerDelegateMock()
        let viewController = AddressViewController(
            addressSpecProvider: addressSpecProvider,
            configuration: configuration,
            delegate: delegate
        )
        viewController.loadViewIfNeeded()

        // When
        viewController.didContinue()

        // Then
        let expectedAddress = AddressFormNormalizer.normalize(
            defaultAddress: defaultAddress,
            fallbackAddress: nil,
            allowedCountries: [],
            addressSpecProvider: addressSpecProvider
        )
        let returnedAddress = try XCTUnwrap(delegate.addressDetails?.address)
        XCTAssertEqual(PaymentSheet.Address(from: returnedAddress), expectedAddress)
    }

    func testAddressViewControllerPreservesNameOnlyDefaultInsteadOfUsingFallback() {
        // Given
        var configuration = AddressViewController.Configuration(
            defaultValues: .init(name: "Jane Doe")
        )
        configuration.billingAddress = .init(
            address: .init(country: "US", line1: "123 Main St.", postalCode: "10001"),
            name: "John Doe"
        )
        let delegate = AddressViewControllerDelegateMock()
        let viewController = AddressViewController(
            addressSpecProvider: addressSpecProvider,
            configuration: configuration,
            delegate: delegate
        )

        // When
        viewController.loadViewIfNeeded()

        // Then
        XCTAssertNil(viewController.addressSection?.addressDetails.address.line1)
    }
}

private final class AddressViewControllerDelegateMock: AddressViewControllerDelegate {
    var addressDetails: AddressViewController.AddressDetails?

    func addressViewControllerDidFinish(
        _ addressViewController: AddressViewController,
        with address: AddressViewController.AddressDetails?
    ) {
        addressDetails = address
    }
}
