//
//  Checkout+ExpressCheckoutElement.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore

extension ExpressCheckoutElement.Configuration {
    func asPaymentSheetConfiguration(apiClient: STPAPIClient) -> PaymentSheet.Configuration {
        var config = PaymentSheet.Configuration()
        config.appearance = appearance
        config.applePay = applePay
        config.link = link
        config.returnURL = returnURL
        config.apiClient = apiClient
        config.billingDetailsCollectionConfiguration = billingDetailsCollectionConfiguration
        config.allowsPromotionCodes = allowsPromotionCodes
        return config
    }
}
