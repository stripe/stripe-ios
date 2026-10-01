//
//  NativeAccessoryLayerViewController.swift
//  StripeConnect
//

import UIKit
import WebKit

final class NativeAccessoryLayerViewController: UIViewController {
    static let requestCloseEventName = "stripe-connect-native-layer-request-close"

    private static let largeContentTopPadding: CGFloat = 24
    /// How long to wait for web content before presenting the sheet anyway.
    private static let presentationTimeout: TimeInterval = 1.0

    private enum SizingMode: String {
        case fit
        case large
    }

    let webView: WKWebView
    var didClose: (() -> Void)?

    private let messageHandler: NativeLayerMessageHandler
    private let messageHandlerName: String
    private let userContentController: WKUserContentController
    private var contentHeight: CGFloat = 320
    private var sizingMode: SizingMode = .fit
    private var isClosing = false
    private let sheetBackgroundColor: UIColor
    private let textColor: UIColor

    // Native header, shown when the web content sends its title (see `NativeLayerMessage.chrome`).
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let closeButton = UIButton(type: .close)
    private var webViewTopToContainer: NSLayoutConstraint?
    private var webViewTopToHeader: NSLayoutConstraint?

    /// Set while the sheet is staged offscreen, waiting for content before presenting.
    private var pendingPresenter: (() -> UIViewController?)?
    private var presentationTimeoutWorkItem: DispatchWorkItem?
    private var presentationAttempts = 0

    init(
        configuration: WKWebViewConfiguration,
        nativeLayerId: String,
        prefersLargeDetent: Bool,
        name: String?,
        backgroundColor: UIColor,
        textColor: UIColor
    ) {
        sheetBackgroundColor = backgroundColor
        self.textColor = textColor
        let messageHandler = NativeLayerMessageHandler()
        let messageHandlerName = "nativeAccessoryLayer_\(nativeLayerId)"
        self.messageHandler = messageHandler
        self.messageHandlerName = messageHandlerName
        userContentController = configuration.userContentController

        configuration.userContentController.add(messageHandler, name: messageHandlerName)

        webView = WKWebView(frame: .zero, configuration: configuration)
        super.init(nibName: nil, bundle: nil)

        messageHandler.didReceive = { [weak self] message in
            switch message {
            case .height(let height):
                self?.updateContentHeight(height)
            case .chrome(let title, let subtitle):
                self?.updateHeader(title: title, subtitle: subtitle)
            }
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
        userContentController.removeScriptMessageHandler(forName: messageHandlerName)
    }

    override func loadView() {
        let containerView = UIView()
        containerView.backgroundColor = sheetBackgroundColor

        configureHeader()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.isHidden = true
        containerView.addSubview(headerView)

        webView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(webView)

        let topPadding = sizingMode == .large ? Self.largeContentTopPadding : 0
        let webViewTopToContainer = webView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: topPadding)
        let webViewTopToHeader = webView.topAnchor.constraint(equalTo: headerView.bottomAnchor)
        self.webViewTopToContainer = webViewTopToContainer
        self.webViewTopToHeader = webViewTopToHeader

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webViewTopToContainer,
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
        view.backgroundColor = sheetBackgroundColor
        presentationController?.delegate = self
    }

    // MARK: - Presentation

