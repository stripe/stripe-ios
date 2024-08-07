//
//  FinancialConnectionsSDKImplementation.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 2/24/22.
//

@_spi(STP) import StripeCore
import UIKit

/**
 NOTE: If you change the name of this class, make sure to also change it FinancialConnectionsSDKAvailability file
 */
@_spi(STP)
public class FinancialConnectionsSDKImplementation: FinancialConnectionsSDKInterface {

    required public init() {}

    public func presentFinancialConnectionsSheet(
        apiClient: STPAPIClient,
        clientSecret: String,
        returnURL: String?,
        onEvent: ((StripeCore.FinancialConnectionsEvent) -> Void)?,
        from presentingViewController: UIViewController,
        completion: @escaping (FinancialConnectionsSDKResult) -> Void
    ) {
        let financialConnectionsSheet = FinancialConnectionsSheet(
            financialConnectionsSessionClientSecret: clientSecret,
            returnURL: returnURL
        )
        financialConnectionsSheet.apiClient = apiClient
        financialConnectionsSheet.onEvent = onEvent
        // Captures self explicitly until the callback is invoked
        financialConnectionsSheet.present(
            from: presentingViewController,
            completion: { result in
                switch result {
                case .completed(let hostControllerResult):
                    switch hostControllerResult {
                    case .financialConnections(let session):
                        guard let paymentAccount = session.paymentAccount else {
                            completion(
                                .failed(
                                    error: FinancialConnectionsSheetError.unknown(
                                        debugDescription: "PaymentAccount is not set on FinancialConnectionsSession"
                                    )
                                )
                            )
                            return
                        }
                        if let linkedBank = self.linkedBankFor(paymentAccount: paymentAccount, session: session) {
                            completion(.completed(.financialConnections(linkedBank)))
                        } else {
                            completion(
                                .failed(
                                    error: FinancialConnectionsSheetError.unknown(
                                        debugDescription: "Unknown PaymentAccount is set on FinancialConnectionsSession"
                                    )
                                )
                            )
                        }
                    case .instantDebits(let instantDebitsLinkedBank):
                        completion(.completed(.instantDebits(instantDebitsLinkedBank)))
                    }
                case .canceled:
                    completion(.cancelled)
                case .failed(let error):
                    completion(.failed(error: error))
                }
            }
        )
    }

    // MARK: - Helpers

    private func linkedBankFor(
        paymentAccount: StripeAPI.FinancialConnectionsSession.PaymentAccount,
        session: StripeAPI.FinancialConnectionsSession
    ) -> FinancialConnectionsLinkedBank? {
        switch paymentAccount {
        case .linkedAccount(let linkedAccount):
            return FinancialConnectionsLinkedBankImplementation(
                with: session.id,
                accountId: linkedAccount.id,
                displayName: linkedAccount.displayName,
                bankName: linkedAccount.institutionName,
                last4: linkedAccount.last4,
                instantlyVerified: true
            )
        case .bankAccount(let bankAccount):
            return FinancialConnectionsLinkedBankImplementation(
                with: session.id,
                accountId: bankAccount.id,
                displayName: bankAccount.bankName,
                bankName: bankAccount.bankName,
                last4: bankAccount.last4,
                instantlyVerified: false
            )
        case .unparsable:
            return nil
        }
    }
}
