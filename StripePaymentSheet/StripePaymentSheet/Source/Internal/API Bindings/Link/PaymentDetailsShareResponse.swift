//
//  PaymentDetailsShareResponse.swift
//  StripePaymentSheet
//
//  Created by David Estes on 1/3/24.
//

import Foundation

struct PaymentDetailsShareResponse: UnknownFieldsDecodable {
    var _allResponseFieldsStorage: StripeCore.NonEncodableParameters?
    
    let paymentMethod: String
}
