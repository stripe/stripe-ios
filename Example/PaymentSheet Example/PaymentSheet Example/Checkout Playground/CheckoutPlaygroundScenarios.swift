//
//  CheckoutPlaygroundScenarios.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 9/8/26.

import Foundation
@_spi(STP) import StripePaymentSheet

extension CheckoutPlayground {
    struct Scenario: Identifiable {
        let id: String
        let title: String
        let detail: String
        let configuration: Configuration

        struct Configuration {
            var settings = Settings()
            var expressCheckoutElement = ExpressCheckoutElementSettings()
        }
    }

    struct ScenarioGroup: Identifiable {
        enum Style {
            case localPaymentMethods
            case tax
            case savedPaymentMethods
            case elements
            case region
        }

        let id: String
        let title: String
        let detail: String
        let style: Style
        var groups: [ScenarioGroup] = []
        var scenarios: [Scenario] = []

        var scenarioCount: Int {
            scenarios.count + groups.reduce(0) { $0 + $1.scenarioCount }
        }
    }

    enum ScenarioCatalog {
        static let groups = [
            localPaymentMethods,
            tax,
            savedPaymentMethods,
            elements,
        ]

        private static let localPaymentMethods = ScenarioGroup(
            id: "local-payment-methods",
            title: "Local payment methods",
            detail: "Regional merchant, currency, and payment method combinations.",
            style: .localPaymentMethods,
            groups: [
                regionalGroup(
                    id: "north-america",
                    title: "North America",
                    scenarios: [
                        regional("us-common", "US common", .us, .usd, ["card", "us_bank_account", "link", "cashapp", "klarna"]),
                        regional("us-alternatives", "US alternatives", .us, .usd, ["card", "affirm", "afterpay_clearpay", "amazon_pay", "crypto", "sunbit"]),
                        regional("mexico", "Mexico", .mexico, .mxn, ["card", "oxxo"]),
                    ]
                ),
                regionalGroup(
                    id: "europe",
                    title: "Europe",
                    scenarios: [
                        regional("euro-bank-methods", "Euro bank methods", .france, .eur, ["card", "ideal", "bancontact", "sepa_debit", "eps"]),
                        regional("france-alternatives", "France / EU alternatives", .france, .eur, ["card", "alma", "mobilepay"]),
                        regional("germany", "Germany", .germany, .eur, ["card", "billie", "wero"]),
                        regional("italy", "Italy", .italy, .eur, ["card", "satispay"]),
                        regional("spain", "Spain", .spain, .eur, ["card", "sequra"]),
                        regional("poland", "Poland", .france, .pln, ["card", "blik", "p24"]),
                        regional("sweden", "Sweden", .france, .sek, ["card", "swish"]),
                        regional("uk-bank-debit", "UK bank debit", .unitedKingdom, .gbp, ["card", "bacs_debit"]),
                        regional("gbp-wallets", "GBP wallets", .unitedKingdom, .gbp, ["card", "paypal", "revolut_pay"]),
                        regional("switzerland", "Switzerland", .unitedKingdom, .chf, ["card", "twint"]),
                        regional("portugal", "Portugal", .france, .eur, ["card", "multibanco"]),
                    ]
                ),
                regionalGroup(
                    id: "asia-pacific",
                    title: "Asia-Pacific",
                    scenarios: [
                        regional("australia", "Australia", .australia, .aud, ["card", "au_becs_debit"]),
                        regional("singapore", "Singapore", .singapore, .sgd, ["card", "grabpay", "paynow"]),
                        regional("malaysia", "Malaysia", .malaysia, .myr, ["card", "fpx"]),
                        regional("thailand", "Thailand", .thailand, .thb, ["card", "promptpay"]),
                        regional("japan", "Japan", .japan, .jpy, ["card", "konbini", "paypay"]),
                        regional("korea", "Korea", .us, .krw, ["card", "kr_card", "naver_pay", "payco"]),
                        regional("alipay", "Alipay", .us, .usd, ["card", "klarna", "affirm", "alipay"]),
                    ]
                ),
                regionalGroup(
                    id: "latin-america",
                    title: "Latin America",
                    scenarios: [
                        regional("brazil", "Brazil", .brazil, .brl, ["card", "boleto"]),
                    ]
                ),
            ]
        )

