//
//  SetPaymentSender.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 8/30/24.
//

import Foundation

typealias SetPaymentSender = CallSetterWithSerializableValueSender<String>
extension SetPaymentSender {
    static func setPayment(id: String) -> Self {
        .init(payload: .init(setter: "setPayment", value: id))
    }
}
