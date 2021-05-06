//
//  MCViewController.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 9/2/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import SafariServices
import UIKit

protocol BottomSheetContentViewController: UIViewController {
    var navigationBar: SheetNavigationBar { get }
    var isDismissable: Bool { get }
    var requiresFullScreen: Bool { get }
    func didTapOrSwipeToDismiss()
}

/// A VC containing a content view controller and manages the layout of its SheetNavigationBar.
class BottomSheetViewController: UIViewController, PanModalPresentable {
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
            let toVC = contentStack.stp_boundSafeObject(at: 1) as? BottomSheetContentViewController
        else {
            return nil
        }

        let popped = contentStack.remove(at: 0)
        contentViewController = toVC
        return popped
    }

    private var contentViewController: BottomSheetContentViewController {
        didSet(oldContentViewController) {
            // Remove the old VC
            oldContentViewController.view.removeFromSuperview()
            oldContentViewController.removeFromParent()

            // Add the new VC
            addChild(contentViewController)
            self.contentContainerView.addArrangedSubview(self.contentViewController.view)
            self.contentViewController.didMove(toParent: self)
            if let panModalPresentationController = rootParent.presentationController
                as? PanModalPresentationController
            {
                panModalPresentationController.forceFullHeight =
                    contentViewController.requiresFullScreen
            }
            self.contentContainerView.layoutIfNeeded()

            animateHeightChange()
            // Add its navigation bar if necessary
            oldContentViewController.navigationBar.removeFromSuperview()
            navigationBarContainerView.addArrangedSubview(contentViewController.navigationBar)
        }
    }

    required init(contentViewController: BottomSheetContentViewController) {
        self.contentViewController = contentViewController

        super.init(nibName: nil, bundle: nil)

        contentStack = [contentViewController]

        addChild(contentViewController)
        contentViewController.didMove(toParent: self)
        contentContainerView.addArrangedSubview(contentViewController.view)
        navigationBarContainerView.addArrangedSubview(contentViewController.navigationBar)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: -
    private var cachedContentHeight: CGFloat = 0
    private var cachedKeyboardHeight: CGFloat = 0
    private var scrollViewHeightConstraint: NSLayoutConstraint? = nil

    /// :nodoc:
    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = CompatibleColor.systemBackground
        registerForKeyboardNotifications()
        [scrollView, navigationBarContainerView].forEach({  // Note: Order important here, navigation bar should be on top
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        })
        NSLayoutConstraint.activate([
            navigationBarContainerView.topAnchor.constraint(equalTo: view.topAnchor),  // For unknown reasons, safeAreaLayoutGuide can have incorrect padding; we'll rely on our superview instead
            navigationBarContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationBarContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: navigationBarContainerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
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
            self, selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(adjustForKeyboard),
            name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc
    private func adjustForKeyboard(notification: Notification) {
        if let firstResponder = view.firstResponder() {
            let firstResponderFrame = scrollView.convert(firstResponder.frame, from: firstResponder)
            scrollView.scrollRectToVisible(firstResponderFrame, animated: true)
        }
    }

    // MARK: - PanModalPresentable

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

// MARK: - STPAuthenticationContext
extension BottomSheetViewController: STPAuthenticationContext {
    func authenticationPresentingViewController() -> UIViewController {
        return self
    }

    func configureSafariViewController(_ viewController: SFSafariViewController) {
        // Change to a from bottom modal presentation. This also avoids a bug where the contents is squished when returning
        viewController.modalPresentationStyle = .overFullScreen
    }

    func authenticationContextWillDismiss(_ viewController: UIViewController) {
        view.setNeedsLayout()
        if let panModalPresentationController = rootParent.presentationController
            as? PanModalPresentationController
        {
            panModalPresentationController.setNeedsLayoutUpdate()
        }
    }

    func present(
        _ threeDS2ChallengeViewController: UIViewController, completion: @escaping () -> Void
    ) {
        let threeDS2ViewController = BottomSheet3DS2ViewController(
            challengeViewController: threeDS2ChallengeViewController)
        threeDS2ViewController.delegate = self
        pushContentViewController(threeDS2ViewController)
        completion()
    }

    func dismiss(_ threeDS2ChallengeViewController: UIViewController) {
        guard contentViewController is BottomSheet3DS2ViewController else {
            return
        }
        _ = popContentViewController()
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
@available(iOSApplicationExtension, unavailable)
@available(macCatalystApplicationExtension, unavailable)
extension BottomSheetViewController: BottomSheet3DS2ViewControllerDelegate {
    func bottomSheet3DS2ViewControllerDidCancel(
        _ bottomSheet3DS2ViewController: BottomSheet3DS2ViewController
    ) {
        STPPaymentHandler.shared().cancel3DS2ChallengeFlow()
    }
}
