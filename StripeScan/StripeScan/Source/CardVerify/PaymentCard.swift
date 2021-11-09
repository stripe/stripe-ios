//
//  CreditCard.swift
//  CardScan
//
//  Created by Jaime Park on 7/22/19.
//

import Foundation
import UIKit

@objc public class PaymentCard: CardBase {
    @objc public var number: String
    @objc public var cvv: String?
    @objc public var zip: String?
    public var network: CardNetwork
    
    @objc public enum Network: Int {
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
    
    public init(number: String, expiryMonth: String?, expiryYear: String?, network: Network?) {
        self.number = number
        self.network = network?.toCardNetwork() ?? CreditCardUtils.determineCardNetwork(cardNumber: number)
        super.init(last4: String(number.suffix(4)), bin: nil, expMonth: expiryMonth, expYear: expiryYear)
    }
    
    public init(last4: String, bin: String?, expiryMonth: String?, expiryYear: String?, network: Network?) {
        self.number = last4
        self.network = network?.toCardNetwork() ?? CardNetwork.UNKNOWN
        super.init(last4: last4, bin: bin, expMonth: expiryMonth, expYear: expiryYear)
    }
    
    @objc public func isValidCvv() -> Bool {
        guard let cvv = self.cvv  else {
            print("Could not unwrap cvv / network")
            return false
        }
        
        return CreditCardUtils.isValidCvv(cvv: cvv, network: self.network)
    }

    @objc public func isValidDate() -> Bool {
        guard let month = self.expMonth, let year = self.expYear else {
            print("Could not unwrap expiration month and/or year")
            return false
        }
    
        return CreditCardUtils.isValidDate(expMonth: month, expYear: year)
    }
    
    @objc public func cardNetworkImage() -> UIImage? {
           guard let bundle = Bouncer.getBundle() else {
               return nil
           }
           
           switch self.network {
           case .AMEX:
               return UIImage(named: "dark_payment_amex", in: bundle, compatibleWith: nil)
           case .MASTERCARD:
               return UIImage(named: "dark_payment_master", in: bundle, compatibleWith: nil)
           case .DISCOVER:
               return UIImage(named: "light_payment_discover", in: bundle, compatibleWith: nil)
           case .VISA:
               return UIImage(named: "dark_payment_visa", in: bundle, compatibleWith: nil)
           case .UNIONPAY:
               return UIImage(named: "unionpay", in: bundle, compatibleWith: nil)
           default:
               return UIImage(named: "credit_card_placeholder", in: bundle, compatibleWith: nil)
           }
       }
}
