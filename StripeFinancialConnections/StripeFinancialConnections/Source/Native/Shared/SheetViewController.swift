//
//  SheetViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 12/18/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

enum PanePresentationStyle {
    case fullscreen
    case sheet
}

extension Notification.Name {
    static let sheetViewControllerWillDismiss = Notification.Name("FinancialConnectionsSheetViewControllerWillDismiss")
}

class SheetViewController: UIViewController {

    private static let cornerRadius: CGFloat = 20

    // Used to toggle between sheet-specific logic and fullscreen.
    //
    // Due to `SheetViewController` being a subclass, and auth flow
    // design constraints of dynamically presenting panes either
    // as sheets or fullscreen, we need this to handle both states.
    let panePresentationStyle: PanePresentationStyle

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
        contentStackView.layer.cornerRadius = Self.cornerRadius
        // only round the corners of top left and top right corners
        contentStackView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        contentStackView.clipsToBounds = true
        if panePresentationStyle == .sheet {
            contentStackView.addArrangedSubview(handleView)
        }
        return contentStackView
    }()

    // The sheet/drawer handle at the top of the sheet
    private lazy var handleView: UIView = {
        let handleView = CreateCustomSheetHandleView()
        handleView.backgroundColor = FinancialConnectionsAppearance.Colors.background
        return handleView
    }()

    private var contentViewMinY: CGFloat = 0
    private var performedSheetPresentationAnimation = false
    private var dismissAnimationInitialSpringVelocityY: CGFloat = 0

    private var paneViewContainerView: UIView?
    private var paneView: PaneLayoutView?
    private var sheetTopConstraint: NSLayoutConstraint?

    private lazy var darkAreaTapGestureRecognizer: UITapGestureRecognizer = {
        let tapGestureRecognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(didTapDarkArea)
        )
        tapGestureRecognizer.delegate = self
        return tapGestureRecognizer
    }()

    init(panePresentationStyle: PanePresentationStyle = .sheet) {
        self.panePresentationStyle = panePresentationStyle
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = panePresentationStyle == .sheet ? .clear : FinancialConnectionsAppearance.Colors.background

        if panePresentationStyle == .sheet {
            view.addSubview(contentView)

            contentStackView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(contentStackView)

            let sheetTopConstraint = contentStackView.topAnchor.constraint(
                // keep the `contentStackView` flexible to resize
                greaterThanOrEqualTo: contentView.topAnchor,
                constant: 0
            )
            self.sheetTopConstraint = sheetTopConstraint
            NSLayoutConstraint.activate([
                sheetTopConstraint,
                contentStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                contentStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                contentStackView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor),
            ])

            Self.addBottomExtensionView(toView: contentView)

            let panGestureRecognizer = UIPanGestureRecognizer(
                target: self,
                action: #selector(handlePanGesture(_:))
            )
            view.addGestureRecognizer(panGestureRecognizer)

            view.addGestureRecognizer(darkAreaTapGestureRecognizer)
        }
        // non-sheet logic
        else {
            view.addAndPinSubview(contentView)
            contentView.addAndPinSubview(contentStackView)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            NotificationCenter.default.post(name: .sheetViewControllerWillDismiss, object: self)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if panePresentationStyle == .sheet {
            // Note that using `UIDevice.current.orientation.isLandscape`
            // performed worse (/ was buggy) when testing on device
            let isLandscapePhone = UIDevice.current.userInterfaceIdiom == .phone && (UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height)
            var contentViewMinY = view.window?.safeAreaInsets.top ?? 0
            // estimated iOS value of how far default sheet
            // stretches beyond safeAreaInset.top
            contentViewMinY += isLandscapePhone ? 0 : 10
            contentViewMinY += UINavigationController().navigationBar.bounds.height
            contentViewMinY += isLandscapePhone ? 0 : 24
            let didChangeContentViewMinY = (self.contentViewMinY != contentViewMinY)
            self.contentViewMinY = contentViewMinY

            // we only want `contentView.frame` to be adjusted
            // if view changes (ex. first presentation or rotation)
            // otherwise, there could be layout/animation glitches
            if didChangeContentViewMinY {
                var contentViewFrame = view.bounds
                contentViewFrame.size.height -= contentViewMinY
                contentViewFrame.origin.y = view.bounds.height - contentViewFrame.height
                contentView.frame = contentViewFrame

                // fixes a bug where rotations wouldn't properly
                // resize the sheet
                sheetTopConstraint?.isActive = false
                sheetTopConstraint?.isActive = true

                // animate the sheet from top to bottom
                if !performedSheetPresentationAnimation {
                    performedSheetPresentationAnimation = true

                    var initialFrame = contentViewFrame
                    initialFrame.origin.y += contentViewFrame.height
                    let finalFrame = contentViewFrame

                    contentView.frame = initialFrame
                    UIView.animate(
                        withDuration: sheetAnimationDuration,
                        delay: 0,
                        options: .curveEaseOut,
                        animations: {
                            self.contentView.frame = finalFrame
                        },
                        completion: { _ in }
                    )
                }
            }
        } else {
            // non-sheet layout is handled by auto-layout
        }
    }

    func setup(withContentView contentView: UIView, footerView: UIView?) {
        self.paneViewContainerView?.removeFromSuperview()
        self.paneViewContainerView = nil
        self.paneView = nil

        let paneLayoutView = PaneLayoutView(contentView: contentView, footerView: footerView)
        let paneContainerView = UIView()
        paneContainerView.backgroundColor = FinancialConnectionsAppearance.Colors.background
        paneLayoutView.addTo(view: paneContainerView)
        contentStackView.addArrangedSubview(paneContainerView)

        self.paneView = paneLayoutView
        self.paneViewContainerView = paneContainerView
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        if panePresentationStyle == .sheet {
            // animate dismiss animation
            UIView.animate(
                withDuration: sheetAnimationDuration,
                delay: 0,
                usingSpringWithDamping: 1.0,
                initialSpringVelocity: abs(dismissAnimationInitialSpringVelocityY)/max(1, view.bounds.height),
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
                    withDuration: sheetAnimationDuration,
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
                        withDuration: sheetAnimationDuration,
                        delay: 0,
                        usingSpringWithDamping: 0.9,
                        // the abs on velocity is important as
                        // velocity when going up is negative
                        initialSpringVelocity: abs(velocity.y)/max(1, view.bounds.height),
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
        contentViewSnapshot?.clipsToBounds = false
        contentViewSnapshot?.frame = contentView.frame
        if let contentViewSnapshot = contentViewSnapshot {
            // the `superview` should always be the UIViewController
            // `view` but we just do it here in case that is not true
            contentView.superview?.addSubview(contentViewSnapshot)
            contentView.isHidden = true
            Self.addBottomExtensionView(toView: contentViewSnapshot)
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
        return round((1 - exp(-dampingFactor * value)) / dampingFactor)
    }

    @objc private func didTapDarkArea() {
        dismiss(animated: true)
    }

    // Adds extra padding at the bottom of the sheet so
    // there is no blank space - instead, it looks like a
    // continous sheet
    private static func addBottomExtensionView(toView view: UIView) {
        view.clipsToBounds = false
        let extensionBottomView = UIView()
        extensionBottomView.backgroundColor = FinancialConnectionsAppearance.Colors.background
        view.insertSubview(extensionBottomView, at: 0)
        extensionBottomView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            extensionBottomView.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.bottomAnchor,
                // if we put this at "0" there will be a "glitchy gap"
                // while moving the drawer, so we set it to a higher
                // value to fix this gap
                //
                // it needs to be smaller than the bottom padding of
                // the footer view
                constant: -4
            ),
            extensionBottomView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            extensionBottomView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // the value is estimated...ideally it should cover bottom safe area insets,
            // and some extra to account for "pulling" the sheet up beyond the size
            // of it on screen
            extensionBottomView.heightAnchor.constraint(equalToConstant: 100),
        ])
    }

    // MARK: - Presenting

    fileprivate let transitionDelegate = SheetTransitioningDelegate()
    func present(on viewController: UIViewController) {
        modalPresentationStyle = .custom
        transitioningDelegate = transitionDelegate
        PresentationManager.shared.present(self, from: viewController)
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
}

