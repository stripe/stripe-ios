//
//  VerificationFlowWebViewController.swift
//  StripeiOS
//
//  Created by Mel Ludowise on 3/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import WebKit

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
protocol VerificationFlowWebViewControllerDelegate: AnyObject {
    /**
     Invoked when the user has closed the `VerificationFlowWebViewController`.
     - Parameters:
       - viewController: The view controller that was closed.
       - result: The result of the user's verification flow.
                 Value is `.flowCompleted` if the user successfully completed the flow.
                 Value is `.flowCanceled` if the user closed the view controller prior to completing the flow.
     */
    func verificationFlowWebViewController(_ viewController: VerificationFlowWebViewController, didFinish result: IdentityVerificationSheet.VerificationFlowResult)
}

/**
 View controller that wraps the Identity Verification web flow. It starts at the URL
 `https://verify.stripe.com/start/{{url_token}}`

 If the user proceeds to the URL `https://verify.stripe.com/success` prior to closing the view,
 then a `.flowCompleted` result is sent to the view controller delegate's `didFinish` method.

 If the user closes the view controller prior to reaching the `/success` page, then a `.flowCanceled`
 result is sent to the view controller delegate's `didFinish` method.

 - NOTE(mludowise|RUN_MOBILESDK-120):
 This class should be marked as `@available(iOS 14.3, *)` when our CI is updated to run tests on iOS 14.
 */
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
final class VerificationFlowWebViewController: UIViewController {

    weak var delegate: VerificationFlowWebViewControllerDelegate?

    let verificationWebView: VerificationFlowWebView

    /// Result to return to the delegate when the ViewController is closed
    private var result: IdentityVerificationSheet.VerificationFlowResult = .flowCanceled

    /**
     Instantiates a new `VerificationFlowWebViewController`.
     - Parameters:
       - clientSecret: The VerificationSession client secret.
       - delegate: Optional delegate for the `VerificationFlowWebViewController`
     */
    private init(clientSecret: VerificationClientSecret,
                 delegate: VerificationFlowWebViewControllerDelegate?) {
        self.verificationWebView = VerificationFlowWebView(initialURL: VerifyWebURLHelper.startURL(fromToken: clientSecret.urlToken))
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        setupNavbar()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /**
     Instantiates a new `VerificationFlowWebViewController` inside of a navigation controller.
     - Parameters:
       - clientSecret: The VerificationSession client secret.
       - delegate: Optional delegate for the `VerificationFlowWebViewController`
     */
    static func makeInNavigationController(
        clientSecret: VerificationClientSecret,
        delegate: VerificationFlowWebViewControllerDelegate?
    ) -> UINavigationController {
        let viewController = VerificationFlowWebViewController(
            clientSecret: clientSecret,
            delegate: delegate
        )
        let navigationController = UINavigationController(rootViewController: viewController)
        return navigationController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Install view
        if verificationWebView !== view {
            verificationWebView.frame = view.frame
            view = verificationWebView
        }
        // Set delegate
        verificationWebView.delegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        verificationWebView.load()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.verificationFlowWebViewController(self, didFinish: result)
    }
}

// MARK: - Private

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
private extension VerificationFlowWebViewController {
    func setupNavbar() {
        title = STPLocalizedString("Verify your identity", "Displays in the navigation bar title of the Identity Verification Sheet")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: STPLocalizedString("Close", "Text for close button"),
            style: .plain,
            target: self,
            action: #selector(didTapCloseButton)
        )
    }

    @objc
    func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - VerificationFlowWebViewDelegate

@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension VerificationFlowWebViewController: VerificationFlowWebViewDelegate {

    func verificationFlowWebView(_ view: VerificationFlowWebView, didChangeURL url: URL?) {
        if url == VerifyWebURLHelper.successURL {
            result = .flowCompleted
        }
    }

    func verificationFlowWebViewDidFinishLoading(_ view: VerificationFlowWebView) { }

    func verificationFlowWebViewDidClose(_ view: VerificationFlowWebView) {
        dismiss(animated: true, completion: nil)
    }

    func verificationFlowWebView(_ view: VerificationFlowWebView, didOpenURLInNewTarget url: URL) {
        UIApplication.shared.open(url)
    }
}
