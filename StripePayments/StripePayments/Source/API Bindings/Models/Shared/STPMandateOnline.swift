//
//  STPMandateOnline.swift
//  StripePayments
//

import Foundation
@_spi(STP) import StripeCore

/// Online acceptance details for a mandate.
@_spi(ConfirmationTokensPublicPreview) public class STPMandateOnline: NSObject, STPAPIResponseDecodable {
    /// IP address of the customer when they accepted the mandate.
    public let ipAddress: String?
    /// User agent of the customer when they accepted the mandate.
    public let userAgent: String?
    
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]
    
    internal init(
        ipAddress: String?,
        userAgent: String?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        self.allResponseFields = allResponseFields
        super.init()
    }
    
    @objc
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()
        
        let ipAddress = dict.stp_string(forKey: "ip_address")
        let userAgent = dict.stp_string(forKey: "user_agent")
        
        return STPMandateOnline(
            ipAddress: ipAddress,
            userAgent: userAgent,
            allResponseFields: response
        ) as? Self
    }
}