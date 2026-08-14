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

/// Internal response model for the mobile Payment Pages API endpoints.
///
/// Properties in this model mirror the API payload. Conversion to the public Checkout
/// representation belongs in `makePublicSession()`.
class PaymentPagesAPIResponse: NSObject {
    let sessionId: String
    let clientSecret: String?
    let currency: String
    let checkoutItems: [CheckoutItem]
    let livemode: Bool
    let status: String?
    let paymentStatus: String
    let paymentIntentId: String?
    let setupIntentId: String?
    let paymentIntent: STPPaymentIntent?
    let setupIntent: STPSetupIntent?
    let paymentMethodOptions: STPPaymentMethodOptions?
    let customer: STPCheckoutSessionCustomer?
    let customerEmail: String?
    let url: String?
    let returnUrl: String?
    let savedPaymentMethodsOfferSave: SavedPaymentMethodsOfferSave?
    let setupFutureUsage: String?
    let setupFutureUsageForPaymentMethodType: [String: String]?
    let billingAddressCollection: String?
    let shippingAddressCollection: ShippingAddressCollection?
    let shippingRate: ShippingRate?
    let recurringDetails: RecurringDetails?
    let totalSummary: TotalSummary?
    let adaptivePricingInfo: AdaptivePricingInfo?
    let developerToolContext: DeveloperToolContext?
    let taxContext: TaxContext?
    let taxMeta: TaxMeta?
    let elementsSession: ElementsSession

    /// The raw API response used to create this object.
    let allResponseFields: [AnyHashable: Any]

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

    override var description: String {
        let props: [String] = [
            String(format: "%@: %p", NSStringFromClass(PaymentPagesAPIResponse.self), self),
            "sessionId = \(sessionId)",
            "totalSummary = \(String(describing: totalSummary))",
            "clientSecret = <redacted>",
            "currency = \(String(describing: currency))",
            "mode = \(String(describing: allResponseFields["mode"]))",
            "status = \(String(describing: status))",
            "paymentIntentId = \(String(describing: paymentIntentId))",
            "setupIntentId = \(String(describing: setupIntentId))",
            "paymentIntent = \(String(describing: paymentIntent))",
            "setupIntent = \(String(describing: setupIntent))",
            "paymentMethodTypes = \(String(describing: allResponseFields["payment_method_types"]))",
            "livemode = \(livemode)",
            "customerId = \(String(describing: customer?.id))",
            "customerEmail = \(String(describing: customerEmail))",
            "url = \(String(describing: url))",
            "returnUrl = \(String(describing: returnUrl))",
            "savedPaymentMethodsOfferSave = \(String(describing: savedPaymentMethodsOfferSave))",
        ]
        return "<\(props.joined(separator: "; "))>"
    }

    private init(
        sessionId: String,
        clientSecret: String?,
        currency: String,
        checkoutItems: [CheckoutItem],
        livemode: Bool,
        status: String?,
        paymentStatus: String,
        paymentIntentId: String?,
        setupIntentId: String?,
        paymentIntent: STPPaymentIntent?,
        setupIntent: STPSetupIntent?,
        paymentMethodOptions: STPPaymentMethodOptions?,
        customer: STPCheckoutSessionCustomer?,
        customerEmail: String?,
        url: String?,
        returnUrl: String?,
        savedPaymentMethodsOfferSave: SavedPaymentMethodsOfferSave?,
        setupFutureUsage: String?,
        setupFutureUsageForPaymentMethodType: [String: String]?,
        billingAddressCollection: String?,
        shippingAddressCollection: ShippingAddressCollection?,
        shippingRate: ShippingRate?,
        recurringDetails: RecurringDetails?,
        totalSummary: TotalSummary?,
        adaptivePricingInfo: AdaptivePricingInfo?,
        developerToolContext: DeveloperToolContext?,
        taxContext: TaxContext?,
        taxMeta: TaxMeta?,
        elementsSession: ElementsSession,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.sessionId = sessionId
        self.clientSecret = clientSecret
        self.currency = currency
        self.checkoutItems = checkoutItems
        self.livemode = livemode
        self.status = status
        self.paymentStatus = paymentStatus
        self.paymentIntentId = paymentIntentId
        self.setupIntentId = setupIntentId
        self.paymentIntent = paymentIntent
        self.setupIntent = setupIntent
        self.paymentMethodOptions = paymentMethodOptions
        self.customer = customer
        self.customerEmail = customerEmail
        self.url = url
        self.returnUrl = returnUrl
        self.savedPaymentMethodsOfferSave = savedPaymentMethodsOfferSave
        self.setupFutureUsage = setupFutureUsage
        self.setupFutureUsageForPaymentMethodType = setupFutureUsageForPaymentMethodType
        self.billingAddressCollection = billingAddressCollection
        self.shippingAddressCollection = shippingAddressCollection
        self.shippingRate = shippingRate
        self.recurringDetails = recurringDetails
        self.totalSummary = totalSummary
        self.adaptivePricingInfo = adaptivePricingInfo
        self.developerToolContext = developerToolContext
        self.taxContext = taxContext
        self.taxMeta = taxMeta
        self.elementsSession = elementsSession
        self.allResponseFields = allResponseFields
        super.init()
    }
}

