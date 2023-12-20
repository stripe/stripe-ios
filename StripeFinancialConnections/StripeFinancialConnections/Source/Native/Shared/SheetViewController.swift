//
//  SheetViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 12/18/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

class SheetViewController: UIViewController {

    // The `contentView` represents the area of the sheet
    // where content is displayed. It's about 80% of the
    // screen and does NOT contain the dark overlay at the top.
    private let contentView = UIView(frame: UIScreen.main.bounds)

    // The `contentStackView` automatically resizes between the
    // bottom of `contentView` and the top of `contentView`.
    private lazy var contentStackView: UIStackView = {
        let contentStackView = UIStackView()
        contentStackView.axis = .vertical
        contentStackView.spacing = 0
        contentStackView.layer.cornerRadius = 20
        contentStackView.clipsToBounds = true
        contentStackView.addArrangedSubview(handleView)
        return contentStackView
    }()
    private lazy var handleView: UIView = {
        let handleView = CreateCustomSheetHandleView()
        handleView.backgroundColor = .customBackgroundColor
        return handleView
    }()
    // adds extra padding at the bottom of the sheet so when the
    // sheet is panned up, there is no blank space - instead,
    // it looks like a continous sheet
    //
    // it also covers the `contentStackView` cornerRadius at the bottom
    private lazy var sheetExtraBottomView: UIView = {
        let sheetExtraBottomView = UIView()
        sheetExtraBottomView.backgroundColor = .customBackgroundColor
        sheetExtraBottomView.isHidden = true // will be unhidden when presentation finishes
      return sheetExtraBottomView
    }()
    private var contentViewMinY: CGFloat = 0
    private var didPresent = false
    private var dismissAnimationInitialSpringVelocityY: CGFloat = 0

    private var paneViewContainerView: UIView?
    private var paneView: PaneLayoutView?