        private static let tax = ScenarioGroup(
            id: "tax",
            title: "Tax",
            detail: "Common automatic tax and address collection configurations.",
            style: .tax,
            scenarios: [
                scenario("no-tax", "No tax", "Automatic tax disabled.") {
                    $0.settings.automaticTax = false
                },
                scenario("tax-automatic-billing", "Automatic billing", "Automatic tax with on-demand billing details.") {
                    $0.settings.merchantCountry = .usTax
                    $0.settings.automaticTax = true
                    $0.settings.billingAddressCollection = .automatic
                    $0.settings.shippingAddressCollection = false
                },
                scenario("tax-required-billing", "Required billing", "Automatic tax with a required billing address.") {
                    $0.settings.merchantCountry = .usTax
                    $0.settings.automaticTax = true
                    $0.settings.billingAddressCollection = .required
                    $0.settings.shippingAddressCollection = false
                },
                scenario("tax-shipping", "Shipping address", "Automatic tax calculated from a collected shipping address.") {
                    $0.settings.merchantCountry = .usTax
                    $0.settings.automaticTax = true
                    $0.settings.shippingAddressCollection = true
                },
            ]
        )

        private static let savedPaymentMethods = ScenarioGroup(
            id: "saved-payment-methods",
            title: "Saved payment methods",
            detail: "Guest, new, and returning customer save/remove behavior.",
            style: .savedPaymentMethods,
            groups: [
                ScenarioGroup(
                    id: "returning-customer",
                    title: "Returning customer",
                    detail: "Choose which saved payment method actions are available.",
                    style: .region,
                    scenarios: [
                        returningCustomer("returning-save-remove", "Save and remove", save: true, remove: true),
                        returningCustomer("returning-save-only", "Save only", save: true, remove: false),
                        returningCustomer("returning-remove-only", "Remove only", save: false, remove: true),
                        returningCustomer("returning-view-only", "View only", save: false, remove: false),
                    ]
                ),
            ],
            scenarios: [
                scenario("guest", "Guest", "Checkout without a Customer object.") {
                    $0.settings.customerType = .guest
                },
                scenario("new-save-enabled", "New customer — saving enabled", "Create a customer and offer to save the payment method.") {
                    $0.settings.customerType = .new
                    $0.settings.checkoutSessionPaymentMethodSave = true
                },
                scenario("new-save-disabled", "New customer — saving disabled", "Create a customer without offering to save.") {
                    $0.settings.customerType = .new
                    $0.settings.checkoutSessionPaymentMethodSave = false
                },
            ]
        )

        private static let elements = ScenarioGroup(
            id: "elements",
            title: "Elements",
            detail: "Payment, express checkout, shipping, and currency selector layouts.",
            style: .elements,
            groups: [
                ScenarioGroup(
                    id: "express-checkout-element",
                    title: "Express Checkout Element",
                    detail: "Apple Pay and Link combinations for iOS.",
                    style: .region,
                    scenarios: [
                        express("ece-link-apple-pay", "Link and Apple Pay", link: true, applePay: true),
                        express("ece-link-only", "Link only", link: true, applePay: false),
                        express("ece-apple-pay-only", "Apple Pay only", link: false, applePay: true),
                        express("ece-shipping", "Shipping required", link: true, applePay: true, shipping: true),
                    ]
                ),
                ScenarioGroup(
                    id: "shipping-address-element",
                    title: "Shipping Address Element",
                    detail: "Collect or prefill shipping details.",
                    style: .region,
                    scenarios: [
                        scenario("shipping-new", "Collect a new shipping address", "Show an empty Shipping Address Element.") {
                            $0.settings.shippingAddressCollection = true
                            $0.settings.defaultShippingAddressOption = .none
                        },
                        scenario("shipping-prefilled", "Prefilled US shipping address", "Start with the standard Jenny Rosen test address.") {
                            $0.settings.shippingAddressCollection = true
                            $0.settings.defaultShippingAddressOption = .usTestAddress
                        },
                    ]
                ),
                ScenarioGroup(
                    id: "currency-selector",
                    title: "Currency Selector",
                    detail: "Exercise Adaptive Pricing location overrides.",
                    style: .region,
                    scenarios: [
                        currencySelector("currency-france", "France", .fr),
                        currencySelector("currency-japan", "Japan", .jp),
                    ]
                ),
            ],
            scenarios: [
                scenario("payment-element-card", "Payment Element — card only", "Present a card-only Payment Element without express checkout.") {
                    $0.settings.integrationType = .flowController
                    $0.settings.showExpressCheckoutElement = false
                    $0.settings.showsCurrencySelectorElement = false
                    $0.settings.automaticPaymentMethods = false
                    $0.settings.paymentMethodTypes = ["card"]
                    $0.expressCheckoutElement.isEnabled = false
                },
                scenario("all-elements", "All elements", "Payment, express checkout, shipping, and currency selector together.") {
                    $0.settings.integrationType = .embedded
                    $0.settings.showExpressCheckoutElement = true
                    $0.settings.showsWalletsInPaymentElement = false
                    $0.settings.showsCurrencySelectorElement = true
                    $0.settings.shippingAddressCollection = true
                    $0.settings.adaptivePricingCountry = .fr
                    $0.settings.automaticPaymentMethods = true
                    $0.expressCheckoutElement.isEnabled = true
                },
            ]
        )

