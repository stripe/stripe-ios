//
//  STPPaymentIntentWithPreferences.swift
//  StripeiOS
//
//  Created by Jaime Park on 6/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

class STPPaymentIntentWithPreferences: NSObject, STPAPIResponseDecodable {
    let paymentIntent: STPPaymentIntent
    let orderedPaymentMethodTypes: [STPPaymentMethodType]
    let allResponseFields: [AnyHashable: Any]
    
    required init(
        paymentIntent: STPPaymentIntent,
        orderedPaymentMethodTypes: [STPPaymentMethodType],
        allResponseFields: [AnyHashable: Any]
    ) {
        self.paymentIntent = paymentIntent
        self.orderedPaymentMethodTypes = orderedPaymentMethodTypes
        self.allResponseFields = allResponseFields
        super.init()
    }
    
    class func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
        guard let dict = response,
              let paymentIntentDict = dict["payment_intent"] as? [AnyHashable: Any],
              let paymentIntent = STPPaymentIntent.decodedObject(fromAPIResponse: paymentIntentDict),
              let orderedPaymentMethodTypes = dict["ordered_payment_method_types"] as? [String]
        else {
            return nil
        }
        
        return STPPaymentIntentWithPreferences(
            paymentIntent: paymentIntent,
            orderedPaymentMethodTypes: STPPaymentMethod.paymentMethodTypes(from: orderedPaymentMethodTypes),
            allResponseFields: dict) as? Self
    }
}
