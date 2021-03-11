//
//  STPPushProvisioningDetails.swift
//  Stripe
//
//  Created by Jack Flintermann on 9/26/18
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation

class STPPushProvisioningDetails: NSObject, STPAPIResponseDecodable {
    let cardId: String
    let livemode: Bool
    let encryptedPassData: Data
    let activationData: Data
    let ephemeralPublicKey: Data

    required init(
        cardId: String,
        livemode: Bool,
        encryptedPass encryptedPassData: Data,
        activationData: Data,
        ephemeralPublicKey: Data
    ) {
        self.cardId = cardId
        self.livemode = livemode
        self.encryptedPassData = encryptedPassData
        self.activationData = activationData
        self.ephemeralPublicKey = ephemeralPublicKey
        super.init()
    }
    private(set) var allResponseFields: [AnyHashable: Any] = [:]

    // MARK: - STPAPIResponseDecodable
    class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard
            let dict = (response as NSDictionary?)?.stp_dictionaryByRemovingNulls() as NSDictionary?
        else {
            return nil
        }

        // required fields
        let cardId = dict.stp_string(forKey: "card")
        let livemode = dict.stp_bool(forKey: "livemode", or: false)
        let encryptedPassString = dict.stp_string(forKey: "contents")
        let encryptedPassData =
            encryptedPassString != nil
            ? Data(base64Encoded: encryptedPassString ?? "", options: []) : nil

        let activationString = dict.stp_string(forKey: "activation_data")
        let activationData =
            activationString != nil ? Data(base64Encoded: activationString ?? "", options: []) : nil

        let ephemeralPublicKeyString = dict.stp_string(forKey: "ephemeral_public_key")
        let ephemeralPublicKeyData =
            ephemeralPublicKeyString != nil
            ? Data(base64Encoded: ephemeralPublicKeyString ?? "", options: []) : nil

        if cardId == nil || encryptedPassData == nil || activationData == nil
            || ephemeralPublicKeyData == nil
        {
            return nil
        }

        if let encryptedPassData = encryptedPassData, let activationData = activationData,
            let ephemeralPublicKeyData = ephemeralPublicKeyData
        {
            let details = self.init(
                cardId: cardId ?? "",
                livemode: livemode,
                encryptedPass: encryptedPassData,
                activationData: activationData,
                ephemeralPublicKey: ephemeralPublicKeyData)
            details.allResponseFields = dict as! [AnyHashable: Any]
            return details
        }
        return nil
    }

    // MARK: - Equality
    override func isEqual(_ object: Any?) -> Bool {
        if let details = object as? STPPushProvisioningDetails {
            return isEqual(to: details)
        }
        return false
    }

    override var hash: Int {
        return activationData.hashValue
    }

    func isEqual(to details: STPPushProvisioningDetails) -> Bool {
        return details.activationData == self.activationData
    }
}