// MARK: - API-shaped nested models

extension PaymentPagesAPIResponse {
    struct CheckoutItem {
        let key: String
        let oneTimePrice: OneTimePrice

        init?(_ dict: [AnyHashable: Any]) {
            guard let key = dict["key"] as? String,
                  let type = dict["type"] as? String,
                  type == "one_time_price",
                  let oneTimePriceDict = dict["one_time_price"] as? [AnyHashable: Any],
                  let oneTimePrice = OneTimePrice(oneTimePriceDict) else {
                return nil
            }
            self.key = key
            self.oneTimePrice = oneTimePrice
        }
    }

    struct OneTimePrice {
        let items: [OneTimePriceItem]
        let subtotal: Int
        let total: Int

        init?(_ dict: [AnyHashable: Any]) {
            guard let itemDicts = dict["items"] as? [[AnyHashable: Any]],
                  let subtotal = dict["subtotal"] as? Int,
                  let total = dict["total"] as? Int else {
                return nil
            }
            let items = itemDicts.compactMap(OneTimePriceItem.init)
            guard items.count == itemDicts.count else {
                return nil
            }
            self.items = items
            self.subtotal = subtotal
            self.total = total
        }
    }

    struct OneTimePriceItem {
        let price: Price
        let quantity: Int
        let unitAmount: Int?
        let unitAmountDecimal: Double?
        let unitLabel: String?
        let taxAmounts: [TaxAmount]
        let taxInclusive: Int
        let taxExclusive: Int
        let adjustableQuantity: AdjustableQuantity?

        init?(_ dict: [AnyHashable: Any]) {
            guard (dict["inner_item_key"] as? String) != nil,
                  let priceDict = dict["price"] as? [AnyHashable: Any],
                  let price = Price(priceDict),
                  let quantity = dict["quantity"] as? Int,
                  quantity >= 0,
                  (dict["subtotal"] as? Int) != nil,
                  (dict["total"] as? Int) != nil,
                  let taxAmountDicts = dict["tax_amounts"] as? [[AnyHashable: Any]],
                  let taxInclusive = dict["tax_inclusive"] as? Int,
                  let taxExclusive = dict["tax_exclusive"] as? Int else {
                return nil
            }

            guard dict["unit_amount"] == nil
                || dict["unit_amount"] is NSNull
                || dict["unit_amount"] is Int else {
                return nil
            }
            let unitAmount = dict["unit_amount"] as? Int

            guard dict["unit_amount_decimal"] == nil
                || dict["unit_amount_decimal"] is NSNull
                || dict["unit_amount_decimal"] is String else {
                return nil
            }
            let unitAmountDecimal: Double?
            if let rawUnitAmountDecimal = dict["unit_amount_decimal"] as? String {
                guard let parsedUnitAmountDecimal = Double(rawUnitAmountDecimal),
                      parsedUnitAmountDecimal.isFinite else {
                    return nil
                }
                unitAmountDecimal = parsedUnitAmountDecimal
            } else {
                unitAmountDecimal = nil
            }

            guard unitAmount != nil || price.unitAmount != nil || unitAmountDecimal != nil else {
                return nil
            }

            guard dict["unit_label"] == nil
                || dict["unit_label"] is NSNull
                || dict["unit_label"] is String else {
                return nil
            }
            let unitLabel = dict["unit_label"] as? String

            let taxAmounts = taxAmountDicts.compactMap(TaxAmount.init)
            guard taxAmounts.count == taxAmountDicts.count else {
                return nil
            }

            let adjustableQuantity: AdjustableQuantity?
            if dict["adjustable_quantity"] == nil || dict["adjustable_quantity"] is NSNull {
                adjustableQuantity = nil
            } else if let adjustableQuantityDict = dict["adjustable_quantity"] as? [AnyHashable: Any],
                      let parsedAdjustableQuantity = AdjustableQuantity(adjustableQuantityDict) {
                adjustableQuantity = parsedAdjustableQuantity
            } else {
                return nil
            }

            self.price = price
            self.quantity = quantity
            self.unitAmount = unitAmount
            self.unitAmountDecimal = unitAmountDecimal
            self.unitLabel = unitLabel
            self.taxAmounts = taxAmounts
            self.taxInclusive = taxInclusive
            self.taxExclusive = taxExclusive
            self.adjustableQuantity = adjustableQuantity
        }
    }