    private lazy var darkAreaTapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapDarkArea)
        )
        tapGestureRecognizer.delegate = self
        return tapGestureRecognizer
    }()

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        view.addSubview(contentView)

        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(contentStackView)
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(
                // keep the `contentStackView` flexible to resize
                greaterThanOrEqualTo: contentView.topAnchor,
                constant: 0
            ),
            contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])

        view.insertSubview(sheetExtraBottomView, belowSubview: contentView)
        sheetExtraBottomView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            sheetExtraBottomView.topAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -50),
            sheetExtraBottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetExtraBottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetExtraBottomView.heightAnchor.constraint(equalToConstant: 100),
        ])

        let panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGesture(_:))
        )
        view.addGestureRecognizer(panGestureRecognizer)

        view.addGestureRecognizer(darkAreaTapGestureRecognizer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        var contentViewMinY = view.window?.safeAreaInsets.top ?? 0
        contentViewMinY += 10 // estimated iOS value of how far drawer stretches
        contentViewMinY += UINavigationController().navigationBar.bounds.height
        contentViewMinY += 24 // typical FInancial COnnecitons padding
        let didChangeContentViewMinY = (self.contentViewMinY != contentViewMinY)
        self.contentViewMinY = contentViewMinY

        if didChangeContentViewMinY {
            var contentViewFrame = view.bounds
            contentViewFrame.size.height -= contentViewMinY
            contentViewFrame.origin.y = view.bounds.height - contentViewFrame.height
            contentView.frame = contentViewFrame

            // animate the sheet from top to bottom
            if !didPresent {
                didPresent = true

                var initialFrame = contentViewFrame
                initialFrame.origin.y += contentViewFrame.height
                let finalFrame = contentViewFrame

                self.sheetExtraBottomView.isHidden = true
                contentView.frame = initialFrame
                UIView.animate(
                    withDuration: customSheetAnimationDuration,
                    delay: 0,
                    options: .curveEaseOut,
                    animations: {
                        self.contentView.frame = finalFrame
                    },
                    completion: { _ in
                        self.sheetExtraBottomView.isHidden = false
                    }
                )
            }
        }
    }

    func setup(withContentView contentView: UIView, footerView: UIView?) {
        self.paneViewContainerView?.removeFromSuperview()
        self.paneViewContainerView = nil
        self.paneView = nil

        let paneLayoutView = PaneLayoutView(contentView: contentView, footerView: footerView)
        let paneContainerView = UIView()
        paneContainerView.backgroundColor = .customBackgroundColor
        paneLayoutView.addTo(view: paneContainerView)
        contentStackView.addArrangedSubview(paneContainerView)

        self.paneView = paneLayoutView
        self.paneViewContainerView = paneContainerView
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        animateSheetDismiss()
        super.dismiss(animated: flag, completion: completion)
    }

    @objc private func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        let touchPoint = recognizer.location(in: view)
        let translation = recognizer.translation(in: view)
        let velocity = recognizer.velocity(in: view)

        if recognizer.state == .began {
            addContentViewSnapshot()
        } else if recognizer.state == .changed {
            contentView.frame = CGRect(
                x: 0,
                y: {
                    // panning down
                    if translation.y > 0 {
                        return contentViewMinY + translation.y
                    }
                    // panning up
                    else {
                        return contentViewMinY + -self.dampenValue(abs(translation.y))
                    }
                }(),
                width: contentView.bounds.width,
                height: contentView.bounds.height
            )
            self.contentViewSnapshot?.frame = self.contentView.frame
        } else if recognizer.state == .ended {

            // panned above the sheet (the dark area by navigation bar)
            if contentView.frame.minY < self.contentViewMinY {
                UIView.animate(
                    withDuration: customSheetAnimationDuration,
                    delay: 0,
                    options: .curveEaseOut
                ) {
                    self.contentView.frame = CGRect(
                        x: 0,
                        y: self.contentViewMinY,
                        width: self.contentView.bounds.width,
                        height: self.contentView.bounds.height
                    )
                    self.removeContentViewSnapshot()
                }
            }
            // panned inside the sheet area
            else {
                let middleOfSheetY = view.bounds.height - (contentStackView.bounds.height / 2)
                let velocityThreshold: CGFloat = 500 // fast velocity
                let didPanDownHalfWay = (
                    touchPoint.y > middleOfSheetY
                    // ensure the user is NOT quickly panning up
                    // (indicating that they want the sheet to be opened)
                    && velocity.y > -velocityThreshold
                )
                let isQuicklyPanningDown = (velocity.y > velocityThreshold)

                // Sheet will be closed
                if didPanDownHalfWay || isQuicklyPanningDown {
                    dismissAnimationInitialSpringVelocityY = velocity.y
                    dismiss(animated: true)
                }
                // Sheet will remain open
                else {
                    UIView.animate(
                        withDuration: customSheetAnimationDuration,
                        delay: 0,
                        usingSpringWithDamping: 0.9,
                        // the abs on velocity is important as
                        // velocity when going up is negative
                        initialSpringVelocity: abs(velocity.y)/view.bounds.height,
                        options: [.curveEaseOut]
                    ) {
                        self.contentView.frame = CGRect(
                            x: 0,
                            y: self.contentViewMinY,
                            width: self.contentView.bounds.width,
                            height: self.contentView.bounds.height
                        )
                        self.removeContentViewSnapshot()
                    }
                }
            }
        }
    }

    private func animateSheetDismiss() {
        UIView.animate(
            withDuration: customSheetAnimationDuration,
            delay: 0,
            usingSpringWithDamping: 1.0,
            initialSpringVelocity: abs(dismissAnimationInitialSpringVelocityY)/view.bounds.height,
            options: [.curveEaseOut]
        ) {
            self.contentView.frame = CGRect(
                x: 0,
                y: self.view.bounds.height,
                width: self.contentView.bounds.width,
                height: self.contentView.bounds.height
            )
            self.removeContentViewSnapshot()
        }
    }

    private var contentViewSnapshot: UIView?
    private func addContentViewSnapshot() {
        // the `contentViewSnapshot` fixes various issues with just
        // animating `contentView`:
        // 1. during UIViewController dismiss animation, the UITextView
        //    text disappears for uknown reason
        // 2. on phones with safe area at the bottom, the safe area
        //    reduces as one drags the sheet up, but this causes the
        //    sheet stack view to resize, and the sheet to not
        //    properly follow the finger until the distance of
        //    safeAreaInset.bottom is traveled
        let contentViewSnapshot = contentView.snapshotView(afterScreenUpdates: false)
        contentViewSnapshot?.frame = contentView.frame
        if let contentViewSnapshot = contentViewSnapshot {
            // the `superview` should always be the UIViewController
            // `view` but we just do it here in case that is not true
            contentView.superview?.addSubview(contentViewSnapshot)
            contentView.isHidden = true
        }
        self.contentViewSnapshot = contentViewSnapshot
    }

    private func removeContentViewSnapshot() {
        self.contentViewSnapshot?.frame = self.contentView.frame
        self.contentViewSnapshot?.removeFromSuperview()
        self.contentViewSnapshot = nil
        self.contentView.isHidden = false
    }

    private func dampenValue(
        _ value: CGFloat,
        dampingFactor: CGFloat = 0.05
    ) -> CGFloat {
        guard dampingFactor > 0, value >= 0 else {
            return value
        }
        return (1 - exp(-dampingFactor * value)) / dampingFactor
    }

    @objc private func didTapDarkArea() {
        dismiss(animated: true)
    }

    // MARK: - Presenting

    fileprivate let transitionDelegate = CustomSheetTransitioningDelegate()
    func present(on viewController: UIViewController) {
        modalPresentationStyle = .custom
        transitioningDelegate = transitionDelegate
        viewController.present(self, animated: true)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension SheetViewController: UIGestureRecognizerDelegate {

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer === darkAreaTapGestureRecognizer {
            let point = gestureRecognizer.location(in: view)
            let drawerTopY = view.convert(handleView.frame.origin, from: handleView.superview).y
            if point.y < drawerTopY {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }

//    func gestureRecognizer(
//        _ gestureRecognizer: UIGestureRecognizer,
//        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
//    ) -> Bool {
//        // Allow simultaneous recognition
//        return true
//    }

//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
//                           shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        if gestureRecognizer == customPanGesture && otherGestureRecognizer == scrollView.panGestureRecognizer {
//            let isScrollingDown = scrollView.contentOffset.y <= 0 && scrollView.panGestureRecognizer.translation(in: scrollView).y > 0
//            return isScrollingDown
//        }
//        return false
//    }
}

private func CreateCustomSheetHandleView() -> UIView {
    let topPadding: CGFloat = 12
    let bottomPadding: CGFloat = 8
    let handleHeight: CGFloat = 4

    let containerView = UIView()
    containerView.backgroundColor = .customBackgroundColor
    containerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        containerView.heightAnchor.constraint(equalToConstant: topPadding + handleHeight + bottomPadding),
    ])

    let handleView = UIView()
    handleView.backgroundColor = UIColor.textDisabled // TODO(kgaidis): fix color
    handleView.layer.cornerRadius = 4
    containerView.addSubview(handleView)
    handleView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        handleView.widthAnchor.constraint(equalToConstant: 32),
        handleView.heightAnchor.constraint(equalToConstant: handleHeight),
        handleView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        handleView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: topPadding),
        handleView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -bottomPadding),
    ])
    return containerView
}

