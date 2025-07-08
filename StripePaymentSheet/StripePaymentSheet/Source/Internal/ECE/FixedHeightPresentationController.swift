//
//  FixedHeightPresentationController.swift
//  StripePaymentSheet
//
import UIKit

class FixedHeightPresentationController: UIPresentationController {

    private let heightRatio: CGFloat

    init(heightRatio: CGFloat, presentedViewController: UIViewController, presenting: UIViewController?) {
        self.heightRatio = heightRatio
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }

    // Optional overlay view for dimming the background
    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.alpha = 0.0

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissController))
        view.addGestureRecognizer(tapGesture)

        return view
    }()

    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else { return .zero }

        let height = containerView.bounds.height * heightRatio
        return CGRect(
            x: 0,
            y: containerView.bounds.height - height,
            width: containerView.bounds.width,
            height: height
        )
    }

    override func presentationTransitionWillBegin() {
        guard let containerView = containerView else { return }

        // Add the dimming view
        dimmingView.frame = containerView.bounds
        containerView.insertSubview(dimmingView, at: 0)

        // Animate the dimming view's alpha alongside the transition
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1.0
        })
    }

    override func dismissalTransitionWillBegin() {
        // Animate the dimming view's alpha alongside the transition
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.0
        })
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override func containerViewDidLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
        dimmingView.frame = containerView?.bounds ?? .zero
    }

    @objc func dismissController() {
        presentedViewController.dismiss(animated: true)
    }
}
