//
//  PaymentPagesAPIResponse.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// The Checkout response used throughout the SDK.
///
/// Properties in this model mirror the API payload. Construction of the public Checkout
/// representation belongs to `CheckoutController.Session`.
struct PaymentPagesAPIResponse: UnknownFieldsDecodable, CustomStringConvertible {
    // TODO: Make this Decodable instead, we don't need _allResponseFieldStorage.
    var _allResponseFieldsStorage: NonEncodableParameters?

    let checkoutConfigID: String?
    let sessionId: String
    var paymentIntentId: String? { paymentResponse?.paymentIntent?.id }
    var paymentIntent: STPPaymentIntent?
    var setupIntentId: String? { paymentResponse?.setupIntent?.id }
    var setupIntent: STPSetupIntent?
    let currency: String
    let integrationCurrency: String
    let checkoutItems: [CheckoutItem]
    let livemode: Bool
    var status: CheckoutController.Session.Status
    var paymentStatus: CheckoutController.Session.Status.PaymentStatus
    let customerEmail: String?
    let savedPaymentMethodsOfferSave: SavedPaymentMethodsOfferSave?
    let setupFutureUsageForPaymentMethodType: [String: String]?
    let billingAddressCollection: String?
    let shippingAddressCollection: ShippingAddressCollection?
    let totalSummary: TotalSummary?
    let adaptivePricingInfo: AdaptivePricingInfo?
    let automaticTax: AutomaticTax?
    let paymentMethodOptions: STPPaymentMethodOptions?
    let customer: Customer?
    let canDetachPaymentMethod: Bool
    let elementsSession: ElementsSession
    let paymentResponse: PaymentResponse?

