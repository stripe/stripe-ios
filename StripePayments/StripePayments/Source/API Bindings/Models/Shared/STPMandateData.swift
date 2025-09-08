//
//  STPMandateData.swift
//  StripePayments
//

import Foundation
@_spi(STP) import StripeCore

/// Mandate data associated with a ConfirmationToken
@_spi(ConfirmationTokensPublicPreview) public class STPMandateData: NSObject, STPAPIResponseDecodable {
    /// Customer acceptance information for the mandate.
    public let customerAcceptance: STPMandateCustomerAcceptance
    
    /// :nodoc:
    @objc private(set) public var allResponseFields: [AnyHashable: Any] = [:]
    
    internal init(
        customerAcceptance: STPMandateCustomerAcceptance,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.customerAcceptance = customerAcceptance
        self.allResponseFields = allResponseFields
        super.init()
    }
    
    @objc
    public static func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let response = response else {
            return nil
        }
        let dict = response.stp_dictionaryByRemovingNulls()
        
        guard let customerAcceptance = STPMandateCustomerAcceptance.decodedObject(
            fromAPIResponse: dict.stp_dictionary(forKey: "customer_acceptance")
        ) else {
            return nil
        }
        
        return STPMandateData(
            customerAcceptance: customerAcceptance,
            allResponseFields: response
        ) as? Self
    }
}