//
//  STPSetupIntentWithPreferences.swift
//  StripeiOS
//
//  Created by Jaime Park on 6/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import Foundation

class STPSetupIntentWithPreferences: NSObject, STPAPIResponseDecodable {
    let setupIntent: STPSetupIntent
    let orderedPaymentMethodTypes: [STPPaymentMethodType]
    let allResponseFields: [AnyHashable: Any]
    
    required init(
        setupIntent: STPSetupIntent,
        orderedPaymentMethodTypes: [STPPaymentMethodType],
        allResponseFields: [AnyHashable: Any]
    ) {
        self.setupIntent = setupIntent
        self.orderedPaymentMethodTypes = orderedPaymentMethodTypes
        self.allResponseFields = allResponseFields
        super.init()
    }
    
    class func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
        guard let dict = response,
              let setupIntentDict = dict["setup_intent"] as? [AnyHashable: Any],
              let setupIntent = STPSetupIntent.decodedObject(fromAPIResponse: setupIntentDict),
              let orderedPaymentMethodTypes = dict["ordered_payment_method_types"] as? [String]
        else {
            return nil
        }

        return STPSetupIntentWithPreferences(
            setupIntent: setupIntent,
            orderedPaymentMethodTypes: STPPaymentMethod.paymentMethodTypes(from: orderedPaymentMethodTypes),
            allResponseFields: dict) as? Self
    }
}
