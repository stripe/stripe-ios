//
//  CustomHeightPresentationController.swift
//  StripePaymentSheet
//
import UIKit

class CustomHeightPresentationController: UIPresentationController {
    enum PresentationHeight {
        case full
        case custom(CGFloat)
    }
    private var presentationHeight: PresentationHeight

    init(presentationHeight: PresentationHeight, presentedViewController: UIViewController, presenting: UIViewController?) {
        self.presentationHeight = presentationHeight
        
        super.init(presentedViewController: presentedViewController, presenting: presenting)
    }

    func updateHeightForKeyboard(_ presentationHeight: PresentationHeight, animated: Bool = true) {
        self.presentationHeight = presentationHeight

        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                self.presentedView?.frame = self.frameOfPresentedViewInContainerView
            }
        } else {
            presentedView?.frame = frameOfPresentedViewInContainerView
        }
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

        var height: CGFloat = 0
        switch presentationHeight {
        case .custom(let heightRatio):
            height = containerView.bounds.height * heightRatio
        case .full:
            height = containerView.bounds.height * 0.94
        }

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
