//
//  STPIntentActionLinkAuthenticateAccount.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 7/6/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

class STPIntentActionLinkAuthenticateAccount: NSObject {
    
    let allResponseFields: [AnyHashable: Any]
    
    required init(_ allResponseFields: [AnyHashable: Any]) {
        self.allResponseFields = allResponseFields
        super.init()
    }

}

/// :nodoc:
extension STPIntentActionLinkAuthenticateAccount: STPAPIResponseDecodable {
    class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        
        return STPIntentActionLinkAuthenticateAccount(response) as? Self
    }
}
