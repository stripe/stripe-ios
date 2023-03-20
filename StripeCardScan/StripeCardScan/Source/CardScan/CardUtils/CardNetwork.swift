//
//  CardNetwork.swift
//  CardScan
//
//  Created by Jaime Park on 1/31/20.
//

import Foundation

enum CardNetwork: Int {
    case VISA
    case MASTERCARD
    case AMEX
    case DISCOVER
    case UNIONPAY
    case JCB
    case DINERSCLUB
    case REGIONAL
    case UNKNOWN

    func toString() -> String {
        switch self {
        case .VISA: return "Visa"
        case .MASTERCARD: return "MasterCard"
        case .AMEX: return "Amex"
        case .DISCOVER: return "Discover"
        case .UNIONPAY: return "Union Pay"
        case .JCB: return "Jcb"
        case .DINERSCLUB: return "Diners Club"
        case .REGIONAL: return "Regional"
        case .UNKNOWN: return "Unknown"
        }
    }
}
