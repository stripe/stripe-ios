//
//  IdentityVerificationSheet.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeCore

/**
 A drop-in class that presents a sheet for a user to verify their identity.
 This class is in beta; see https://stripe.com/docs/identity for access
 */
final public class IdentityVerificationSheet {

    /// The result of an attempt to finish an identity verification flow
    @frozen public enum VerificationFlowResult {
        /// User completed the verification flow
        case flowCompleted
        /// User canceled out of the flow or declined to give consent
        case flowCanceled
        /// Failed with error
        case flowFailed(error: Error)
    }

    /**
     The client secret of the Stripe VerificationSession object.
     See https://stripe.com/docs/api/identity/verification_sessions
     */
    public let verificationSessionClientSecret: String

    // TODO(mludowise|IDPROD-2542): Make non-optional when native component
    // experience is ready for release.
    // This is required to be non-null for native experience.
    private let verificationSheetController: VerificationSheetController?

    /**
     Initializes an `IdentityVerificationSheet`
     - Parameters:
       - verificationSessionClientSecret: The [client secret](https://stripe.com/docs/api/identity/verification_sessions) of a Stripe VerificationSession object.
     */
    public convenience init(verificationSessionClientSecret: String) {
        self.init(
            verificationSessionClientSecret: verificationSessionClientSecret,
            verificationSheetController: nil,
            analyticsClient: STPAnalyticsClient.sharedClient
        )
    }

    /**
     Initializes an `IdentityVerificationSheet` using native iOS components (in development) instead of a web view

     :nodoc:
     - Note: Modifying this property in a production app can lead to unexpected behavior.
     TODO(mludowise|IDPROD-2542): Remove `spi` when native component experience is ready for release.

     - Parameters:
       - verificationSessionId: The id of a Stripe [VerificationSession](https://stripe.com/docs/api/identity/verification_sessions) object.
       - ephemeralKeySecret: A short-lived token that allows the SDK to access a [VerificationSession](https://stripe.com/docs/api/identity/verification_sessions) object.
     */
    @_spi(STP) public convenience init(
        verificationSessionId: String,
        ephemeralKeySecret: String
    ) {
        self.init(
            verificationSessionClientSecret: "",
            verificationSheetController: VerificationSheetController(
                verificationSessionId: verificationSessionId,
                ephemeralKeySecret: ephemeralKeySecret
            ),
            analyticsClient: STPAnalyticsClient.sharedClient
        )
    }

    init(verificationSessionClientSecret: String,
         verificationSheetController: VerificationSheetController?,
         analyticsClient: STPAnalyticsClientProtocol) {
        self.verificationSessionClientSecret = verificationSessionClientSecret
        self.clientSecret = VerificationClientSecret(string: verificationSessionClientSecret)
        self.verificationSheetController = verificationSheetController
        self.analyticsClient = analyticsClient

        analyticsClient.addClass(toProductUsageIfNecessary: IdentityVerificationSheet.self)
        verificationSheetController?.delegate = self
    }

    /**
     Presents a sheet for a customer to verify their identity.
     - Parameters:
       - presentingViewController: The view controller to present the identity verification sheet.
       - completion: Called with the result of the verification session after the identity verification sheet is dismissed.
     */
    @available(iOS 14.3, *)
    @available(iOSApplicationExtension, unavailable)
    public func present(
        from presentingViewController: UIViewController,
        completion: @escaping (VerificationFlowResult) -> Void
    ) {
        presentInternal(from: presentingViewController, completion: completion)
    }

