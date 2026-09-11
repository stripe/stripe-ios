//
//  LinkAuthFlowViewController-PresentationController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

extension LinkAuthFlowViewController {

    /// For internal SDK use only
    @objc(STP_Internal_LinkPresentationController)
    final class PresentationController: UIPresentationController {
        struct Constants {
            static let padding: CGFloat = 16
            static let maxWidth: CGFloat = 400
        }

        /// A bottom inset necessary for the presented view to avoid the software keyboard.
        private var bottomInset: CGFloat = 0

        /// UIKit owns the view's animated frame once dismissal begins.
        private var isDismissing = false
        private var frameAtDismissal: CGRect?

        ///  An area where it is safe to present the modal on.
        ///
        ///  The container view safe area minus `padding` on each edge.
        private var safeFrame: CGRect {
            guard let containerView else {
                return .zero
            }

            return containerView.bounds
                .inset(by: containerView.safeAreaInsets)
                .insetBy(dx: Constants.padding, dy: Constants.padding)
        }

        private lazy var dimmingView: UIView = {
            let view = UIView()
            view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            return view
        }()

        override var frameOfPresentedViewInContainerView: CGRect {
            if isDismissing, let frameAtDismissal {
                return frameAtDismissal
            }
            guard let containerView else {
                return .zero
            }

            return calculateModalFrame(forContainerSize: containerView.bounds.size)
        }

        func updatePresentedViewFrame() {
            guard !isDismissing, containerView != nil else { return }
            let frame = frameOfPresentedViewInContainerView
            if presentedView?.frame != frame {
                presentedView?.frame = frame
            }
        }

        private func calculateModalFrame(forContainerSize containerSize: CGSize) -> CGRect {
            guard let controller = presentedViewController as? LinkAuthFlowViewController else {
                return .zero
            }

            let width = min(Constants.maxWidth, safeFrame.width)
            let availableHeight = max(0, safeFrame.height - bottomInset)
            let actualSize = CGSize(
                width: width,
                height: min(controller.fittingHeight(width: width), availableHeight)
            )

            return CGRect(
                x: (containerSize.width - actualSize.width) / 2,
                y: safeFrame.minY + (availableHeight - actualSize.height) / 2,
                width: actualSize.width,
                height: actualSize.height
            ).integral
        }

        override func containerViewWillLayoutSubviews() {
            super.containerViewWillLayoutSubviews()

            guard let containerView else {
                return
            }

            dimmingView.frame = containerView.bounds
            updatePresentedViewFrame()
        }

        override func presentationTransitionWillBegin() {
            isDismissing = false
            frameAtDismissal = nil
            super.presentationTransitionWillBegin()

            guard let containerView,
                  let transitionCoordinator = presentedViewController.transitionCoordinator else {
                return
            }

            containerView.insertSubview(dimmingView, at: 0)
            dimmingView.frame = containerView.bounds
            dimmingView.alpha = 0

            transitionCoordinator.animate { _ in
                self.dimmingView.alpha = 1
            }
        }

        override func dismissalTransitionWillBegin() {
            frameAtDismissal = presentedView?.frame
            isDismissing = true
            super.dismissalTransitionWillBegin()
            guard let transitionCoordinator = presentedViewController.transitionCoordinator else {
                dimmingView.alpha = 0
                return
            }

            transitionCoordinator.animate(
                alongsideTransition: { _ in
                    self.dimmingView.alpha = 0.0
                }
            )
        }

        override func dismissalTransitionDidEnd(_ completed: Bool) {
            super.dismissalTransitionDidEnd(completed)
            if completed {
                dimmingView.removeFromSuperview()
            } else {
                isDismissing = false
                frameAtDismissal = nil
                dimmingView.alpha = 1
                updatePresentedViewFrame()
            }
        }

        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)

            coordinator.animate { _ in
                self.updatePresentedViewFrame()
            }
        }

        override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
            super.willTransition(to: newCollection, with: coordinator)

            coordinator.animate { _ in
                self.updatePresentedViewFrame()
            }
        }

        override init(
            presentedViewController: UIViewController,
            presenting presentingViewController: UIViewController?
        ) {
            super.init(presentedViewController: presentedViewController, presenting: presentingViewController)

            NotificationCenter.default.addObserver(self,
                selector: #selector(keyboardFrameChanged(_:)),
                name: UIResponder.keyboardWillChangeFrameNotification,
                object: nil)

            NotificationCenter.default.addObserver(self,
                selector: #selector(keyboardWillHide(_:)),
                name: UIResponder.keyboardWillHideNotification,
                object: nil)
        }

        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }

}

// MARK: - Keyboard handling

extension LinkAuthFlowViewController.PresentationController {

    @objc func keyboardFrameChanged(_ notification: Notification) {
        let userInfo = notification.userInfo

        guard let keyboardFrame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let containerView else {
            return
        }

        let absoluteFrame = containerView.convert(safeFrame, to: containerView.window)
        let intersection = absoluteFrame.intersection(keyboardFrame)

        UIView.animateAlongsideKeyboard(notification) {
            self.bottomInset = intersection.height
            self.updatePresentedViewFrame()
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        UIView.animateAlongsideKeyboard(notification) {
            self.bottomInset = 0
            self.updatePresentedViewFrame()
        }
    }

}
