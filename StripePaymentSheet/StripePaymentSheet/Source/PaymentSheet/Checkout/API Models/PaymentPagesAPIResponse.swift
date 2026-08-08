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
    let currency: String?
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
    let successUrl: String?
    let savedPaymentMethodsOfferSave: SavedPaymentMethodsOfferSave?
    let setupFutureUsage: String?
    let setupFutureUsageForPaymentMethodType: [String: String]?
    let paymentMethodTypes: [String]
    let billingAddressCollection: String?
    let shippingAddressCollection: ShippingAddressCollection?
    let shippingRate: ShippingRate?
    let shippingOptions: [ShippingOption]
    let shippingTaxAmounts: [TaxAmount]?
    let recurringDetails: RecurringDetails?
    let totalSummary: TotalSummary?
    let adaptivePricingInfo: AdaptivePricingInfo?
    let developerToolContext: DeveloperToolContext?
    let taxContext: TaxContext?
    let taxMeta: TaxMeta?
    let elementsSession: ElementsSession

    /// The raw API response used to create this object.
    let allResponseFields: [AnyHashable: Any]

    // MARK: Local-only state

    /// Client-side state. This is not part of the Payment Pages API response.
    var local_shippingAddress: Checkout.Session.ShippingAddress?

    /// Client-side state. This is not part of the Payment Pages API response.
    var local_paymentOption: Checkout.Session.PaymentOptionDisplayData?

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
        currency: String?,
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
        successUrl: String?,
        savedPaymentMethodsOfferSave: SavedPaymentMethodsOfferSave?,
        setupFutureUsage: String?,
        setupFutureUsageForPaymentMethodType: [String: String]?,
        paymentMethodTypes: [String],
        billingAddressCollection: String?,
        shippingAddressCollection: ShippingAddressCollection?,
        shippingRate: ShippingRate?,
        shippingOptions: [ShippingOption],
        shippingTaxAmounts: [TaxAmount]?,
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
        self.successUrl = successUrl
        self.savedPaymentMethodsOfferSave = savedPaymentMethodsOfferSave
        self.setupFutureUsage = setupFutureUsage
        self.setupFutureUsageForPaymentMethodType = setupFutureUsageForPaymentMethodType
        self.paymentMethodTypes = paymentMethodTypes
        self.billingAddressCollection = billingAddressCollection
        self.shippingAddressCollection = shippingAddressCollection
        self.shippingRate = shippingRate
        self.shippingOptions = shippingOptions
        self.shippingTaxAmounts = shippingTaxAmounts
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
        let key: String?
        let type: String?
        let oneTimePriceItem: OneTimePriceItem?

        init(_ dict: [AnyHashable: Any]) {
            key = dict["key"] as? String
            type = dict["type"] as? String
            oneTimePriceItem = (dict["one_time_price_item"] as? [AnyHashable: Any]).map(OneTimePriceItem.init)
        }
    }

    struct OneTimePriceItem {
        let quantity: Int?
        let price: Price?

        init(_ dict: [AnyHashable: Any]) {
            quantity = dict["quantity"] as? Int
            price = (dict["price"] as? [AnyHashable: Any]).map(Price.init)
        }
    }

    struct Price {
        let currency: String?
        let unitAmount: Int?
        let unitAmountDecimal: String?
        let product: Product?

        init(_ dict: [AnyHashable: Any]) {
            currency = dict["currency"] as? String
            unitAmount = dict["unit_amount"] as? Int
            unitAmountDecimal = dict["unit_amount_decimal"] as? String
            product = (dict["product"] as? [AnyHashable: Any]).map(Product.init)
        }
    }

    struct Product {
        let name: String?
        let description: String?
        let images: [String]?

        init(_ dict: [AnyHashable: Any]) {
            name = dict["name"] as? String
            description = dict["description"] as? String
            images = dict["images"] as? [String]
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

        init(_ dict: [AnyHashable: Any]) {
            totalDiscountAmounts = (dict["total_discount_amounts"] as? [[AnyHashable: Any]])?.map(DiscountAmount.init)
            totalTaxAmounts = (dict["total_tax_amounts"] as? [[AnyHashable: Any]])?.map(TaxAmount.init)
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
        let amount: Int?
        let inclusive: Bool?
        let displayName: String?
        let taxRate: TaxRate?

        init(_ dict: [AnyHashable: Any]) {
            amount = dict["amount"] as? Int
            inclusive = dict["inclusive"] as? Bool
            displayName = dict["display_name"] as? String
            taxRate = (dict["tax_rate"] as? [AnyHashable: Any]).map(TaxRate.init)
        }
    }

    struct TaxRate {
        let displayName: String?

        init(_ dict: [AnyHashable: Any]) {
            displayName = dict["display_name"] as? String
        }
    }

    struct ShippingAddressCollection {
        let allowedCountries: [String]?

        init(_ dict: [AnyHashable: Any]) {
            allowedCountries = dict["allowed_countries"] as? [String]
        }
    }

    struct ShippingOption {
        let shippingRate: ShippingRate?

        init(_ dict: [AnyHashable: Any]) {
            shippingRate = (dict["shipping_rate"] as? [AnyHashable: Any]).map(ShippingRate.init)
        }
    }

    struct ShippingRate {
        let id: String?
        let amount: Int?
        let currency: String?
        let displayName: String?
        let deliveryEstimate: DeliveryEstimate?

        init(_ dict: [AnyHashable: Any]) {
            id = dict["id"] as? String
            amount = dict["amount"] as? Int
            currency = dict["currency"] as? String
            displayName = dict["display_name"] as? String
            deliveryEstimate = (dict["delivery_estimate"] as? [AnyHashable: Any]).map(DeliveryEstimate.init)
        }
    }

    struct DeliveryEstimate {
        let minimum: DeliveryBound?
        let maximum: DeliveryBound?

        init(_ dict: [AnyHashable: Any]) {
            minimum = (dict["minimum"] as? [AnyHashable: Any]).map(DeliveryBound.init)
            maximum = (dict["maximum"] as? [AnyHashable: Any]).map(DeliveryBound.init)
        }
    }

    struct DeliveryBound {
        let unit: String?
        let value: Int?

        init(_ dict: [AnyHashable: Any]) {
            unit = dict["unit"] as? String
            value = dict["value"] as? Int
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
              let livemode = dict["livemode"] as? Bool,
              let paymentStatus = dict["payment_status"] as? String,
              let paymentMethodTypes = dict["payment_method_types"] as? [String],
              let elementsSessionDict = dict["elements_session"] as? [AnyHashable: Any],
              let elementsSessionValue = STPElementsSession.decodedObject(fromAPIResponse: elementsSessionDict)
        else {
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
            currency: dict["currency"] as? String,
            checkoutItems: (dict["checkout_items"] as? [[AnyHashable: Any]])?.map(CheckoutItem.init) ?? [],
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
            successUrl: dict["success_url"] as? String,
            savedPaymentMethodsOfferSave: (dict["customer_managed_saved_payment_methods_offer_save"] as? [AnyHashable: Any]).map(SavedPaymentMethodsOfferSave.init),
            setupFutureUsage: dict["setup_future_usage"] as? String,
            setupFutureUsageForPaymentMethodType: dict["setup_future_usage_for_payment_method_type"] as? [String: String],
            paymentMethodTypes: paymentMethodTypes,
            billingAddressCollection: dict["billing_address_collection"] as? String,
            shippingAddressCollection: (dict["shipping_address_collection"] as? [AnyHashable: Any]).map(ShippingAddressCollection.init),
            shippingRate: (dict["shipping_rate"] as? [AnyHashable: Any]).map(ShippingRate.init),
            shippingOptions: (dict["shipping_options"] as? [[AnyHashable: Any]])?.map(ShippingOption.init) ?? [],
            shippingTaxAmounts: (dict["shipping_tax_amounts"] as? [[AnyHashable: Any]])?.map(TaxAmount.init),
            recurringDetails: (dict["recurring_details"] as? [AnyHashable: Any]).map(RecurringDetails.init),
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
