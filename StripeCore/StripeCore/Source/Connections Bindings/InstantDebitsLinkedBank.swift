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
    
    public init(
        paymentMethod: LinkBankPaymentMethod,
        bankName: String?,
        last4: String?,
        linkMode: LinkMode?
    ) {
        self.paymentMethod = paymentMethod
        self.bankName = bankName
        self.last4 = last4
        self.linkMode = linkMode
    }
}
