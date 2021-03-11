//
//  STPPushProvisioningContext.swift
//  Stripe
//
//  Created by Jack Flintermann on 9/27/18.
//  Copyright © 2018 Stripe, Inc. All rights reserved.
//

import Foundation
import PassKit

/// This class makes it easier to implement "Push Provisioning", the process by which an end-user can add a card to their Apple Pay wallet without having to type their number. This process is mediated by an Apple class called `PKAddPaymentPassViewController`; this class will help you implement that class' delegate methods. Note that this flow requires a special entitlement from Apple; for more information please see https://stripe.com/docs/issuing/cards/digital-wallets .
public class STPPushProvisioningContext: NSObject {
    /// The API Client to use to make requests.
    /// Defaults to STPAPIClient.shared
    @objc public var apiClient: STPAPIClient = .shared

    /// This is a helper method to generate a PKAddPaymentPassRequestConfiguration that will work with
    /// Stripe's Issuing APIs. Pass the returned configuration object to `PKAddPaymentPassViewController`'s `initWithRequestConfiguration:delegate:` initializer.
    /// - Parameters:
    ///   - name: Your cardholder's name. Example: John Appleseed
    ///   - description: A localized description of your card's name. This will appear in Apple's UI as "{description} will be available in Wallet". Example: Platinum Rewards Card
    ///   - last4: The last 4 of the card to be added to the user's Apple Pay wallet. Example: 4242
    ///   - brand: The brand of the card. Example: `STPCardBrandVisa`
    @objc
    public class func requestConfiguration(
        withName name: String,
        description: String?,
        last4: String?,
        brand: STPCardBrand
    ) -> PKAddPaymentPassRequestConfiguration {
        let config = PKAddPaymentPassRequestConfiguration(encryptionScheme: .ECC_V2)
        config?.cardholderName = name
        config?.primaryAccountSuffix = last4
        config?.localizedDescription = description
        if #available(iOS 12.0, *) {
            config?.style = .payment
        }
        if brand == .visa {
            config?.paymentNetwork = .visa
        }
        if brand == .mastercard {
            config?.paymentNetwork = .masterCard
        }
        return config!
    }

    /// In order to retreive the encrypted payload that PKAddPaymentPassViewController expects, the Stripe SDK must talk to the Stripe API. As this requires privileged access, you must write a "key provider" that generates an Ephemeral Key on your backend and provides it to the SDK when requested. For more information, see https://stripe.com/docs/mobile/ios/basic#ephemeral-key
    @objc
    public init(keyProvider: STPIssuingCardEphemeralKeyProvider) {
        apiClient = STPAPIClient.shared
        keyManager = STPEphemeralKeyManager(
            keyProvider: keyProvider, apiVersion: STPAPIClient.apiVersion,
            performsEagerFetching: false)
        super.init()
    }

    /// This method lines up with the method of the same name on `PKAddPaymentPassViewControllerDelegate`. You should implement that protocol in your own app, and when that method is called, call this method on your `STPPushProvisioningContext`. This in turn will first initiate a call to your `keyProvider` (see above) to obtain an Ephemeral Key, then make a call to the Stripe Issuing API to fetch an encrypted payload for the card in question, then return that payload to iOS.
    @objc
    public func addPaymentPassViewController(
        _ controller: PKAddPaymentPassViewController,
        generateRequestWithCertificateChain certificates: [Data], nonce: Data, nonceSignature: Data,
        completionHandler handler: @escaping (PKAddPaymentPassRequest) -> Void
    ) {
        keyManager.getOrCreateKey({ ephemeralKey, keyError in
            if let keyError = keyError {
                let request = PKAddPaymentPassRequest()
                request.stp_error = keyError as NSError
                // handler, bizarrely, cannot take an NSError, but passing an empty PKAddPaymentPassRequest causes roughly equivalent behavior.
                handler(request)
                return
            }
            let params = STPPushProvisioningDetailsParams(
                cardId: ephemeralKey?.issuingCardID ?? "", certificates: certificates, nonce: nonce,
                nonceSignature: nonceSignature)
            if let ephemeralKey = ephemeralKey {
                self.apiClient.retrievePushProvisioningDetails(
                    with: params, ephemeralKey: ephemeralKey
                ) {
                    details, error in
                    if let error = error {
                        let request = PKAddPaymentPassRequest()
                        request.stp_error = error as NSError
                        handler(request)
                        return
                    }
                    let request = PKAddPaymentPassRequest()
                    request.activationData = details?.activationData
                    request.encryptedPassData = details?.encryptedPassData
                    request.ephemeralPublicKey = details?.ephemeralPublicKey
                    handler(request)
                }
            }
        })
    }

    private var keyManager: STPEphemeralKeyManager
    private var ephemeralKey: STPEphemeralKey?
}
