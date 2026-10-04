//
//  NativeSheetContainerViewController.swift
//  StripePaymentSheet
//
//  Created by George Birch on 9/30/26.
//  Copyright © 2026 Stripe, Inc. All rights reserved.
//

import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

/// A VC containing a content view controller and manages the layout of its SheetNavigationBar.
/// For internal SDK use only
@objc(STP_Internal_NativeSheetContainerViewController)
class NativeSheetContainerViewController: UIViewController, PaymentSheetContainer {

    var sheetCornerRadius: CGFloat? {
        appearance.sheetCornerRadius
    }

    #if !os(visionOS)
    static let contentDetentIdentifier = UISheetPresentationController.Detent.Identifier(
        "com.stripe.paymentsheet.content"
    )

    // UIKit caps content-sized sheets at the available height; 3DS may request that full height.
    lazy var contentSizedDetent: UISheetPresentationController.Detent = {
        // For iOS 15 devices, we can't set custom detents and instead conservatively use the largest
        guard #available(iOS 16.0, *) else {
            return .large()
        }
        return .custom(identifier: Self.contentDetentIdentifier) { [weak self] context in
            guard let self else {
                return context.maximumDetentValue
            }
            guard !self.contentRequiresFullScreen else {
                return context.maximumDetentValue
            }
            // Since the form may change before a resize starts, we use the last measured height.
            // UIKit adds its own bottom safe area padding, and so we remove that since our content already includes the intended bottom padding.
            return min(max(0, self.lastFittedContentHeight - self.view.safeAreaInsets.bottom), context.maximumDetentValue)
        }
    }()
    #endif

    // MARK: - Views
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        #if !os(visionOS)
        scrollView.keyboardDismissMode = .onDrag
        #endif
        scrollView.delegate = self
        return scrollView
    }()

    private lazy var contentContainerView: UIStackView = {
        return UIStackView()
    }()

    // Navigation updates this logical stack immediately; native presentation may defer the visible child change.
    private(set) var contentStack: [BottomSheetContentViewController] = []

    /// Content offset of the scroll view as a percentage (0 - 1.0) of the total height.
    var contentOffsetPercentage: CGFloat {
        get {
            guard scrollView.contentSize.height > scrollView.bounds.height else { return 0 }
            return scrollView.contentOffset.y / (scrollView.contentSize.height - scrollView.bounds.height)
        }
        set {
            let maxContentOffset = scrollView.contentSize.height - scrollView.bounds.height
            let newContentOffset = maxContentOffset * newValue
            scrollView.setContentOffset(CGPoint(x: 0, y: newContentOffset), animated: false)
        }
    }

    private var pendingNativeContentViewController: BottomSheetContentViewController?
    private var pendingNativeContentCompletions: [() -> Void] = []
    private var isWaitingForNativePresentation = false
    private var isUpdatingNativeContent = false

    func setViewControllers(_ viewControllers: [BottomSheetContentViewController]) {
        contentStack = viewControllers
        if let top = viewControllers.first {
            updateContent(to: top)
        }
    }

    func pushContentViewController(_ contentViewController: BottomSheetContentViewController) {
        contentStack.insert(contentViewController, at: 0)
        updateContent(to: contentViewController)
    }

    func popContentViewController(completion: (() -> Void)? = nil) -> BottomSheetContentViewController? {
        guard contentStack.count > 1,
              let toVC = contentStack.stp_boundSafeObject(at: 1)
        else {
            return nil
        }

        let popped = contentStack.remove(at: 0)
        updateContent(to: toVC, completion: completion)
        return popped
    }

    let isTestMode: Bool
    let appearance: PaymentSheet.Appearance

    private var contentViewController: BottomSheetContentViewController

    var contentRequiresFullScreen: Bool {
        return contentViewController.requiresFullScreen
    }

    let didCancelNative3DS2: () -> Void

    func setUserInteractionEnabled(_ enabled: Bool) {
        view.isUserInteractionEnabled = enabled
        // Native controls live in the navigation controller, outside our content view.
        contentViewController.navigationBar.isUserInteractionEnabled = enabled
    }

    required init(
        contentViewController: BottomSheetContentViewController,
        appearance: PaymentSheet.Appearance,
        isTestMode: Bool,
        didCancelNative3DS2: @escaping () -> Void
    ) {
        self.contentViewController = contentViewController
        self.appearance = appearance
        self.isTestMode = isTestMode
        self.didCancelNative3DS2 = didCancelNative3DS2
        super.init(nibName: nil, bundle: nil)

        contentStack = [contentViewController]

        addChild(contentViewController)
        contentViewController.didMove(toParent: self)
        contentContainerView.addArrangedSubview(contentViewController.view)
        contentViewController.navigationBar.systemNavigationItem = navigationItem
        self.view.backgroundColor = appearance.colors.background
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Blur

    // Blur view over sheet
    private lazy var blurView: UIView = {
        return UIView(frame: .zero)
    }()

    private let spinnerSize = CGSize(width: 48, height: 48)
    private lazy var checkProgressView: CheckProgressView = {
        let view = CheckProgressView(frame: CGRect(origin: .zero, size: spinnerSize),
                                                   baseLineWidth: 2.5)
        view.color = UIColor.dynamic(light: .black, dark: .white)
        return view
    }()

    func addBlurEffect(animated: Bool, backgroundColor: UIColor, completion: @escaping () -> Void) {
        if let containingSuperview = self.view {
            [self.blurView].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                containingSuperview.addSubview($0)
            }
            NSLayoutConstraint.activate([
                self.blurView.topAnchor.constraint(equalTo: containingSuperview.topAnchor),
                self.blurView.leadingAnchor.constraint(equalTo: containingSuperview.leadingAnchor),
                self.blurView.trailingAnchor.constraint(equalTo: containingSuperview.trailingAnchor),
                self.blurView.bottomAnchor.constraint(equalTo: containingSuperview.bottomAnchor),
            ])

            [self.checkProgressView].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                self.blurView.addSubview($0)
            }
            NSLayoutConstraint.activate([
                self.checkProgressView.centerXAnchor.constraint(equalTo: self.blurView.centerXAnchor),
                self.checkProgressView.centerYAnchor.constraint(equalTo: self.blurView.centerYAnchor),
                self.checkProgressView.heightAnchor.constraint(equalToConstant: spinnerSize.height),
                self.checkProgressView.widthAnchor.constraint(equalToConstant: spinnerSize.width),
            ])

            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration, animations: {
                self.blurView.backgroundColor = backgroundColor
            }, completion: { _ in
                completion()
            })
        }
    }

    func updateContent(to newContentViewController: BottomSheetContentViewController, completion: (() -> Void)? = nil) {
        // Keep only the latest visual destination, but complete every requested operation.
        pendingNativeContentViewController = newContentViewController
        if let completion {
            pendingNativeContentCompletions.append(completion)
        }
        updateNativeContentIfPossible()
    }

    private func updateNativeContentIfPossible() {
        guard !isWaitingForNativePresentation, !isUpdatingNativeContent,
              let newContentViewController = pendingNativeContentViewController else {
            return
        }

        if rootParent.isBeingPresented || rootParent.isBeingDismissed, let transitionCoordinator = rootParent.transitionCoordinator {
            isWaitingForNativePresentation = true
            transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
                // UIKit must finish forwarding the parent's appearance callbacks before we change its children.
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.isWaitingForNativePresentation = false
                    self.updateNativeContentIfPossible()
                }
            }
            return
        }

        let completions = pendingNativeContentCompletions
        pendingNativeContentViewController = nil
        pendingNativeContentCompletions = []
        isUpdatingNativeContent = true
        updateDisplayedContent(to: newContentViewController) {
            self.removeUnusedNativeContentViewControllers()
            completions.forEach { $0() }
            self.isUpdatingNativeContent = false
            self.updateNativeContentIfPossible()
        }
    }

    private func removeUnusedNativeContentViewControllers() {
        // Wait until the visual transition finishes before detaching popped or replaced children.
        for child in children where child is BottomSheetContentViewController
            && child !== contentViewController
            && !contentStack.contains(where: { $0 === child }) {
            child.willMove(toParent: nil)
            child.removeFromParent()
        }
    }

    private func updateDisplayedContent(to newContentViewController: BottomSheetContentViewController, completion: (() -> Void)? = nil) {
        guard contentViewController !== newContentViewController else {
            completion?()
            return
        }
        let oldContentViewController = contentViewController
        contentViewController = newContentViewController

        // Take a snapshot of the old content and add it to our container - we'll fade it out
        let oldView = oldContentViewController.view!
        let oldViewImage = oldView.snapshotView(afterScreenUpdates: false) ?? UIView()
        contentContainerView.addSubview(oldViewImage)

        // Remove the old VC
        oldContentViewController.beginAppearanceTransition(false, animated: true)
        oldContentViewController.view.removeFromSuperview()
        oldContentViewController.endAppearanceTransition()

        // Add the new VC
        newContentViewController.beginAppearanceTransition(true, animated: true)
        // When your custom container calls the addChild(_:) method, it automatically calls the willMove(toParent:) method of the view controller to be added as a child before adding it.
        addChild(newContentViewController)
        contentContainerView.addArrangedSubview(self.contentViewController.view)

        contentContainerView.layoutIfNeeded()
        scrollView.layoutIfNeeded()
        scrollView.updateConstraintsIfNeeded()
        oldContentViewController.navigationBar.removeFromSuperview()
        oldContentViewController.navigationBar.systemNavigationItem = nil
        newContentViewController.navigationBar.systemNavigationItem = navigationItem
        newContentViewController.view.alpha = 0

        let transitionCompletion: (Bool) -> Void = { _ in
            // If you are implementing your own container view controller, it must call the didMove(toParent:) method of the child view controller after the transition to the new controller is complete or, if there is no transition, immediately after calling the addChild(_:) method.
            newContentViewController.didMove(toParent: self)
            newContentViewController.endAppearanceTransition()

            // Remove the old content snapshot
            oldViewImage.removeFromSuperview()

            // Inform accessibility
            UIAccessibility.post(notification: .screenChanged, argument: newContentViewController.view)
            completion?()
        }

        invalidateContentDetent()
        UIView.animate(withDuration: 0.2, animations: {
            oldViewImage.alpha = 0
            newContentViewController.view.alpha = 1
        }, completion: transitionCompletion)
    }

    func startSpinner() {
        self.checkProgressView.beginProgress()
    }

    func transitionSpinnerToComplete(animated: Bool, completion: @escaping () -> Void) {
        self.checkProgressView.completeProgress(completion: {
            completion()
        })
    }

    func removeBlurEffect(animated: Bool, completion: (() -> Void)? = nil) {
        if self.blurView.superview != nil {
            self.blurView.translatesAutoresizingMaskIntoConstraints = true
            self.blurView.removeConstraints(self.blurView.constraints)

            if checkProgressView.superview != nil {
                self.checkProgressView.translatesAutoresizingMaskIntoConstraints = true
                self.checkProgressView.removeConstraints(self.checkProgressView.constraints)
            }

            UIView.animate(withDuration: PaymentSheetUI.defaultAnimationDuration, animations: {
                self.blurView.backgroundColor = .clear
            }, completion: { _ in
                self.blurView.removeFromSuperview()
                if let completion {
                    completion()
                }
            })
        } else {
            if let completion {
                completion()
            }
        }
    }

    // MARK: -
    private var scrollViewHeightConstraint: NSLayoutConstraint?
    private var keyboardAvoidanceConstraint: NSLayoutConstraint?

    private var lastFittedContentHeight: CGFloat = 0
    private var hasScheduledDetentInvalidation = false
    private var isWaitingForDetentTransition = false

    private var fittedContentHeight: CGFloat {
        // A vertical system bar narrows the usable content width, which can increase wrapped content height.
        let width = scrollView.bounds.width > 0
            ? scrollView.bounds.width
            : view.bounds.inset(by: view.safeAreaInsets).width
        // Handle case where initial layout hasn't happened yet.
        guard width > 0 else {
            return 0
        }
        let fittingSize = CGSize(width: width, height: UIView.layoutFittingCompressedSize.height)
        let navigationBarHeight: CGFloat
        if let navigationController {
            if view.window != nil {
                // Only include space above the content. A vertical bar consumes width, not height.
                let contentTop = view.convert(CGPoint(x: 0, y: view.safeAreaInsets.top), to: navigationController.view).y
                navigationBarHeight = max(0, contentTop - navigationController.view.safeAreaInsets.top)
            } else {
                navigationBarHeight = navigationController.navigationBar.sizeThatFits(fittingSize).height
            }
        } else {
            navigationBarHeight = 0
        }
        let contentHeight = contentContainerView.systemLayoutSizeFitting(
            fittingSize,
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        return navigationBarHeight + contentHeight
    }

    func prepareForPresentation(in availableWidth: CGFloat) {
        // Laying out the navigation controller here interrupts UIKit's opening dimming animation
        // on iOS 26.1. Measure only our content and let UIKit lay out its presentation host.
        view.bounds.size.width = availableWidth
        view.setNeedsLayout()
        view.layoutIfNeeded()
        lastFittedContentHeight = fittedContentHeight
    }

    func invalidateContentDetent() {
        #if !os(visionOS)
        guard #available(iOS 16.0, *) else {
            return
        }
        guard viewIfLoaded?.window != nil else {
            // If the sheet is offscreen, we should just set the height and not perform an animation
            lastFittedContentHeight = fittedContentHeight
            return
        }

        // Prevent multiple animations from happening (for example if this was called repeatedly during presentation or dismissal)
        guard !isWaitingForDetentTransition else {
            return
        }

        // Wait until UIKit finishes presenting or dismissing before starting a height animation.
        if rootParent.isBeingPresented || rootParent.isBeingDismissed {
            guard let transitionCoordinator = rootParent.transitionCoordinator else { return }
            // Set `isWaitingForDetentTransition` to true if animation work successfully starts
            isWaitingForDetentTransition = transitionCoordinator.animate(alongsideTransition: nil) { [weak self] _ in
                // UIKit must clear the parent's transition state before we start another sheet animation.
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.isWaitingForDetentTransition = false
                    self.invalidateContentDetent()
                }
            }
            return
        }

        let fittedContentHeight = fittedContentHeight
        // UISheetPresentationController.animateChanges(_:) can cause an infinite layout loop
        // when resizing scrollable content on an iPhone Duo with its screen open.
        // Use the Stripe version instead
        animateHeightChange(forceAnimation: true) {
            self.lastFittedContentHeight = fittedContentHeight
            self.rootParent.sheetPresentationController?.invalidateDetents()
        }
        #endif
    }

    /// :nodoc:
    public override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Content view controllers already constrain their contents against the safe area.
        scrollView.contentInsetAdjustmentBehavior = .never
        // Existing form padding extends to the sheet's bottom; only a visible keyboard should shorten it.
        // TODO: When we drop iOS 16 support, set keyboardLayoutGuide.usesBottomSafeArea = false here.
        // The hidden keyboard guide will then reach the view's bottom without the constraint adjustment below.
        let bottomAnchor = scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        bottomAnchor.priority = .defaultLow
        keyboardAvoidanceConstraint = bottomAnchor

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bottomAnchor,
        ])

        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.directionalLayoutMargins = appearance.formInsets
        scrollView.addSubview(contentContainerView)

        // Prefer the content's natural height while allowing UIKit to cap the sheet at the available height.
        let scrollViewHeightConstraint = scrollView.heightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.heightAnchor)
        scrollViewHeightConstraint.priority = .fittingSizeLevel
        self.scrollViewHeightConstraint = scrollViewHeightConstraint

        NSLayoutConstraint.activate([
            contentContainerView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentContainerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentContainerView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            scrollViewHeightConstraint,
        ])

        let hideKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAnywhere))
        hideKeyboardGesture.cancelsTouchesInView = false
        hideKeyboardGesture.delegate = self
        view.addGestureRecognizer(hideKeyboardGesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // The keyboard guide reserves the bottom safe area by default, even with the keyboard hidden.
        // TODO: When we drop iOS 16 support, remove this compensation after setting usesBottomSafeArea = false.
        let bottomInset = view.keyboardLayoutGuide.layoutFrame.height <= view.safeAreaInsets.bottom
            ? view.safeAreaInsets.bottom : 0
        if keyboardAvoidanceConstraint?.constant != bottomInset {
            keyboardAvoidanceConstraint?.constant = bottomInset
            view.layoutIfNeeded()
        }

        let fittedContentHeight = fittedContentHeight
        // Don't perform a layout update if:
        //  a) The sheet is off screen
        //  b) There is only a small difference in height (this can cause infinite loops)
        //  c) There is already a schedule animation
        guard view.window != nil,
              abs(fittedContentHeight - lastFittedContentHeight) > 0.5,
              !hasScheduledDetentInvalidation else {
            return
        }

        // Coalesce layout-driven changes and invalidate after the current layout pass completes.
        hasScheduledDetentInvalidation = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hasScheduledDetentInvalidation = false
            // An explicit content update may already have resized the sheet in its own animation.
            guard abs(self.fittedContentHeight - self.lastFittedContentHeight) > 0.5 else { return }
            self.invalidateContentDetent()
        }
    }

    func didTapOrSwipeToDismiss() {
        contentViewController.didTapOrSwipeToDismiss()
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetDismissed)
    }
}

