//
//  BillingDetails+ApplePay.swift
//  StripeApplePay
//
//  Created by David Estes on 8/9/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit
@_spi(STP) import StripeCore

extension StripeContact {
    /// Initializes a new Contact with data from an PassKit contact.
    /// - Parameter contact: The PassKit contact you want to populate the Contact from.
    /// - Returns: A new Contact with data copied from the passed in contact.
    init(
        pkContact contact: PKContact
    ) {
        let nameComponents = contact.name
        if let nameComponents = nameComponents {
            givenName = stringIfHasContentsElseNil(nameComponents.givenName)
            familyName = stringIfHasContentsElseNil(nameComponents.familyName)

            name = stringIfHasContentsElseNil(
                PersonNameComponentsFormatter.localizedString(from: nameComponents, style: .default)
            )
        }
        email = stringIfHasContentsElseNil(contact.emailAddress)
        if let phoneNumber = contact.phoneNumber {
            phone = sanitizedPhoneString(from: phoneNumber)
        } else {
            phone = nil
        }
        setAddressFromCNPostal(contact.postalAddress)
    }

    private func sanitizedPhoneString(from phoneNumber: CNPhoneNumber) -> String? {
        return stringIfHasContentsElseNil(
            STPNumericStringValidator.sanitizedNumericString(for: phoneNumber.stringValue)
        )
    }

    private mutating func setAddressFromCNPostal(_ address: CNPostalAddress?) {
        line1 = stringIfHasContentsElseNil(address?.street)
        city = stringIfHasContentsElseNil(address?.city)
        state = stringIfHasContentsElseNil(address?.state)
        postalCode = stringIfHasContentsElseNil(address?.postalCode)
        country = stringIfHasContentsElseNil(address?.isoCountryCode.uppercased())
    }
}

extension StripeAPI.BillingDetails {
    init?(
        from payment: PKPayment
    ) {
        var billingDetails: StripeAPI.BillingDetails?
        if payment.billingContact != nil {
            billingDetails = StripeAPI.BillingDetails()
            if let billingContact = payment.billingContact {
                let billingAddress = StripeContact(pkContact: billingContact)
                billingDetails?.name = billingAddress.name
                billingDetails?.email = billingAddress.email
                billingDetails?.phone = billingAddress.phone
                if billingContact.postalAddress != nil {
                    billingDetails?.address = StripeAPI.BillingDetails.Address(
                        contact: billingAddress
                    )
                }
            }
        }

        // The phone number and email in the "Contact" panel in the Apple Pay dialog go into the shippingContact,
        // not the billingContact. To work around this, we should fill the billingDetails' email and phone
        // number from the shippingDetails.
        if payment.shippingContact != nil {
            var shippingAddress: StripeContact?
            if let shippingContact = payment.shippingContact {
                shippingAddress = StripeContact(pkContact: shippingContact)
            }
            if billingDetails?.email == nil && shippingAddress?.email != nil {
                if billingDetails == nil {
                    billingDetails = StripeAPI.BillingDetails()
                }
                billingDetails?.email = shippingAddress?.email
            }
            if billingDetails?.phone == nil && shippingAddress?.phone != nil {
                if billingDetails == nil {
                    billingDetails = StripeAPI.BillingDetails()
                }
                billingDetails?.phone = shippingAddress?.phone
            }
        }

        if let billingDetails = billingDetails {
            self = billingDetails
        } else {
            return nil
        }
    }
}
