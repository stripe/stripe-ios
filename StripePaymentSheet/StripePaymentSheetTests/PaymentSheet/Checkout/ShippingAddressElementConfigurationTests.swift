//
//  ShippingAddressElementConfigurationTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 8/4/26.

@_spi(STP) @testable import StripeCore
@_spi(AppearanceAPIAdditionsPreview) @_spi(STP) @testable import StripePaymentSheet
import UIKit
import XCTest

@MainActor
final class ShippingAddressElementConfigurationTests: XCTestCase {
    func testCheckoutInitializesShippingAddressElement() async throws {
        // Given
        var sessionJSON = CheckoutTestHelpers.openSessionJSON
        sessionJSON["shipping_address_collection"] = ["allowed_countries": ["US", "CA"]]
        var elementsSessionJSON = CheckoutTestHelpers.minimalElementsSessionJSON
        elementsSessionJSON["flags"] = ["ocs_mobile_should_use_autocomplete_proxy_endpoints": true]
        sessionJSON["elements_session"] = elementsSessionJSON
        let apiResponse = try XCTUnwrap(PaymentPagesAPIResponse.decodedObject(fromAPIResponse: sessionJSON))

        var configuration = Checkout.Configuration(
            clientSecret: "cs_test_123_secret_abc",
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.shippingAddressElement.title = "Delivery address"
        configuration.shippingAddressElement.buttonTitle = "Save delivery address"
        configuration.shippingAddressElement.appearance.colors.primary = .purple
        var shippingDetails = Checkout.Configuration.Defaults.ShippingDetails()
        shippingDetails.name = "Jenny Rosen"
        shippingDetails.address = .init(
            country: "US",
            line1: "510 Townsend St.",
            city: "San Francisco",
            state: "CA",
            postalCode: "94103"
        )
        configuration.defaults.shippingDetails = shippingDetails
        configuration = CheckoutTestHelpers.makeConfiguration(
            apiResponse: apiResponse,
            configuration: configuration
        )

        // When
        let checkout = try await Checkout(configuration: configuration)
        let shippingAddressElement = checkout.getShippingAddressElement()
        let addressConfiguration = shippingAddressElement.addressViewController.configuration

        // Then
        XCTAssertTrue(shippingAddressElement === checkout.getShippingAddressElement())
        XCTAssertEqual(addressConfiguration.title, "Delivery address")
        XCTAssertEqual(addressConfiguration.buttonTitle, "Save delivery address")
        XCTAssertEqual(addressConfiguration.appearance.colors.primary, .purple)
        XCTAssertEqual(addressConfiguration.allowedCountries, ["US", "CA"])
        XCTAssertEqual(addressConfiguration.defaultValues.name, "Jenny Rosen")
        XCTAssertEqual(addressConfiguration.defaultValues.address.country, "US")
        XCTAssertEqual(addressConfiguration.defaultValues.address.line1, "510 Townsend St.")
        XCTAssertTrue(addressConfiguration.apiClient === configuration.apiClient)
        XCTAssertTrue(shippingAddressElement.addressViewController.useAutocompleteEndpoints)
    }

    func testMakeAddressViewControllerConfiguration() {
        // Given
        let apiClient = STPAPIClient(publishableKey: "pk_test_123")
        let shippingAddress = Checkout.Session.ShippingAddress(
            name: "Jenny Rosen",
            address: .init(
                country: "US",
                line1: "510 Townsend St.",
                line2: "Floor 4",
                city: "San Francisco",
                state: "CA",
                postalCode: "94103"
            )
        )
        var configuration = ShippingAddressElement.Configuration()
        configuration.title = "Delivery address"
        configuration.buttonTitle = "Save delivery address"
        configuration.appearance.colors.primary = .purple

        // When
        let addressConfiguration = configuration.makeAddressViewControllerConfiguration(
            shippingAddress: shippingAddress,
            allowedCountries: ["US", "CA"],
            apiClient: apiClient
        )

        // Then
        XCTAssertEqual(addressConfiguration.title, "Delivery address")
        XCTAssertEqual(addressConfiguration.buttonTitle, "Save delivery address")
        XCTAssertEqual(addressConfiguration.appearance.colors.primary, .purple)
        XCTAssertEqual(addressConfiguration.allowedCountries, ["US", "CA"])
        XCTAssertEqual(addressConfiguration.defaultValues.name, "Jenny Rosen")
        XCTAssertEqual(addressConfiguration.defaultValues.address.country, "US")
        XCTAssertEqual(addressConfiguration.defaultValues.address.line1, "510 Townsend St.")
        XCTAssertEqual(addressConfiguration.defaultValues.address.line2, "Floor 4")
        XCTAssertEqual(addressConfiguration.defaultValues.address.city, "San Francisco")
        XCTAssertEqual(addressConfiguration.defaultValues.address.state, "CA")
        XCTAssertEqual(addressConfiguration.defaultValues.address.postalCode, "94103")
        XCTAssertTrue(addressConfiguration.apiClient === apiClient)
    }

    func testMakeAddressViewControllerConfigurationIgnoresDisallowedShippingAddress() {
        // Given
        let shippingAddress = Checkout.Session.ShippingAddress(
            name: "Jenny Rosen",
            address: .init(country: "CA", line1: "123 Front St.")
        )
        let configuration = ShippingAddressElement.Configuration()

        // When
        let addressConfiguration = configuration.makeAddressViewControllerConfiguration(
            shippingAddress: shippingAddress,
            allowedCountries: ["US"],
            apiClient: .shared
        )

        // Then
        XCTAssertNil(addressConfiguration.defaultValues.name)
        XCTAssertTrue(addressConfiguration.defaultValues.address.isEmpty)
    }

    func testMakePaymentSheetAppearance() {
        // Given
        var appearance = ShippingAddressElement.Appearance()
        appearance.font.sizeScaleFactor = 1.2
        appearance.font.base = .preferredFont(forTextStyle: .body)
        appearance.font.custom.headline = .preferredFont(forTextStyle: .headline)
        appearance.colors.primary = .red
        appearance.colors.background = .orange
        appearance.colors.componentBackground = .yellow
        appearance.colors.componentBorder = .green
        appearance.colors.componentDivider = .blue
        appearance.colors.text = .purple
        appearance.colors.textSecondary = .brown
        appearance.colors.componentText = .cyan
        appearance.colors.componentPlaceholderText = .magenta
        appearance.colors.icon = .gray
        appearance.colors.danger = .darkGray
        appearance.primaryButton.backgroundColor = .red
        appearance.primaryButton.textColor = .orange
        appearance.primaryButton.disabledBackgroundColor = .yellow
        appearance.primaryButton.disabledTextColor = .green
        appearance.primaryButton.cornerRadius = 10
        appearance.primaryButton.borderColor = .blue
        appearance.primaryButton.borderWidth = 2
        appearance.primaryButton.font = .preferredFont(forTextStyle: .title1)
        var primaryButtonShadow = ShippingAddressElement.Appearance.Shadow()
        primaryButtonShadow.color = .purple
        primaryButtonShadow.opacity = 0.2
        primaryButtonShadow.offset = .init(width: 3, height: 4)
        primaryButtonShadow.radius = 5
        appearance.primaryButton.shadow = primaryButtonShadow
        appearance.primaryButton.height = 48
        appearance.cornerRadius = 12
        appearance.borderWidth = 3
        appearance.shadow.color = .brown
        appearance.shadow.opacity = 0.3
        appearance.shadow.offset = .init(width: 6, height: 7)
        appearance.shadow.radius = 8
        appearance.textFieldInsets = .init(top: 1, leading: 2, bottom: 3, trailing: 4)
        appearance.formInsets = .init(top: 5, leading: 6, bottom: 7, trailing: 8)

        // When
        let paymentSheetAppearance = appearance.makePaymentSheetAppearance()

        // Then
        XCTAssertEqual(paymentSheetAppearance.font.sizeScaleFactor, appearance.font.sizeScaleFactor)
        XCTAssertEqual(paymentSheetAppearance.font.base, appearance.font.base)
        XCTAssertEqual(paymentSheetAppearance.font.custom.headline, appearance.font.custom.headline)
        XCTAssertEqual(paymentSheetAppearance.colors.primary, appearance.colors.primary)
        XCTAssertEqual(paymentSheetAppearance.colors.background, appearance.colors.background)
        XCTAssertEqual(paymentSheetAppearance.colors.componentBackground, appearance.colors.componentBackground)
        XCTAssertEqual(paymentSheetAppearance.colors.componentBorder, appearance.colors.componentBorder)
        XCTAssertEqual(paymentSheetAppearance.colors.componentDivider, appearance.colors.componentDivider)
        XCTAssertEqual(paymentSheetAppearance.colors.text, appearance.colors.text)
        XCTAssertEqual(paymentSheetAppearance.colors.textSecondary, appearance.colors.textSecondary)
        XCTAssertEqual(paymentSheetAppearance.colors.componentText, appearance.colors.componentText)
        XCTAssertEqual(paymentSheetAppearance.colors.componentPlaceholderText, appearance.colors.componentPlaceholderText)
        XCTAssertEqual(paymentSheetAppearance.colors.icon, appearance.colors.icon)
        XCTAssertEqual(paymentSheetAppearance.colors.danger, appearance.colors.danger)
        XCTAssertEqual(paymentSheetAppearance.primaryButton.backgroundColor, appearance.primaryButton.backgroundColor)
        XCTAssertEqual(paymentSheetAppearance.primaryButton.textColor, appearance.primaryButton.textColor)
        XCTAssertEqual(paymentSheetAppearance.primaryButton.disabledBackgroundColor, appearance.primaryButton.disabledBackgroundColor)
        XCTAssertEqual(paymentSheetAppearance.primaryButton.disabledTextColor, appearance.primaryButton.disabledTextColor)
        XCTAssertEqual(paymentSheetAppearance.primaryButton.cornerRadius, appearance.primaryButton.cornerRadius)
        XCTAssertEqual(paymentSheetAppearance.primaryButton.borderColor, appearance.primaryButton.borderColor)
        XCTAssertEqual(paymentSheetAppearance.primaryButton.borderWidth, appearance.primaryButton.borderWidth)
        XCTAssertEqual(paymentSheetAppearance.primaryButton.font, appearance.primaryButton.font)
        XCTAssertEqual(paymentSheetAppearance.primaryButton.shadow?.color, appearance.primaryButton.shadow?.color)
        XCTAssertEqual(paymentSheetAppearance.primaryButton.shadow?.opacity, appearance.primaryButton.shadow?.opacity)
        XCTAssertEqual(paymentSheetAppearance.primaryButton.shadow?.offset, appearance.primaryButton.shadow?.offset)
        XCTAssertEqual(paymentSheetAppearance.primaryButton.shadow?.radius, appearance.primaryButton.shadow?.radius)
        XCTAssertEqual(paymentSheetAppearance.primaryButton.height, appearance.primaryButton.height)
        XCTAssertEqual(paymentSheetAppearance.cornerRadius, appearance.cornerRadius)
        XCTAssertEqual(paymentSheetAppearance.borderWidth, appearance.borderWidth)
        XCTAssertEqual(paymentSheetAppearance.shadow.color, appearance.shadow.color)
        XCTAssertEqual(paymentSheetAppearance.shadow.opacity, appearance.shadow.opacity)
        XCTAssertEqual(paymentSheetAppearance.shadow.offset, appearance.shadow.offset)
        XCTAssertEqual(paymentSheetAppearance.shadow.radius, appearance.shadow.radius)
        XCTAssertEqual(paymentSheetAppearance.textFieldInsets, appearance.textFieldInsets)
        XCTAssertEqual(paymentSheetAppearance.formInsets, appearance.formInsets)
    }
}
