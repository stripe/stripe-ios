//
//  InstantDebitsLinkedBank.swift
//  StripeCore
//
//  Created by Krisjanis Gaidis on 4/16/24.
//

import Foundation

@_spi(STP) public struct InstantDebitsLinkedBank: Equatable {
    public let paymentMethodId: String
    public let bankName: String?
    public let last4: String?
    public let linkMode: LinkMode?
    public init(
        paymentMethodId: String,
        bankName: String?,
        last4: String?,
        linkMode: LinkMode?
    ) {
        self.paymentMethodId = paymentMethodId
        self.bankName = bankName
        self.last4 = last4
        self.linkMode = linkMode
    }
}
