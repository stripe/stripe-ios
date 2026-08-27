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

/// Internal response model for the Payment Pages API endpoints.
///
/// Properties in this model mirror the API payload. Conversion to the public Checkout
/// representation belongs in `makePublicSession()`.
struct PaymentPagesAPIResponse: UnknownFieldsDecodable, CustomStringConvertible {
    // TODO: Make this Decodable instead, we don't need _allResponseFieldStorage.
    var _allResponseFieldsStorage: NonEncodableParameters?

    let sessionId: String
    let paymentIntentId: String?
    let paymentIntent: STPPaymentIntent?
    let setupIntentId: String?
    let setupIntent: STPSetupIntent?
    let currency: String
    let checkoutItems: [CheckoutItem]
    let livemode: Bool
    let status: CheckoutController.Session.Status
    let paymentStatus: CheckoutController.Session.Status.PaymentStatus
    let submissionAttempt: SubmissionAttempt?
    let routeToOrchestrationInterface: Bool?
    let customerEmail: String?
    let url: String?
    let savedPaymentMethodsOfferSave: SavedPaymentMethodsOfferSave?
    let setupFutureUsage: String?
    let setupFutureUsageForPaymentMethodType: [String: String]?
    let billingAddressCollection: String?
    let shippingAddressCollection: ShippingAddressCollection?
    let recurringDetails: RecurringDetails?
    let adaptivePricingInfo: AdaptivePricingInfo?
    let taxContext: TaxContext?
    let taxMeta: TaxMeta?
    let paymentMethodOptions: STPPaymentMethodOptions?
    let customer: Customer?
    let elementsSession: ElementsSession

    /// Extracts the client secret from whichever expanded intent is present in the response.
    func intentClientSecret() throws -> String {
        if let setupIntent {
            return setupIntent.clientSecret
        } else if let paymentIntent {
            return paymentIntent.clientSecret
        }
        throw PaymentSheetError.unknown(
            debugDescription: "No intent found in checkout session response"
        )
    }

