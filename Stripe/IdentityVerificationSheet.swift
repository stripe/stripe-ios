//
//  IdentityVerificationSheet.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 3/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/**
 A drop-in class that presents a sheet for a user to verify their identity.
 This class is in beta; see {{TODO(mludowise|IDPROD-1440): link to docs}} for access
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
     See {{TODO(mludowise|IDPROD-1440): link to docs}}
     */
    public let verificationSessionClientSecret: String

    /**
     Initializes an `IdentityVerificationSheet`
     - Parameters:
       - verificationSessionClientSecret: The client secret of the Stripe VerificationSession object.
     */
    public init(verificationSessionClientSecret: String) {
        self.verificationSessionClientSecret = verificationSessionClientSecret
    }

    /**
     Presents a sheet for a customer to verify their identity.
     - Parameters:
       - presentingViewController: The view controller to present the identity verification sheet.
       - completion: Called with the result of the verification session after the identity verification sheet is dismissed.
     */
    @available(iOS 14.3, *)
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
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
     */
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    func presentInternal(
        from presentingViewController: UIViewController,
        completion: @escaping (VerificationFlowResult) -> Void
    ) {
        // Overwrite completion closure to retain self until called
        let completion: (VerificationFlowResult) -> Void = { result in
            // TODO(mludowise|IDPROD-1438): Add analytics to log completion or error
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

        // Validate client secret
        guard let clientSecret = VerificationClientSecret(string: verificationSessionClientSecret) else {
            completion(.flowFailed(error: IdentityVerificationSheetError.invalidClientSecret))
            return
        }

        let navigationController = VerificationFlowWebViewController.makeInNavigationController(
            clientSecret: clientSecret,
            delegate: self
        )
        // TODO(mludowise|IDPROD-1438): Add analytics for starting flow
        presentingViewController.present(navigationController, animated: true)
    }

    // MARK: - Private

    private var completion: ((VerificationFlowResult) -> Void)?
}

// MARK: - VerificationFlowWebViewControllerDelegate

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension IdentityVerificationSheet: VerificationFlowWebViewControllerDelegate {
    func verificationFlowWebViewController(_ viewController: VerificationFlowWebViewController, didFinish result: VerificationFlowResult) {
        completion?(result)
    }
}
