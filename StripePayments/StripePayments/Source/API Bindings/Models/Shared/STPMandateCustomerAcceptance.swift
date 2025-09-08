//
//  STPMandateCustomerAcceptance.swift
//  StripePayments
//

import Foundation
@_spi(STP) import StripeCore

/// Customer acceptance information for the mandate of a transaction.
@_spi(ConfirmationTokensPublicPreview) public class STPMandateCustomerAcceptance: NSObject, STPAPIResponseDecodable {
    /// The type of customer acceptance information.
    public let type: String
    /// Online acceptance details if accepted online.
    public let online: STPMandateOnline?
    
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]
    
    internal init(
        type: String,
        online: STPMandateOnline?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.type = type
        self.online = online
        self.allResponseFields = allResponseFields
        super.init()
    }
    
    @objc
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()
        
        guard let type = dict.stp_string(forKey: "type") else {
            return nil
        }
        
        let online = STPMandateOnline.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "online")
        )
        
        return STPMandateCustomerAcceptance(
            type: type,
            online: online,
            allResponseFields: response
        ) as? Self
    }
}