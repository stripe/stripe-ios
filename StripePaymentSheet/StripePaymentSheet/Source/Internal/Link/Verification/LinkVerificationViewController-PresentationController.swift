//
//  LinkVerificationViewController-PresentationController.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

extension LinkVerificationViewController {

    /// For internal SDK use only
    @objc(STP_Internal_LinkPresentationController)
    final class PresentationController: UIPresentationController {
        struct Constants {
            static let padding: CGFloat = 16
            static let maxWidth: CGFloat = 400
            static let maxHeight: CGFloat = 410
            static let targetHeight: CGFloat = 332
        }

        /// A bottom inset necessary for the presented view to avoid the software keyboard.
        private var bottomInset: CGFloat = 0

        ///  An area where it is safe to present the modal on.
        ///
        ///  This is always equals to the container view safe area minus `padding` on eat edge.
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

        private var contentView: UIView? {
            if let scrollView = presentedView as? UIScrollView {
                return scrollView.subviews.first
            }

            return presentedView
        }

        override var frameOfPresentedViewInContainerView: CGRect {
            guard let containerView else {
                return .zero
            }

            return calculateModalFrame(forContainerSize: containerView.bounds.size)
        }

        func updatePresentedViewFrame() {
            presentedView?.frame = frameOfPresentedViewInContainerView
        }

        private func calculateModalFrame(forContainerSize containerSize: CGSize) -> CGRect {
            guard let contentView = contentView else {
                return .zero
            }

            let targetSize = CGSize(
                width: min(Constants.maxWidth, safeFrame.width),
                height: Constants.targetHeight
            )

            let fittingSize = contentView.systemLayoutSizeFitting(
                targetSize,
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .defaultLow
            )

            let actualSize = CGSize(
                width: fittingSize.width,
                height: min(fittingSize.height, Constants.maxHeight)
            )

            return CGRect(
                x: (containerSize.width - actualSize.width) / 2,
                y: max((containerSize.height - actualSize.height - bottomInset) / 2, Constants.padding),
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
            presentedView?.frame = frameOfPresentedViewInContainerView
        }

        override func presentationTransitionWillBegin() {
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
            super.dismissalTransitionWillBegin()
            guard let transitionCoordinator = presentedViewController.transitionCoordinator else {
                return
            }

            transitionCoordinator.animate(
                alongsideTransition: { _ in
                    self.dimmingView.alpha = 0.0
                },
                completion: { _ in
                    self.dimmingView.removeFromSuperview()
                }
            )
        }

        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
            super.viewWillTransition(to: size, with: coordinator)

            coordinator.animate { context in
                self.presentedView?.frame = self.calculateModalFrame(
                    forContainerSize: context.containerView.bounds.size
                )
            }
        }

        override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
            super.willTransition(to: newCollection, with: coordinator)

            coordinator.animate { context in
                self.presentedView?.frame = self.calculateModalFrame(
                    forContainerSize: context.containerView.bounds.size
                )
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

extension LinkVerificationViewController.PresentationController {

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
            self.presentedView?.frame = self.frameOfPresentedViewInContainerView
        }
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        UIView.animateAlongsideKeyboard(notification) {
            self.bottomInset = 0
            self.presentedView?.frame = self.frameOfPresentedViewInContainerView
        }
    }

}
