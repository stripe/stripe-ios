//
//  LinkAccountSessionAttachResponse.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 2/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit

/// For internal SDK use only
@objc(STP_Internal_LinkAccountSessionAttachResponse)
class LinkAccountSessionAttachResponse: NSObject, STPAPIResponseDecodable {
    let authorizationURL: URL
    
    let allResponseFields: [AnyHashable : Any]
    
    private init(authorizationURL: URL,
                 allResponseFields: [AnyHashable: Any]) {
        self.authorizationURL = authorizationURL
        self.allResponseFields = allResponseFields
        super.init()
    }

    static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
        guard let response = response,
        let urlString = response["hosted_auth_url"] as? String,
        let url = URL(string: urlString) else {
            return nil
        }

        return LinkAccountSessionAttachResponse(authorizationURL: url, allResponseFields: response) as? Self
    }
}
