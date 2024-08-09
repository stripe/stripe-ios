//
//  InstantDebitsLinkedBank.swift
//  StripeCore
//
//  Created by Krisjanis Gaidis on 4/16/24.
//

import Foundation

@_spi(STP) public protocol InstantDebitsLinkedBank: Sendable {
    var paymentMethodId: String { get }
    var bankName: String? { get }
    var last4: String? { get }
}
