//
//  FinancialConnectionsSDKImplementation.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 2/24/22.
//

import UIKit
@_spi(STP) import StripeCore

/**
 NOTE: If you change the name of this class, make sure to also change it FinancialConnectionsSDKAvailability file
 */
@_spi(STP) public class FinancialConnectionsSDKImplementation: FinancialConnectionsSDKInterface {

    required public init() {}

    public func presentFinancialConnectionsSheet(clientSecret: String,
                                                 from presentingViewController: UIViewController,
                                                 completion: @escaping (FinancialConnectionsSDKResult) -> ()) {
        let financialConnectionsSheet = FinancialConnectionsSheet(linkAccountSessionClientSecret: clientSecret)
        // Captures self explicitly until the callback is invoked
        financialConnectionsSheet.present(
            from: presentingViewController,
            completion: { result in
                switch result {
                case .completed(session: let session):
                    guard let paymentAccount = session.paymentAccount else {
                        completion(.failed(error: FinancialConnectionsSheetError.unknown(debugDescription: "PaymentAccount is not set on LinkAccountSession")))
                        return
                    }
                    if let linkedBank = self.linkedBankFor(paymentAccount: paymentAccount, session: session) {
                        completion(.completed(linkedBank: linkedBank))
                    } else {
                        completion(.failed(error: FinancialConnectionsSheetError.unknown(debugDescription: "Unknown PaymentAccount is set on LinkAccountSession")))
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
                                   session: StripeAPI.LinkAccountSession) -> LinkedBank? {
        switch paymentAccount {
        case .linkedAccount(let linkedAccount):
            return LinkedBankImplementation(with: session.id,
                                            displayName: linkedAccount.displayName,
                                            bankName: linkedAccount.institutionName,
                                            last4: linkedAccount.last4,
                                            instantlyVerified: true)
        case .bankAccount(let bankAccount):
            return LinkedBankImplementation(with: session.id,
                                            displayName: bankAccount.bankName,
                                            bankName: bankAccount.bankName,
                                            last4: bankAccount.last4,
                                            instantlyVerified: false)
        case .unparsable:
            return nil
        }
    }
    
}

// MARK: - LinkedBank Implementation
struct LinkedBankImplementation: LinkedBank {
    public let sessionId: String
    public let displayName: String?
    public let bankName: String?
    public let last4: String?
    public let instantlyVerified: Bool
    
    public init(with sessionId: String,
                displayName: String?,
                bankName: String?,
                last4: String?,
                instantlyVerified: Bool) {
        self.sessionId = sessionId
        self.displayName = displayName
        self.bankName = bankName
        self.last4 = last4
        self.instantlyVerified = instantlyVerified
    }
}
