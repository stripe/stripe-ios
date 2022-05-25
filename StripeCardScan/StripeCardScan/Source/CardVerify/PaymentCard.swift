//
//  CreditCard.swift
//  CardScan
//
//  Created by Jaime Park on 7/22/19.
//

import Foundation
import UIKit

class PaymentCard: CardBase {
    var number: String
    var cvv: String?
    var zip: String?
    var network: CardNetwork
    
    enum Network: Int {
        case VISA, MASTERCARD, AMEX, DISCOVER, UNIONPAY, UNKNOWN
           
        func toCardNetwork() -> CardNetwork {
            switch self {
            case .VISA: return CardNetwork.VISA
            case .MASTERCARD: return CardNetwork.MASTERCARD
            case .AMEX: return CardNetwork.AMEX
            case .DISCOVER: return CardNetwork.DISCOVER
            case .UNIONPAY: return CardNetwork.UNIONPAY
            default: return CardNetwork.UNKNOWN
            }
        }
    }
    
    init(number: String, expiryMonth: String?, expiryYear: String?, network: Network?) {
        self.number = number
        self.network = network?.toCardNetwork() ?? CreditCardUtils.determineCardNetwork(cardNumber: number)
        super.init(last4: String(number.suffix(4)), bin: nil, expMonth: expiryMonth, expYear: expiryYear)
    }
    
    init(last4: String, bin: String?, expiryMonth: String?, expiryYear: String?, network: Network?) {
        self.number = last4
        self.network = network?.toCardNetwork() ?? CardNetwork.UNKNOWN
        super.init(last4: last4, bin: bin, expMonth: expiryMonth, expYear: expiryYear)
    }
    
    func isValidCvv() -> Bool {
        guard let cvv = self.cvv  else {
            return false
        }
        
        return CreditCardUtils.isValidCvv(cvv: cvv, network: self.network)
    }

    func isValidDate() -> Bool {
        guard let month = self.expMonth, let year = self.expYear else {
            return false
        }
    
        return CreditCardUtils.isValidDate(expMonth: month, expYear: year)
    }
}
