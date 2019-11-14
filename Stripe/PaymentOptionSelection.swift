//
//  PaymentOption.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 11/12/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

/**
 This represents the payment method the customer last selected in STPPaymentOptionViewController,
 so we can preselect it the next time payment options are displayed and spare them from re-inputting details
 e.g. re-selecting their bank for FPX
 */
public enum PaymentOptionSelection: Equatable {
    /**
     Major versions only.
     
     Bump this for breaking changes that require migration.
     */
    static let version = "1"

    case reusablePaymentMethod(paymentMethodID: String)
    case applePay
    case FPX(bank: STPFPXBankBrand)
}

// MARK: - Codable

extension PaymentOptionSelection: Codable {
    /**
     Unfortunately, an enum with associated values requires some boilerplate to conform to Codable.
     
     CodingKeys defines the keys for our JSON representation:
     {
        "version": String
        "paymenOptionSelectionType": PaymentOptionSelectionType
        "reusablePaymentMethod": ReusablePaymentMethod                   // Only present if .reusablePaymentMethod
        "fpx": FPX                                                                                         // Only present if .FPX
        // etc.
     }
     
     */
    private enum CodingKeys: String, CodingKey {
        case version
        case paymentOptionSelectionType
        case reusablePaymentMethod
        case FPX
    }
    
    /**
     All the values for the "paymenOptionSelectionType" key.
     Corresponds to PaymentOptionSelect w/o the associated values.
     */
    private enum PaymentOptionSelectionType: String, Codable {
        case reusablePaymentMethod
        case applePay
        case FPX
    }
    
    // MARK: Each case w/ associated values has a corresponding Struct:
    
    private struct ReusablePaymentMethod: Codable {
        let paymentMethodID: String
    }
    
    private struct _FPX: Codable {
        let bank: STPFPXBankBrand
    }
    
    // MARK: Encodable
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode the version
        try container.encode(PaymentOptionSelection.version, forKey: .version)
        
        // Encode the case and any associated values
        switch self {
        case .reusablePaymentMethod(paymentMethodID: let paymentMethodID):
            try container.encode(PaymentOptionSelectionType.reusablePaymentMethod, forKey: .paymentOptionSelectionType)
            try container.encode(ReusablePaymentMethod(paymentMethodID: paymentMethodID), forKey: .reusablePaymentMethod)
        case .applePay:
            try container.encode(PaymentOptionSelectionType.applePay, forKey: .paymentOptionSelectionType)
        case .FPX(let bankBrand):
            try container.encode(PaymentOptionSelectionType.FPX, forKey: .paymentOptionSelectionType)
            try container.encode(_FPX(bank: bankBrand), forKey: .FPX)
        }
    }
    
    // MARK: Decodable
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(String.self, forKey: .version)
        print(version)
        guard version == PaymentOptionSelection.version else {
            // TODO: Handle prior versions. Probably we will need to preserve the old code (eg PaymentOptionSelect_v1) to work with Codable.
            throw NSError()
        }
        let type = try container.decode(PaymentOptionSelectionType.self, forKey: .paymentOptionSelectionType)
        switch type {
        case .reusablePaymentMethod:
            let reusablePaymentMethod = try container.decode(ReusablePaymentMethod.self, forKey: .reusablePaymentMethod)
            self = .reusablePaymentMethod(paymentMethodID: reusablePaymentMethod.paymentMethodID)
        case .applePay:
            self = .applePay
        case .FPX:
            let fpx = try container.decode(_FPX.self, forKey: .FPX)
            self = .FPX(bank: fpx.bank)
        }
    }
}

extension STPFPXBankBrand: Codable {}