    var description: String {
        let props: [String] = [
            "PaymentPagesAPIResponse",
            "sessionId = \(sessionId)",
            "currency = \(currency)",
            "uiMode = \(String(describing: allResponseFields["ui_mode"]))",
            "status = \(status)",
            "paymentIntentId = \(String(describing: paymentIntentId))",
            "setupIntentId = \(String(describing: setupIntentId))",
            "paymentMethodTypes = \(elementsSession.value.orderedPaymentMethodTypes)",
            "livemode = \(livemode)",
            "customerId = \(String(describing: customer?.id))",
            "customerEmail = \(String(describing: customerEmail))",
            "savedPaymentMethodsOfferSave = \(String(describing: savedPaymentMethodsOfferSave))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    private enum CodingKeys: String, CodingKey {
        case uiMode, savedPaymentMethodOptions, automaticTax
        case sessionId = "id"
        case currency = "presentment_currency"
        case integrationCurrency
        case checkoutConfigID = "checkout_session_config_id"
        case checkoutItems = "items"
        case livemode
        case status
        case paymentStatus
        case customerEmail
        case setupFutureUsageForPaymentMethodType
        case billingAddressCollection
        case shippingAddressCollection
        case totalSummary
        case adaptivePricingInfo
        case paymentMethodOptions
        case customer
        case paymentResponse
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        checkoutConfigID = try container.decodeIfPresent(String.self, forKey: .checkoutConfigID)
        paymentResponse = try container.decodeIfPresent(PaymentResponse.self, forKey: .paymentResponse)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        paymentIntent = nil
        setupIntent = nil
        let decodedCurrency = try container.decode(String.self, forKey: .currency)
        guard !decodedCurrency.isEmpty else {
            throw decoder.dataCorrupted("currency must not be empty")
        }
        currency = decodedCurrency
        integrationCurrency = try container.decode(String.self, forKey: .integrationCurrency)

        let uiMode = try container.decode(String.self, forKey: .uiMode)
        guard uiMode == "mobile_elements" else {
            throw decoder.dataCorrupted("Only mobile_elements Checkout Sessions are supported")
        }

        let decodedCheckoutItems = try container.decode([CheckoutItem].self, forKey: .checkoutItems)
        guard !decodedCheckoutItems.isEmpty else {
            throw decoder.dataCorrupted("checkout_items must not be empty")
        }
        guard decodedCheckoutItems.allSatisfy({ checkoutItem in
            checkoutItem.oneTimePrice.items.allSatisfy { $0.price.currency == decodedCurrency }
        }) else {
            throw decoder.dataCorrupted("Every Checkout item currency must match currency")
        }
        checkoutItems = decodedCheckoutItems

        livemode = try container.decode(Bool.self, forKey: .livemode)
        let decodedPaymentStatus = try container.decode(String.self, forKey: .paymentStatus)
        guard let paymentStatus = CheckoutController.Session.Status.PaymentStatus.paymentStatus(
            from: decodedPaymentStatus
        ) else {
            throw decoder.dataCorrupted("Unsupported payment_status: \(decodedPaymentStatus)")
        }
        self.paymentStatus = paymentStatus

        let decodedStatus = try container.decode(String.self, forKey: .status)
        guard let status = CheckoutController.Session.Status.status(
            from: decodedStatus,
            paymentStatus: paymentStatus
        ) else {
            throw decoder.dataCorrupted("Unsupported Checkout Session status: \(decodedStatus)")
        }
        self.status = status

        customerEmail = try container.decodeIfPresent(String.self, forKey: .customerEmail)
        let savedOptions = try container.decodeIfPresent(SavedPaymentMethodOptions.self, forKey: .savedPaymentMethodOptions)
        canDetachPaymentMethod = savedOptions?.paymentMethodRemove == "enabled"
        savedPaymentMethodsOfferSave = savedOptions?.paymentMethodSave.map {
            SavedPaymentMethodsOfferSave(enabled: $0 == "enabled")
        }
        setupFutureUsageForPaymentMethodType = try container.decodeIfPresent(
            [String: String].self,
            forKey: .setupFutureUsageForPaymentMethodType
        )
        billingAddressCollection = try container.decodeIfPresent(
            String.self,
            forKey: .billingAddressCollection
        )
        shippingAddressCollection = try container.decodeIfPresent(
            ShippingAddressCollection.self,
            forKey: .shippingAddressCollection
        )
        totalSummary = try container.decodeIfPresent(TotalSummary.self, forKey: .totalSummary)
        adaptivePricingInfo = try container.decodeIfPresent(AdaptivePricingInfo.self, forKey: .adaptivePricingInfo)
        automaticTax = try container.decodeIfPresent(AutomaticTax.self, forKey: .automaticTax)
        paymentMethodOptions = try container.decodeIfPresent(
            LegacyDecoded<STPPaymentMethodOptions>.self,
            forKey: .paymentMethodOptions
        )?.value
        customer = try container.decodeIfPresent(Customer.self, forKey: .customer)
        elementsSession = try ElementsSession(checkoutClient: decoder)
    }
}

extension PaymentPagesAPIResponse {
    struct IntentReference: Decodable {
        let id: String
        let clientSecret: String
    }

    struct AutomaticTax: Decodable {
        let enabled: Bool
        let status: String?
        let addressSource: String?
    }

    /// CheckoutClient's canonical payment details. Intent references are retrieved separately for authentication.
    struct PaymentResponse: Decodable {
        let status: String
        let lastPaymentError: StripeAPIError?
        let paymentIntent: IntentReference?
        let setupIntent: IntentReference?
    }

    /// Adapts a dictionary-backed API model to `Decodable` while it is migrated.
    struct LegacyDecoded<Value: STPAPIResponseDecodable>: Decodable {
        let value: Value

        init(from decoder: Decoder) throws {
            let dictionary = try decoder.stripeJSONDictionary
            guard let value = Value.decodedObject(fromAPIResponse: dictionary) else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: decoder.codingPath,
                        debugDescription: "Could not decode \(Value.self) using its legacy parser"
                    )
                )
            }
            self.value = value
        }
    }

}

// MARK: - API-shaped nested models

extension PaymentPagesAPIResponse {
    struct CheckoutItem: Decodable {
        let key: String
        let oneTimePrice: OneTimePrice

