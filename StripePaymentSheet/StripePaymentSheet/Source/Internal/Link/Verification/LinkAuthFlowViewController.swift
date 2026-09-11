// Copyright © 2026 Stripe, Inc. All rights reserved.

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

/// Hosts auth screens within the custom dialog or the existing Link bottom sheet.
final class LinkAuthFlowViewController: UIViewController {
    let coordinator: LinkAuthFlowCoordinator
    var onFinish: ((LinkVerificationResult) -> Void)?
    var onNavigationUpdate: (() -> Void)?
    private(set) var didPresentWebFallback = false

    private let mode: LinkVerificationView.Mode
    private let account: PaymentSheetLinkAccount
    private let appearance: LinkAppearance?
    private let otpController: LinkVerificationViewController
    private lazy var phoneController = LinkPhoneMatchViewController(account: account, coordinator: coordinator, appearance: appearance)
    private let header: LinkVerificationView.Header
    private let contentStack = UIStackView()
    private let childContainer = UIView()
    private let statusController = UIViewController()
    private let statusLabel = UILabel()
    private var activeController: UIViewController?
    private var timer: Timer?
    private var lastInputRevision = -1
    private var webController: LinkVerificationWebFallbackController?

    init(
        mode: LinkVerificationView.Mode = .modal,
        linkAccount: PaymentSheetLinkAccount,
        brand: LinkBrand,
        appearance: LinkAppearance? = nil,
        allowLogoutInDialog: Bool = false,
        consentViewModel: LinkConsentViewModel? = nil,
        capabilities: [SupportedVerificationType] = SupportedVerificationType.nativeCapabilities
    ) {
        self.mode = mode
        self.account = linkAccount
        self.appearance = appearance
        let consentGranted: Bool? = if case .inline = consentViewModel { true } else { nil }
        coordinator = LinkAuthFlowCoordinator(account: linkAccount, capabilities: capabilities, consentGranted: consentGranted)
        header = LinkVerificationView.Header(brand: brand)
        otpController = LinkVerificationViewController(
            mode: mode,
            linkAccount: linkAccount,
            brand: brand,
            appearance: appearance,
            allowLogoutInDialog: allowLogoutInDialog,
            consentViewModel: consentViewModel,
            coordinator: coordinator
        )
        super.init(nibName: nil, bundle: nil)
        if mode.requiresModalPresentation {
            modalPresentationStyle = .custom
            transitioningDelegate = TransitioningDelegate.shared
        }
        coordinator.onUpdate = { [weak self] in self?.render() }
        coordinator.onFinish = { [weak self] result in
            self?.timer?.invalidate()
            self?.webController?.cancel()
            self?.webController = nil
            self?.onFinish?(result)
        }
        coordinator.onWebHandoff = { [weak self] url in self?.presentWeb(url) }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { timer?.invalidate() }

    override func loadView() {
        contentStack.axis = .vertical
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        if mode.requiresModalPresentation {
            let scrollView = UIScrollView()
            scrollView.addSubview(contentStack)
            view = scrollView
            NSLayoutConstraint.activate([
                contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
                contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
                contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
                contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
                contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            ])
            view.layer.cornerRadius = LinkUI.largeCornerRadius
            view.clipsToBounds = true
            let headerContainer = UIView()
            headerContainer.addSubview(header)
            header.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                header.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 20),
                header.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
                header.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 20),
                header.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -20),
                header.heightAnchor.constraint(equalToConstant: header.intrinsicContentSize.height),
            ])
            contentStack.addArrangedSubview(headerContainer)
        } else {
            view = UIView()
            view.addSubview(contentStack)
            NSLayoutConstraint.activate([
                contentStack.topAnchor.constraint(equalTo: view.topAnchor),
                contentStack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
        }
        view.backgroundColor = .linkSurfacePrimary
        contentStack.addArrangedSubview(childContainer)
        header.closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        header.backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        statusLabel.numberOfLines = 0
        statusLabel.textAlignment = .center
        statusLabel.font = LinkUI.font(forTextStyle: .body)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.textColor = .linkTextSecondary
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusController.view.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: statusController.view.topAnchor, constant: 40),
            statusLabel.bottomAnchor.constraint(equalTo: statusController.view.bottomAnchor, constant: -40),
            statusLabel.leadingAnchor.constraint(equalTo: statusController.view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: statusController.view.trailingAnchor, constant: -20),
            statusController.view.heightAnchor.constraint(greaterThanOrEqualToConstant: 180),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        coordinator.prepare()
        render()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        coordinator.start()
        focusCurrentScreen()
        if timer == nil {
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.otpController.render() }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        (presentationController as? PresentationController)?.updatePresentedViewFrame()
    }

    func fittingHeight(width: CGFloat) -> CGFloat {
        let contentHeight = activeController?.view.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel).height ?? 0
        return contentHeight + (mode.requiresModalPresentation ? 20 + header.intrinsicContentSize.height : 0)
    }

    @objc func close() { coordinator.cancel() }
    @objc func back() { coordinator.goBack() }

    private func render() {
        guard isViewLoaded else { return }
        header.showsBackButton = coordinator.showsBackButton
        header.backButton.isEnabled = coordinator.canGoBack
        let next: UIViewController
        switch coordinator.screen {
        case .otp:
            otpController.render()
            next = otpController
        case .phoneMatch:
            phoneController.render()
            next = phoneController
        case .loading, .blocked, .webHandoff:
            statusLabel.text = coordinator.errorMessage ?? STPLocalizedString("Verifying your account…", "Link authentication in progress.")
            next = statusController
        }
        let changed = activeController !== next
        if changed {
            view.endEditing(true)
            activeController?.willMove(toParent: nil)
            activeController?.view.removeFromSuperview()
            activeController?.removeFromParent()
            addChild(next)
            childContainer.addSubview(next.view)
            next.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                next.view.topAnchor.constraint(equalTo: childContainer.topAnchor),
                next.view.bottomAnchor.constraint(equalTo: childContainer.bottomAnchor),
                next.view.leadingAnchor.constraint(equalTo: childContainer.leadingAnchor),
                next.view.trailingAnchor.constraint(equalTo: childContainer.trailingAnchor),
            ])
            next.didMove(toParent: self)
            activeController = next
        }
        // Initial rendering can precede presentation. Let UIKit size the modal before forcing layout.
        if let presentation = presentationController as? PresentationController,
           let containerView = presentation.containerView,
           containerView.bounds.width > 0 {
            UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.2) {
                presentation.updatePresentedViewFrame()
                self.view.layoutIfNeeded()
            }
        }
        onNavigationUpdate?()
        if changed || lastInputRevision != coordinator.inputRevision {
            lastInputRevision = coordinator.inputRevision
            if view.window != nil { focusCurrentScreen() }
            if changed { UIAccessibility.post(notification: .screenChanged, argument: next.view) }
        }
    }

    private func focusCurrentScreen() {
        switch coordinator.screen {
        case .otp: otpController.focusCode()
        case .phoneMatch: phoneController.focusPhone()
        case .loading, .blocked, .webHandoff: view.endEditing(true)
        }
    }

    private func presentWeb(_ url: URL) {
        didPresentWebFallback = true
        let controller = LinkVerificationWebFallbackController(authenticationUrl: url, presentingWindow: view.window)
        webController = controller
        controller.present { [weak self] result in
            DispatchQueue.main.async {
                self?.webController = nil
                self?.coordinator.webHandoffFinished(result)
            }
        }
    }
}

extension LinkAuthFlowViewController {
    final class TransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
        static let shared = TransitioningDelegate()
        func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
            PresentationController(presentedViewController: presented, presenting: presenting)
        }
    }
}
