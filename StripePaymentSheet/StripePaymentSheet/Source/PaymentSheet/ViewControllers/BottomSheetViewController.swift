//
//  BottomSheetViewController.swift
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
    func didFinishAnimatingHeight()
}

/// A VC containing a content view controller and manages the layout of its SheetNavigationBar.
/// For internal SDK use only
@objc(STP_Internal_BottomSheetViewController)
class BottomSheetViewController: UIViewController, BottomSheetPresentable {
    struct Constants {
        static let keyboardAvoidanceEdgePadding: CGFloat = 16
    }

    // MARK: - Views
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.delegate = self
        return scrollView
    }()

    private lazy var navigationBarContainerView: UIStackView = {
        return UIStackView()
    }()

    private lazy var contentContainerView: UIStackView = {
        return UIStackView()
    }()

    var contentStack: [BottomSheetContentViewController] = [] {
        didSet {
            if let top = contentStack.first {
                contentViewController = top
            }
        }
    }

    func pushContentViewController(_ contentViewController: BottomSheetContentViewController) {
        contentStack.insert(contentViewController, at: 0)
        self.contentViewController = contentViewController
    }

    func popContentViewController() -> BottomSheetContentViewController? {
        guard contentStack.count > 1,
              let toVC = contentStack.stp_boundSafeObject(at: 1)
        else {
            return nil
        }

        let popped = contentStack.remove(at: 0)
        contentViewController = toVC
        return popped
    }

    let isTestMode: Bool
    let appearance: PaymentSheet.Appearance

    private var contentViewController: BottomSheetContentViewController {
        didSet(oldContentViewController) {
            guard self.contentViewController !== oldContentViewController else {
                return
            }

            // This is a hack to get the animation right.
            // Instead of allowing the height change to implicitly occur within
            // the animation block's layoutIfNeeded, we force a layout pass,
            // calculate the old and new heights, and then only animate the height
            // constraint change.
            // Without this, the inner ScrollView tends to animate from the center
            // instead of remaining pinned to the top.

            // First, get the old height of the content + navigation bar + safe area.
            manualHeightConstraint.constant = oldContentViewController.view.frame.size.height + navigationBarContainerView.bounds.size.height + view.safeAreaInsets.bottom

            // Remove the old VC
            oldContentViewController.view.removeFromSuperview()
            oldContentViewController.removeFromParent()

            // Add the new VC
            addChild(contentViewController)
            self.contentContainerView.addArrangedSubview(self.contentViewController.view)
            self.contentViewController.didMove(toParent: self)
            if let presentationController = rootParent.presentationController
                as? BottomSheetPresentationController
            {
                presentationController.forceFullHeight =
                    contentViewController.requiresFullScreen
            }

            scrollView.contentInsetAdjustmentBehavior = .never
            self.contentContainerView.layoutIfNeeded()
            self.scrollView.layoutIfNeeded()
            self.scrollView.updateConstraintsIfNeeded()
            oldContentViewController.navigationBar.removeFromSuperview()
            navigationBarContainerView.addArrangedSubview(contentViewController.navigationBar)
            navigationBarContainerView.layoutIfNeeded()
            // Layout is mostly completed at this point. The new height is the navigation bar + content + the unsafe area at the bottom.
            let newHeight = self.contentViewController.view.bounds.size.height + navigationBarContainerView.bounds.size.height + view.safeAreaInsets.bottom

            // Force the old height, then force a layout pass
            if self.modalPresentationStyle == .custom { // Only if we're using the custom presentation style (e.g. pinned to the bottom)
                manualHeightConstraint.isActive = true
            }
            self.rootParent.presentationController?.containerView?.layoutIfNeeded()
            self.contentViewController.view.alpha = 0
            // Now animate to the correct height.
            animateHeightChange(forceAnimation: true, {
                self.contentViewController.view.alpha = 1
                self.manualHeightConstraint.constant = newHeight
            }, completion: {_ in
                // We shouldn't need this constraint anymore.
                self.manualHeightConstraint.isActive = false
                self.contentViewController.didFinishAnimatingHeight()
            })
        }
    }

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
    private lazy var checkProgressView: ConfirmButton.CheckProgressView = {
        let view = ConfirmButton.CheckProgressView(frame: CGRect(origin: .zero, size: spinnerSize),
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

    private var bottomAnchor: NSLayoutConstraint?

    private lazy var manualHeightConstraint: NSLayoutConstraint = {
        let manualHeightConstraint: NSLayoutConstraint = self.view.heightAnchor.constraint(equalToConstant: 0)
        manualHeightConstraint.priority = .defaultHigh
        return manualHeightConstraint
    }()

    /// :nodoc:
    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        registerForKeyboardNotifications()
        [scrollView, navigationBarContainerView].forEach({  // Note: Order important here, navigation bar should be on top
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        })
        let bottomAnchor = scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        bottomAnchor.priority = .defaultLow
        self.bottomAnchor = bottomAnchor

        NSLayoutConstraint.activate([
            navigationBarContainerView.topAnchor.constraint(equalTo: view.topAnchor),  // For unknown reasons, safeAreaLayoutGuide can have incorrect padding; we'll rely on our superview instead
            navigationBarContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBarContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: navigationBarContainerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            bottomAnchor,
        ])

        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.directionalLayoutMargins = PaymentSheetUI.defaultSheetMargins
        scrollView.addSubview(contentContainerView)

        // Give the scroll view a desired height
        let scrollViewHeightConstraint = scrollView.heightAnchor.constraint(
            equalTo: scrollView.contentLayoutGuide.heightAnchor)
        scrollViewHeightConstraint.priority = .fittingSizeLevel
        self.scrollViewHeightConstraint = scrollViewHeightConstraint

        NSLayoutConstraint.activate([
            contentContainerView.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentContainerView.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentContainerView.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentContainerView.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor),
            scrollViewHeightConstraint,
        ])
        let hideKeyboardGesture = UITapGestureRecognizer(
            target: self, action: #selector(didTapAnywhere))
        hideKeyboardGesture.cancelsTouchesInView = false
        hideKeyboardGesture.delegate = self
        view.addGestureRecognizer(hideKeyboardGesture)
    }

    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardDidHide),
            name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardDidShow),
            name: UIResponder.keyboardWillShowNotification, object: nil)
    }

    @objc
    private func keyboardDidShow(notification: Notification) {
        adjustForKeyboard(notification: notification) {
            if let firstResponder = self.view.firstResponder() {
                let firstResponderFrame = self.scrollView.convert(firstResponder.bounds, from: firstResponder).insetBy(
                    dx: -Constants.keyboardAvoidanceEdgePadding,
                    dy: -Constants.keyboardAvoidanceEdgePadding
                )
                self.scrollView.scrollRectToVisible(firstResponderFrame, animated: true)
            }
        }
    }

    @objc
    private func keyboardDidHide(notification: Notification) {
        adjustForKeyboard(notification: notification) {
            if let firstResponder = self.view.firstResponder() {
                let firstResponderFrame = self.scrollView.convert(firstResponder.bounds, from: firstResponder).insetBy(
                    dx: -Constants.keyboardAvoidanceEdgePadding,
                    dy: -Constants.keyboardAvoidanceEdgePadding
                )
                self.scrollView.scrollRectToVisible(firstResponderFrame, animated: true)
            }
        }
    }

    @objc
    private func adjustForKeyboard(notification: Notification, animations: @escaping () -> Void) {
        let adjustForKeyboard = {
            self.view.superview?.setNeedsLayout()
            UIView.animateAlongsideKeyboard(notification) {
                guard
                    let keyboardScreenEndFrame =
                        (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
                        .cgRectValue,
                    let bottomAnchor = self.bottomAnchor
                else {
                    return
                }

                let keyboardViewEndFrame = self.view.convert(keyboardScreenEndFrame, from: self.view.window)
                var keyboardInViewHeight = self.view.bounds.intersection(keyboardViewEndFrame).height
                if self.modalPresentationStyle == .custom {
                    // If we're presenting in the custom (pinned to bottom of screen) style, incorporate the safe area insets
                    keyboardInViewHeight -= self.view.safeAreaInsets.bottom
                }

                if notification.name == UIResponder.keyboardWillHideNotification {
                    bottomAnchor.constant = 0
                } else {
                    bottomAnchor.constant = -keyboardInViewHeight
                }

                self.view.superview?.layoutIfNeeded()
                animations()
            }
        }
        if self.modalPresentationStyle == .formSheet {
            // If we're presenting as a form sheet (on an iPad etc), the form sheet presenter might move us around to center us on the screen.
            // Then we can't calculate the keyboard's location correctly, because we'll be estimating based on the keyboard's size
            // in our *old* location instead of the new one.
            // To work around this, wait for a turn of the runloop, then add the keyboard padding.
            DispatchQueue.main.async {
                adjustForKeyboard()
            }
        } else {
            // But usually we can do this immediately, as we control the presentation and know we'll always be pinned to the bottom of the screen.
            adjustForKeyboard()
        }
    }

    // MARK: - BottomSheetPresentable

    var panScrollable: UIScrollView? {
        // Returning the scroll view causes contentInset issues; I'm not sure why.
        return nil
    }

    func didTapOrSwipeToDismiss() {
        contentViewController.didTapOrSwipeToDismiss()
    }
}

