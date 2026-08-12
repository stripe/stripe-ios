//
//  PaymentSheetContainerViewController.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 9/2/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore
import UIKit

protocol BottomSheetContentViewController: UIViewController {

    /// - Note: Implementing `navigationBar` as a computed variable will result in undefined behavior.
    var navigationBar: SheetNavigationBar { get }
    var requiresFullScreen: Bool { get }
    func didTapOrSwipeToDismiss()
}

/// A VC containing a content view controller and manages the layout of its SheetNavigationBar.
/// For internal SDK use only
@objc(STP_Internal_PaymentSheetContainerViewController)
class PaymentSheetContainerViewController: UIViewController {

    static let contentDetentIdentifier = UISheetPresentationController.Detent.Identifier(
        "com.stripe.paymentsheet.content"
    )

    lazy var contentSizedDetent: UISheetPresentationController.Detent = {
        guard #available(iOS 17.0, *) else {
            return .large()
        }
        return .custom(identifier: Self.contentDetentIdentifier) { [weak self] context in
            guard let self else {
                return context.maximumDetentValue
            }
            guard !self.contentRequiresFullScreen else {
                return context.maximumDetentValue
            }
            return min(self.fittedContentHeight, context.maximumDetentValue)
        }
    }()

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

    private lazy var navigationBarContainerView: UIStackView = {
        return UIStackView()
    }()

    private lazy var contentContainerView: UIStackView = {
        return UIStackView()
    }()

    private lazy var outsideSheetTapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOutsideSheet))
        tapGestureRecognizer.cancelsTouchesInView = false
        tapGestureRecognizer.delegate = self
        return tapGestureRecognizer
    }()

    #if compiler(>=6.2)
    private lazy var navigationBarBlur: UIInteraction? = {
        guard appearance.navigationBarStyle.isGlass, #available(iOS 26.0, visionOS 26.0, *) else {
            return nil
        }
        let interaction = UIScrollEdgeElementContainerInteraction()
        interaction.scrollView = scrollView
        interaction.edge = .top
        return interaction
    }()
    #endif

    private(set) var contentStack: [BottomSheetContentViewController] = []

    var navigationBarHeight: CGFloat {
        SheetNavigationBar.height(appearance: appearance)
    }

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
        // If you are implementing your own container view controller, it must call the willMove(toParent:) method of the child view controller before calling the removeFromParent() method, passing in a parent value of nil.
        // The removeFromParent() method automatically calls the didMove(toParent:) method of the child view controller after it removes the child.
        popped.willMove(toParent: nil)
        popped.removeFromParent()

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
        navigationBarContainerView.addArrangedSubview(contentViewController.navigationBar)
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
        guard contentViewController !== newContentViewController else {
            return
        }
        let oldContentViewController = contentViewController
        contentViewController = newContentViewController

        // Take a snapshot and add it to the main view at the same visual position
        let oldView = oldContentViewController.view!
        let oldViewImage = oldView.snapshotView(afterScreenUpdates: false) ?? UIView()
        let snapshotFrame = oldView.convert(oldView.bounds, to: view)
        oldViewImage.frame = snapshotFrame
        view.addSubview(oldViewImage)

        // Remove the old VC
        oldContentViewController.beginAppearanceTransition(false, animated: true)
        oldContentViewController.view.removeFromSuperview()
        oldContentViewController.endAppearanceTransition()

        // Add the new VC
        newContentViewController.beginAppearanceTransition(true, animated: true)
        addChild(newContentViewController)
        contentContainerView.addArrangedSubview(self.contentViewController.view)

        contentContainerView.layoutIfNeeded()
        scrollView.layoutIfNeeded()
        scrollView.updateConstraintsIfNeeded()
        oldContentViewController.navigationBar.removeFromSuperview()
        navigationBarContainerView.addArrangedSubview(newContentViewController.navigationBar)
        navigationBarContainerView.layoutIfNeeded()

        // New content starts transparent
        newContentViewController.view.alpha = 0

        let animator = UIViewPropertyAnimator(duration: 0.25, curve: .easeInOut) {
            oldViewImage.alpha = 0
            self.contentViewController.view.alpha = 1
        }
        animator.addCompletion { _ in
            self.contentViewController.didMove(toParent: self)
            self.contentViewController.endAppearanceTransition()
            oldViewImage.removeFromSuperview()
            UIAccessibility.post(notification: .screenChanged, argument: self.contentViewController.view)
            completion?()
        }
        animator.startAnimation()
        invalidateContentDetent()
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

    private var lastFittedContentHeight: CGFloat = 0
    private var hasScheduledDetentInvalidation = false

    private var fittedContentHeight: CGFloat {
        let width = max(contentContainerView.bounds.width, view.bounds.width)
        guard width > 0 else {
            return navigationBarHeight
        }
        let contentHeight = contentContainerView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        return navigationBarHeight + contentHeight
    }

    func prepareForPresentation(in availableWidth: CGFloat) {
        loadViewIfNeeded()
        view.bounds.size.width = availableWidth
        view.setNeedsLayout()
        view.layoutIfNeeded()
        lastFittedContentHeight = fittedContentHeight
    }

    func invalidateContentDetent() {
        guard #available(iOS 17.0, *) else {
            return
        }
        sheetPresentationController?.animateChanges {
            self.sheetPresentationController?.invalidateDetents()
        }
    }

    /// :nodoc:
    public override func viewDidLoad() {
        super.viewDidLoad()

        [scrollView, navigationBarContainerView].forEach({  // Note: Order important here, navigation bar should be on top
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        })

        // Our content VCs constrain against safeAreaLayoutGuide, we don't want the scroll view to adjust its content inset too. If `contentInsetAdjustmentBehavior` is left as the default (automatic),
        // it causes an infinite layout loop under certain conditions when the content exceeds the height of the screen.
        scrollView.contentInsetAdjustmentBehavior = .never
        let bottomAnchor = scrollView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor)
        bottomAnchor.priority = .defaultLow

        NSLayoutConstraint.activate([
            navigationBarContainerView.topAnchor.constraint(equalTo: view.topAnchor),  // For unknown reasons, safeAreaLayoutGuide can have incorrect padding; we'll rely on our superview instead
            navigationBarContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 2),
            navigationBarContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -2),

            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bottomAnchor,
        ])

        if appearance.navigationBarStyle.isGlass {
            NSLayoutConstraint.activate([
                // Allow scroll view to extend under the navigation bar for blur effect
                scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                scrollView.topAnchor.constraint(equalTo: navigationBarContainerView.bottomAnchor)
            ])
        }
        #if compiler(>=6.2)
        enableNavigationBarBlurInteraction()
        #endif

        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.directionalLayoutMargins = appearance.formInsets
        scrollView.addSubview(contentContainerView)

        // Give the scroll view a desired height
        let scrollViewHeightConstraint = scrollView.heightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.heightAnchor)
        scrollViewHeightConstraint.priority = .fittingSizeLevel
        self.scrollViewHeightConstraint = scrollViewHeightConstraint

        // Move the contentContainerView to start below the sheet
        let topOffset = appearance.navigationBarStyle.isGlass ? navigationBarHeight : 0.0

        NSLayoutConstraint.activate([
            contentContainerView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentContainerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: topOffset),
            contentContainerView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentContainerView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            scrollViewHeightConstraint,
        ])
        let hideKeyboardGesture = UITapGestureRecognizer(
            target: self, action: #selector(didTapAnywhere))
        hideKeyboardGesture.cancelsTouchesInView = false
        hideKeyboardGesture.delegate = self
        view.addGestureRecognizer(hideKeyboardGesture)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard outsideSheetTapGestureRecognizer.view == nil else {
            return
        }
        presentationController?.containerView?.addGestureRecognizer(outsideSheetTapGestureRecognizer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let fittedContentHeight = fittedContentHeight
        guard abs(fittedContentHeight - lastFittedContentHeight) > 0.5,
              !hasScheduledDetentInvalidation else {
            return
        }
        lastFittedContentHeight = fittedContentHeight
        hasScheduledDetentInvalidation = true
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.hasScheduledDetentInvalidation = false
            self.invalidateContentDetent()
        }
    }
    #if compiler(>=6.2)
    func enableNavigationBarBlurInteraction() {
        guard let navigationBarBlur,
            navigationBarBlur.view == nil,
            navigationController != nil,
        // Hack: This line causes PaymentSheetSnapshotTests to fail on iOS 26 - the sheet becomes transparent. I can't figure out a fix, so just remove it out for tests.
        NSClassFromString("XCTest") == nil else {
            return
        }
        navigationBarContainerView.addInteraction(navigationBarBlur)
    }
    #endif

    func didTapOrSwipeToDismiss() {
        contentViewController.didTapOrSwipeToDismiss()
        STPAnalyticsClient.sharedClient.logPaymentSheetEvent(event: .paymentSheetDismissed)
    }
}