    /*
     TODO(mludowise|RUN_MOBILESDK-120): Internal method for `present` so we can
     call it form tests that run on versions prior to iOS 14. This can be removed
     after we've updated our CI to run tests on iOS 14.

     TODO(mludowise|IDPROD-2542): Remove SPI exposure
     */
    @available(iOSApplicationExtension, unavailable)
    @_spi(STP) public func presentInternal(
        from presentingViewController: UIViewController,
        completion: @escaping (VerificationFlowResult) -> Void
    ) {
        // Overwrite completion closure to retain self until called
        let completion: (VerificationFlowResult) -> Void = { result in
            let verificationSessionId = self.clientSecret?.verificationSessionId
                ?? self.verificationSheetController?.verificationSessionId
            self.analyticsClient.log(analytic: VerificationSheetCompletionAnalytic.make(
                verificationSessionId: verificationSessionId,
                sessionResult: result
            ))
            completion(result)
            self.completion = nil
        }
        self.completion = completion

        // Guard against basic user error
        guard presentingViewController.presentedViewController == nil else {
            assertionFailure("presentingViewController is already presenting a view controller")
            let error = IdentityVerificationSheetError.unknown(
                debugDescription: "presentingViewController is already presenting a view controller"
            )
            completion(.flowFailed(error: error))
            return
        }

        // Navigation Controller to present
        let navigationController: UINavigationController

        // VS id used to log analytics
        let verificationSessionId: String

        if let verificationSheetController = verificationSheetController {
            // Use native UI
            verificationSessionId = verificationSheetController.verificationSessionId
            navigationController = verificationSheetController.flowController.navigationController
            verificationSheetController.loadAndUpdateUI()
        } else {
            // Validate client secret
            guard let clientSecret = clientSecret else {
                completion(.flowFailed(error: IdentityVerificationSheetError.invalidClientSecret))
                return
            }

            verificationSessionId = clientSecret.verificationSessionId

            navigationController = VerificationFlowWebViewController.makeInNavigationController(
                clientSecret: clientSecret,
                delegate: self
            )
        }
        analyticsClient.log(analytic: VerificationSheetPresentedAnalytic(verificationSessionId: verificationSessionId))
        presentingViewController.present(navigationController, animated: true)
    }

    // MARK: - Private

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

    /// Completion block called when the sheet is closed or fails to open
    private var completion: ((VerificationFlowResult) -> Void)?

    /// Parsed client secret string
    private let clientSecret: VerificationClientSecret?

    // MARK: - Experimental / API Mocks

    /**
     If using native iOS components (in development), load mock data from the local file system instead of making a live request.

     :nodoc:

     TODO(mludowise|IDPROD-2734): Remove this property when endpoint is live
     */
    @_spi(STP) public func mockNativeUIAPIResponse(
        verificationPageDataFileURL: URL,
        displayErrorOnScreen: Int?
    ) {
        verificationSheetController?.apiClient = MockIdentityAPIClient(
            verificationPageDataFileURL: verificationPageDataFileURL,
            displayErrorOnScreen: displayErrorOnScreen,
            responseDelay: 1
        )
    }

    @_spi(STP) public var mockNativeUIScanTimeout: TimeInterval {
        set {
            DocumentScanner.mockTimeToFindImage = newValue
        }
        get {
            return DocumentScanner.mockTimeToFindImage
        }
    }

    @_spi(STP) public func mockCameraFeed(
        frontDocumentImageFile: URL,
        backDocumentImageFile: URL
    ) {
        verificationSheetController?.mockCameraFeed = MockIdentityDocumentCameraFeed(
            imageFiles: frontDocumentImageFile, backDocumentImageFile
        )
    }
}

// MARK: - VerificationFlowWebViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
extension IdentityVerificationSheet: VerificationFlowWebViewControllerDelegate {
    func verificationFlowWebViewController(_ viewController: VerificationFlowWebViewController, didFinish result: VerificationFlowResult) {
        completion?(result)
    }
}

// MARK: - VerificationSheetControllerDelegate

extension IdentityVerificationSheet: VerificationSheetControllerDelegate {
    func verificationSheetController(_ controller: VerificationSheetControllerProtocol, didFinish result: VerificationFlowResult) {
        completion?(result)
    }
}

// MARK: - STPAnalyticsProtocol

/// :nodoc:
@_spi(STP) extension IdentityVerificationSheet: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier = "IdentityVerificationSheet"
}