        private static func regionalGroup(
            id: String,
            title: String,
            scenarios: [Scenario]
        ) -> ScenarioGroup {
            ScenarioGroup(
                id: id,
                title: title,
                detail: "\(scenarios.count) regional configurations",
                style: .region,
                scenarios: scenarios
            )
        }

        private static func regional(
            _ id: String,
            _ title: String,
            _ merchant: MerchantCountry,
            _ currency: Currency,
            _ paymentMethods: Set<String>
        ) -> Scenario {
            scenario(id, title, "\(merchant.displayName) · \(currency.rawValue.uppercased()) · \(paymentMethods.count) methods") {
                $0.settings.merchantCountry = merchant
                $0.settings.currency = currency
                $0.settings.automaticTax = false
                $0.settings.shippingAddressCollection = false
                $0.settings.automaticPaymentMethods = false
                $0.settings.paymentMethodTypes = paymentMethods
            }
        }

        private static func returningCustomer(
            _ id: String,
            _ title: String,
            save: Bool,
            remove: Bool
        ) -> Scenario {
            scenario(id, title, "Save \(save ? "on" : "off") · Remove \(remove ? "on" : "off")") {
                $0.settings.customerType = .returning
                $0.settings.checkoutSessionPaymentMethodSave = save
                $0.settings.checkoutSessionPaymentMethodRemove = remove
            }
        }

        private static func express(
            _ id: String,
            _ title: String,
            link: Bool,
            applePay: Bool,
            shipping: Bool = false
        ) -> Scenario {
            scenario(id, title, shipping ? "Collect shipping details in the wallet." : "Express checkout without Payment Element wallets.") {
                $0.settings.integrationType = .eceOnly
                $0.settings.showExpressCheckoutElement = true
                $0.settings.showsWalletsInPaymentElement = false
                $0.settings.showsCurrencySelectorElement = false
                $0.settings.automaticPaymentMethods = true
                $0.expressCheckoutElement.isEnabled = true
                $0.expressCheckoutElement.linkDisplay = link ? .automatic : .never
                $0.expressCheckoutElement.applePayDisplay = applePay ? .automatic : .never
                $0.expressCheckoutElement.shippingAddressRequired = shipping
            }
        }

        private static func currencySelector(
            _ id: String,
            _ title: String,
            _ country: AdaptivePricingCountry
        ) -> Scenario {
            scenario(id, title, "Mock the customer location as \(country.displayName).") {
                $0.settings.showsCurrencySelectorElement = true
                $0.settings.adaptivePricingCountry = country
            }
        }

        private static func scenario(
            _ id: String,
            _ title: String,
            _ detail: String,
            configure: (inout Scenario.Configuration) -> Void
        ) -> Scenario {
            var configuration = Scenario.Configuration()
            configure(&configuration)
            configuration.settings.showExpressCheckoutElement = configuration.expressCheckoutElement.isEnabled
            return Scenario(id: id, title: title, detail: detail, configuration: configuration)
        }
    }
}
