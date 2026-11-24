// Copyright © 2026 Stripe, Inc. All rights reserved.

@_spi(InternalOnlyAPI) import StripeCore
@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/// Hosts auth screens within the custom dialog or the existing Link bottom sheet.
final class LinkAuthFlowViewController: UIViewController {
    let coordinator: LinkAuthFlowCoordinator
    var onFinish: ((LinkVerificationResult) -> Void)?
    var onNavigationUpdate: (() -> Void)?
    /// Called instead of canceling when the customer closes a flow attached to a shared coordinator.
    var onDetachRequested: (() -> Void)?
    private(set) var didPresentWebFallback = false

    private let mode: LinkVerificationView.Mode
    private let account: PaymentSheetLinkAccount
    /// False when another host owns the coordinator's callbacks and forwards them to this controller.
    private let ownsCoordinator: Bool
    private let appearance: LinkAppearance?
    private let otpController: LinkVerificationViewController
    private lazy var phoneController = LinkPhoneMatchViewController(
        account: account,
        coordinator: coordinator,
        appearance: appearance
    )
    private let header: LinkVerificationView.Header
    private let contentStack = UIStackView()
    private let childContainer = UIView()
    private let statusController = UIViewController()
    private let statusLabel = UILabel()
    private var activeController: UIViewController?
    private var timer: Timer?
    private var lastInputRevision = -1
    private var webController: LinkVerificationWebFallbackController?
    private var lastSettledEmbeddedBounds: CGRect?
    /// Set while the incoming screen is laid out ahead of the resize animation, so the dialog frame isn't updated early.
    private var isPreparingTransition = false

    convenience init(
        mode: LinkVerificationView.Mode = .modal,
        linkAccount: PaymentSheetLinkAccount,
        brand: LinkBrand,
        appearance: LinkAppearance? = nil,
        allowLogoutInDialog: Bool = false,
        consentViewModel: LinkConsentViewModel? = nil,
        analyticsHelper: LinkAnalyticsHelper
    ) {
        let consentGranted: Bool? = if case .inline = consentViewModel { true } else { nil }
        let coordinator = LinkAuthFlowCoordinator(
            account: linkAccount,
            analyticsHelper: analyticsHelper,
            consentGranted: consentGranted
        )
        self.init(
            mode: mode,
            linkAccount: linkAccount,
            brand: brand,
            appearance: appearance,
            allowLogoutInDialog: allowLogoutInDialog,
            consentViewModel: consentViewModel,
            coordinator: coordinator,
            ownsCoordinator: true
        )
        coordinator.onUpdate = { [weak self] in self?.coordinatorDidUpdate() }
        coordinator.onFinish = { [weak self] result in self?.coordinatorDidFinish(result) }
        coordinator.onWebHandoff = { [weak self] url in self?.coordinatorDidRequestWebHandoff(url) }
    }

    /// Shows an attempt another host owns, such as one that started inline. The host keeps the coordinator's
    /// callbacks and forwards them through the `coordinatorDid…` methods. Closing calls `onDetachRequested`
    /// instead of canceling, so the attempt and any code already sent stay valid.
    convenience init(
        mode: LinkVerificationView.Mode = .modal,
        sharedCoordinator coordinator: LinkAuthFlowCoordinator,
        linkAccount: PaymentSheetLinkAccount,
        brand: LinkBrand,
        appearance: LinkAppearance? = nil,
        allowLogoutInDialog: Bool = false
    ) {
        self.init(
            mode: mode,
            linkAccount: linkAccount,
            brand: brand,
            appearance: appearance,
            allowLogoutInDialog: allowLogoutInDialog,
            consentViewModel: nil,
            coordinator: coordinator,
            ownsCoordinator: false
        )
    }

