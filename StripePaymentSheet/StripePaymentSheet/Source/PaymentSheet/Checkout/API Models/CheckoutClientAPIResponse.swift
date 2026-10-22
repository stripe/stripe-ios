//
//  CheckoutClientAPIResponse.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 1/14/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments

/// The response returned by CheckoutClient init, update, retrieve, and confirm.
struct CheckoutClientAPIResponse: UnknownFieldsDecodable, CustomStringConvertible {
    var _allResponseFieldsStorage: NonEncodableParameters?

    let id: String
    let uiMode: String
    let presentmentCurrency: String
    let integrationCurrency: String
    let items: [CheckoutItem]
    let livemode: Bool
    var status: CheckoutController.Session.Status
    var paymentStatus: CheckoutController.Session.Status.PaymentStatus
    let customerEmail: String?
    let billingAddressCollection: String?
    let shippingAddressCollection: ShippingAddressCollection?
    let totalSummary: TotalSummary?
    let automaticTax: AutomaticTax?
    let adaptivePricingInfo: AdaptivePricingInfo?
    let savedPaymentMethodOptions: SavedPaymentMethodOptions?
    let setupFutureUsageForPaymentMethodType: [String: String]?
    let paymentMethodOptions: STPPaymentMethodOptions?
    let customer: Customer?
    let merchantInfo: MerchantInfo
    let paymentResponse: PaymentResponse?
    let elementsSession: STPElementsSession

    // Expanded separately when confirmation needs authentication or next-action handling.
    var paymentIntent: STPPaymentIntent?
    var setupIntent: STPSetupIntent?

    func intentClientSecret() throws -> String {
        if let setupIntent { return setupIntent.clientSecret }
        if let paymentIntent { return paymentIntent.clientSecret }
        throw PaymentSheetError.unknown(debugDescription: "No intent found in CheckoutClient response")
    }

    var description: String {
        "<CheckoutClientAPIResponse; id = \(id); status = \(status); currency = \(presentmentCurrency); livemode = \(livemode)>"
    }

    private enum CodingKeys: String, CodingKey {
        case id, uiMode, presentmentCurrency, integrationCurrency, items, livemode, status, paymentStatus
        case customerEmail, billingAddressCollection, shippingAddressCollection, totalSummary, automaticTax
        case adaptivePricingInfo, savedPaymentMethodOptions, setupFutureUsageForPaymentMethodType
        case paymentMethodOptions, customer, merchantInfo, paymentResponse
        case elementsSessionId, elementsSessionConfigId, orderedPaymentMethodTypesAndWallets
        case unactivatedPaymentMethodTypes, countryCode, linkSettings, experimentsData, flags
        case cardBrandChoice, applePayPreference, passiveCaptcha
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        uiMode = try container.decode(String.self, forKey: .uiMode)
        guard ["mobile_elements", "custom"].contains(uiMode) else {
            throw decoder.dataCorrupted("Unsupported CheckoutClient ui_mode: \(uiMode)")
        }
        let presentmentCurrency = try container.decode(String.self, forKey: .presentmentCurrency)
        self.presentmentCurrency = presentmentCurrency
        integrationCurrency = try container.decode(String.self, forKey: .integrationCurrency)
        guard !presentmentCurrency.isEmpty else {
            throw decoder.dataCorrupted("presentment_currency must not be empty")
        }
        items = try container.decode([CheckoutItem].self, forKey: .items)
        guard !items.isEmpty else { throw decoder.dataCorrupted("items must not be empty") }
        guard items.allSatisfy({ $0.oneTimePrice.items.allSatisfy { $0.price.currency == presentmentCurrency } }) else {
            throw decoder.dataCorrupted("Every Checkout item currency must match presentment_currency")
        }
        livemode = try container.decode(Bool.self, forKey: .livemode)
        let paymentStatusString = try container.decode(String.self, forKey: .paymentStatus)
        guard
            let paymentStatus = CheckoutController.Session.Status.PaymentStatus.paymentStatus(from: paymentStatusString)
        else {
            throw decoder.dataCorrupted("Unsupported payment_status: \(paymentStatusString)")
        }
        self.paymentStatus = paymentStatus
        let statusString = try container.decode(String.self, forKey: .status)
        guard let status = CheckoutController.Session.Status.status(from: statusString, paymentStatus: paymentStatus)
        else {
            throw decoder.dataCorrupted("Unsupported Checkout Session status: \(statusString)")
        }
        self.status = status
        customerEmail = try container.decodeIfPresent(String.self, forKey: .customerEmail)
        billingAddressCollection = try container.decodeIfPresent(String.self, forKey: .billingAddressCollection)
        shippingAddressCollection = try container.decodeIfPresent(
            ShippingAddressCollection.self,
            forKey: .shippingAddressCollection
        )
        totalSummary = try container.decodeIfPresent(TotalSummary.self, forKey: .totalSummary)
        automaticTax = try container.decodeIfPresent(AutomaticTax.self, forKey: .automaticTax)
        adaptivePricingInfo = try container.decodeIfPresent(AdaptivePricingInfo.self, forKey: .adaptivePricingInfo)
        savedPaymentMethodOptions = try container.decodeIfPresent(
            SavedPaymentMethodOptions.self,
            forKey: .savedPaymentMethodOptions
        )
        setupFutureUsageForPaymentMethodType = try container.decodeIfPresent(
            [String: String].self,
            forKey: .setupFutureUsageForPaymentMethodType
        )
        // TODO(OCS_API_EXT-267): Return the resolved per-method SFU map, including inherited values.
        paymentMethodOptions = try container.decodeIfPresent(
            APIResponseDecoded<STPPaymentMethodOptions>.self,
            forKey: .paymentMethodOptions
        )?.value
        customer = try container.decodeIfPresent(Customer.self, forKey: .customer)
        merchantInfo = try container.decode(MerchantInfo.self, forKey: .merchantInfo)
        paymentResponse = try container.decodeIfPresent(PaymentResponse.self, forKey: .paymentResponse)

