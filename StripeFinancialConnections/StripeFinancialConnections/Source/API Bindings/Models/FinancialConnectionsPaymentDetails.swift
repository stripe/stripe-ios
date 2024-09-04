//
//  FinancialConnectionsPaymentDetails.swift
//  StripeFinancialConnections
//
//  Created by Mat Schmid on 2024-08-07.
//

import Foundation

struct FinancialConnectionsPaymentDetails: Decodable {
    let redactedPaymentDetails: RedactedPaymentDetails
}

struct RedactedPaymentDetails: Decodable {
    let id: String
    let bankAccountDetails: BankAccountDetails?
}

struct BankAccountDetails: Decodable {
    let bankName: String?
    let last4: String?
}

struct FinancialConnectionsPaymentMethod: Decodable {
    let id: String
}
