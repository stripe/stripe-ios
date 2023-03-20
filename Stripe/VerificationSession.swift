//
//  VerificationSession.swift
//  StripeiOS
//
//  Created by Cameron Sabol on 2/22/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

extension ConsumerSession {
    class VerificationSession: NSObject, STPAPIResponseDecodable {
        internal init(type: VerificationSession.SessionType,
                      state: VerificationSession.SessionState,
                      allResponseFields: [AnyHashable : Any]) {
            self.type = type
            self.state = state
            self.allResponseFields = allResponseFields
        }
        
        
        enum SessionType: String {
            case unknown = ""
            case signup = "signup"
            case email = "email"
            case sms = "sms"
        }
        
        enum SessionState: String {
            case unknown = ""
            case started = "started"
            case failed = "failed"
            case verified = "verified"
            case canceled = "canceled"
            case expired = "expired"
        }
        
        let type: SessionType
        let state: SessionState
        
        let allResponseFields: [AnyHashable : Any]
        
        static func decodedObject(fromAPIResponse response: [AnyHashable : Any]?) -> Self? {
            guard let response = response,
                  let typeString = (response["type"] as? String)?.lowercased(),
                  let statusString = (response["state"] as? String)?.lowercased() else {
                return nil
            }
            
            let type: SessionType = SessionType(rawValue: typeString) ?? .unknown
            let state: SessionState = SessionState(rawValue: statusString) ?? .unknown
            
            return VerificationSession(type: type,
                                       state: state,
                                       allResponseFields: response) as? Self
        }
        
        
    }
}

extension Sequence where Iterator.Element == ConsumerSession.VerificationSession {
    var containsVerifiedSMSSession: Bool {
        return contains(where: { $0.type == .sms && $0.state == .verified })
    }
    
    var isVerifiedForSignup: Bool {
        return contains(where: { $0.type == .signup && $0.state == .started })
    }
}
