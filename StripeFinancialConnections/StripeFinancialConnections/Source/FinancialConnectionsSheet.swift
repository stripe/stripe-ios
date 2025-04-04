//
//  FinancialConnectionsSheet.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 11/10/21.
//

@_spi(STP) import StripeCore
import UIKit

/**
 A drop-in class that presents a sheet for a user to connect their financial accounts.
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

    @frozen public enum TokenResult {
        /// User completed the financialConnections session
        case completed(
            result: (
                session: StripeAPI.FinancialConnectionsSession,
                token: StripeAPI.BankAccountToken?
            )
        )
        /// Failed with error
        case failed(error: Error)
        /// User canceled out of the financialConnections session
        case canceled

        /// Convenience initializer that extracts token from session
        static func completed(session: StripeAPI.FinancialConnectionsSession) -> Self {
            .completed(result: (session: session, token: session.bankAccountToken))
        }
    }

    /// Configuration for the Financial Connections Sheet.
    public struct Configuration {
        /// Style options for colors in Financial Connections.
        @frozen public enum UserInterfaceStyle {
            /// (default)  Financial Connections will automatically switch between light and dark mode compatible colors based on device settings.
            case automatic

            /// Financial Connections will always use colors appropriate for light mode UI.
            case alwaysLight

            /// Financial Connections will always use colors appropriate for dark mode UI.
            case alwaysDark

            /// Applies the specified user interface style to the given view controller.
            func configure(_ viewController: UIViewController?) {
                guard let viewController else { return }

                switch self {
                case .automatic:
                    break
                case .alwaysLight:
                    viewController.overrideUserInterfaceStyle = .light
                case .alwaysDark:
                    viewController.overrideUserInterfaceStyle = .dark
                }
            }
        }

        public var style: UserInterfaceStyle

        public init(style: UserInterfaceStyle = .automatic) {
            self.style = style
        }
    }

    // MARK: - Properties

    /**
     The client secret of the Stripe FinancialConnectionsSession object.
     See https://stripe.com/docs/api/financial_connections/sessions/object#financial_connections_session_object-client_secret
     */
    public let financialConnectionsSessionClientSecret: String

    /// A URL that redirects back to your app that FinancialConnectionsSheet can use
    /// get back to your app after completing authentication in another app (such as bank app or Safari).
    public let returnURL: String?

    /// The `onEvent` closure is triggered upon the occurrence of specific events
    /// during the process of a user connecting their financial accounts.
    ///
    /// Refer to `FinancialConnectionsEvent.Name` for a list of possible event types.
    ///
    /// Every `FinancialConnectionsEvent` can carry additional metadata,
    /// the content of which can vary based on the specific type of occurring event.
    public var onEvent: ((FinancialConnectionsEvent) -> Void)?

    /// The APIClient instance used to make requests to Stripe
    public var apiClient: STPAPIClient = STPAPIClient.shared {
        didSet {
            APIVersion.configureFinancialConnectionsAPIVersion(apiClient: apiClient)
        }
    }

    /// Contains all configurable properties of Financial Connections.
    public let configuration: FinancialConnectionsSheet.Configuration

    /// An internal result type that holds a `HostControllerResult` and an optional Link Account Session ID for logging.
    private typealias HostControllerOutcome = (result: HostControllerResult, sessionId: String?)
    /// Completion block called when the sheet is closed or fails to open
    private var completion: ((HostControllerOutcome) -> Void)?

    private var hostController: HostController?

    private var wrapperViewController: ModalPresentationWrapperViewController?

    /// Any additional Elements context useful for the Financial Connections SDK.
    @_spi(STP) public var elementsSessionContext: StripeCore.ElementsSessionContext?

    /// Analytics client to use for logging analytics
    @_spi(STP) public let analyticsClient: STPAnalyticsClientProtocol

    // MARK: - Init

    /**
     Initializes a `FinancialConnectionsSheet`.

     - Parameters:
       - financialConnectionsSessionClientSecret: The [client secret](https://stripe.com/docs/api/financial_connections/sessions/object#financial_connections_session_object-client_secret) of a Stripe FinancialConnectionsSession object.
       - returnURL: A URL that redirects back to your application. FinancialConnectionsSheet uses it after completing authentication in another application (such as a bank application or Safari).
       - configuration: Allows configuring the FinancialConnectionsSheet, such as style options for appearance preferences.
     */
    public convenience init(
        financialConnectionsSessionClientSecret: String,
        returnURL: String? = nil,
        configuration: FinancialConnectionsSheet.Configuration = .init()
    ) {
        self.init(
            financialConnectionsSessionClientSecret: financialConnectionsSessionClientSecret,
            returnURL: returnURL,
            configuration: configuration,
            analyticsClient: STPAnalyticsClient.sharedClient
        )
    }

    init(
        financialConnectionsSessionClientSecret: String,
        returnURL: String?,
        configuration: FinancialConnectionsSheet.Configuration,
        analyticsClient: STPAnalyticsClientProtocol
    ) {
        self.financialConnectionsSessionClientSecret = financialConnectionsSessionClientSecret
        self.returnURL = returnURL
        self.configuration = configuration
        self.analyticsClient = analyticsClient

        analyticsClient.addClass(toProductUsageIfNecessary: FinancialConnectionsSheet.self)
        APIVersion.configureFinancialConnectionsAPIVersion(apiClient: apiClient)
        PresentationManager.shared.configuration = configuration
    }

    // MARK: - Public

    /// Presents a sheet for a customer to connect their financial account. This API surfaces details on the connected bank account token.
    /// - Parameters:
    ///   - presentingViewController: The view controller to present the financial connections sheet.
    ///   - completion: The result of the financial connections session after the financial connections sheet is dismissed, along with the bank account token.
    public func presentForToken(
        from presentingViewController: UIViewController,
        completion: @escaping (TokenResult) -> Void
    ) {
        present(from: presentingViewController) { result in
            switch result {
            case .completed(let session):
                completion(.completed(session: session))
            case .failed(let error):
                completion(.failed(error: error))
            case .canceled:
                completion(.canceled)
            }
        }
    }

    /// Presents a sheet for a customer to connect their financial account. This API surfaces details on the connected bank account token.
    /// - Parameter presentingViewController: The view controller to present the financial connections sheet.
    /// - Returns: The result of the financial connections session after the financial connections sheet is dismissed, along with the bank account token.
    @MainActor
    @_spi(v25) public func presentForToken(from presentingViewController: UIViewController) async -> TokenResult {
        await withCheckedContinuation { continuation in
            presentForToken(from: presentingViewController) { (result: TokenResult) in
                continuation.resume(returning: result)
            }
        }
    }

    /**
     Presents a sheet for a customer to connect their financial account.
     - Parameters:
       - presentingViewController: The view controller to present the financial connections sheet.
       - completion: Called with the result of the financial connections session after the financial connections sheet is dismissed.
     */
    public func present(
        from presentingViewController: UIViewController,
        completion: @escaping (Result) -> Void
    ) {
        present(
            from: presentingViewController,
            completion: { hostControllerResult in
                switch hostControllerResult {
                case .completed(let completedResult):
                    switch completedResult {
                    case .financialConnections(let session):
                        completion(.completed(session: session))
                    case .instantDebits(let linkedBank):
                        // TODO(mats): Add support for instant debits.
                        let errorDescription = "Instant Debits is not currently supported via this interface."
                        let sessionInfo =
                        """
                        paymentMethodId=\(linkedBank.paymentMethod.id)
                        bankName=\(linkedBank.bankName ?? "N/A")
                        last4=\(linkedBank.last4 ?? "N/A")
                        """

                        completion(
                            .failed(
                                error: FinancialConnectionsSheetError
                                    .unknown(debugDescription: "\(errorDescription)\n\n\(sessionInfo)")
                            )
                        )
                    }
                case .canceled:
                    completion(.canceled)
                case .failed(let error):
                    completion(.failed(error: error))
                }
            }
        )
    }

    /// Presents a sheet for a customer to connect their financial account.
    /// - Parameter presentingViewController: The view controller to present the financial connections sheet.
    /// - Returns: The result of the financial connections session after the financial connections sheet is dismissed.
    @MainActor
    @_spi(v25) public func present(from presentingViewController: UIViewController) async -> Result {
        await withCheckedContinuation { continuation in
            present(from: presentingViewController) { (result: Result) in
                continuation.resume(returning: result)
            }
        }
    }

    @_spi(STP) public func present(
        from presentingViewController: UIViewController,
        completion: @escaping (HostControllerResult) -> Void
    ) {
        // Overwrite completion closure to retain self until called
        let completion: (HostControllerOutcome) -> Void = { outcome in
            self.analyticsClient.log(
                analytic: FinancialConnectionsSheetCompletionAnalytic.make(
                    linkAccountSessionId: outcome.sessionId,
                    result: outcome.result
                ),
                apiClient: self.apiClient
            )
            completion(outcome.result)
            self.completion = nil
        }
        self.completion = completion

        // Guard against basic user error
        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            let error = FinancialConnectionsSheetError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            let flowResult = HostControllerOutcome(result: .failed(error: error), sessionId: nil)
            completion(flowResult)
            return
        }

        if let urlString = returnURL {
            guard URL(string: urlString) != nil else {
                assertionFailure(
                    "invalid returnURL: \(urlString) parameter passed in when creating FinancialConnectionsSheet"
                )
                let error = FinancialConnectionsSheetError.unknown(
                    debugDescription:
                        "invalid returnURL: \(urlString) parameter passed in when creating FinancialConnectionsSheet"
                )
                let flowResult = HostControllerOutcome(result: .failed(error: error), sessionId: nil)
                completion(flowResult)
                return
            }
        }

        let financialConnectionsApiClient: any FinancialConnectionsAPI = FinancialConnectionsAsyncAPIClient(apiClient: apiClient)
        hostController = HostController(
            apiClient: financialConnectionsApiClient,
            analyticsClientV1: analyticsClient,
            clientSecret: financialConnectionsSessionClientSecret,
            returnURL: returnURL,
            configuration: configuration,
            elementsSessionContext: elementsSessionContext,
            publishableKey: apiClient.publishableKey,
            stripeAccount: apiClient.stripeAccount
        )
        hostController?.delegate = self

        analyticsClient.log(
            analytic: FinancialConnectionsSheetPresentedAnalytic(
                // We don't have the session ID yet.
                linkAccountSessionId: nil
            ),
            apiClient: apiClient
        )
        let navigationController = hostController!.navigationController
        present(navigationController, presentingViewController)
    }

    private func present(
        _ navigationController: FinancialConnectionsNavigationController,
        _ presentingViewController: UIViewController
    ) {
        let toPresent: UIViewController
        let animated: Bool
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationController.modalPresentationStyle = .formSheet
            toPresent = navigationController
            animated = true
        } else {
            wrapperViewController = ModalPresentationWrapperViewController(vc: navigationController)
            toPresent = wrapperViewController!
            animated = false
        }
        PresentationManager.shared.present(toPresent, from: presentingViewController, animated: animated)
    }
}

// MARK: - HostControllerDelegate

/// :nodoc:
extension FinancialConnectionsSheet: HostControllerDelegate {
    func hostController(
        _ hostController: HostController,
        viewController: UIViewController,
        didFinish result: HostControllerResult,
        linkAccountSessionId: String?
    ) {
        viewController.dismiss(
            animated: true,
            completion: {
                let flowResult = HostControllerOutcome(result: result, sessionId: linkAccountSessionId)
                if let wrapperViewController = self.wrapperViewController {
                    wrapperViewController.dismiss(
                        animated: false,
                        completion: {
                            self.completion?(flowResult)
                        }
                    )
                    self.wrapperViewController = nil
                } else {
                    self.completion?(flowResult)
                }
            }
        )
    }

    func hostController(_ hostController: HostController, didReceiveEvent event: FinancialConnectionsEvent) {
        onEvent?(event)
    }
}

// MARK: - STPAnalyticsProtocol

/// :nodoc:
@_spi(STP)
extension FinancialConnectionsSheet: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier = "FinancialConnectionsSheet"
}
