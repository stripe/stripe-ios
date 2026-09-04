//
//  CheckoutPlaygroundBackend.swift
//  PaymentSheet Example
//

@_spi(STP) import StripePaymentSheet

extension CheckoutPlayground {
    struct SessionFactory {
        private static let checkoutAPISettings = "2025-03-31.preview"

        let backend: PlaygroundBackend
        let apiClient: STPAPIClient

        func create(
            currency: Currency,
            customerType: CustomerType,
            lineItems: [LineItemConfig],
            shippingAddressCollection: Bool,
            billingAddressCollection: BillingAddressCollection,
            automaticTax: Bool,
            paymentMethodSave: Bool,
            paymentMethodRemove: Bool,
            adaptivePricingCountry: AdaptivePricingCountry,
            automaticPaymentMethods: Bool,
            paymentMethodTypes: Set<String>
        ) async throws -> String {
            let customerEmail = adaptivePricingCountry == .none
                ? nil
                : "test+location_\(adaptivePricingCountry.rawValue.uppercased())@example.com"

            var customerID: String?
            if customerType != .guest {
                var customerParams: [String: Any] = [:]
                if let customerEmail {
                    customerParams["email"] = customerEmail
                }
                customerID = try await backend.createCustomer(requestParams: customerParams)

                if customerType == .returning,
                   let customerID {
                    try await createAndAttachCard(customerID: customerID)
                }
            }

            let oneTimePrice = [
                "type": "one_time_price",
                "one_time_price": [
                    "items": lineItems.map { item in
                        [
                            "price_data": [
                                "currency": currency.rawValue,
                                "product_data": [
                                    "name": item.name,
                                    "tax_code": "txcd_99999999",
                                ],
                                "unit_amount": item.unitAmount,
                                "tax_behavior": "exclusive",
                            ],
                            "quantity": item.quantity,
                        ]
                    },
                ],
            ] as [String: Any]
            var sessionParams: [String: Any] = [
                "ui_mode": "custom",
                "currency": currency.rawValue,
                "items": [
                    oneTimePrice,
                ],
            ]

            if !automaticPaymentMethods {
                sessionParams["payment_method_types"] = paymentMethodTypes.sorted()
            }
            if automaticTax {
                sessionParams["automatic_tax"] = ["enabled": true]
            }
            if billingAddressCollection == .required {
                sessionParams["billing_address_collection"] = "required"
            }
            if shippingAddressCollection {
                sessionParams["shipping_address_collection"] = [
                    "allowed_countries": ["US", "CA", "IE", "GB"],
                ]
            }

            if let customerID {
                sessionParams["customer"] = customerID
                if automaticTax {
                    var customerUpdate: [String: Any] = [:]
                    if billingAddressCollection == .required {
                        customerUpdate["address"] = "auto"
                    }
                    if shippingAddressCollection {
                        customerUpdate["shipping"] = "auto"
                    }
                    if !customerUpdate.isEmpty {
                        sessionParams["customer_update"] = customerUpdate
                    }
                }
            } else {
                sessionParams["customer_email"] = customerEmail ?? "jenny@example.com"
                if paymentMethodSave {
                    sessionParams["customer_creation"] = "always"
                }
            }

            if customerID != nil || paymentMethodSave {
                sessionParams["saved_payment_method_options"] = [
                    "payment_method_save": paymentMethodSave ? "enabled" : "disabled",
                    "payment_method_remove": paymentMethodRemove ? "enabled" : "disabled",
                ]
            }

            return try await backend.createCheckoutSession(
                stripeVersion: Self.checkoutAPISettings,
                requestParams: sessionParams
            )
        }

        private func createAndAttachCard(customerID: String) async throws {
            let card = STPPaymentMethodCardParams()
            card.number = "4242424242424242"
            card.expMonth = 12
            card.expYear = 2030
            card.cvc = "123"

            let address = STPPaymentMethodAddress()
            address.line1 = "354 Oyster Point Blvd"
            address.city = "South San Francisco"
            address.state = "CA"
            address.postalCode = "94080"
            address.country = "US"

            let billingDetails = STPPaymentMethodBillingDetails()
            billingDetails.name = "Jenny Rosen"
            billingDetails.email = "jenny.rosen@example.com"
            billingDetails.phone = "+15555555555"
            billingDetails.address = address

            let params = STPPaymentMethodParams(
                card: card,
                billingDetails: billingDetails,
                allowRedisplay: .always,
                metadata: nil
            )
            let paymentMethod = try await apiClient.createPaymentMethod(with: params)
            try await backend.attachPaymentMethod(paymentMethod.stripeId, to: customerID)
        }
    }
}
