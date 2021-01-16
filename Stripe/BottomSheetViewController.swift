//
//  MCViewController.swift
//  Stripe
//
//  Created by Yuki Tokuhiro on 9/2/20.
//  Copyright © 2020 Stripe, Inc. All rights reserved.
//

import UIKit
import SafariServices

protocol BottomSheetContentViewController: UIViewController {
    var navigationBar: SheetNavigationBar { get }
    var isDismissable: Bool { get }
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

    var contentViewController: BottomSheetContentViewController {
        didSet(oldContentViewController) {
            // Remove the old VC
            oldContentViewController.view.removeFromSuperview()
            oldContentViewController.removeFromParent()

            // Add the new VC
            addChild(contentViewController)
            self.contentContainerView.addArrangedSubview(self.contentViewController.view)
            self.contentViewController.didMove(toParent: self)
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

        addChild(contentViewController)
        contentContainerView.addArrangedSubview(contentViewController.view)
        contentViewController.didMove(toParent: self)
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
        [scrollView, navigationBarContainerView].forEach({ // Note: Order important here, navigation bar should be on top
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        })
        NSLayoutConstraint.activate([
            navigationBarContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBarContainerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            navigationBarContainerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),

            scrollView.topAnchor.constraint(equalTo: navigationBarContainerView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])

        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.directionalLayoutMargins = PaymentSheetUI.defaultSheetMargins
        scrollView.addSubview(contentContainerView)

        // Give the scroll view a desired height
        let scrollViewHeightConstraint = scrollView.heightAnchor.constraint(equalTo: scrollView.contentLayoutGuide.heightAnchor)
        scrollViewHeightConstraint.priority = .fittingSizeLevel // Warning: some values, like .defaultHigh, cause autolayout to enter an infinite loop...
        self.scrollViewHeightConstraint = scrollViewHeightConstraint

        NSLayoutConstraint.activate([
            contentContainerView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentContainerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentContainerView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            scrollViewHeightConstraint
        ])
        let hideKeyboardGesture = UITapGestureRecognizer(target: self, action: #selector(didTapAnywhere))
        hideKeyboardGesture.cancelsTouchesInView = false
        hideKeyboardGesture.delegate = self
        view.addGestureRecognizer(hideKeyboardGesture)
    }

    func calculateContentHeight() -> CGFloat {
        let layoutSize = CGSize(width: view.frame.width, height: UIView.layoutFittingCompressedSize.height)
        let navigationBarHeight = navigationBarContainerView.systemLayoutSizeFitting(layoutSize).height
        let contentHeight = contentViewController.view.systemLayoutSizeFitting(layoutSize).height
        return navigationBarHeight + contentHeight
    }

    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc
    private func adjustForKeyboard(notification: Notification) {
        guard let keyboardScreenEndFrame = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }

        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        let keyboardInViewHeight = view.bounds.intersection(keyboardViewEndFrame).height
        if notification.name == UIResponder.keyboardWillHideNotification {
            scrollView.contentInset = .zero
            cachedKeyboardHeight = 0
        } else {
            cachedKeyboardHeight = keyboardInViewHeight
        }

        // Trigger an animated height adjustment of the modal
        self.scrollViewHeightConstraint?.constant = self.cachedKeyboardHeight
        self.scrollView.setNeedsLayout()
        animateHeightChange {
            self.scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardInViewHeight - self.view.safeAreaInsets.bottom, right: 0)
            self.scrollView.scrollIndicatorInsets = self.scrollView.contentInset

            // UIScrollView automatically scrolls the selected text field to the top
            // However, this can exceed the max content offset.
            // TODO: Find the first responder and scroll it as far up as possible
            let maxOffset = max(0, self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.contentInset.bottom)
            self.scrollView.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: false)
        }
    }

    // MARK: - PanModalPresentable

    var panScrollable: UIScrollView? {
        // Returning the scroll view causes contentInset issues; I'm not sure why.
        return nil
    }

    // Our "full screen" height
    var longFormHeight: PanModalHeight {
        return .contentHeight(calculateContentHeight() + cachedKeyboardHeight)
    }

    var allowsExtendedPanScrolling: Bool = false

    // Our initial, "some content may be peeking" height
    var shortFormHeight: PanModalHeight {
        // Initial height of the sheet
        let maxHeight = CGFloat(400)
        // TODO: If we are showing AddPaymentMethodViewController, return a height such that the first input field is peeking above the bottom
        let contentHeight = calculateContentHeight()
        return .contentHeight(min(maxHeight, contentHeight))
    }

    func shouldRespond(to panModalGestureRecognizer: UIPanGestureRecognizer) -> Bool {
        return allowsDragToDismiss
    }

    var allowsDragToDismiss: Bool {
        return contentViewController.isDismissable
    }

    func didTapOrSwipeToDismiss() {
        contentViewController.didTapOrSwipeToDismiss()
    }

    func willTransition(to state: PanModalPresentationController.PresentationState) {
        // When user swipes down enough to trigger a height change, the keyboard should disappear
        if state == .shortForm {
            view.endEditing(true)
        }
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
        // Simply setting the delegate changes the presentation from a 'push' style to a 'present' style
        viewController.transitioningDelegate = self
    }
}

// MARK: - UIViewControllerTransitioningDelegate
extension BottomSheetViewController: UIViewControllerTransitioningDelegate {}

// MARK: - UIGestureRecognizerDelegate
extension BottomSheetViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // I can't find another way to allow custom UIControl subclasses to receive touches
        return !(touch.view is UIControl)
    }

    @objc func didTapAnywhere() {
        view.endEditing(false)
    }
}
