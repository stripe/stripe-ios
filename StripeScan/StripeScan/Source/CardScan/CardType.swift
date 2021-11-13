//
//  CardType.swift
//  CardScan
//
//  Created by Adam Wushensky on 8/27/20.
//

import Foundation

enum CardType: Int {
    case CREDIT
    case DEBIT
    case PREPAID
    case UNKNOWN

    func toString() -> String {
        switch self {
        case .CREDIT: return "Credit"
        case .DEBIT: return "Debit"
        case .PREPAID: return "Prepaid"
        case .UNKNOWN: return "Unknown"
        }
    }

    static func fromString(_ str: String) -> CardType {
        switch str.lowercased() {
        case "credit": return .CREDIT
        case "debit": return .DEBIT
        case "prepaid": return .PREPAID
        default: return .UNKNOWN
        }
    }
}
