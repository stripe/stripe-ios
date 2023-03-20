//
//  LinkAccountSession.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 10/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/// For internal SDK use only
@objc(STP_Internal_LinkAccountSession)
class LinkAccountSession: NSObject, STPAPIResponseDecodable {
    let stripeID: String
    let livemode: Bool
    let clientSecret: String
    
    let allResponseFields: [AnyHashable : Any]

    required init(stripeID: String,
                  livemode: Bool,
                  clientSecret: String,
                  allResponseFields: [AnyHashable: Any]) {
        self.stripeID = stripeID
        self.livemode = livemode
        self.clientSecret = clientSecret
        self.allResponseFields = allResponseFields
        super.init()
    }
    
    
    static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
        guard let response = response,
              let stripeID = response["id"] as? String,
              let livemode = response["livemode"] as? Bool,
              let clientSecret = response["client_secret"] as? String else {
            return nil
        }
        
        return LinkAccountSession(stripeID: stripeID,
                                  livemode: livemode,
                                  clientSecret: clientSecret,
                                  allResponseFields: response) as? Self
    }
}