// MARK: - Presentation

extension NativeSheetContainerViewController {

    func present(from presentingViewController: UIViewController, completion: (() -> Void)?) {
        #if !os(visionOS)
        // UIKit adapts navigation items into the appropriate horizontal or vertical system bar.
        let navigationController = navigationController ?? UINavigationController(rootViewController: self)
        navigationController.modalPresentationStyle = .automatic
        // Dismissal is handled by the sheet's explicit controls rather than UIKit's interactive gestures.
        navigationController.isModalInPresentation = true
        navigationController.modalPresentationCapturesStatusBarAppearance = true
        navigationController.overrideUserInterfaceStyle = overrideUserInterfaceStyle
        navigationController.navigationBar.tintColor = appearance.colors.icon

        let barAppearance = UINavigationBarAppearance()
        barAppearance.configureWithDefaultBackground()
        barAppearance.titleTextAttributes = [
            .font: appearance.scaledFont(
                for: appearance.font.base.medium,
                style: .headline,
                maximumPointSize: 20
            ),
            .foregroundColor: appearance.colors.text,
        ]
        if appearance.navigationBarStyle.isPlain {
            barAppearance.backgroundColor = appearance.colors.background
        }
        navigationController.navigationBar.standardAppearance = barAppearance
        navigationController.navigationBar.scrollEdgeAppearance = barAppearance
        navigationController.navigationBar.compactAppearance = barAppearance

        if let sheetPresentationController = navigationController.sheetPresentationController {
            if #available(iOS 16.0, *) {
                prepareForPresentation(in: presentingViewController.view.bounds.width)
                sheetPresentationController.detents = [contentSizedDetent]
                sheetPresentationController.selectedDetentIdentifier = Self.contentDetentIdentifier
            } else {
                sheetPresentationController.detents = [.large()]
                sheetPresentationController.selectedDetentIdentifier = .large
            }
            sheetPresentationController.preferredCornerRadius = sheetCornerRadius
            sheetPresentationController.prefersGrabberVisible = false
            sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        navigationController.presentationController?.delegate = self

        presentingViewController.viewIfLoaded?.endEditing(true)
        presentingViewController.present(navigationController, animated: true, completion: completion)
        #endif
    }
}

