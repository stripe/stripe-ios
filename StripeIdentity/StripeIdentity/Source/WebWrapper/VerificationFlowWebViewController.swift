//
//  VerificationFlowWebViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 3/3/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
import AVKit
import WebKit
@_spi(STP) import StripeCore

@available(iOS 14.3, *)
@available(iOSApplicationExtension, unavailable)
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
 */
@available(iOS 14.3, *)
@available(iOSApplicationExtension, unavailable)
final class VerificationFlowWebViewController: UIViewController {

    weak var delegate: VerificationFlowWebViewControllerDelegate?

    private(set) var verificationWebView: VerificationFlowWebView?
    
    private let startUrl: URL

    /// Result to return to the delegate when the ViewController is closed
    private var result: IdentityVerificationSheet.VerificationFlowResult = .flowCanceled

    init(
        startUrl: URL,
        delegate: VerificationFlowWebViewControllerDelegate?
    ) {
        self.startUrl = startUrl
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        setupNavbar()
    }

    /**
     Instantiates a new `VerificationFlowWebViewController`.
     - Parameters:
       - clientSecret: The VerificationSession client secret.
       - delegate: Optional delegate for the `VerificationFlowWebViewController`
     */
    convenience init(
        clientSecret: VerificationClientSecret,
        delegate: VerificationFlowWebViewControllerDelegate?
    ) {
        self.init(
            startUrl: VerifyWebURLHelper.startURL(fromToken: clientSecret.urlToken),
            delegate: delegate
        )
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
        
        // Set the background color while we wait for the use to grant camera
        // permissions, otherwise the view controller is transparent while the
        // camera permissions prompt is displayed.
        if verificationWebView == nil {
            view.backgroundColor = .systemBackground
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        // Since `viewWillAppear` can be called multiple times, only setup the webView once.
        guard self.verificationWebView == nil else {
            return
        }

        // NOTE(mludowise|RUN_IDPROD-1210): Ask for camera permissions prior to
        // instantiating the webView, otherwise the `getUserMedia` returns
        // `undefined` in Javascript on iOS 14.6.
        requestCameraPermissionsIfNeeded(completion: { [weak self] in
            guard let self = self else { return }

            self.verificationWebView = VerificationFlowWebView(initialURL: self.startUrl)

            // Install view
            if self.verificationWebView !== self.view {
                self.verificationWebView?.frame = self.view.frame
                self.view = self.verificationWebView
            }

            // Set delegate
            self.verificationWebView?.delegate = self

            // Load webView
            self.verificationWebView?.load()
        })
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.verificationFlowWebViewController(self, didFinish: result)
    }
}

// MARK: - Private

@available(iOS 14.3, *)
@available(iOSApplicationExtension, unavailable)
private extension VerificationFlowWebViewController {
    func setupNavbar() {
        title = STPLocalizedString("Verify your identity", "Displays in the navigation bar title of the Identity Verification Sheet")
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: String.Localized.close,
            style: .plain,
            target: self,
            action: #selector(didTapCloseButton)
        )
    }

    func requestCameraPermissionsIfNeeded(completion: @escaping () -> Void) {
        // NOTE: We won't do anything different if the user does vs. doesn't
        // grant camera access. The web flow already handles both cases.
        switch AVCaptureDevice.authorizationStatus(for: .video) {

        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { _ in
                DispatchQueue.main.async {
                    completion()
                }
            }
            
        case .authorized,
             .denied,
             .restricted:
            completion()
            
        @unknown default:
            completion()
        }
    }

    @objc
    func didTapCloseButton() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - VerificationFlowWebViewDelegate

@available(iOS 14.3, *)
@available(iOSApplicationExtension, unavailable)
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
