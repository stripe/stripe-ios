//
//  SetPaymentSender.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 8/30/24.
//

import Foundation

struct SetPaymentSender: MessageSender {
    let name = "setPayment"
    let payload: String
}