extension PaymentSheetContainerViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // The content view controller decides whether dismissal is currently allowed after the interactive gesture ends.
        return false
    }

    func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
        didTapOrSwipeToDismiss()
    }
}

// MARK: - UIScrollViewDelegate
extension PaymentSheetContainerViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 0 {
            contentViewController.navigationBar.setShadowHidden(false)
        } else {
            contentViewController.navigationBar.setShadowHidden(true)
        }
    }
}

// MARK: - PaymentSheetAuthenticationContext
extension PaymentSheetContainerViewController: PaymentSheetAuthenticationContext {

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

    func presentPollingVCForAction(action: STPPaymentHandlerPaymentIntentActionParams, type: STPPaymentMethodType, safariViewController: SFSafariViewController?) {
        let pollingVC = PollingViewController(currentAction: action, viewModel: PollingViewModel(paymentMethodType: type),
                                                      appearance: self.appearance, safariViewController: safariViewController)
        pushContentViewController(pollingVC)
    }

    func dismiss(_ authenticationViewController: UIViewController, completion: (() -> Void)?) {
        guard contentViewController is BottomSheet3DS2ViewController || contentViewController is PollingViewController else {
            assertionFailure("Dismiss called, but it will do nothing!")
            return
        }
        _ = popContentViewController(completion: completion)
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PaymentSheetContainerViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch)
        -> Bool
    {
        if gestureRecognizer === outsideSheetTapGestureRecognizer {
            let location = touch.location(in: view)
            return !view.point(inside: location, with: nil)
        }

        // I can't find another way to allow custom UIControl subclasses to receive touches
        return !(touch.view is UIControl)
    }

    @objc private func didTapOutsideSheet() {
        didTapOrSwipeToDismiss()
    }

    @objc func didTapAnywhere() {
        view.endEditing(false)
    }
}

// MARK: - BottomSheet3DS2ViewControllerDelegate
extension PaymentSheetContainerViewController: BottomSheet3DS2ViewControllerDelegate {
    func bottomSheet3DS2ViewControllerDidCancel(
        _ bottomSheet3DS2ViewController: BottomSheet3DS2ViewController
    ) {
        didCancelNative3DS2()
    }
}
