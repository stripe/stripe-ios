//
//  InstantDebitsLinkedBank.swift
//  StripeCore
//
//  Created by Krisjanis Gaidis on 4/16/24.
//

import Foundation

@_spi(STP) public struct InstantDebitsLinkedBank: Equatable {
    public let paymentMethod: LinkBankPaymentMethod
    public let bankName: String?
    public let last4: String?
    public let linkMode: LinkMode?
    public let incentiveEligible: Bool
    public let linkAccountSessionId: String?

    public init(
        paymentMethod: LinkBankPaymentMethod,
        bankName: String?,
        last4: String?,
        linkMode: LinkMode?,
        incentiveEligible: Bool,
        linkAccountSessionId: String?
    ) {
        self.paymentMethod = paymentMethod
        self.bankName = bankName
        self.last4 = last4
        self.linkMode = linkMode
        self.incentiveEligible = incentiveEligible
        self.linkAccountSessionId = linkAccountSessionId
    }
}