    /// Lays the sheet out offscreen so its web content can render and report a size, then presents it once,
    /// already at the right height. Presents anyway after a short timeout.
    ///
    /// - Parameters:
    ///   - stagingHost: A view in the window, used to lay the sheet out offscreen while it loads.
    ///   - presenter: Resolves the view controller to present from at presentation time.
    func presentWhenReady(stagingHost host: UIView, presenter: @escaping () -> UIViewController?) {
        pendingPresenter = presenter
        view.frame = CGRect(x: 0, y: host.bounds.maxY + 40, width: host.bounds.width, height: host.bounds.height * 0.6)
        host.addSubview(view)
        view.layoutIfNeeded()

        let workItem = DispatchWorkItem { [weak self] in self?.presentIfPending() }
        presentationTimeoutWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.presentationTimeout, execute: workItem)
    }

    private func presentIfPending() {
        guard let resolvePresenter = pendingPresenter, let presenter = resolvePresenter() else { return }
        // Another sheet is still animating away (e.g. the menu that opened this dialog). Present once it's gone.
        if presenter.presentedViewController != nil, presentationAttempts < 30 {
            presentationAttempts += 1
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in self?.presentIfPending() }
            return
        }
        pendingPresenter = nil
        presentationTimeoutWorkItem?.cancel()
        view.removeFromSuperview()
        presenter.present(self, animated: true)
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
                        let height = self.contentHeight + self.headerHeight
                        return min(max(height, 120), context.maximumDetentValue)
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
        preferredContentSize.height = height + headerHeight

        if pendingPresenter != nil {
            presentIfPending()
        } else if #available(iOS 16.0, *) {
            sheetPresentationController?.invalidateDetents()
        }
    }

    // MARK: - Header

    private var headerHeight: CGFloat {
        guard !headerView.isHidden else { return 0 }
        let width = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        return headerView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
    }

    private func configureHeader() {
        titleLabel.font = UIFontMetrics(forTextStyle: .headline)
            .scaledFont(for: .systemFont(ofSize: 20, weight: .bold))
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = textColor
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header

        subtitleLabel.font = UIFontMetrics(forTextStyle: .subheadline)
            .scaledFont(for: .systemFont(ofSize: 15))
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = textColor.withAlphaComponent(0.6)
        subtitleLabel.numberOfLines = 0

        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)

        let labels = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labels.axis = .vertical
        labels.spacing = 4

        let row = UIStackView(arrangedSubviews: [labels, closeButton])
        row.axis = .horizontal
        row.alignment = .top
        row.spacing = 12
        row.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setContentHuggingPriority(.required, for: .horizontal)
        headerView.addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 28),
            row.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20),
            row.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -20),
            row.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8),
        ])
    }

    private func updateHeader(title: String?, subtitle: String?) {
        loadViewIfNeeded()
        titleLabel.text = title
        titleLabel.isHidden = title == nil
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        self.title = title ?? self.title
        headerView.isHidden = false
        webViewTopToContainer?.isActive = false
        webViewTopToHeader?.isActive = true
        view.layoutIfNeeded()

        preferredContentSize.height = contentHeight + headerHeight
        if #available(iOS 16.0, *) {
            sheetPresentationController?.invalidateDetents()
        }
    }

    @objc private func closeButtonTapped() {
        requestClose()
    }

    // MARK: - Closing

    /// Asks the web content to close, so it can run its own confirmation logic.
    private func requestClose() {
        let eventName = Self.requestCloseEventName
        webView.evaluateJavaScript("window.dispatchEvent(new Event('\(eventName)'))")
    }

    private func close() {
        guard !isClosing else { return }
        isClosing = true
        if pendingPresenter != nil {
            // Closed before it was ever shown.
            pendingPresenter = nil
            presentationTimeoutWorkItem?.cancel()
            view.removeFromSuperview()
            didClose?()
            return
        }
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

private enum NativeLayerMessage {
    case height(CGFloat)
    case chrome(title: String?, subtitle: String?)
}

private final class NativeLayerMessageHandler: NSObject, WKScriptMessageHandler {
    var didReceive: ((NativeLayerMessage) -> Void)?

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        guard let payload = message.body as? [String: Any] else { return }
        if payload["type"] as? String == "chrome" {
            didReceive?(.chrome(title: payload["title"] as? String, subtitle: payload["subtitle"] as? String))
        } else if let height = payload["height"] as? NSNumber {
            didReceive?(.height(CGFloat(truncating: height)))
        }
    }
}
