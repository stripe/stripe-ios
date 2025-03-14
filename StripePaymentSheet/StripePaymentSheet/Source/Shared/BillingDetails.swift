//
//  BillingDetails.swift
//  StripePaymentSheet
//

@_spi(STP) import StripeUICore

/// Billing details of a customer
    public struct BillingDetails: Equatable {
        /// The customer's billing address
        public var address: Address = Address()

        /// The customer's email
        /// - Note: When used with defaultBillingDetails, the value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var email: String?

        /// The customer's full name
        /// - Note: When used with defaultBillingDetails, the value set is displayed in the payment sheet as-is. Depending on the payment method, the customer may be required to edit this value.
        public var name: String?

        /// The customer's phone number in e164 formatting (e.g. +15551234567)
        /// - Note: When used with defaultBillingDetails, omitting '+' will assume a US based phone number.
        public var phone: String?

        /// The customer's phone number formatted for display in your UI (e.g. "+1 (555) 555-5555")
        public var phoneNumberForDisplay: String? {
            guard let phone = self.phone else {
                return nil
            }
            return PhoneNumber.fromE164(phone)?.string(as: .international)
        }

        /// Initializes billing details
        public init(address: PaymentSheet.Address = Address(), email: String? = nil, name: String? = nil, phone: String? = nil) {
            self.address = address
            self.email = email
            self.name = name
            self.phone = phone
        }
    }
