//
//  STPIntentActionUseStripeSDK.swift
//  StripePayments
//
//  Created by Cameron Sabol on 5/15/19.
//  Copyright © 2019 Stripe, Inc. All rights reserved.
//

import Foundation

@objc
enum STPIntentActionUseStripeSDKType: Int {
    case unknown = 0
    case threeDS2Fingerprint
    case threeDS2Redirect
}

class STPIntentActionUseStripeSDK: NSObject {

    let allResponseFields: [AnyHashable: Any]

    let type: STPIntentActionUseStripeSDKType

    // MARK: - 3DS2 Fingerprint
    let directoryServerName: String?
    let directoryServerID: String?

    /// PEM encoded DS certificate
    let directoryServerCertificate: String?
    let rootCertificateStrings: [String]?

    /// A Visa-specific field
    let directoryServerKeyID: String?
    let serverTransactionID: String?
    let threeDSSourceID: String?

    /// Publishable key to use for making authentication API calls (Link-specific)
    let publishableKeyOverride: String?
    let threeDS2IntentOverride: String?

    // MARK: - 3DS2 Redirect
    let redirectURL: URL?

    private init(
        type: STPIntentActionUseStripeSDKType,
        directoryServerName: String?,
        directoryServerID: String?,
        directoryServerCertificate: String?,
        rootCertificateStrings: [String]?,
        directoryServerKeyID: String?,
        serverTransactionID: String?,
        threeDSSourceID: String?,
        publishableKeyOverride: String?,
        threeDS2IntentOverride: String?,
        redirectURL: URL?,
        allResponseFields: [AnyHashable: Any]
    ) {
        self.type = type
        self.directoryServerName = directoryServerName
        self.directoryServerID = directoryServerID
        self.directoryServerCertificate = directoryServerCertificate
        self.rootCertificateStrings = rootCertificateStrings
        self.directoryServerKeyID = directoryServerKeyID
        self.serverTransactionID = serverTransactionID
        self.threeDSSourceID = threeDSSourceID
        self.publishableKeyOverride = publishableKeyOverride
        self.threeDS2IntentOverride = threeDS2IntentOverride
        self.redirectURL = redirectURL
        self.allResponseFields = allResponseFields
        super.init()
    }

    convenience init?(
        encryptionInfo: [AnyHashable: Any],
        directoryServerName: String?,
        directoryServerKeyID: String?,
        serverTransactionID: String?,
        threeDSSourceID: String?,
        publishableKeyOverride: String?,
        threeDS2IntentOverride: String?,
        allResponseFields: [AnyHashable: Any]
    ) {
        guard let certificate = encryptionInfo["certificate"] as? String,
            !certificate.isEmpty,
            let directoryServerID = encryptionInfo["directory_server_id"] as? String,
            !directoryServerID.isEmpty,
            let rootCertificates = encryptionInfo["root_certificate_authorities"] as? [String],
            !rootCertificates.isEmpty
        else {
            return nil
        }
        self.init(
            type: .threeDS2Fingerprint,
            directoryServerName: directoryServerName,
            directoryServerID: directoryServerID,
            directoryServerCertificate: certificate,
            rootCertificateStrings: rootCertificates,
            directoryServerKeyID: directoryServerKeyID,
            serverTransactionID: serverTransactionID,
            threeDSSourceID: threeDSSourceID,
            publishableKeyOverride: publishableKeyOverride,
            threeDS2IntentOverride: threeDS2IntentOverride,
            redirectURL: nil,
            allResponseFields: allResponseFields
        )
    }

    convenience init(
        redirectURL: URL,
        allResponseFields: [AnyHashable: Any]
    ) {
        var threeDSSourceID: String?
        if redirectURL.lastPathComponent.hasPrefix("src_") {
            threeDSSourceID = redirectURL.lastPathComponent
        }
        self.init(
            type: .threeDS2Redirect,
            directoryServerName: nil,
            directoryServerID: nil,
            directoryServerCertificate: nil,
            rootCertificateStrings: nil,
            directoryServerKeyID: nil,
            serverTransactionID: nil,
            threeDSSourceID: threeDSSourceID,
            publishableKeyOverride: nil,
            threeDS2IntentOverride: nil,
            redirectURL: redirectURL,
            allResponseFields: allResponseFields
        )
    }

    convenience override init() {
        self.init(
            type: .unknown,
            directoryServerName: nil,
            directoryServerID: nil,
            directoryServerCertificate: nil,
            rootCertificateStrings: nil,
            directoryServerKeyID: nil,
            serverTransactionID: nil,
            threeDSSourceID: nil,
            publishableKeyOverride: nil,
            threeDS2IntentOverride: nil,
            redirectURL: nil,
            allResponseFields: [:]
        )
    }

    @objc override var description: String {
        let props: [String] = [
            // Object
            String(format: "%@: %p", String(describing: STPIntentActionUseStripeSDK.self), self),
            // IntentActionUseStripeSDK details (alphabetical)
            "directoryServer = \(String(describing: directoryServerName))",
            "directoryServerID = \(String(describing: directoryServerID))",
            "directoryServerKeyID = \(String(describing: directoryServerKeyID))",
            "serverTransactionID = \(String(describing: serverTransactionID))",
            "directoryServerCertificate = \(String(describing: (directoryServerCertificate?.count ?? 0 > 0 ? "<redacted>" : nil)))",
            "rootCertificateStrings = \(String(describing: (rootCertificateStrings?.count ?? 0 > 0 ? "<redacted>" : nil)))",
            "threeDSSourceID = \(String(describing: threeDSSourceID))",
            "type = \(String(describing: allResponseFields["type"]))",
            "redirectURL = \(String(describing: redirectURL))",
        ]

        return "<\(props.joined(separator: "; "))>"
    }
}

/// :nodoc:
extension STPIntentActionUseStripeSDK: STPAPIResponseDecodable {
    class func decodedObject(fromAPIResponse response: [AnyHashable: Any]?) -> Self? {
        guard let dict = response,
            let typeString = dict["type"] as? String
        else {
            return nil
        }

        switch typeString {
        case "stripe_3ds2_fingerprint":
            if let encryptionInfo = dict["directory_server_encryption"] as? [AnyHashable: Any] {
                return STPIntentActionUseStripeSDK(
                    encryptionInfo: encryptionInfo,
                    directoryServerName: dict["directory_server_name"] as? String,
                    directoryServerKeyID: encryptionInfo["key_id"] as? String,
                    serverTransactionID: dict["server_transaction_id"] as? String,
                    threeDSSourceID: dict["three_d_secure_2_source"] as? String,
                    publishableKeyOverride: dict["publishable_key"] as? String,
                    threeDS2IntentOverride: dict["three_d_secure_2_intent"] as? String,
                    allResponseFields: dict
                ) as? Self
            } else {
                return nil
            }
        case "three_d_secure_redirect":
            if let redirectURLString = dict["stripe_js"] as? String,
                let redirectURL = URL(string: redirectURLString)
            {
                return STPIntentActionUseStripeSDK(
                    redirectURL: redirectURL,
                    allResponseFields: dict
                )
                    as? Self
            } else {
                return nil
            }

        default:
            return STPIntentActionUseStripeSDK(
                type: .unknown,
                directoryServerName: nil,
                directoryServerID: nil,
                directoryServerCertificate: nil,
                rootCertificateStrings: nil,
                directoryServerKeyID: nil,
                serverTransactionID: nil,
                threeDSSourceID: nil,
                publishableKeyOverride: nil,
                threeDS2IntentOverride: nil,
                redirectURL: nil,
                allResponseFields: dict
            ) as? Self
        }
    }
}