    struct Price {
        let id: String
        let currency: String
        let unitAmount: Int?
        let product: Product

        init?(_ dict: [AnyHashable: Any]) {
            guard let id = dict["id"] as? String,
                  let currency = dict["currency"] as? String,
                  !currency.isEmpty,
                  let productDict = dict["product"] as? [AnyHashable: Any],
                  let product = Product(productDict),
                  dict["unit_amount"] == nil
                    || dict["unit_amount"] is NSNull
                    || dict["unit_amount"] is Int else {
                return nil
            }
            self.id = id
            self.currency = currency
            self.unitAmount = dict["unit_amount"] as? Int
            self.product = product
        }
    }

    struct Product {
        let name: String
        let images: [String]

        init?(_ dict: [AnyHashable: Any]) {
            guard let name = dict["name"] as? String,
                  let images = dict["images"] as? [String] else {
                return nil
            }
            self.name = name
            self.images = images
        }
    }

    struct TotalSummary {
        let subtotal: Int?
        let total: Int?
        let appliedBalance: Int?
        let balanceAppliedToNextInvoice: Bool?

        init(_ dict: [AnyHashable: Any]) {
            subtotal = dict["subtotal"] as? Int
            total = dict["total"] as? Int
            appliedBalance = dict["applied_balance"] as? Int
            balanceAppliedToNextInvoice = dict["balance_applied_to_next_invoice"] as? Bool
        }
    }

    struct RecurringDetails {
        let totalDiscountAmounts: [DiscountAmount]?
        let totalTaxAmounts: [TaxAmount]?

        init?(_ dict: [AnyHashable: Any]) {
            totalDiscountAmounts = (dict["total_discount_amounts"] as? [[AnyHashable: Any]])?.map(DiscountAmount.init)
            if dict["total_tax_amounts"] == nil || dict["total_tax_amounts"] is NSNull {
                totalTaxAmounts = nil
            } else if let taxAmountDicts = dict["total_tax_amounts"] as? [[AnyHashable: Any]] {
                let parsedTaxAmounts = taxAmountDicts.compactMap(TaxAmount.init)
                guard parsedTaxAmounts.count == taxAmountDicts.count else {
                    return nil
                }
                totalTaxAmounts = parsedTaxAmounts
            } else {
                return nil
            }
        }
    }

    struct DiscountAmount {
        let amount: Int?
        let displayName: String?
        let coupon: Coupon?
        let promotionCode: PromotionCode?

        init(_ dict: [AnyHashable: Any]) {
            amount = dict["amount"] as? Int
            displayName = dict["display_name"] as? String
            coupon = (dict["coupon"] as? [AnyHashable: Any]).map(Coupon.init)
            promotionCode = (dict["promotion_code"] as? [AnyHashable: Any]).map(PromotionCode.init)
        }
    }

    struct Coupon {
        let id: String?
        let name: String?

        init(_ dict: [AnyHashable: Any]) {
            id = dict["id"] as? String
            name = dict["name"] as? String
        }
    }

    struct PromotionCode {
        let code: String?

        init(_ dict: [AnyHashable: Any]) {
            code = dict["code"] as? String
        }
    }

    struct TaxAmount {
        let amount: Int
        let inclusive: Bool
        let taxRate: TaxRate

        init?(_ dict: [AnyHashable: Any]) {
            guard let amount = dict["amount"] as? Int,
                  let inclusive = dict["inclusive"] as? Bool,
                  let taxRateDict = dict["tax_rate"] as? [AnyHashable: Any],
                  let taxRate = TaxRate(taxRateDict) else {
                return nil
            }
            self.amount = amount
            self.inclusive = inclusive
            self.taxRate = taxRate
        }
    }