extension NativeSheetContainerViewController: UIAdaptivePresentationControllerDelegate {

    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // Also prevent UIKit's outside-tap dismissal when the presentation adapts to a form sheet.
        return false
    }
}

// MARK: - UIScrollViewDelegate
extension NativeSheetContainerViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 0 {
            contentViewController.navigationBar.setShadowHidden(false)
        } else {
            contentViewController.navigationBar.setShadowHidden(true)
        }
    }
}

// MARK: - PaymentSheetAuthenticationContext
extension NativeSheetContainerViewController: PaymentSheetAuthenticationContext {

    func authenticationPresentingViewController() -> UIViewController {
        return findTopMostPresentedViewController()
    }

    func configureSafariViewController(_ viewController: SFSafariViewController) {
        // Change to a from bottom modal presentation. This also avoids a bug where the contents is squished when returning
        viewController.modalPresentationStyle = .overFullScreen
    }

    func authenticationContextWillDismiss(_ viewController: UIViewController) {
        view.setNeedsLayout()
    }

    // TODO: Remove these three methods! BottomSheetVC shouldn't be aware of any of these specific VCs; it should expose generic present/dismiss methods
    func present(
        _ authenticationViewController: UIViewController, completion: @escaping () -> Void
    ) {
        let threeDS2ViewController = BottomSheet3DS2ViewController(
            challengeViewController: authenticationViewController, appearance: appearance, isTestMode: isTestMode)
        threeDS2ViewController.delegate = self
        pushContentViewController(threeDS2ViewController)
        // Remove a blur effect, if any
        self.removeBlurEffect(animated: true, completion: completion)
    }