    var description: String {
        let props: [String] = [
            "PaymentPagesAPIResponse",
            "sessionId = \(sessionId)",
            "currency = \(currency)",
            "mode = \(String(describing: allResponseFields["mode"]))",
            "status = \(status)",
            "paymentIntentId = \(String(describing: paymentIntentId))",
            "setupIntentId = \(String(describing: setupIntentId))",
            "paymentMethodTypes = \(String(describing: allResponseFields["payment_method_types"]))",
            "livemode = \(livemode)",
            "customerId = \(String(describing: customer?.id))",
            "customerEmail = \(String(describing: customerEmail))",
            "url = \(String(describing: url))",
            "savedPaymentMethodsOfferSave = \(String(describing: savedPaymentMethodsOfferSave))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    private enum CodingKeys: String, CodingKey {
        case sessionId
        case paymentIntent
        case setupIntent
        case currency
        case checkoutItems
        case livemode
        case mode
        case status
        case paymentStatus
        case submissionAttempt
        case routeToOrchestrationInterface
        case customerEmail
        case url
        case savedPaymentMethodsOfferSave = "customer_managed_saved_payment_methods_offer_save"
        case setupFutureUsage
        case setupFutureUsageForPaymentMethodType
        case billingAddressCollection
        case shippingAddressCollection
        case recurringDetails
        case adaptivePricingInfo
        case taxContext
        case taxMeta
        case paymentMethodOptions
        case customer
        case elementsSession
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        let decodedPaymentIntent = try container.decodeIfPresent(
            LegacyExpandable<STPPaymentIntent>.self,
            forKey: .paymentIntent
        )
        paymentIntentId = decodedPaymentIntent?.id
        paymentIntent = decodedPaymentIntent?.expandedObject
        let decodedSetupIntent = try container.decodeIfPresent(
            LegacyExpandable<STPSetupIntent>.self,
            forKey: .setupIntent
        )
        setupIntentId = decodedSetupIntent?.id
        setupIntent = decodedSetupIntent?.expandedObject
        let decodedCurrency = try container.decode(String.self, forKey: .currency)
        guard !decodedCurrency.isEmpty else {
            throw decoder.dataCorrupted("currency must not be empty")
        }
        currency = decodedCurrency

        let mode = try container.decode(String.self, forKey: .mode)
        guard mode == "modeless" else {
            throw decoder.dataCorrupted("Only modeless Checkout Sessions are supported")
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

        submissionAttempt = try container.decodeIfPresent(
            SubmissionAttempt.self,
            forKey: .submissionAttempt
        )
        routeToOrchestrationInterface = try container.decodeIfPresent(
            Bool.self,
            forKey: .routeToOrchestrationInterface
        )
        customerEmail = try container.decodeIfPresent(String.self, forKey: .customerEmail)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        savedPaymentMethodsOfferSave = try container.decodeIfPresent(
            SavedPaymentMethodsOfferSave.self,
            forKey: .savedPaymentMethodsOfferSave
        )
        setupFutureUsage = try container.decodeIfPresent(String.self, forKey: .setupFutureUsage)
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
        recurringDetails = try container.decodeIfPresent(RecurringDetails.self, forKey: .recurringDetails)
        adaptivePricingInfo = try container.decodeIfPresent(
            AdaptivePricingInfo.self,
            forKey: .adaptivePricingInfo
        )
        taxContext = try container.decodeIfPresent(TaxContext.self, forKey: .taxContext)
        taxMeta = try container.decodeIfPresent(TaxMeta.self, forKey: .taxMeta)
        paymentMethodOptions = try container.decodeIfPresent(
            LegacyDecoded<STPPaymentMethodOptions>.self,
            forKey: .paymentMethodOptions
        )?.value
        customer = try container.decodeIfPresent(Customer.self, forKey: .customer)
        elementsSession = try container.decode(ElementsSession.self, forKey: .elementsSession)
    }
}

extension PaymentPagesAPIResponse {
    struct SubmissionAttempt: Decodable {
        enum State: String, Decodable {
            case processing
            case requiresApproval = "requires_approval"
            case complete
            case failed
        }

        let state: State
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

    private struct LegacyExpandable<Value: STPAPIResponseDecodable>: Decodable {
        let id: String
        let expandedObject: Value?

        private enum CodingKeys: String, CodingKey {
            case id
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let id = try? container.decode(String.self) {
                self.id = id
                self.expandedObject = nil
                return
            }

            let expandedObject = try LegacyDecoded<Value>(from: decoder).value
            guard let id = expandedObject.allResponseFields["id"] as? String else {
                throw DecodingError.keyNotFound(
                    CodingKeys.id,
                    .init(
                        codingPath: decoder.codingPath,
                        debugDescription: "Expanded \(Value.self) is missing id"
                    )
                )
            }
            self.id = id
            self.expandedObject = expandedObject
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
        let subtotal: Int
        let total: Int
    }

    struct OneTimePriceItem: Decodable {
        let innerItemKey: String
        let price: Price
        let quantity: Int
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

    struct RecurringDetails: Decodable {
        let totalDiscountAmounts: [DiscountAmount]
        let totalTaxAmounts: [TaxAmount]
    }

    struct DiscountAmount: Decodable {
        let amount: Int
        let displayName: String?
        let coupon: Coupon
        let promotionCode: PromotionCode?
    }

    struct Coupon: Decodable {
        let code: String
        let name: String?
        let percentOff: Double?
    }

    struct PromotionCode: Decodable {
        let code: String?
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

    struct AdaptivePricingInfo: Decodable {
        let activePresentmentCurrency: String
        let integrationAmount: Int
        let integrationCurrency: String
        let localCurrencyOptions: [LocalCurrencyOption]
    }

    struct LocalCurrencyOption: Decodable {
        let amount: Int
        let conversionMarkupBps: Int?
        let currency: String
        let presentmentExchangeRate: String
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

    struct SavedPaymentMethodsOfferSave: Decodable {
        enum Status: String, SafeParsedEnumCodable {
            case accepted
            case notAccepted = "not_accepted"
        }

        let enabled: Bool
        let status: ParsedEnum<Status>
    }

    struct ElementsSession: Decodable {
        let businessName: String?
        let merchantCountryCode: String
        let value: STPElementsSession

        private enum CodingKeys: String, CodingKey {
            case businessName
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            businessName = try container.decodeIfPresent(String.self, forKey: .businessName)
            let value = try LegacyDecoded<STPElementsSession>(from: decoder).value
            // TODO: Make merchant_country non-optional in CheckoutClient when Checkout migrates to it.
            guard let merchantCountryCode = value.merchantCountryCode else {
                throw decoder.dataCorrupted("Missing required elements_session.merchant_country")
            }
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