        private enum CodingKeys: String, CodingKey {
            case key
            case type
            case oneTimePrice
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            key = try container.decode(String.self, forKey: .key)
            let type = try container.decode(String.self, forKey: .type)
            guard type == "one_time_price" else {
                throw decoder.dataCorrupted("Unsupported Checkout item type: \(type)")
            }
            oneTimePrice = try container.decode(OneTimePrice.self, forKey: .oneTimePrice)
        }
    }

    struct OneTimePrice: Decodable {
        let items: [OneTimePriceItem]
    }

    struct OneTimePriceItem: Decodable {
        let innerItemKey: String
        let price: Price
        let quantity: Int
        let subtotal: Int
        let total: Int
        let unitAmount: Int?
        let unitAmountDecimal: Double?
        let unitLabel: String?
        let taxAmounts: [TaxAmount]
        let taxInclusive: Int
        let taxExclusive: Int
        let adjustableQuantity: AdjustableQuantity?

        private enum CodingKeys: String, CodingKey {
            case innerItemKey
            case price
            case quantity
            case amountDetails
            case unitAmount
            case unitAmountDecimal
            case unitLabel
            case adjustableQuantity
        }

        private struct AmountDetails: Decodable {
            let subtotal: Int
            let total: Int
            let taxAmounts: [TaxAmount]?
            let taxInclusive: Int
            let taxExclusive: Int
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            innerItemKey = try container.decode(String.self, forKey: .innerItemKey)
            price = try container.decode(Price.self, forKey: .price)
            quantity = try container.decode(Int.self, forKey: .quantity)
            guard quantity >= 0 else {
                throw decoder.dataCorrupted("quantity must not be negative")
            }
            let amountDetails = try container.decode(AmountDetails.self, forKey: .amountDetails)
            subtotal = amountDetails.subtotal
            total = amountDetails.total
            unitAmount = try container.decodeIfPresent(Int.self, forKey: .unitAmount)

            if let rawUnitAmountDecimal = try container.decodeIfPresent(
                String.self,
                forKey: .unitAmountDecimal
            ) {
                guard let parsedUnitAmountDecimal = Double(rawUnitAmountDecimal),
                      parsedUnitAmountDecimal.isFinite else {
                    throw decoder.dataCorrupted("unit_amount_decimal must be a finite number")
                }
                unitAmountDecimal = parsedUnitAmountDecimal
            } else {
                unitAmountDecimal = nil
            }

            guard unitAmount != nil || price.unitAmount != nil || unitAmountDecimal != nil else {
                throw decoder.dataCorrupted("A one-time Price item must have a unit amount")
            }

            unitLabel = try container.decodeIfPresent(String.self, forKey: .unitLabel)
            taxAmounts = amountDetails.taxAmounts ?? []
            taxInclusive = amountDetails.taxInclusive
            taxExclusive = amountDetails.taxExclusive
            adjustableQuantity = try container.decodeIfPresent(
                AdjustableQuantity.self,
                forKey: .adjustableQuantity
            )
        }
    }

    struct Price: Decodable {
        let id: String
        let currency: String
        let unitAmount: Int?
        let product: Product

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(String.self, forKey: .id)
            currency = try container.decode(String.self, forKey: .currency)
            guard !currency.isEmpty else {
                throw decoder.dataCorrupted("Price currency must not be empty")
            }
            unitAmount = try container.decodeIfPresent(Int.self, forKey: .unitAmount)
            product = try container.decode(Product.self, forKey: .product)
        }

