//
//  FinancialConnectionsSheet.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/10/21.
//

import UIKit
@_spi(STP) import StripeCore

/**
 A drop-in class that presents a sheet for a user to connect their financial accounts.
 This class is in beta; see https://stripe.com/docs/financial-connections for access
 */
final public class FinancialConnectionsSheet {

    // MARK: - Types

    /// The result of financial account connection flow
    @frozen public enum Result {
        /// User completed the financialConnections session
        case completed(session: StripeAPI.FinancialConnectionsSession)
        /// Failed with error
        case failed(error: Error)
        /// User canceled out of the financialConnections session
        case canceled
    }

    @_spi(STP) @frozen public enum TokenResult {
        // User completed the financialConnections session
        case completed(result: (session: StripeAPI.FinancialConnectionsSession,
                                token: StripeAPI.BankAccountToken?))
        // Failed with error
        case failed(error: Error)
        // User canceled out of the financialConnections session
        case canceled
    }

    // MARK: - Properties

    /**
     The client secret of the Stripe FinancialConnectionsSession object.
     See https://stripe.com/docs/api/financial_connections/sessions/object#financial_connections_session_object-client_secret
     */
    public let financialConnectionsSessionClientSecret: String

    /// The APIClient instance used to make requests to Stripe
    public var apiClient: STPAPIClient = STPAPIClient.shared

    /// Completion block called when the sheet is closed or fails to open
    private var completion: ((Result) -> Void)?

    // Analytics client to use for logging analytics
    @_spi(STP) public let analyticsClient: STPAnalyticsClientProtocol

    // MARK: - Init

    /**
     Initializes a `FinancialConnectionsSheet`.

     - Parameters:
       - financialConnectionsSessionClientSecret: The [client secret](https://stripe.com/docs/api/financial_connections/sessions/object#financial_connections_session_object-client_secret) of a Stripe FinancialConnectionsSession object.
     */
    public convenience init(financialConnectionsSessionClientSecret: String) {
        self.init(financialConnectionsSessionClientSecret: financialConnectionsSessionClientSecret, analyticsClient: STPAnalyticsClient.sharedClient)
    }

    init(financialConnectionsSessionClientSecret: String,
         analyticsClient: STPAnalyticsClientProtocol) {
        self.financialConnectionsSessionClientSecret = financialConnectionsSessionClientSecret
        self.analyticsClient = analyticsClient

        analyticsClient.addClass(toProductUsageIfNecessary: FinancialConnectionsSheet.self)
    }

    // MARK: - Public

    @_spi(STP) public func presentForToken(from presentingViewController: UIViewController,
                                           completion: @escaping (TokenResult) -> ()) {
        present(from: presentingViewController) { result in
            switch (result) {
            case .completed(session: let session):
                completion(.completed(result: (session: session, token: session.bankAccountToken)))
            case .failed(error: let error):
                completion(.failed(error: error))
            case .canceled:
                completion(.canceled)
            }
        }
    }

    /**
     Presents a sheet for a customer to connect their financial account.
     - Parameters:
       - presentingViewController: The view controller to present the financial connections sheet.
       - completion: Called with the result of the financial connections session after the financial connections  sheet is dismissed.
     */
    public func present(from presentingViewController: UIViewController,
                        completion: @escaping (Result) -> ()) {
        // Overwrite completion closure to retain self until called
        let completion: (Result) -> Void = { result in
            self.analyticsClient.log(analytic: FinancialConnectionsSheetCompletionAnalytic.make(
                clientSecret: self.financialConnectionsSessionClientSecret,
                result: result
            ))
            completion(result)
            self.completion = nil
        }
        self.completion = completion

        // Guard against basic user error
        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            let error = FinancialConnectionsSheetError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            completion(.failed(error: error))
            return
        }

        let accountFetcher = FinancialConnectionsAccountAPIFetcher(api: apiClient, clientSecret: financialConnectionsSessionClientSecret)
        let sessionFetcher = FinancialConnectionsSessionAPIFetcher(api: apiClient, clientSecret: financialConnectionsSessionClientSecret, accountFetcher: accountFetcher)
        let hostViewController = FinancialConnectionsHostViewController(financialConnectionsSessionClientSecret: financialConnectionsSessionClientSecret,
                                                                        apiClient: apiClient,
                                                                        sessionFetcher: sessionFetcher)
        hostViewController.delegate = self

        let navigationController = UINavigationController(rootViewController: hostViewController)
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationController.modalPresentationStyle = .fullScreen
        }
        analyticsClient.log(analytic: FinancialConnectionsSheetPresentedAnalytic(clientSecret: self.financialConnectionsSessionClientSecret))
        presentingViewController.present(navigationController, animated: true)
    }
}

// MARK: - FinancialConnectionsHostViewControllerDelegate

extension FinancialConnectionsSheet: FinancialConnectionsHostViewControllerDelegate {
    func financialConnectionsHostViewController(_ viewController: FinancialConnectionsHostViewController, didFinish result: Result) {
        viewController.dismiss(animated: true, completion: {
            self.completion?(result)
        })
    }
}

// MARK: - STPAnalyticsProtocol

/// :nodoc:
@_spi(STP)
extension FinancialConnectionsSheet: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier = "FinancialConnectionsSheet"
}
