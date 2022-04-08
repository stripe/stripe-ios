//
//  ConnectionsSDKImplementation.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 2/24/22.
//

import UIKit
@_spi(STP) import StripeCore

/**
 NOTE: If you change the name of this class, make sure to also change it ConnectionsSDKAvailability file
 */
@_spi(STP) public class ConnectionsSDKImplementation: ConnectionsSDKInterface {

    required public init() {}

    public func presentConnectionsSheet(clientSecret: String,
                                        from presentingViewController: UIViewController,
                                        completion: @escaping (ConnectionsSDKResult) -> ()) {
        let connectionsSheet = ConnectionsSheet(linkAccountSessionClientSecret: clientSecret)
        connectionsSheet.present(
            from: presentingViewController,
            completion: { result in
                switch result {
                case .completed(session: let session):
                    guard let paymentAccount = session.paymentAccount else {
                        completion(.failed(error: ConnectionsSheetError.unknown(debugDescription: "PaymentAccount is not set on LinkAccountSession")))
                        return
                    }
                    if let linkedBank = linkedBankFor(paymentAccount: paymentAccount, session: session) {
                        completion(.completed(linkedBank: linkedBank))
                    } else {
                        completion(.failed(error: ConnectionsSheetError.unknown(debugDescription: "Unknown PaymentAccount is set on LinkAccountSession")))
                    }
                case .canceled:
                    completion(.cancelled)
                case .failed(let error):
                    completion(.failed(error: error))
                }
            })
    }

    // MARK: - Helpers

    fileprivate func linkedBankFor(paymentAccount: StripeAPI.LinkAccountSession.PaymentAccount,
                                   session: StripeAPI.LinkAccountSession) -> ConnectionsSDKResult.LinkedBank? {
        switch paymentAccount {
        case .linkedAccount(let linkedAccount):
            return ConnectionsSDKResult.LinkedBank(with: session.id,
                                                   displayName: linkedAccount.displayName,
                                                   bankName: linkedAccount.institutionName,
                                                   last4: linkedAccount.last4,
                                                   instantlyVerified: true)
        case .bankAccount(let bankAccount):
            return ConnectionsSDKResult.LinkedBank(with: session.id,
                                                   displayName: bankAccount.bankName,
                                                   bankName: bankAccount.bankName,
                                                   last4: bankAccount.last4,
                                                   instantlyVerified: false)
        case .unparsable:
            return nil
        }
    }

}
