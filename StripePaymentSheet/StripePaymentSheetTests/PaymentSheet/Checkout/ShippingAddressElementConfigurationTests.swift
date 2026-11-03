//
//  ShippingAddressElementConfigurationTests.swift
//  StripePaymentSheetTests
//
//  Created by George Birch on 8/4/26.

@_spi(InternalOnlyAPI) @testable import StripeCore
@_spi(AppearanceAPIAdditionsPreview) @_spi(InternalOnlyAPI) @testable import StripePaymentSheet
import UIKit
import XCTest

@MainActor
final class ShippingAddressElementConfigurationTests: XCTestCase {

    func testConfigurationDefaultsToNil() {
        let configuration = CheckoutController.Configuration(
            clientSecret: "cs_test_123_secret_abc",
            returnURL: "stripe-ios-test://checkout-return"
        )

        XCTAssertNil(configuration.shippingAddressElement)
    }

    func testCheckoutInitializesShippingAddressElement() async throws {
        // Given
        var sessionJSON = CheckoutTestHelpers.openSessionJSON
        sessionJSON["shipping_address_collection"] = ["allowed_countries": ["US", "CA"]]
        var elementsSessionJSON = CheckoutTestHelpers.minimalCheckoutClientConfigurationJSON
        elementsSessionJSON["flags"] = ["ocs_mobile_should_use_autocomplete_proxy_endpoints": true]
        for (key, value) in elementsSessionJSON { sessionJSON[key] = value }
        let apiResponse = try CheckoutClientAPIResponse.decode(fromAPIResponse: sessionJSON)

        var configuration = CheckoutController.Configuration(
            clientSecret: "cs_test_123_secret_abc",
            returnURL: "stripe-ios-test://checkout-return"
        )
        var shippingAddressElementConfiguration = ShippingAddressElement.Configuration()
        shippingAddressElementConfiguration.title = "Delivery address"
        shippingAddressElementConfiguration.buttonTitle = "Save delivery address"
        shippingAddressElementConfiguration.appearance.colors.primary = .purple
        configuration.shippingAddressElement = shippingAddressElementConfiguration
        configuration.userInterfaceStyle = .alwaysDark
        var shippingDetails = CheckoutController.Configuration.Defaults.ShippingDetails()
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
        let checkout = try await CheckoutController(configuration: configuration)
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
        XCTAssertEqual(shippingAddressElement.addressViewController.overrideUserInterfaceStyle, .dark)
    }

    /// Reproduces stale form values and the old address being saved over a direct update.
    func testShippingAddressElementDoesNotReflectAddressUpdatesMadeOutsideTheElement() async throws {
        // Given a Checkout Session with a Shipping Address Element, seeded with a default address.
        var sessionJSON = CheckoutTestHelpers.openSessionJSON
        sessionJSON["shipping_address_collection"] = ["allowed_countries": ["US", "CA"]]
        let apiResponse = try CheckoutClientAPIResponse.decode(fromAPIResponse: sessionJSON)

        var configuration = CheckoutController.Configuration(
            clientSecret: "cs_test_123_secret_abc",
            returnURL: "stripe-ios-test://checkout-return"
        )
        configuration.shippingAddressElement = ShippingAddressElement.Configuration()
        var shippingDetails = CheckoutController.Configuration.Defaults.ShippingDetails()
        shippingDetails.name = "Jenny Rosen"
        shippingDetails.address = .init(
            country: "US",
            line1: "510 Townsend St.",
            city: "San Francisco",
            state: "CA",
            postalCode: "94103"
        )
        configuration.defaults.shippingDetails = shippingDetails
        configuration = CheckoutTestHelpers.makeConfiguration(apiResponse: apiResponse, configuration: configuration)

        let checkout = try await CheckoutController(configuration: configuration)
        XCTAssertEqual(
            checkout.getShippingAddressElement().addressViewController.configuration.defaultValues.address.city,
            "San Francisco"
        )
        XCTAssertEqual(checkout.session.shippingAddress?.address.city, "San Francisco")

        // When the shipping address is updated through the public API directly, bypassing the
        // element (e.g. the merchant's own "use my saved address" button). This session has no
        // automatic tax address source configured, so the update is purely local -- no network
        // stubbing is needed to exercise it.
        try await checkout.updateShippingAddress(
            name: "New Name",
            address: CheckoutController.Address(
                country: "US",
                line1: "1 New St.",
                city: "New York",
                state: "NY",
                postalCode: "10001"
            )
        )

        // Then: the session reflects the new address...
        XCTAssertEqual(checkout.session.shippingAddress?.address.city, "New York")

        // ...but the Shipping Address Element's own form still has the OLD address baked in --
        // it was seeded once at construction and has no mechanism to re-sync.
        XCTAssertEqual(
            checkout.getShippingAddressElement().addressViewController.configuration.defaultValues.address.city,
            "San Francisco",
            "the element should reflect the session's current shipping address, but it never updates after construction"
        )

        // Read the actual form fields, rather than relying only on immutable configuration.
        let element = checkout.getShippingAddressElement()
        let formDetails = await element.addressViewController.initialAddressDetails()
        let staleAddress = try XCTUnwrap(formDetails)
        XCTAssertEqual(staleAddress.name, "Jenny Rosen")
        XCTAssertEqual(staleAddress.address.city, "San Francisco")

        // When the user saves those unchanged form values through the normal save delegate
        try await element.save(addressDetails: staleAddress)

        // Then the old form values replace the merchant's newer address in the session
        XCTAssertEqual(checkout.session.shippingAddress?.name, "Jenny Rosen")
        XCTAssertEqual(checkout.session.shippingAddress?.address.city, "San Francisco")

        // Clearing the session address also leaves the form populated with the old address.
        try await checkout.updateShippingAddress(name: nil, address: nil)
        XCTAssertNil(checkout.session.shippingAddress)
        let detailsAfterClearing = await element.addressViewController.initialAddressDetails()
        XCTAssertEqual(detailsAfterClearing?.name, "Jenny Rosen")
        XCTAssertEqual(detailsAfterClearing?.address.city, "San Francisco")
    }

    func testMakeAddressViewControllerConfiguration() {
        // Given
        let apiClient = STPAPIClient(publishableKey: "pk_test_123")
        let shippingAddress = CheckoutController.Session.ShippingAddress(
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
        let shippingAddress = CheckoutController.Session.ShippingAddress(
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