private class CustomSheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    private let transitionAnimator = CustomSheetTransitionAnimator()

    func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isPresenting = true
        return transitionAnimator
    }

    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        transitionAnimator.isPresenting = false
        return transitionAnimator
    }
}

private let customSheetAnimationDuration: TimeInterval = 0.3

private class CustomSheetTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private let backgroundDimmingView = UIView()

    var isPresenting: Bool = true

    override init() {
        super.init()
        backgroundDimmingView.backgroundColor = .black.withAlphaComponent(0.5)
    }

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        return customSheetAnimationDuration
    }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toViewController = transitionContext.viewController(forKey: .to),
            let fromViewController = transitionContext.viewController(forKey: .from)
        else {
            transitionContext.completeTransition(false)
            return
        }
        let containerView = transitionContext.containerView

        if isPresenting {
            // iPad
            if UIDevice.current.userInterfaceIdiom == .pad {
                // the `sheetContainerView` is a
                let sheetContainerView: UIView = {
                    // the `fromViewController` has the right frame
                    // (a sheet frame) so we use that to get the
                    // right sheet size
                    let origin = fromViewController.view.convert(
                        fromViewController.view.frame.origin,
                        to: fromViewController.view.window
                    )
                    let size = fromViewController.view.frame.size

                    let sheetContainerView = UIView(
                        frame: CGRect(
                            origin: origin,
                            size: size
                        )
                    )
                    sheetContainerView.backgroundColor = .clear
                    return sheetContainerView
                }()
                sheetContainerView.clipsToBounds = true
                sheetContainerView.layer.cornerRadius = {
                    let defaultCornerRadius: CGFloat = 10
                    let fromSuperView = fromViewController.view.superview
                    if (fromSuperView?.layer.cornerRadius ?? 0) > 0 {
                        return fromSuperView?.layer.cornerRadius ?? defaultCornerRadius
                    } else {
                        return defaultCornerRadius
                    }
                }() as CGFloat

                // rotate if iPad rotates
                sheetContainerView.autoresizingMask = [
                    .flexibleLeftMargin,
                    .flexibleTopMargin,
                    .flexibleRightMargin,
                    .flexibleBottomMargin,
                ]
                containerView.addSubview(sheetContainerView)

                sheetContainerView.addAndPinSubview(backgroundDimmingView)
                sheetContainerView.addAndPinSubview(toViewController.view)
            }
            // iPhone
            else {
                containerView.addAndPinSubview(backgroundDimmingView)
                containerView.addAndPinSubview(toViewController.view)
            }

            backgroundDimmingView.alpha = 0.0
            UIView.animate(
                withDuration: transitionDuration(using: transitionContext),
                animations: {
                    self.backgroundDimmingView.alpha = 1.0
                },
                completion: { _ in
                    transitionContext.completeTransition(true)
                }
            )
        }
        // dismissing the view controller
        else {
            backgroundDimmingView.alpha = 1.0
            UIView.animate(
                withDuration: transitionDuration(using: transitionContext),
                animations: {
                    self.backgroundDimmingView.alpha = 0.0
                },
                completion: { _ in
                    self.backgroundDimmingView.removeFromSuperview()
                    fromViewController.view.removeFromSuperview()
                    transitionContext.completeTransition(true)
                }
            )
        }
    }
}
