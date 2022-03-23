//
//  STPBankAccountCollector.swift
//  StripeiOS
//
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
import UIKit
@_spi(STP) import StripeCore

public class STPBankAccountCollector: NSObject {

    /// By default `sharedHandler` initializes with STPAPIClient.shared.
    public var apiClient: STPAPIClient

    /// By default `sharedHandler` initializes with STPAPIClient.shared.
    @available(swift, deprecated: 0.0.1, renamed: "apiClient")
    @objc(apiClient) public var _objc_apiClient: _stpobjc_STPAPIClient {
        get {
            _stpobjc_STPAPIClient(apiClient: apiClient)
        }
        set {
            apiClient = newValue._apiClient
        }
    }

    @objc(init)
    @available(swift, deprecated: 0.0.1, obsoleted: 0.0.1, renamed: "init()")
    public convenience override init() {
        self.init(apiClient: STPAPIClient.shared)
    }

    @objc(initWithAPIClient:)
    @available(swift, deprecated: 0.0.1, obsoleted: 0.0.1)
    public convenience init(apiClient: _stpobjc_STPAPIClient = .shared) {
        self.init(apiClient: apiClient._apiClient)
    }

    public init(apiClient: STPAPIClient = .shared) {
        self.apiClient = apiClient
    }

    // MARK: Collect Bank Account - Payment Intent
    public typealias STPCollectBankAccountForPaymentCompletionBlock = (STPPaymentIntent?, Error?) -> Void

    enum CollectBankAccountError: Error, CustomStringConvertible {
        case connectionsSDKNotLinked
        case invalidClientSecret
        case unableToLinkAccount
        case userCanceled
        case unexpectedError

        public var description: String {
            switch self {
            case .connectionsSDKNotLinked:
                return "Connections SDK has not been linked into your project"
            case .invalidClientSecret:
                return "Unable to parse client secret"
            case .unableToLinkAccount:
                return "Failed to link account"
            case .userCanceled:
                return "User canceled out of workflow"
            case .unexpectedError:
                return "Unexpected error"
            }
        }
    }

    /// Presents a modal from the viewController to collect bank account
    /// and if completed successfully, link your bank account to a PaymentIntent
    /// - Parameters:
    ///   - clientSecret:      Client secret of the payment intent
    ///   - params:            Parameters for this call
    ///   - viewController:    Presenting view controller that will present the modal
    ///   - completion:        completion block to be called on completion of the operation
    @available(iOS 12, *)
    @objc(collectBankAccountForPaymentWithClientSecret:params:from:completion:)
    public func collectBankAccountForPayment(clientSecret: String,
                                             params: STPCollectBankAccountParams,
                                             from viewController: UIViewController,
                                             completion: @escaping STPCollectBankAccountForPaymentCompletionBlock) {
        guard let connectionsAPI = ConnectionsSDKAvailability.connections() else {
            assertionFailure("Connections SDK has not been linked into your project")
            completion(nil, CollectBankAccountError.connectionsSDKNotLinked)
            return
        }
        guard let paymentIntentID = STPPaymentIntent.id(fromClientSecret: clientSecret) else {
            completion(nil, CollectBankAccountError.invalidClientSecret)
            return
        }
        let connectionsCompletion: (ConnectionsSDKResult, LinkAccountSession) -> () = { result, linkAccountSession in
            switch(result) {
            case .completed:
                self.attachLinkAccountSessionToPaymentIntent(paymentIntentID: paymentIntentID,
                                                             clientSecret: clientSecret,
                                                             linkAccountSession: linkAccountSession,
                                                             completion: completion)
            case .cancelled:
                completion(nil, CollectBankAccountError.userCanceled)
            case .failed(let error):
                completion(nil, error)
            @unknown default:
                completion(nil, CollectBankAccountError.unexpectedError)
            }
        }
        let linkAccountSessionCallback: STPLinkAccountSessionBlock = { linkAccountSession, error in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let linkAccountSession = linkAccountSession else {
                completion(nil, NSError.stp_genericFailedToParseResponseError())
                return
            }
            connectionsAPI.presentConnectionsSheet(clientSecret: linkAccountSession.clientSecret,
                                                   from: viewController) { result in
                connectionsCompletion(result, linkAccountSession)
            }
        }

        apiClient.createLinkAccountSession(paymentIntentID: paymentIntentID,
                                           clientSecret: clientSecret,
                                           paymentMethodType: params.paymentMethodParams.type,
                                           customerName: params.paymentMethodParams.billingDetails?.name,
                                           customerEmailAddress: params.paymentMethodParams.billingDetails?.email,
                                           completion: linkAccountSessionCallback)
    }