        let orderedTypes = try container.decode([String].self, forKey: .orderedPaymentMethodTypesAndWallets)
        let flags = try container.decodeIfPresent([String: Bool].self, forKey: .flags) ?? [:]
        let captcha = try container.decodeIfPresent(PassiveCaptcha.self, forKey: .passiveCaptcha)
        // TODO(OCS_API_EXT-266): Return the mobile Link settings from the resolved Elements Session.
        elementsSession = STPElementsSession(
            allResponseFields: try decoder.stripeJSONDictionary,
            sessionID: try container.decode(String.self, forKey: .elementsSessionId),
            configID: try container.decodeIfPresent(String.self, forKey: .elementsSessionConfigId),
            orderedPaymentMethodTypes: orderedTypes.filter {
                !["apple_pay", "google_pay", "card_wallet_link"].contains($0)
            }.map { STPPaymentMethod.type(from: $0) },
            orderedPaymentMethodTypesAndWallets: orderedTypes,
            unactivatedPaymentMethodTypes: (try container.decodeIfPresent(
                [String].self,
                forKey: .unactivatedPaymentMethodTypes
            ) ?? []).map { STPPaymentMethod.type(from: $0) },
            countryCode: try container.decodeIfPresent(String.self, forKey: .countryCode),
            merchantCountryCode: merchantInfo.country,
            merchantLogoUrl: merchantInfo.logoUrl.flatMap(URL.init(string:)),
            accountID: nil,
            linkSettings: try container.decodeIfPresent(APIResponseDecoded<LinkSettings>.self, forKey: .linkSettings)?
                .value,
            experimentsData: try container.decodeIfPresent(
                APIResponseDecoded<ExperimentsData>.self,
                forKey: .experimentsData
            )?.value,
            flags: flags,
            cardBrandChoice: try container.decodeIfPresent(
                APIResponseDecoded<STPCardBrandChoice>.self,
                forKey: .cardBrandChoice
            )?.value,
            isApplePayEnabled: try container.decodeIfPresent(String.self, forKey: .applePayPreference) != "disabled",
            externalPaymentMethods: [],
            customPaymentMethods: [],
            passiveCaptchaData: flags["elements_enable_passive_captcha"] == true
                ? captcha.map {
                    PassiveCaptchaData(
                        siteKey: $0.siteKey,
                        rqdata: $0.rqdata,
                        tokenTimeoutSeconds: $0.tokenRefreshAfterSeconds
                    )
                } : nil,
            customer: nil
        )
    }
}

extension CheckoutClientAPIResponse {
    struct PaymentResponse: Decodable {
        let status: String
        let lastPaymentError: StripeAPIError?
        let paymentIntent: IntentReference?
        let setupIntent: IntentReference?
    }

    struct IntentReference: Decodable {
        let id: String
        let clientSecret: String
    }

    struct MerchantInfo: Decodable {
        let country: String
        let displayName: String?
        let logoUrl: String?
    }

    struct PassiveCaptcha: Decodable {
        let siteKey: String
        let rqdata: String?
        let tokenRefreshAfterSeconds: TimeInterval
    }

    struct SavedPaymentMethodOptions: Decodable {
        let paymentMethodSave: String?
        let paymentMethodRemove: String?
    }

    struct AutomaticTax: Decodable {
        let enabled: Bool
        let status: String?
        let addressSource: String?
    }

    struct TotalSummary: Decodable {
        let totalTaxAmounts: [TotalTaxAmount]?
    }

    struct TotalTaxAmount: Decodable {
        let amount: Int
        let inclusive: Bool
        let displayName: String
        let percentage: Double
    }

    struct AdaptivePricingInfo: Decodable {
        let integrationCurrencyOption: CurrencyOption
        let localCurrencyOptions: [CurrencyOption]
    }

    struct CurrencyOption: Decodable {
        let amount: Int
        let currency: String
        let disclosure: Disclosure?
    }

    struct Disclosure: Decodable {
        let caption: String?
        let details: String?
    }

    /// Adapts a dictionary-backed API model to `Decodable` for use by typed CheckoutClient fields.
    struct APIResponseDecoded<Value: STPAPIResponseDecodable>: Decodable {
        let value: Value

        init(from decoder: Decoder) throws {
            let dictionary = try decoder.stripeJSONDictionary
            guard let value = Value.decodedObject(fromAPIResponse: dictionary) else {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: decoder.codingPath,
                        debugDescription: "Could not decode \(Value.self) from its API response"
                    )
                )
            }
            self.value = value
        }
    }

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

    struct TaxAmount: Decodable {
        let amount: Int
        let inclusive: Bool
        let taxRate: TaxRate
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

}

private extension Decoder {
    func dataCorrupted(_ description: String) -> DecodingError {
        .dataCorrupted(.init(codingPath: codingPath, debugDescription: description))
    }
}