private func CreateCustomSheetHandleView() -> UIView {
    let topPadding: CGFloat = 12
    let bottomPadding: CGFloat = 8
    let handleHeight: CGFloat = 4

    let containerView = UIView()
    containerView.backgroundColor = FinancialConnectionsAppearance.Colors.background
    containerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        containerView.heightAnchor.constraint(equalToConstant: topPadding + handleHeight + bottomPadding),
    ])

    let handleView = UIView()
    handleView.backgroundColor = FinancialConnectionsAppearance.Colors.spinnerNeutral
    handleView.layer.cornerRadius = 2
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

private class SheetTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {

    private let transitionAnimator = SheetTransitionAnimator()

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

private let sheetAnimationDuration: TimeInterval = 0.3

private class SheetTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    private let backgroundDimmingView = UIView()

    var isPresenting: Bool = true

    override init() {
        super.init()
        backgroundDimmingView.backgroundColor = .black.withAlphaComponent(0.5)
    }

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        return sheetAnimationDuration
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
                containerView.addSubview(sheetContainerView)
                sheetContainerView.autoresizingMask = [
                    .flexibleLeftMargin,
                    .flexibleTopMargin,
                    .flexibleRightMargin,
                    .flexibleBottomMargin,
                ]

                // WARNING: Do not use autolayout because it
                //          breaks the custom presentation
                //          when other VC is presented on top
                sheetContainerView.addSubview(backgroundDimmingView)
                backgroundDimmingView.frame = sheetContainerView.bounds
                backgroundDimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

                sheetContainerView.addSubview(toViewController.view)
                toViewController.view.frame = sheetContainerView.bounds
                toViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            }
            // iPhone
            else {
                // WARNING: Do not use autolayout because it
                //          breaks the custom presentation
                //          when other VC is presented on top
                containerView.addSubview(backgroundDimmingView)
                backgroundDimmingView.frame = containerView.bounds
                backgroundDimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

                containerView.addSubview(toViewController.view)
                toViewController.view.frame = containerView.bounds
                toViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
