//
//  SignUpRequest.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 10/15/25.
//

import Foundation

typealias LogInRequest = SignUpRequest

struct SignUpRequest: Encodable {
    let email: String
    let password: String
    let livemode: Bool
}
