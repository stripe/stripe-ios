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
    let taxContext: TaxContext?
    let taxMeta: TaxMeta?
    let paymentMethodOptions: STPPaymentMethodOptions?
    let customer: Customer?
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
        guard ["mobile_elements", "custom", "elements"].contains(uiMode) else {
            throw decoder.dataCorrupted("Unsupported CheckoutClient ui_mode: \(uiMode)")
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
        let tax = try container.decodeIfPresent(AutomaticTax.self, forKey: .automaticTax)
        taxContext = tax.map { TaxContext(automaticTaxEnabled: $0.enabled, automaticTaxAddressSource: $0.addressSource.map { "session.\($0)" }) }
        taxMeta = tax.map {
            TaxMeta(computationType: .init($0.enabled ? .automatic : .off), status: $0.status == "requires_address" ? .init(.requiresLocationInputs) : ($0.status == "ready" ? .init(.complete) : nil))
        }
        paymentMethodOptions = try container.decodeIfPresent(
            LegacyDecoded<STPPaymentMethodOptions>.self,
            forKey: .paymentMethodOptions
        )?.value
        var decodedCustomer = try container.decodeIfPresent(Customer.self, forKey: .customer)
        // CheckoutClient returns removal permission alongside the customer, in saved_payment_method_options.
        decodedCustomer?.canDetachPaymentMethod = savedOptions?.paymentMethodRemove == "enabled"
        customer = decodedCustomer
        elementsSession = try ElementsSession(checkoutClient: decoder)
    }
}

extension PaymentPagesAPIResponse {
    struct IntentReference: Decodable {
        let id: String
        let clientSecret: String
    }

    private struct AutomaticTax: Decodable {
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
            case subtotal
            case total
            case unitAmount
            case unitAmountDecimal
            case unitLabel
            case taxAmounts
            case taxInclusive
            case taxExclusive
            case adjustableQuantity
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            innerItemKey = try container.decode(String.self, forKey: .innerItemKey)
            price = try container.decode(Price.self, forKey: .price)
            quantity = try container.decode(Int.self, forKey: .quantity)
            guard quantity >= 0 else {
                throw decoder.dataCorrupted("quantity must not be negative")
            }
            subtotal = try container.decode(Int.self, forKey: .subtotal)
            total = try container.decode(Int.self, forKey: .total)
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
            taxAmounts = try container.decode([TaxAmount].self, forKey: .taxAmounts)
            taxInclusive = try container.decode(Int.self, forKey: .taxInclusive)
            taxExclusive = try container.decode(Int.self, forKey: .taxExclusive)
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
            let caption: String?
            let details: String?
        }

        let amount: Int
        let conversionMarkupBps: Int?
        let currency: String
        let presentmentExchangeRate: String?
        let disclosureCaption: String?
        let disclosureDetails: String?

        private enum CodingKeys: String, CodingKey {
            case amount, currency, disclosure
            case caption, details
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            amount = try container.decode(Int.self, forKey: .amount)
            currency = try container.decode(String.self, forKey: .currency)
            let disclosure = try container.decodeIfPresent(Disclosure.self, forKey: .disclosure)
            disclosureCaption = disclosure?.caption
            disclosureDetails = disclosure?.details
            // CheckoutClient returns localized disclosures instead of raw exchange rates.
            conversionMarkupBps = nil
            presentmentExchangeRate = nil
        }
    }

    struct TaxContext: Decodable {
        let automaticTaxEnabled: Bool
        let automaticTaxAddressSource: String?
    }

    struct TaxMeta: Decodable {
        enum ComputationType: String, SafeParsedEnumCodable {
            case off = "Off"
            case automatic
            case extensionDefined = "extension_defined"
            case manual
            case userDefined = "user_defined"
        }

        enum Status: String, SafeParsedEnumCodable {
            case complete
            case failed
            case requiresLocationInputs = "requires_location_inputs"
        }

        let computationType: ParsedEnum<ComputationType>
        let status: ParsedEnum<Status>?
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

        init(checkoutClient decoder: Decoder) throws {
            guard let fields = try decoder.stripeJSONDictionary as? [String: Any],
                  let merchant = fields["merchant_info"] as? [String: Any],
                  let merchantCountryCode = merchant["country"] as? String,
                  let elementsSessionID = fields["elements_session_id"] as? String,
                  let orderedTypes = fields["ordered_payment_method_types_and_wallets"] as? [String] else {
                throw decoder.dataCorrupted("CheckoutClient response is missing required Elements configuration")
            }
            let paymentMethodTypes = orderedTypes.filter {
                !["apple_pay", "google_pay", "card_wallet_link"].contains($0)
            }
            // TODO(OCS_API_EXT-266): CheckoutClient's Link resource omits Elements' mobile flags, including
            // attestation endpoint selection. Backend parity is required for those settings.
            var linkSettings = fields["link_settings"] as? [String: Any]
            if linkSettings?["link_passthrough_mode_enabled"] == nil {
                // Elements derives this legacy flag from link_mode. CheckoutClient returns the mode
                // without the flag, which the SDK still uses to offer Link in Express Checkout.
                let linkMode = (linkSettings?["link_mode"] as? String).flatMap(LinkMode.init(rawValue:))
                linkSettings?["link_passthrough_mode_enabled"] = linkMode == .passthrough || linkMode == .linkCardBrand
            }
            let flags = fields["flags"] as? [String: Bool] ?? [:]
            var passiveCaptcha = fields["passive_captcha"] as? [String: Any]
            let tokenRefreshAfterSeconds = passiveCaptcha?["token_refresh_after_seconds"]
            passiveCaptcha?["token_timeout_seconds"] = tokenRefreshAfterSeconds
            let value = STPElementsSession(
                allResponseFields: fields,
                sessionID: elementsSessionID,
                configID: fields["elements_session_config_id"] as? String,
                orderedPaymentMethodTypes: paymentMethodTypes.map { STPPaymentMethod.type(from: $0) },
                orderedPaymentMethodTypesAndWallets: orderedTypes,
                unactivatedPaymentMethodTypes: (fields["unactivated_payment_method_types"] as? [String] ?? []).map { STPPaymentMethod.type(from: $0) },
                countryCode: fields["country_code"] as? String,
                merchantCountryCode: merchantCountryCode,
                merchantLogoUrl: (merchant["logo_url"] as? String).flatMap(URL.init(string:)),
                accountID: nil,
                linkSettings: LinkSettings.decodedObject(fromAPIResponse: linkSettings),
                experimentsData: ExperimentsData.decodedObject(fromAPIResponse: fields["experiments_data"] as? [String: Any]),
                flags: flags,
                cardBrandChoice: STPCardBrandChoice.decodedObject(fromAPIResponse: fields["card_brand_choice"] as? [String: Any]),
                isApplePayEnabled: fields["apple_pay_preference"] as? String != "disabled",
                externalPaymentMethods: [],
                customPaymentMethods: [],
                passiveCaptchaData: flags["elements_enable_passive_captcha"] == true ? passiveCaptcha.flatMap(PassiveCaptchaData.decoded(fromAPIResponse:)) : nil,
                customer: nil
            )
            self.businessName = merchant["display_name"] as? String
            self.merchantCountryCode = merchantCountryCode
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
