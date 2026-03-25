//
//  PaymentIntentCodableTest.swift
//  StripeApplePay
//
@_spi(STP) import StripeApplePay
import XCTest

class PaymentIntentCodableTest: XCTestCase {
    func testDeserialization_WithoutLine1() throws {
        let json = """
            {
               "amount" : 2000,
               "amount_details" : {
                  "tip" : {}
               },
               "automatic_payment_methods" : null,
               "canceled_at" : null,
               "cancellation_reason" : null,
               "capture_method" : "automatic_async",
               "client_secret" : "pi_3R123456",
               "confirmation_method" : "automatic",
               "created" : 1754555555,
               "currency" : "aud",
               "description" : null,
               "id" : "pi_123456",
               "last_payment_error" : null,
               "livemode" : true,
               "next_action" : null,
               "object" : "payment_intent",
               "payment_method" : {
                  "allow_redisplay" : "unspecified",
                  "billing_details" : {
                     "address" : {
                        "city" : null,
                        "country" : "AU",
                        "line1" : null,
                        "line2" : null,
                        "postal_code" : null,
                        "state" : null
                     },
                     "email" : null,
                     "name" : null,
                     "phone" : null,
                     "tax_id" : null
                  },
                  "card" : {
                     "brand" : "mastercard",
                     "checks" : {
                        "address_line1_check" : null,
                        "address_postal_code_check" : null,
                        "cvc_check" : null
                     },
                     "country" : "AU",
                     "display_brand" : "eftpos_australia",
                     "exp_month" : 12,
                     "exp_year" : 2030,
                     "funding" : "debit",
                     "generated_from" : null,
                     "last4" : "1234",
                     "networks" : {
                        "available" : [
                           "mastercard"
                        ],
                        "preferred" : null
                     },
                     "regulated_status" : "unregulated",
                     "three_d_secure_usage" : {
                        "supported" : true
                     },
                     "wallet" : null
                  },
                  "created" : 1754355555,
                  "customer" : null,
                  "id" : "pm_123456",
                  "livemode" : true,
                  "object" : "payment_method",
                  "type" : "card"
               },
               "payment_method_configuration_details" : null,
               "payment_method_types" : [
                  "card"
               ],
               "processing" : null,
               "receipt_email" : null,
               "setup_future_usage" : null,
               "shipping" : {
                  "address" : {
                     "city" : null,
                     "country" : "AU",
                     "line1" : null,
                     "line2" : null,
                     "postal_code" : null,
                     "state" : null
                  },
                  "carrier" : null,
                  "name" : "Jane Doe",
                  "phone" : null,
                  "tracking_number" : null
               },
               "source" : null,
               "status" : "succeeded"
            }
            """

        let decoder = StripeJSONDecoder()
        _ = try decoder.decode(StripeAPI.PaymentIntent.self, from: json.data(using: .utf8)!)
    }
}
