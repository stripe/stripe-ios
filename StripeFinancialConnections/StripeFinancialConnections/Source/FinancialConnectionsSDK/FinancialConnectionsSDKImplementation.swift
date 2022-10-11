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
@_spi(STP)
@available(iOSApplicationExtension, unavailable)
public class FinancialConnectionsSDKImplementation: FinancialConnectionsSDKInterface {
    required public init() {}

    public func presentFinancialConnectionsSheet(
        apiClient: STPAPIClient,
        clientSecret: String,
        returnURL: String?,
        from presentingViewController: UIViewController,
        completion: @escaping (FinancialConnectionsSDKResult) -> ()
    ) {
        let financialConnectionsSheet = FinancialConnectionsSheet(financialConnectionsSessionClientSecret: clientSecret, returnURL: returnURL)
        financialConnectionsSheet.apiClient = apiClient
        // Captures self explicitly until the callback is invoked
        financialConnectionsSheet.present(
            from: presentingViewController,
            completion: { result in
                switch result {
                case .completed(session: let session):
                    guard let paymentAccount = session.paymentAccount else {
                        completion(.failed(error: FinancialConnectionsSheetError.unknown(debugDescription: "PaymentAccount is not set on FinancialConnectionsSession")))
                        return
                    }
                    if let linkedBank = self.linkedBankFor(paymentAccount: paymentAccount, session: session) {
                        completion(.completed(linkedBank: linkedBank))
                    } else {
                        completion(.failed(error: FinancialConnectionsSheetError.unknown(debugDescription: "Unknown PaymentAccount is set on FinancialConnectionsSession")))
                    }
                case .canceled:
                    completion(.cancelled)
                case .failed(let error):
                    completion(.failed(error: error))
                }
            })
    }
    
    // MARK: - Helpers
    
    private func linkedBankFor(paymentAccount: StripeAPI.FinancialConnectionsSession.PaymentAccount,
                                   session: StripeAPI.FinancialConnectionsSession) -> LinkedBank? {
        switch paymentAccount {
        case .linkedAccount(let linkedAccount):
            return LinkedBankImplementation(with: session.id,
                                            accountId: linkedAccount.id,
                                            displayName: linkedAccount.displayName,
                                            bankName: linkedAccount.institutionName,
                                            last4: linkedAccount.last4,
                                            instantlyVerified: true)
        case .bankAccount(let bankAccount):
            return LinkedBankImplementation(with: session.id,
                                            accountId: bankAccount.id,
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
    public let accountId: String
    public let displayName: String?
    public let bankName: String?
    public let last4: String?
    public let instantlyVerified: Bool
    
    public init(with sessionId: String,
                accountId: String,
                displayName: String?,
                bankName: String?,
                last4: String?,
                instantlyVerified: Bool) {
        self.sessionId = sessionId
        self.accountId = accountId
        self.displayName = displayName
        self.bankName = bankName
        self.last4 = last4
        self.instantlyVerified = instantlyVerified
    }
}