    struct TaxRate {
        let displayName: String
        let percentage: Double
        let rateType: String?

        init?(_ dict: [AnyHashable: Any]) {
            guard let displayName = dict["display_name"] as? String,
                  let percentage = dict["percentage"] as? Double,
                  dict["rate_type"] == nil
                    || dict["rate_type"] is NSNull
                    || dict["rate_type"] is String else {
                return nil
            }
            let rateType = dict["rate_type"] as? String
            guard rateType == nil || rateType == "flat_amount" || rateType == "percentage" else {
                return nil
            }
            self.displayName = displayName
            self.percentage = percentage
            self.rateType = rateType
        }
    }

    struct AdjustableQuantity {
        let enabled: Bool
        let maximum: Int?
        let minimum: Int?

        init?(_ dict: [AnyHashable: Any]) {
            guard let enabled = dict["enabled"] as? Bool,
                  dict["maximum"] == nil
                    || dict["maximum"] is NSNull
                    || dict["maximum"] is Int,
                  dict["minimum"] == nil
                    || dict["minimum"] is NSNull
                    || dict["minimum"] is Int else {
                return nil
            }
            self.enabled = enabled
            self.maximum = dict["maximum"] as? Int
            self.minimum = dict["minimum"] as? Int
        }
    }

    struct ShippingAddressCollection {
        let allowedCountries: [String]?

        init(_ dict: [AnyHashable: Any]) {
            allowedCountries = dict["allowed_countries"] as? [String]
        }
    }

    struct ShippingRate {
        let amount: Int?

        init(_ dict: [AnyHashable: Any]) {
            amount = dict["amount"] as? Int
        }
    }

    struct AdaptivePricingInfo {
        let activePresentmentCurrency: String?
        let integrationAmount: Int?
        let integrationCurrency: String?
        let localCurrencyOptions: [LocalCurrencyOption]?

        init(_ dict: [AnyHashable: Any]) {
            activePresentmentCurrency = dict["active_presentment_currency"] as? String
            integrationAmount = dict["integration_amount"] as? Int
            integrationCurrency = dict["integration_currency"] as? String
            localCurrencyOptions = (dict["local_currency_options"] as? [[AnyHashable: Any]])?.map(LocalCurrencyOption.init)
        }
    }

    struct LocalCurrencyOption {
        let amount: Int?
        let conversionMarkupBps: Int?
        let currency: String?
        let presentmentExchangeRate: String?

        init(_ dict: [AnyHashable: Any]) {
            amount = dict["amount"] as? Int
            conversionMarkupBps = dict["conversion_markup_bps"] as? Int
            currency = dict["currency"] as? String
            presentmentExchangeRate = dict["presentment_exchange_rate"] as? String
        }
    }

    struct DeveloperToolContext {
        let adaptivePricing: AdaptivePricing?

        init(_ dict: [AnyHashable: Any]) {
            adaptivePricing = (dict["adaptive_pricing"] as? [AnyHashable: Any]).map(AdaptivePricing.init)
        }

        struct AdaptivePricing {
            let active: Bool?

            init(_ dict: [AnyHashable: Any]) {
                active = dict["active"] as? Bool
            }
        }
    }

    struct TaxContext {
        let automaticTaxEnabled: Bool?
        let automaticTaxAddressSource: String?

        init(_ dict: [AnyHashable: Any]) {
            automaticTaxEnabled = dict["automatic_tax_enabled"] as? Bool
            automaticTaxAddressSource = dict["automatic_tax_address_source"] as? String
        }
    }

    struct TaxMeta {
        let computationType: String?
        let status: String?

        init(_ dict: [AnyHashable: Any]) {
            computationType = dict["computation_type"] as? String
            status = dict["status"] as? String
        }
    }

    struct SavedPaymentMethodsOfferSave {
        let enabled: Bool?
        let status: String?

        init(_ dict: [AnyHashable: Any]) {
            enabled = dict["enabled"] as? Bool
            status = dict["status"] as? String
        }
    }

    struct ElementsSession {
        let businessName: String?
        let value: STPElementsSession
    }
}

// MARK: - STPAPIResponseDecodable

