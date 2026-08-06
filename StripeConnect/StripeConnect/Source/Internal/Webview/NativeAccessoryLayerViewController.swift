//
//  NativeAccessoryLayerViewController.swift
//  StripeConnect
//

import UIKit
import WebKit

final class NativeAccessoryLayerViewController: UIViewController {
    static let requestCloseEventName = "stripe-connect-native-layer-request-close"

    private static let largeContentTopPadding: CGFloat = 24

    private enum SizingMode: String {
        case fit
        case large
    }

    let webView: WKWebView
    var didClose: (() -> Void)?

    private let contentHeightHandler: ContentHeightMessageHandler
    private let contentHeightMessageHandlerName: String
    private let userContentController: WKUserContentController
    private var contentHeight: CGFloat = 320
    private var sizingMode: SizingMode = .fit
    private var isClosing = false

    init(
        configuration: WKWebViewConfiguration,
        nativeLayerId: String,
        prefersLargeDetent: Bool,
        name: String?
    ) {
        let contentHeightHandler = ContentHeightMessageHandler()
        let contentHeightMessageHandlerName = "nativeAccessoryLayer_\(nativeLayerId)"
        self.contentHeightHandler = contentHeightHandler
        self.contentHeightMessageHandlerName = contentHeightMessageHandlerName
        userContentController = configuration.userContentController

        configuration.userContentController.add(
            contentHeightHandler,
            name: contentHeightMessageHandlerName
        )

        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(nibName: nil, bundle: nil)

        contentHeightHandler.didReceiveHeight = { [weak self] height in
            self?.updateContentHeight(height)
        }

        sizingMode = prefersLargeDetent ? .large : .fit
        title = name
        webView.accessibilityLabel = name
        modalPresentationStyle = .pageSheet
        configureSheetPresentation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        userContentController.removeScriptMessageHandler(
            forName: contentHeightMessageHandlerName
        )
    }

    override func loadView() {
        let containerView = UIView()
        containerView.backgroundColor = .systemBackground
        webView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(webView)

        let topPadding = sizingMode == .large ? Self.largeContentTopPadding : 0
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: topPadding),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
        ])

        view = containerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView.uiDelegate = self
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        view.backgroundColor = .systemBackground
        presentationController?.delegate = self
    }

    private func configureSheetPresentation() {
        guard let sheetPresentationController else { return }

        sheetPresentationController.prefersGrabberVisible = true
        sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = false

        if #available(iOS 16.0, *) {
            switch sizingMode {
            case .fit:
                let contentDetentIdentifier = UISheetPresentationController.Detent.Identifier(
                    "stripe-connect-content"
                )
                sheetPresentationController.detents = [
                    .custom(identifier: contentDetentIdentifier) { [weak self] context in
                        guard let self else { return min(320, context.maximumDetentValue) }
                        return min(max(self.contentHeight, 120), context.maximumDetentValue)
                    },
                ]
                sheetPresentationController.selectedDetentIdentifier = contentDetentIdentifier
            case .large:
                sheetPresentationController.detents = [.large()]
                sheetPresentationController.selectedDetentIdentifier = .large
            }
        } else {
            switch sizingMode {
            case .fit:
                sheetPresentationController.detents = [.medium()]
                sheetPresentationController.selectedDetentIdentifier = .medium
            case .large:
                sheetPresentationController.detents = [.large()]
                sheetPresentationController.selectedDetentIdentifier = .large
            }
        }
    }

    private func updateContentHeight(_ height: CGFloat) {
        guard height.isFinite, height > 0 else { return }
        contentHeight = height
        preferredContentSize.height = height

        if #available(iOS 16.0, *) {
            sheetPresentationController?.invalidateDetents()
        }
    }

    private func requestClose() {
        let eventName = Self.requestCloseEventName
        webView.evaluateJavaScript("window.dispatchEvent(new Event('\(eventName)'))")
    }

    private func close() {
        guard !isClosing else { return }
        isClosing = true
        dismiss(animated: true) { [weak self] in
            self?.didClose?()
        }
    }

}

extension NativeAccessoryLayerViewController: WKUIDelegate {
    func webViewDidClose(_ webView: WKWebView) {
        close()
    }
}

extension NativeAccessoryLayerViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        false
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        requestClose()
    }
}

private final class ContentHeightMessageHandler: NSObject, WKScriptMessageHandler {
    var didReceiveHeight: ((CGFloat) -> Void)?

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let payload = message.body as? [String: Any],
              let height = payload["height"] as? NSNumber else {
            return
        }
        didReceiveHeight?(CGFloat(truncating: height))
    }
}
