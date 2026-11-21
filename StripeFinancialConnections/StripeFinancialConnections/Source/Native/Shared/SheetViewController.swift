//
//  SheetViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 12/18/23.
//

import Foundation
@_spi(InternalOnlyAPI) import StripeUICore
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
    private let contentView = UIView()

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
        handleView.backgroundColor = FinancialConnectionsAppearance.Colors.surfacePrimary
        return handleView
    }()

    private var contentViewMinY: CGFloat = 0
    private var contentViewLayoutSize: CGSize = .zero
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
        view.backgroundColor = panePresentationStyle == .sheet ? .clear : FinancialConnectionsAppearance.Colors.surfacePrimary

        if panePresentationStyle == .sheet {
            // `viewDidLayoutSubviews` sizes the sheet; start at the view's size until then.
            contentView.frame = view.bounds
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

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        updateHorizontalSafeAreaInsets()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateHorizontalSafeAreaInsets()
    }

    /// Sheets cover the iPhone Duo's side column, so their content can ignore its horizontal safe area inset.
    private func updateHorizontalSafeAreaInsets() {
        let ignoredEdges: UIRectEdge = panePresentationStyle == .sheet ? sideColumnEdges : []
        // `safeAreaInsets` already includes `additionalSafeAreaInsets`, so remove them to get the system insets.
        // A view controller's root view doesn't clamp its safe area at 0, so this works even while they're negated.
        let systemLeftInset = view.safeAreaInsets.left - additionalSafeAreaInsets.left
        let systemRightInset = view.safeAreaInsets.right - additionalSafeAreaInsets.right
        let insets = UIEdgeInsets(
            top: 0,
            left: ignoredEdges.contains(.left) ? -systemLeftInset : 0,
            bottom: 0,
            right: ignoredEdges.contains(.right) ? -systemRightInset : 0
        )
        if additionalSafeAreaInsets != insets {
            additionalSafeAreaInsets = insets
        }
    }

    /// The physical edges where the system can place the iPhone Duo's side column.
    private var sideColumnEdges: UIRectEdge {
        #if compiler(>=6.4.2) && !os(visionOS)
        if #available(iOS 27.1, *) {
            // `verticalBarEdge` follows the layout direction, while safe area insets use physical edges.
            let isRightToLeft = view.effectiveUserInterfaceLayoutDirection == .rightToLeft
            switch traitCollection.verticalBarEdge {
            case .leading:
                return isRightToLeft ? .right : .left
            case .trailing:
                return isRightToLeft ? .left : .right
            case .unspecified:
                return []
            @unknown default:
                return []
            }
        }
        #endif
        // Without the trait, assume portrait insets come from the side column. In landscape,
        // horizontal insets come from the sensor housing instead, which the sheet doesn't cover.
        return traitCollection.verticalSizeClass == .regular ? [.left, .right] : []
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
            let isVerticallyCompact = traitCollection.verticalSizeClass == .compact
            var contentViewMinY = view.window?.safeAreaInsets.top ?? 0
            // estimated iOS value of how far default sheet
            // stretches beyond safeAreaInset.top
            contentViewMinY += isVerticallyCompact ? 0 : 10
            contentViewMinY += UINavigationController().navigationBar.bounds.height
            contentViewMinY += isVerticallyCompact ? 0 : 24
            let didChangeContentViewMinY = (self.contentViewMinY != contentViewMinY)
            self.contentViewMinY = contentViewMinY
            let didChangeViewSize = (contentViewLayoutSize != view.bounds.size)
            contentViewLayoutSize = view.bounds.size

            // we only want `contentView.frame` to be adjusted
            // if view changes (ex. first presentation, rotation, or window resize)
            // otherwise, there could be layout/animation glitches
            if didChangeContentViewMinY || didChangeViewSize {
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
        paneContainerView.backgroundColor = FinancialConnectionsAppearance.Colors.surfacePrimary
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
        extensionBottomView.backgroundColor = FinancialConnectionsAppearance.Colors.surfacePrimary
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
    /// The view controller that the sheet covers on iPad, which is presented as a form sheet.
    fileprivate weak var formSheetViewController: UIViewController?

    func present(on viewController: UIViewController) {
        var formSheetViewController = viewController
        while let parent = formSheetViewController.parent {
            formSheetViewController = parent
        }
        self.formSheetViewController = formSheetViewController
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
    containerView.backgroundColor = FinancialConnectionsAppearance.Colors.surfacePrimary
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

    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {
        return SheetPresentationController(presentedViewController: presented, presenting: presenting)
    }
}

private class SheetPresentationController: UIPresentationController {

    override func containerViewDidLayoutSubviews() {
        super.containerViewDidLayoutSubviews()
        // The form sheet moves and resizes with the window, so keep the sheet matched to it.
        layoutSheetContainerView()
    }

    /// Covers the form sheet when it's narrower than the window (e.g. on iPad or an unfolded iPhone Duo),
    /// and the whole window otherwise.
    func layoutSheetContainerView() {
        guard
            let containerView,
            let sheetContainerView = presentedViewController.view.superview,
            sheetContainerView !== containerView
        else {
            return
        }
        guard let formSheetViewController = (presentedViewController as? SheetViewController)?.formSheetViewController else {
            sheetContainerView.frame = containerView.bounds
            sheetContainerView.layer.cornerRadius = 0
            return
        }
        // Lay out the form sheet first, so its frame reflects the current window size.
        formSheetViewController.presentationController?.containerView?.layoutIfNeeded()
        let formSheetView = formSheetViewController.view!
        let formSheetFrame = formSheetView.convert(formSheetView.bounds, to: containerView)
        let coversFormSheet = formSheetFrame.width < containerView.bounds.width
        sheetContainerView.frame = coversFormSheet ? formSheetFrame : containerView.bounds
        // Only iPad presents the flow as a form sheet, whose corners clip the sheet. Page sheets, such as
        // on an unfolded iPhone Duo, don't round the corners that the sheet covers.
        let isFormSheet = coversFormSheet && formSheetViewController.modalPresentationStyle == .formSheet
        sheetContainerView.layer.cornerRadius = isFormSheet ? Self.cornerRadius(of: formSheetView) : 0
        sheetContainerView.layer.cornerCurve = .continuous
    }

    /// The corner radius that the system clips `formSheetView` to.
    private static func cornerRadius(of formSheetView: UIView) -> CGFloat {
        let defaultCornerRadius: CGFloat = 10
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            // The system rounds form sheets through `cornerConfiguration` on a superview, possibly split
            // across nested views with one corner each, and leaves `layer.cornerRadius` at 0.
            var view: UIView? = formSheetView
            while let current = view, current !== formSheetView.window {
                let corners: [UIRectCorner] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
                let radius = corners.map { current.effectiveRadius(corner: $0) }.max() ?? 0
                if radius > 0 {
                    return radius
                }
                view = current.superview
            }
            return defaultCornerRadius
        }
        #endif
        let superviewCornerRadius = formSheetView.superview?.layer.cornerRadius ?? 0
        return superviewCornerRadius > 0 ? superviewCornerRadius : defaultCornerRadius
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
            // WARNING: Do not use autolayout because it
            //          breaks the custom presentation
            //          when other VC is presented on top
            // dim the whole window, even when the sheet only covers the form sheet
            containerView.addSubview(backgroundDimmingView)
            backgroundDimmingView.frame = containerView.bounds
            backgroundDimmingView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            let sheetContainerView = UIView(frame: containerView.bounds)
            sheetContainerView.backgroundColor = .clear
            sheetContainerView.clipsToBounds = true
            containerView.addSubview(sheetContainerView)

            sheetContainerView.addSubview(toViewController.view)
            toViewController.view.frame = sheetContainerView.bounds
            toViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]

            // match the form sheet's frame, or the window's
            (toViewController.presentationController as? SheetPresentationController)?.layoutSheetContainerView()

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