    func presentPollingVCForAction(action: STPPaymentHandlerActionParams, type: STPPaymentMethodType, safariViewController: SFSafariViewController?) {
        let pollingVC = PollingViewController(currentAction: action, viewModel: PollingViewModel(paymentMethodType: type),
                                                      appearance: self.appearance, safariViewController: safariViewController)
        pushContentViewController(pollingVC)
    }

    func dismiss(_ authenticationViewController: UIViewController, completion: (() -> Void)?) {
        // Authentication can finish before a queued native content transition becomes visible.
        guard contentStack.first is BottomSheet3DS2ViewController || contentStack.first is PollingViewController else {
            assertionFailure("Dismiss called, but it will do nothing!")
            return
        }
        _ = popContentViewController(completion: completion)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension NativeSheetContainerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch)
        -> Bool
    {
        // I can't find another way to allow custom UIControl subclasses to receive touches
        return !(touch.view is UIControl)
    }

    @objc func didTapAnywhere() {
        view.endEditing(false)
    }
}

// MARK: - BottomSheet3DS2ViewControllerDelegate
extension NativeSheetContainerViewController: BottomSheet3DS2ViewControllerDelegate {
    func bottomSheet3DS2ViewControllerDidCancel(
        _ bottomSheet3DS2ViewController: BottomSheet3DS2ViewController
    ) {
        didCancelNative3DS2()
    }
}