    private init(
        mode: LinkVerificationView.Mode,
        linkAccount: PaymentSheetLinkAccount,
        brand: LinkBrand,
        appearance: LinkAppearance?,
        allowLogoutInDialog: Bool,
        consentViewModel: LinkConsentViewModel?,
        coordinator: LinkAuthFlowCoordinator,
        ownsCoordinator: Bool
    ) {
        self.mode = mode
        self.account = linkAccount
        self.appearance = appearance
        self.coordinator = coordinator
        self.ownsCoordinator = ownsCoordinator
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
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !isPreparingTransition {
            (presentationController as? PresentationController)?.updatePresentedViewFrame()
        }
        // In embedded mode, contentStack's height is imposed by the host (via view's frame)
        // rather than derived from its own content, unlike the scroll-view-hosted modal path.
        // UIStackView's arranged-subview sizing (childContainer, and in turn the active child
        // controller's view) doesn't fully converge to that imposed height within a single
        // layout pass, so force a second pass whenever the bounds actually change.
        if !mode.requiresModalPresentation, view.bounds != lastSettledEmbeddedBounds {
            lastSettledEmbeddedBounds = view.bounds
            view.setNeedsLayout()
            view.layoutIfNeeded()
        }
    }

    func fittingHeight(width: CGFloat) -> CGFloat {
        let contentHeight = activeController?.view.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height ?? 0
        return contentHeight + (mode.requiresModalPresentation ? 20 + header.intrinsicContentSize.height : 0)
    }

    @objc func close() {
        guard ownsCoordinator else {
            timer?.invalidate()
            timer = nil
            view.endEditing(true)
            onDetachRequested?()
            return
        }
        coordinator.cancel()
    }

    // MARK: Coordinator events

    func coordinatorDidUpdate() {
        render()
    }

    func coordinatorDidFinish(_ result: LinkVerificationResult) {
        timer?.invalidate()
        webController?.cancel()
        webController = nil
        onFinish?(result)
    }

    func coordinatorDidRequestWebHandoff(_ url: URL) {
        presentWeb(url)
    }

    @objc func back() {
        coordinator.goBack()
    }

    /// Ticks the OTP screen once a second, only while a resend cooldown is counting down.
    private func updateResendTimer() {
        guard coordinator.screen == .otp, coordinator.resendSecondsRemaining > 0 else {
            timer?.invalidate()
            timer = nil
            return
        }
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.otpController.render()
                self?.updateResendTimer()
            }
        }
    }

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
        // Initial rendering can precede presentation. Let UIKit size the modal before forcing layout.
        let presentation: PresentationController? = {
            guard let presentation = presentationController as? PresentationController,
                  let containerView = presentation.containerView,
                  containerView.bounds.width > 0 else { return nil }
            return presentation
        }()
        var outgoingSnapshot: UIView?
        if changed {
            view.endEditing(true)
            if presentation != nil, let outgoingView = activeController?.view {
                outgoingSnapshot = outgoingView.snapshotView(afterScreenUpdates: false)
                outgoingSnapshot?.frame = outgoingView.frame
            }
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
        if let presentation {
            if changed {
                // Give the incoming screen its real frames before the resize animation below,
                // so its subviews don't animate in from a zero rect. The dialog frame is left
                // alone here so the animation can resize it.
                isPreparingTransition = true
                UIView.performWithoutAnimation {
                    view.layoutIfNeeded()
                }
                isPreparingTransition = false
                // Crossfade from the outgoing screen while the dialog resizes.
                next.view.alpha = 0
                if let outgoingSnapshot { childContainer.addSubview(outgoingSnapshot) }
            }
            UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.2, animations: {
                presentation.updatePresentedViewFrame()
                self.view.layoutIfNeeded()
                next.view.alpha = 1
                outgoingSnapshot?.alpha = 0
            }, completion: { _ in
                outgoingSnapshot?.removeFromSuperview()
            })
        }
        updateResendTimer()
        onNavigationUpdate?()
        if changed || lastInputRevision != coordinator.inputRevision {
            lastInputRevision = coordinator.inputRevision
            if view.window != nil { focusCurrentScreen() }
            if changed { UIAccessibility.post(notification: .screenChanged, argument: next.view) }
        }
    }

    private func focusCurrentScreen() {
        switch coordinator.screen {
        case .otp:
            otpController.focusCode()
        case .phoneMatch:
            phoneController.focusPhone()
        case .loading, .blocked, .webHandoff:
            view.endEditing(true)
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
        func presentationController(
            forPresented presented: UIViewController,
            presenting: UIViewController?,
            source: UIViewController
        ) -> UIPresentationController? {
            PresentationController(presentedViewController: presented, presenting: presenting)
        }
    }
}
