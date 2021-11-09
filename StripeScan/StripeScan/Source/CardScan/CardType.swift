//
//  CardType.swift
//  CardScan
//
//  Created by Adam Wushensky on 8/27/20.
//

import Foundation

@objc public enum CardType: Int {
    case CREDIT
    case DEBIT
    case PREPAID
    case UNKNOWN
    
    public func toString() -> String {
        switch self {
        case .CREDIT: return "Credit"
        case .DEBIT: return "Debit"
        case .PREPAID: return "Prepaid"
        case .UNKNOWN: return "Unknown"
        }
    }
    
    public static func fromString(_ str: String) -> CardType {
        switch str.lowercased() {
        case "credit": return .CREDIT
        case "debit": return .DEBIT
        case "prepaid": return .PREPAID
        default: return .UNKNOWN
        }
    }
}