        private enum CodingKeys: String, CodingKey {
            case id
            case currency
            case unitAmount
            case product
        }
    }

    struct Product: Decodable {
        let name: String
        let images: [String]
    }

    struct TotalSummary: Decodable {
        let totalTaxAmounts: [TaxAmount]?
    }

    struct TaxAmount: Decodable {
        let amount: Int
        let inclusive: Bool
        let taxRate: TaxRate

        private enum CodingKeys: String, CodingKey {
            case amount, inclusive, taxRate
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            amount = try container.decode(Int.self, forKey: .amount)
            inclusive = try container.decode(Bool.self, forKey: .inclusive)
            taxRate = try container.contains(.taxRate)
                ? container.decode(TaxRate.self, forKey: .taxRate)
                : TaxRate(from: decoder)
        }
    }

    struct TaxRate: Decodable {
        let displayName: String
        let percentage: Double
        let rateType: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            displayName = try container.decode(String.self, forKey: .displayName)
            percentage = try container.decode(Double.self, forKey: .percentage)
            rateType = try container.decodeIfPresent(String.self, forKey: .rateType)
            guard rateType == nil || rateType == "flat_amount" || rateType == "percentage" else {
                throw decoder.dataCorrupted("Unsupported tax rate type: \(rateType!)")
            }
        }

        private enum CodingKeys: String, CodingKey {
            case displayName
            case percentage
            case rateType
        }
    }

    struct AdjustableQuantity: Decodable {
        let enabled: Bool
        let maximum: Int?
        let minimum: Int?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            enabled = try container.decode(Bool.self, forKey: .enabled)
            if enabled {
                maximum = try container.decode(Int.self, forKey: .maximum)
                minimum = try container.decode(Int.self, forKey: .minimum)
            } else {
                maximum = try container.decodeIfPresent(Int.self, forKey: .maximum)
                minimum = try container.decodeIfPresent(Int.self, forKey: .minimum)
            }
        }

        private enum CodingKeys: String, CodingKey {
            case enabled
            case maximum
            case minimum
        }
    }

    struct ShippingAddressCollection: Decodable {
        let allowedCountries: [String]
    }

    struct AdaptivePricingInfo: Decodable {
        let integrationAmount: Int
        let integrationCurrency: String
        let integrationCurrencyDisclosureCaption: String?
        let localCurrencyOptions: [LocalCurrencyOption]

        private enum CodingKeys: String, CodingKey {
            case integrationCurrencyOption, localCurrencyOptions
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let integrationOption = try container.decode(LocalCurrencyOption.self, forKey: .integrationCurrencyOption)
            integrationAmount = integrationOption.amount
            integrationCurrency = integrationOption.currency
            integrationCurrencyDisclosureCaption = integrationOption.disclosureCaption
            localCurrencyOptions = try container.decode([LocalCurrencyOption].self, forKey: .localCurrencyOptions)
        }
    }

    struct LocalCurrencyOption: Decodable {
        private struct Disclosure: Decodable {
            let caption: String
            let details: String?
        }

        let amount: Int
        let currency: String
        let disclosureCaption: String?
        let disclosureDetails: String?

        private enum CodingKeys: String, CodingKey {
            case amount, currency, disclosure
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            amount = try container.decode(Int.self, forKey: .amount)
            currency = try container.decode(String.self, forKey: .currency)
            let disclosure = try container.decodeIfPresent(Disclosure.self, forKey: .disclosure)
            disclosureCaption = disclosure?.caption
            disclosureDetails = disclosure?.details
        }
    }

    private struct SavedPaymentMethodOptions: Decodable {
        let paymentMethodSave: String?
        let paymentMethodRemove: String?
    }

    struct SavedPaymentMethodsOfferSave {
        let enabled: Bool
    }

    struct ElementsSession {
        let businessName: String?
        let merchantCountryCode: String
        let value: STPElementsSession

        private enum CodingKeys: String, CodingKey {
            case merchantInfo, elementsSessionId, elementsSessionConfigId
            case orderedPaymentMethodTypesAndWallets, unactivatedPaymentMethodTypes
            case countryCode, linkSettings, experimentsData, flags, cardBrandChoice
            case applePayPreference, passiveCaptcha
        }

        private struct MerchantInfo: Decodable {
            let displayName: String?
            let country: String
            let logoUrl: String?
        }

        private struct PassiveCaptcha: Decodable {
            let siteKey: String
            let rqdata: String?
            let tokenRefreshAfterSeconds: TimeInterval?
        }

        /// Supplies the legacy Link parser's passthrough flag from CheckoutClient's mode.
        private struct LegacyLinkSettings: Decodable {
            let value: LinkSettings?

            init(from decoder: Decoder) throws {
                var fields = try decoder.stripeJSONDictionary
                if fields["link_passthrough_mode_enabled"] == nil {
                    // Elements derives this legacy flag from link_mode. CheckoutClient returns the mode
                    // without the flag, which the SDK still uses to offer Link in Express Checkout.
                    let linkMode = (fields["link_mode"] as? String).flatMap(LinkMode.init(rawValue:))
                    fields["link_passthrough_mode_enabled"] = linkMode == .passthrough || linkMode == .linkCardBrand
                }
                value = LinkSettings.decodedObject(fromAPIResponse: fields)
            }
        }

        init(checkoutClient decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let merchant = try container.decode(MerchantInfo.self, forKey: .merchantInfo)
            let elementsSessionID = try container.decode(String.self, forKey: .elementsSessionId)
            let orderedTypes = try container.decode([String].self, forKey: .orderedPaymentMethodTypesAndWallets)
            let paymentMethodTypes = orderedTypes.filter {
                !["apple_pay", "google_pay", "card_wallet_link"].contains($0)
            }
            let flags = try container.decodeIfPresent([String: Bool].self, forKey: .flags) ?? [:]
            let captcha = try container.decodeIfPresent(PassiveCaptcha.self, forKey: .passiveCaptcha)
            let passiveCaptchaData: PassiveCaptchaData?
            if flags["elements_enable_passive_captcha"] == true, let captcha {
                passiveCaptchaData = PassiveCaptchaData(
                    siteKey: captcha.siteKey,
                    rqdata: captcha.rqdata,
                    tokenTimeoutSeconds: captcha.tokenRefreshAfterSeconds ?? PassiveCaptchaData.defaultTokenTimeoutSeconds
                )
            } else {
                passiveCaptchaData = nil
            }
            let value = STPElementsSession(
                allResponseFields: try decoder.stripeJSONDictionary,
                sessionID: elementsSessionID,
                configID: try container.decodeIfPresent(String.self, forKey: .elementsSessionConfigId),
                orderedPaymentMethodTypes: paymentMethodTypes.map { STPPaymentMethod.type(from: $0) },
                orderedPaymentMethodTypesAndWallets: orderedTypes,
                unactivatedPaymentMethodTypes: (try container.decodeIfPresent([String].self, forKey: .unactivatedPaymentMethodTypes) ?? []).map { STPPaymentMethod.type(from: $0) },
                countryCode: try container.decodeIfPresent(String.self, forKey: .countryCode),
                merchantCountryCode: merchant.country,
                merchantLogoUrl: merchant.logoUrl.flatMap(URL.init(string:)),
                accountID: nil,
                linkSettings: try container.decodeIfPresent(LegacyLinkSettings.self, forKey: .linkSettings)?.value,
                experimentsData: try container.decodeIfPresent(LegacyDecoded<ExperimentsData>.self, forKey: .experimentsData)?.value,
                flags: flags,
                cardBrandChoice: try container.decodeIfPresent(LegacyDecoded<STPCardBrandChoice>.self, forKey: .cardBrandChoice)?.value,
                isApplePayEnabled: try container.decodeIfPresent(String.self, forKey: .applePayPreference) != "disabled",
                externalPaymentMethods: [],
                customPaymentMethods: [],
                passiveCaptchaData: passiveCaptchaData,
                customer: nil
            )
            self.businessName = merchant.displayName
            self.merchantCountryCode = merchant.country
            self.value = value
        }

    }
}

private extension Decoder {
    func dataCorrupted(_ description: String) -> DecodingError {
        return DecodingError.dataCorrupted(
            .init(codingPath: codingPath, debugDescription: description)
        )
    }
}
