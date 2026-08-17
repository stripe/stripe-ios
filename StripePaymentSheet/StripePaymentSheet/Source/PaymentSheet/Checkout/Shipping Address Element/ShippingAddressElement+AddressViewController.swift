//
//  ShippingAddressElement+AddressViewController.swift
//  StripePaymentSheet
//
//  Created by George Birch on 8/4/26.

@_spi(STP) import StripeCore

extension ShippingAddressElement.Configuration {
    func makeAddressViewControllerConfiguration(
        shippingAddress: Checkout.Session.ShippingAddress?,
        allowedCountries: [String]?,
        apiClient: STPAPIClient
    ) -> AddressViewController.Configuration {
        let allowedCountries = allowedCountries ?? []
        let defaultValues: AddressViewController.Configuration.DefaultAddressDetails
        if let shippingAddress,
           allowedCountries.isEmpty || allowedCountries.contains(shippingAddress.address.country) {
            defaultValues = .init(
                address: .init(
                    city: shippingAddress.address.city,
                    country: shippingAddress.address.country,
                    line1: shippingAddress.address.line1,
                    line2: shippingAddress.address.line2,
                    postalCode: shippingAddress.address.postalCode,
                    state: shippingAddress.address.state
                ),
                name: shippingAddress.name
            )
        } else {
            defaultValues = .init()
        }

        var configuration = AddressViewController.Configuration(
            defaultValues: defaultValues,
            allowedCountries: allowedCountries,
            appearance: appearance.makePaymentSheetAppearance(),
            buttonTitle: buttonTitle,
            title: title
        )
        configuration.apiClient = apiClient
        return configuration
    }
}

extension ShippingAddressElement.Appearance {
    func makePaymentSheetAppearance() -> PaymentSheet.Appearance {
        var appearance = PaymentSheet.Appearance()
        appearance.font.sizeScaleFactor = font.sizeScaleFactor
        appearance.font.base = font.base
        appearance.font.custom.headline = font.custom.headline

        appearance.colors.primary = colors.primary
        appearance.colors.background = colors.background
        appearance.colors.componentBackground = colors.componentBackground
        appearance.colors.componentBorder = colors.componentBorder
        appearance.colors.componentDivider = colors.componentDivider
        appearance.colors.text = colors.text
        appearance.colors.textSecondary = colors.textSecondary
        appearance.colors.componentText = colors.componentText
        appearance.colors.componentPlaceholderText = colors.componentPlaceholderText
        appearance.colors.icon = colors.icon
        appearance.colors.danger = colors.danger

        appearance.primaryButton.backgroundColor = primaryButton.backgroundColor
        appearance.primaryButton.textColor = primaryButton.textColor
        appearance.primaryButton.disabledBackgroundColor = primaryButton.disabledBackgroundColor
        appearance.primaryButton.disabledTextColor = primaryButton.disabledTextColor
        appearance.primaryButton.cornerRadius = primaryButton.cornerRadius
        appearance.primaryButton.borderColor = primaryButton.borderColor
        appearance.primaryButton.borderWidth = primaryButton.borderWidth
        appearance.primaryButton.font = primaryButton.font
        if let shadow = primaryButton.shadow {
            appearance.primaryButton.shadow = .init(
                color: shadow.color,
                opacity: shadow.opacity,
                offset: shadow.offset,
                radius: shadow.radius
            )
        }
        appearance.primaryButton.height = primaryButton.height

        appearance.cornerRadius = cornerRadius
        appearance.borderWidth = borderWidth
        appearance.shadow = .init(
            color: shadow.color,
            opacity: shadow.opacity,
            offset: shadow.offset,
            radius: shadow.radius
        )
        appearance.textFieldInsets = textFieldInsets
        appearance.formInsets = formInsets
        return appearance
    }
}
