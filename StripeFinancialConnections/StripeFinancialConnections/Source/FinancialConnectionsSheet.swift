//
//  FinancialConnectionsSheet.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/10/21.
//

import UIKit
@_spi(STP) import StripeCore

final public class FinancialConnectionsSheet {

    // MARK: - Types

    @frozen public enum Result {
        // User completed the financialConnections session
        case completed(session: StripeAPI.LinkAccountSession)
        // Failed with error
        case failed(error: Error)
        // User canceled out of the financialConnections session
        case canceled
    }

    @_spi(STP) @frozen public enum TokenResult {
        // User completed the financialConnections session
        case completed(result: (session: StripeAPI.LinkAccountSession,
                                token: StripeAPI.BankAccountToken?))
        // Failed with error
        case failed(error: Error)
        // User canceled out of the financialConnections session
        case canceled
    }

    // MARK: - Properties

    public let linkAccountSessionClientSecret: String

    /// The APIClient instance used to make requests to Stripe
    public var apiClient: STPAPIClient = STPAPIClient.shared

    /// Completion block called when the sheet is closed or fails to open
    private var completion: ((Result) -> Void)?

    // Analytics client to use for logging analytics
    @_spi(STP) public let analyticsClient: STPAnalyticsClientProtocol

    // MARK: - Init

    public convenience init(linkAccountSessionClientSecret: String) {
        self.init(linkAccountSessionClientSecret: linkAccountSessionClientSecret, analyticsClient: STPAnalyticsClient.sharedClient)
    }

    init(linkAccountSessionClientSecret: String,
         analyticsClient: STPAnalyticsClientProtocol) {
        self.linkAccountSessionClientSecret = linkAccountSessionClientSecret
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

    public func present(from presentingViewController: UIViewController,
                        completion: @escaping (Result) -> ()) {
        // Overwrite completion closure to retain self until called
        let completion: (Result) -> Void = { result in
            self.analyticsClient.log(analytic: FinancialConnectionsSheetCompletionAnalytic.make(
                clientSecret: self.linkAccountSessionClientSecret,
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

        let accountFetcher = LinkedAccountAPIFetcher(api: apiClient, clientSecret: linkAccountSessionClientSecret)
        let linkAccountSessionFetcher = LinkAccountSessionAPIFetcher(api: apiClient, clientSecret: linkAccountSessionClientSecret, accountFetcher: accountFetcher)
        let hostViewController = FinancialConnectionsHostViewController(linkAccountSessionClientSecret: linkAccountSessionClientSecret,
                                                                        apiClient: apiClient,
                                                                        linkAccountSessionFetcher: linkAccountSessionFetcher)
        hostViewController.delegate = self

        let navigationController = UINavigationController(rootViewController: hostViewController)
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationController.modalPresentationStyle = .fullScreen
        }
        analyticsClient.log(analytic: FinancialConnectionsSheetPresentedAnalytic(clientSecret: self.linkAccountSessionClientSecret))
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