    // MARK: Helper
    private func attachLinkAccountSessionToPaymentIntent(paymentIntentID: String,
                                                         clientSecret: String,
                                                         linkAccountSession: LinkAccountSession,
                                                         completion: @escaping STPCollectBankAccountForPaymentCompletionBlock) {
        STPAPIClient.shared.attachLinkAccountSession(paymentIntentID: paymentIntentID,
                                                     linkAccountSessionID: linkAccountSession.stripeID,
                                                     clientSecret: clientSecret) { paymentIntent, error in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let paymentIntent = paymentIntent else {
                completion(nil, NSError.stp_genericFailedToParseResponseError())
                return
            }
            completion(paymentIntent, nil)
        }
    }
    
    // MARK: Collect Bank Account - Setup Intent
    public typealias STPCollectBankAccountForSetupCompletionBlock = (STPSetupIntent?, Error?) -> Void
    
    /// Presents a modal from the viewController to collect bank account
    /// and if completed successfully, link your bank account to a SetupIntent
    /// - Parameters:
    ///   - clientSecret:      Client secret of the setup intent
    ///   - params:            Parameters for this call
    ///   - viewController:     Presenting view controller that will present the modal
    ///   - completion:        completion block to be called on completion of the operation
    @available(iOS 12, *)
    @objc(collectBankAccountForSetupWithClientSecret:params:from:completion:)
    public func collectBankAccountForSetup(clientSecret: String,
                                           params: STPCollectBankAccountParams,
                                           from viewController: UIViewController,
                                           completion: @escaping STPCollectBankAccountForSetupCompletionBlock) {
        guard let connectionsAPI = ConnectionsSDKAvailability.connections() else {
            assertionFailure("Connections SDK has not been linked into your project")
            completion(nil, CollectBankAccountError.connectionsSDKNotLinked)
            return
        }
        guard let setupIntentID = STPSetupIntent.id(fromClientSecret: clientSecret) else {
            completion(nil, CollectBankAccountError.invalidClientSecret)
            return
        }
        let connectionsCompletion: (ConnectionsSDKResult, LinkAccountSession) -> () = { result, linkAccountSession in
            switch(result) {
            case .completed:
                self.attachLinkAccountSessionToSetupIntent(setupIntentID: setupIntentID,
                                                           clientSecret: clientSecret,
                                                           linkAccountSession: linkAccountSession,
                                                           completion: completion)
            case .cancelled:
                completion(nil, CollectBankAccountError.userCanceled)
            case .failed(let error):
                completion(nil, error)
            @unknown default:
                completion(nil, CollectBankAccountError.unexpectedError)
            }
        }
        let linkAccountSessionCallback: STPLinkAccountSessionBlock = { linkAccountSession, error in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let linkAccountSession = linkAccountSession else {
                completion(nil, NSError.stp_genericFailedToParseResponseError())
                return
            }
            connectionsAPI.presentConnectionsSheet(clientSecret: linkAccountSession.clientSecret,
                                                   from: viewController) { result in
                connectionsCompletion(result, linkAccountSession)
            }
        }
        apiClient.createLinkAccountSession(setupIntentID: setupIntentID,
                                           clientSecret: clientSecret,
                                           paymentMethodType: params.paymentMethodParams.type,
                                           customerName: params.paymentMethodParams.billingDetails?.name,
                                           customerEmailAddress: params.paymentMethodParams.billingDetails?.email,
                                           completion: linkAccountSessionCallback)
    }

    // MARK: Helper
    private func attachLinkAccountSessionToSetupIntent(setupIntentID: String,
                                                       clientSecret: String,
                                                       linkAccountSession: LinkAccountSession,
                                                       completion: @escaping STPCollectBankAccountForSetupCompletionBlock) {
        STPAPIClient.shared.attachLinkAccountSession(setupIntentID: setupIntentID,
                                                     linkAccountSessionID: linkAccountSession.stripeID,
                                                     clientSecret: clientSecret) { setupIntent, error in
            if let error = error {
                completion(nil, error)
                return
            }
            guard let setupIntent = setupIntent else {
                completion(nil, NSError.stp_genericFailedToParseResponseError())
                return
            }
            completion(setupIntent, nil)
        }
    }
}