extension BottomSheetViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        // On iPad, tapping outside the sheet dismisses it without informing us - so we override this method to be informed.
        didTapOrSwipeToDismiss()
        return false
    }
}

// MARK: - UIScrollViewDelegate
extension BottomSheetViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 0 {
            contentViewController.navigationBar.setShadowHidden(false)
        } else {
            contentViewController.navigationBar.setShadowHidden(true)
        }
    }
}

// MARK: - PaymentSheetAuthenticationContext
extension BottomSheetViewController: PaymentSheetAuthenticationContext {

    func authenticationPresentingViewController() -> UIViewController {
        return findTopMostPresentedViewController() ?? self
    }

    func configureSafariViewController(_ viewController: SFSafariViewController) {
        // Change to a from bottom modal presentation. This also avoids a bug where the contents is squished when returning
        viewController.modalPresentationStyle = .overFullScreen
    }

    func authenticationContextWillDismiss(_ viewController: UIViewController) {
        view.setNeedsLayout()
    }

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
            return
        }
        _ = popContentViewController()
        completion?()
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension BottomSheetViewController: UIViewControllerTransitioningDelegate {}

// MARK: - UIGestureRecognizerDelegate
extension BottomSheetViewController: UIGestureRecognizerDelegate {
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
extension BottomSheetViewController: BottomSheet3DS2ViewControllerDelegate {
    func bottomSheet3DS2ViewControllerDidCancel(
        _ bottomSheet3DS2ViewController: BottomSheet3DS2ViewController
    ) {
        didCancelNative3DS2()
    }
}