extension PaymentPagesAPIResponse: STPAPIResponseDecodable {
    @objc
    class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
              let sessionId = dict["session_id"] as? String,
              let currency = dict["currency"] as? String,
              !currency.isEmpty,
              (dict["mode"] as? String) == "modeless",
              let checkoutItemDicts = dict["checkout_items"] as? [[AnyHashable: Any]],
              !checkoutItemDicts.isEmpty,
              let livemode = dict["livemode"] as? Bool,
              let paymentStatus = dict["payment_status"] as? String,
              (dict["payment_method_types"] as? [String]) != nil,
              let elementsSessionDict = dict["elements_session"] as? [AnyHashable: Any],
              let elementsSessionValue = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionDict)
        else {
            return nil
        }

        let checkoutItems = checkoutItemDicts.compactMap(CheckoutItem.init)
        guard checkoutItems.count == checkoutItemDicts.count,
              checkoutItems.allSatisfy({ checkoutItem in
                  checkoutItem.oneTimePrice.items.allSatisfy { $0.price.currency == currency }
              }) else {
            return nil
        }

        let recurringDetails: RecurringDetails?
        if dict["recurring_details"] == nil || dict["recurring_details"] is NSNull {
            recurringDetails = nil
        } else if let recurringDetailsDict = dict["recurring_details"] as? [AnyHashable: Any],
                  let parsedRecurringDetails = RecurringDetails(recurringDetailsDict) {
            recurringDetails = parsedRecurringDetails
        } else {
            return nil
        }

        let paymentIntent: STPPaymentIntent?
        let paymentIntentId: String?
        if let intentDict = dict["payment_intent"] as? [AnyHashable: Any] {
            paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: intentDict)
            paymentIntentId = paymentIntent?.stripeId
        } else {
            paymentIntent = nil
            paymentIntentId = dict["payment_intent"] as? String
        }

        let setupIntent: STPSetupIntent?
        let setupIntentId: String?
        if let intentDict = dict["setup_intent"] as? [AnyHashable: Any] {
            setupIntent = STPSetupIntent.decodedObject(fromAPIResponse: intentDict)
            setupIntentId = setupIntent?.stripeID
        } else {
            setupIntent = nil
            setupIntentId = dict["setup_intent"] as? String
        }

        let customer = STPCheckoutSessionCustomer.decodedObject(
            from: dict["customer"] as? [AnyHashable: Any]
        )

        return PaymentPagesAPIResponse(
            sessionId: sessionId,
            clientSecret: dict["client_secret"] as? String,
            currency: currency,
            checkoutItems: checkoutItems,
            livemode: livemode,
            status: dict["status"] as? String,
            paymentStatus: paymentStatus,
            paymentIntentId: paymentIntentId,
            setupIntentId: setupIntentId,
            paymentIntent: paymentIntent,
            setupIntent: setupIntent,
            paymentMethodOptions: STPPaymentMethodOptions.decodedObject(
                fromAPIResponse: dict["payment_method_options"] as? [AnyHashable: Any]
            ),
            customer: customer,
            customerEmail: dict["customer_email"] as? String,
            url: dict["url"] as? String,
            returnUrl: dict["return_url"] as? String,
            savedPaymentMethodsOfferSave: (dict["customer_managed_saved_payment_methods_offer_save"] as? [AnyHashable: Any]).map(SavedPaymentMethodsOfferSave.init),
            setupFutureUsage: dict["setup_future_usage"] as? String,
            setupFutureUsageForPaymentMethodType: dict["setup_future_usage_for_payment_method_type"] as? [String: String],
            billingAddressCollection: dict["billing_address_collection"] as? String,
            shippingAddressCollection: (dict["shipping_address_collection"] as? [AnyHashable: Any]).map(ShippingAddressCollection.init),
            shippingRate: (dict["shipping_rate"] as? [AnyHashable: Any]).map(ShippingRate.init),
            recurringDetails: recurringDetails,
            totalSummary: (dict["total_summary"] as? [AnyHashable: Any]).map(TotalSummary.init),
            adaptivePricingInfo: (dict["adaptive_pricing_info"] as? [AnyHashable: Any]).map(AdaptivePricingInfo.init),
            developerToolContext: (dict["developer_tool_context"] as? [AnyHashable: Any]).map(DeveloperToolContext.init),
            taxContext: (dict["tax_context"] as? [AnyHashable: Any]).map(TaxContext.init),
            taxMeta: (dict["tax_meta"] as? [AnyHashable: Any]).map(TaxMeta.init),
            elementsSession: ElementsSession(
                businessName: elementsSessionDict["business_name"] as? String,
                value: elementsSessionValue
            ),
            allResponseFields: dict
        ) as? Self
    }
}
