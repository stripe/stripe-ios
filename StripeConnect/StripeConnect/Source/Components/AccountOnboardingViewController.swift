//
//  AccountOnboardingViewController.swift
//  StripeConnect
//
//  Created by Mel Ludowise on 5/1/24.
//

import Combine
import UIKit
import WebKit

public class AccountOnboardingViewController: UIViewController {
    let webView: ComponentWebView

    private var onExit: () -> Void

    init(connectInstance: StripeConnectInstance,
         onExit: @escaping () -> Void) {
        self.onExit = onExit
        webView = ComponentWebView(
            connectInstance: connectInstance,
            componentType: "account-onboarding"
        )
        super.init(nibName: nil, bundle: nil)
        webView.presentPopup = { [weak self] vc in
            self?.present(vc, animated: true)
        }
        webView.addMessageHandler(.init(name: "componentOnExit", didReceiveMessage: { [weak self] _ in
            self?.onExit()
        }))
        webView.didFinishLoading = { webView in
            webView.evaluateJavaScript("""
            component.setOnExit(() => {
                window.webkit.messageHandlers.componentOnExit.postMessage('');
            })
            """)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        webView.preventRetainCycles()
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        webView.frame = view.frame
        view = webView
    }

    // MARK: - Public

    public struct CollectionOptions: Encodable {
        public enum FieldOption: String, Encodable {
            case currentlyDue = "currently_due"
            case eventuallyDue = "eventually_due"
        }

        public enum FutureRequirementOption: String, Encodable {
            case omit
            case include
        }

        public var fields: FieldOption = .currentlyDue
        public var futureRequirements: FutureRequirementOption = .omit

        public init() { }
    }

    public func setFullTermsOfServiceUrl(_ url: URL) {
        webView.evaluateJavaScript("component.setFullTermsOfServiceUrl(\(url.absoluteString)")
    }

    public func setRecipientTermsOfServiceUrl(_ url: URL) {
        webView.evaluateJavaScript("component.setRecipientTermsOfServiceUrl(\(url.absoluteString)")
    }

    public func setPrivacyPolicyUrl(_ url: URL) {
        webView.evaluateJavaScript("component.setPrivacyPolicyUrl(\(url.absoluteString)")
    }

    public func setSkipTermsOfServiceCollection(_ skip: Bool) {
        webView.evaluateJavaScript("component.setSkipTermsOfServiceCollection(\(skip)")
    }

    public func setCollectionOptions(_ options: CollectionOptions) {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        guard let data = try? encoder.encode(options),
            let string = String(data: data, encoding: .utf8) else {
                return
        }

        webView.evaluateJavaScript("component.setCollectionOptions(\(string)")
    }

    public func setOnExit(_ block: @escaping () -> Void) {
        self.onExit = block
    }
}
