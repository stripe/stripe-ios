//
//  ConnectionsSheet.swift
//  StripeConnections
//
//  Created by Vardges Avetisyan on 11/10/21.
//

import UIKit
@_spi(STP) import StripeCore

final public class ConnectionsSheet {

    // MARK: - Types

    @frozen public enum Result {
        // User completed the connections session
        case completed(session: StripeAPI.LinkAccountSession)
        // Failed with error
        case failed(error: Error)
        // User canceled out of the connections session
        case canceled
    }

    // MARK: - Properties

    public let linkAccountSessionClientSecret: String

    /// The APIClient instance used to make requests to Stripe
    public var apiClient: STPAPIClient = STPAPIClient.shared

    /// Completion block called when the sheet is closed or fails to open
    private var completion: ((Result) -> Void)?

    // Analytics client to use for logging analytics
    //
    // NOTE: Swift 5.4 introduced a fix where private vars couldn't conform to @_spi protocols
    // See https://github.com/apple/swift/commit/5f5372a3fca19e7fd9f67e79b7f9ddbc12e467fe
    #if swift(<5.4)
    /// :nodoc:
    @_spi(STP) public let analyticsClient: STPAnalyticsClientProtocol
    #else
    private let analyticsClient: STPAnalyticsClientProtocol
    #endif

    // MARK: - Init

    public convenience init(linkAccountSessionClientSecret: String) {
        self.init(linkAccountSessionClientSecret: linkAccountSessionClientSecret, analyticsClient: STPAnalyticsClient.sharedClient)
    }

    init(linkAccountSessionClientSecret: String,
         analyticsClient: STPAnalyticsClientProtocol) {
        self.linkAccountSessionClientSecret = linkAccountSessionClientSecret
        self.analyticsClient = analyticsClient

        analyticsClient.addClass(toProductUsageIfNecessary: ConnectionsSheet.self)
    }

    // MARK: - Public

    public func present(from presentingViewController: UIViewController,
                        completion: @escaping (Result) -> ()) {
        // Overwrite completion closure to retain self until called
        let completion: (Result) -> Void = { result in
            self.analyticsClient.log(analytic: ConnectionsSheetCompletionAnalytic.make(
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
            let error = ConnectionsSheetError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            completion(.failed(error: error))
            return
        }

        let accountFetcher = LinkedAccountAPIFetcher(api: apiClient, clientSecret: linkAccountSessionClientSecret)
        let linkAccountSessionFetcher = LinkAccountSessionAPIFetcher(api: apiClient, clientSecret: linkAccountSessionClientSecret, accountFetcher: accountFetcher)
        let hostViewController = ConnectionsHostViewController(linkAccountSessionClientSecret: linkAccountSessionClientSecret,
                                                               apiClient: apiClient,
                                                               linkAccountSessionFetcher: linkAccountSessionFetcher)
        hostViewController.delegate = self

        let navigationController = UINavigationController(rootViewController: hostViewController)
        analyticsClient.log(analytic: ConnectionsSheetPresentedAnalytic(clientSecret: self.linkAccountSessionClientSecret))
        presentingViewController.present(navigationController, animated: true)
    }
}

// MARK: - ConnectionsHostViewControllerDelegate

extension ConnectionsSheet: ConnectionsHostViewControllerDelegate {
    func connectionsHostViewController(_ viewController: ConnectionsHostViewController, didFinish result: Result) {
        viewController.dismiss(animated: true, completion: {
            self.completion?(result)
        })
    }
}

// MARK: - STPAnalyticsProtocol

/// :nodoc:
@_spi(STP)
extension ConnectionsSheet: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier = "ConnectionsSheet"
}
