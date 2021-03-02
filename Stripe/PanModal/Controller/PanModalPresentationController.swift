//
//  PanModalPresentationController.swift
//  PanModal
//
//  Copyright © 2019 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
    import UIKit

    /// The PanModalPresentationController is the middle layer between the presentingViewController
    /// and the presentedViewController.
    ///
    /// It controls the coordination between the individual transition classes as well as
    /// provides an abstraction over how the presented view is presented & displayed.
    ///
    /// For example, we add a drag indicator view above the presented view and
    /// a background overlay between the presenting & presented view.
    ///
    /// The presented view's layout configuration & presentation is defined using the PanModalPresentable.
    ///
    /// By conforming to the PanModalPresentable protocol & overriding values
    /// the presented view can define its layout configuration & presentation.
    class PanModalPresentationController: UIPresentationController {

        /**
     Enum representing the possible presentation states
     */
        enum PresentationState {
            case shortForm
            case longForm
        }

        /**
     Constants
     */
        struct Constants {
            static let indicatorYOffset = CGFloat(8.0)
            static let snapMovementSensitivity = CGFloat(0.7)
            static let dragIndicatorSize = CGSize(width: 36.0, height: 5.0)
        }

        // MARK: - Properties
        private var bottomAnchor: NSLayoutConstraint?

        /**
     A flag to track if the presented view is animating
     */
        private var isPresentedViewAnimating = false

        /**
     A flag to determine if scrolling should seamlessly transition
     from the pan modal container view to the scroll view
     once the scroll limit has been reached.
     */
        private var extendsPanScrolling = true

        /**
     A flag to determine if scrolling should be limited to the longFormHeight.
     Return false to cap scrolling at .max height.
     */
        private var anchorModalToLongForm = true

        /**
     The y content offset value of the embedded scroll view
     */
        private var scrollViewYOffset: CGFloat = 0.0

        /**
     An observer for the scroll view content offset
     */
        private var scrollObserver: NSKeyValueObservation?

        // store the y positions so we don't have to keep re-calculating

        /**
     The y value for the short form presentation state
     */
        private var shortFormYPosition: CGFloat = 0

        /**
     The y value for the long form presentation state
     */
        private var longFormYPosition: CGFloat = 0

        /**
     Determine anchored Y postion based on the `anchorModalToLongForm` flag
     */
        private var anchoredYPosition: CGFloat {
            let defaultTopOffset = presentable?.topOffset ?? 0
            return anchorModalToLongForm ? longFormYPosition : defaultTopOffset
        }

        /**
     Configuration object for PanModalPresentationController
     */
        private var presentable: PanModalPresentable? {
            return presentedViewController as? PanModalPresentable
        }

        private lazy var fullHeightConstraint: NSLayoutConstraint = {
            guard let containerView = containerView else {
                assertionFailure()
                return NSLayoutConstraint()
            }
            return panContainerView.topAnchor.constraint(
                equalTo: containerView.safeAreaLayoutGuide.topAnchor)
        }()

        var forceFullHeight: Bool = false {
            didSet {
                fullHeightConstraint.isActive = forceFullHeight
            }
        }

        // MARK: - Views

        /**
     Background view used as an overlay over the presenting view
     */
        private lazy var backgroundView: DimmedView = {
            let view: DimmedView
            if let color = presentable?.panModalBackgroundColor {
                view = DimmedView(dimColor: color)
            } else {
                view = DimmedView()
            }
            view.didTap = { [weak self] _ in
                self?.presentable?.didTapOrSwipeToDismiss()
            }
            return view
        }()

        /**
     A wrapper around the presented view so that we can modify
     the presented view apperance without changing
     the presented view's properties
     */
        private lazy var panContainerView: PanContainerView = {
            let frame = containerView?.frame ?? .zero
            return PanContainerView(presentedView: presentedViewController.view, frame: frame)
        }()

        /**
     Drag Indicator View
     */
        private lazy var dragIndicatorView: UIView = {
            let view = UIView()
            view.backgroundColor = presentable?.dragIndicatorBackgroundColor
            view.layer.cornerRadius = Constants.dragIndicatorSize.height / 2.0
            return view
        }()

        /**
     Override presented view to return the pan container wrapper
     */
        override var presentedView: UIView {
            return panContainerView
        }

        // MARK: - Gesture Recognizers

        /**
     Gesture recognizer to detect & track pan gestures
     */
        private lazy var panGestureRecognizer: UIPanGestureRecognizer = {
            let gesture = UIPanGestureRecognizer(
                target: self, action: #selector(didPanOnPresentedView(_:)))
            gesture.minimumNumberOfTouches = 1
            gesture.maximumNumberOfTouches = 1
            gesture.delegate = self
            return gesture
        }()

        // MARK: - Deinitializers

        deinit {
            scrollObserver?.invalidate()
        }

        // MARK: - Lifecycle

        override func presentationTransitionWillBegin() {

            guard let containerView = containerView
            else { return }

            layoutBackgroundView(in: containerView)
            addPresentedView(in: containerView)
            configureScrollViewInsets()

            guard let coordinator = presentedViewController.transitionCoordinator else {
                backgroundView.dimState = .max
                return
            }

            coordinator.animate(alongsideTransition: { [weak self] _ in
                self?.backgroundView.dimState = .max
                self?.presentedViewController.setNeedsStatusBarAppearanceUpdate()
            })
        }

        override func presentationTransitionDidEnd(_ completed: Bool) {
            if completed { return }

            backgroundView.removeFromSuperview()
        }

        override func dismissalTransitionWillBegin() {
            presentable?.panModalWillDismiss()

            guard let coordinator = presentedViewController.transitionCoordinator else {
                backgroundView.dimState = .off
                return
            }

            /**
         Drag indicator is drawn outside of view bounds
         so hiding it on view dismiss means avoiding visual bugs
         */
            coordinator.animate(alongsideTransition: { [weak self] _ in
                self?.dragIndicatorView.alpha = 0.0
                self?.backgroundView.dimState = .off
                self?.presentingViewController.setNeedsStatusBarAppearanceUpdate()
            })
        }

        override func dismissalTransitionDidEnd(_ completed: Bool) {
            if !completed { return }

            presentable?.panModalDidDismiss()
        }

        /**
     Update presented view size in response to size class changes
     */
        override func viewWillTransition(
            to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator
        ) {
            super.viewWillTransition(to: size, with: coordinator)

            coordinator.animate(alongsideTransition: { [weak self] _ in
                guard
                    let self = self,
                    let presentable = self.presentable
                else { return }

                if presentable.shouldRoundTopCorners {
                    self.addRoundedCorners(to: self.presentedView)
                }
            })
        }

        var heightAnchor: NSLayoutConstraint? = nil
    }

    // MARK: - Methods

    extension PanModalPresentationController {

        /**
     Operations on the scroll view, such as content height changes,
     or when inserting/deleting rows can cause the pan modal to jump,
     caused by the pan modal responding to content offset changes.

     To avoid this, you can call this method to perform scroll view updates,
     with scroll observation temporarily disabled.
     */
        func performUpdates(_ updates: () -> Void) {

            guard let scrollView = presentable?.panScrollable
            else { return }

            // Pause scroll observer
            scrollObserver?.invalidate()
            scrollObserver = nil

            // Perform updates
            updates()

            // Resume scroll observer
            trackScrolling(scrollView)
            observe(scrollView: scrollView)
        }

        /**
     Updates the PanModalPresentationController layout
     based on values in the PanModalPresentable

     - Note: This should be called whenever any
     pan modal presentable value changes after the initial presentation
     */
        func setNeedsLayoutUpdate() {
            observe(scrollView: presentable?.panScrollable)
            configureScrollViewInsets()
        }
    }

    // MARK: - Presented View Layout Configuration

    extension PanModalPresentationController {

        /**
     Boolean flag to determine if the presented view is anchored
     */
        fileprivate var isPresentedViewAnchored: Bool {
            if !isPresentedViewAnimating
                && extendsPanScrolling
                && presentedView.frame.minY.rounded() <= anchoredYPosition.rounded()
            {
                return true
            }

            return false
        }

        /**
     Adds the presented view to the given container view
     & configures the view elements such as drag indicator, rounded corners
     based on the pan modal presentable.
     */
        fileprivate func addPresentedView(in containerView: UIView) {

            /**
         If the presented view controller does not conform to pan modal presentable
         don't configure
         */
            guard let presentable = presentable
            else { return }

            /**
         ⚠️ If this class is NOT used in conjunction with the PanModalPresentationAnimator
         & PanModalPresentable, the presented view should be added to the container view
         in the presentation animator instead of here
         */
            presentedView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(presentedView)
            containerView.addGestureRecognizer(panGestureRecognizer)

            // We'll use this constraint to handle the keyboard
            let bottomAnchor = presentedView.bottomAnchor.constraint(
                equalTo: containerView.safeAreaLayoutGuide.bottomAnchor)
            self.bottomAnchor = bottomAnchor

            // The presented view (BottomSheetVC) does not inherit safeAreaLayoutGuide.bottom, so use a dummy view instead
            let coverUpBottomView = UIView()
            presentedView.addSubview(coverUpBottomView)
            coverUpBottomView.backgroundColor = PaymentSheetUI.backgroundColor
            coverUpBottomView.translatesAutoresizingMaskIntoConstraints = false

            NSLayoutConstraint.activate([
                presentedView.topAnchor.constraint(
                    greaterThanOrEqualTo: containerView.safeAreaLayoutGuide.topAnchor),
                presentedView.leadingAnchor.constraint(
                    equalTo: containerView.safeAreaLayoutGuide.leadingAnchor),
                presentedView.trailingAnchor.constraint(
                    equalTo: containerView.safeAreaLayoutGuide.trailingAnchor),
                bottomAnchor,

                coverUpBottomView.topAnchor.constraint(equalTo: presentedView.bottomAnchor),
                coverUpBottomView.leadingAnchor.constraint(
                    equalTo: containerView.safeAreaLayoutGuide.leadingAnchor),
                coverUpBottomView.trailingAnchor.constraint(
                    equalTo: containerView.safeAreaLayoutGuide.trailingAnchor),
                coverUpBottomView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            ])

            if presentable.showDragIndicator {
                addDragIndicatorView(to: presentedView)
            }

            if presentable.shouldRoundTopCorners {
                addRoundedCorners(to: presentedView)
            }

            adjustPanContainerBackgroundColor()
            registerForKeyboardNotifications()
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
            guard
                let userInfo = notification.userInfo,
                let keyboardScreenEndFrame =
                    (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?
                    .cgRectValue,
                let containerView = containerView,
                let bottomAnchor = bottomAnchor
            else {
                return
            }

            let keyboardViewEndFrame = containerView.convert(
                keyboardScreenEndFrame, from: containerView.window)
            let keyboardInViewHeight =
                containerView.bounds.intersection(keyboardViewEndFrame).height
                - containerView.safeAreaInsets.bottom
            if notification.name == UIResponder.keyboardWillHideNotification {
                bottomAnchor.constant = 0
            } else {
                bottomAnchor.constant = -keyboardInViewHeight
            }

            // Get keyboard animation info
            let durationKey = UIResponder.keyboardAnimationDurationUserInfoKey
            let duration = userInfo[durationKey] as? Double ?? 0.2
            let curveValue = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int ?? -1
            let curve = UIView.AnimationCurve(rawValue: curveValue) ?? .easeOut

            // Animate the container above the keyboard
            containerView.setNeedsLayout()
            let animator = UIViewPropertyAnimator(duration: duration, curve: curve) {
                containerView.layoutIfNeeded()
            }
            animator.startAnimation()
        }

        /**
     Adds a background color to the pan container view
     in order to avoid a gap at the bottom
     during initial view presentation in longForm (when view bounces)
     */
        fileprivate func adjustPanContainerBackgroundColor() {
            panContainerView.backgroundColor =
                presentedViewController.view.backgroundColor
                ?? presentable?.panScrollable?.backgroundColor
        }

        /**
     Adds the background view to the view hierarchy
     & configures its layout constraints.
     */
        fileprivate func layoutBackgroundView(in containerView: UIView) {
            containerView.addSubview(backgroundView)
            backgroundView.translatesAutoresizingMaskIntoConstraints = false
            backgroundView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
            backgroundView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor).isActive =
                true
            backgroundView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor).isActive =
                true
            backgroundView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor).isActive =
                true
        }

        /**
     Adds the drag indicator view to the view hierarchy
     & configures its layout constraints.
     */
        fileprivate func addDragIndicatorView(to view: UIView) {
            view.addSubview(dragIndicatorView)
            dragIndicatorView.translatesAutoresizingMaskIntoConstraints = false
            dragIndicatorView.topAnchor.constraint(
                equalTo: view.topAnchor, constant: Constants.indicatorYOffset
            ).isActive = true
            dragIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            dragIndicatorView.widthAnchor.constraint(
                equalToConstant: Constants.dragIndicatorSize.width
            ).isActive = true
            dragIndicatorView.heightAnchor.constraint(
                equalToConstant: Constants.dragIndicatorSize.height
            ).isActive = true
        }

        /**
     Configures the scroll view insets
     */
        fileprivate func configureScrollViewInsets() {

            guard
                let scrollView = presentable?.panScrollable,
                !scrollView.isScrolling
            else { return }

            /**
         Disable vertical scroll indicator until we start to scroll
         to avoid visual bugs
         */
            scrollView.showsVerticalScrollIndicator = false
            scrollView.scrollIndicatorInsets = presentable?.scrollIndicatorInsets ?? .zero

            /**
         Set the appropriate contentInset as the configuration within this class
         offsets it
         */
            scrollView.contentInset.bottom = presentingViewController.view.safeAreaInsets.bottom

            /**
         As we adjust the bounds during `handleScrollViewTopBounce`
         we should assume that contentInsetAdjustmentBehavior will not be correct
         */
            if #available(iOS 11.0, *) {
                scrollView.contentInsetAdjustmentBehavior = .never
            }
        }

    }

    // MARK: - Pan Gesture Event Handler

    extension PanModalPresentationController {

        /**
     The designated function for handling pan gesture events
     */
        @objc fileprivate func didPanOnPresentedView(_ recognizer: UIPanGestureRecognizer) {}

        /**
     Determine if the pan modal should respond to the gesture recognizer.

     If the pan modal is already being dragged & the delegate returns false, ignore until
     the recognizer is back to it's original state (.began)

     ⚠️ This is the only time we should be cancelling the pan modal gesture recognizer
     */
        fileprivate func shouldRespond(to panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
            guard
                presentable?.shouldRespond(to: panGestureRecognizer) == true
                    || !(panGestureRecognizer.state == .began
                        || panGestureRecognizer.state == .cancelled)
            else {
                panGestureRecognizer.isEnabled = false
                panGestureRecognizer.isEnabled = true
                return false
            }
            return !shouldFail(panGestureRecognizer: panGestureRecognizer)
        }

        /**
     Communicate intentions to presentable and adjust subviews in containerView
     */
        fileprivate func respond(to panGestureRecognizer: UIPanGestureRecognizer) {
            presentable?.willRespond(to: panGestureRecognizer)

            var yDisplacement = panGestureRecognizer.translation(in: presentedView).y

            /**
         If the presentedView is not anchored to long form, reduce the rate of movement
         above the threshold
         */
            if presentedView.frame.origin.y < longFormYPosition {
                yDisplacement /= 2.0
            }

            panGestureRecognizer.setTranslation(.zero, in: presentedView)
        }

        /**
     Determines if we should fail the gesture recognizer based on certain conditions

     We fail the presented view's pan gesture recognizer if we are actively scrolling on the scroll view.
     This allows the user to drag whole view controller from outside scrollView touch area.

     Unfortunately, cancelling a gestureRecognizer means that we lose the effect of transition scrolling
     from one view to another in the same pan gesture so don't cancel
     */
        fileprivate func shouldFail(panGestureRecognizer: UIPanGestureRecognizer) -> Bool {

            /**
         Allow api consumers to override the internal conditions &
         decide if the pan gesture recognizer should be prioritized.

         ⚠️ This is the only time we should be cancelling the panScrollable recognizer,
         for the purpose of ensuring we're no longer tracking the scrollView
         */
            guard !shouldPrioritize(panGestureRecognizer: panGestureRecognizer) else {
                presentable?.panScrollable?.panGestureRecognizer.isEnabled = false
                presentable?.panScrollable?.panGestureRecognizer.isEnabled = true
                return false
            }

            guard
                isPresentedViewAnchored,
                let scrollView = presentable?.panScrollable,
                scrollView.contentOffset.y > 0
            else {
                return false
            }

            let loc = panGestureRecognizer.location(in: presentedView)
            return (scrollView.frame.contains(loc) || scrollView.isScrolling)
        }

        /**
     Determine if the presented view's panGestureRecognizer should be prioritized over
     embedded scrollView's panGestureRecognizer.
     */
        fileprivate func shouldPrioritize(panGestureRecognizer: UIPanGestureRecognizer) -> Bool {
            return panGestureRecognizer.state == .began
                && presentable?.shouldPrioritize(panModalGestureRecognizer: panGestureRecognizer)
                    == true
        }

        /**
     Check if the given velocity is within the sensitivity range
     */
        fileprivate func isVelocityWithinSensitivityRange(_ velocity: CGFloat) -> Bool {
            return (abs(velocity) - (1000 * (1 - Constants.snapMovementSensitivity))) > 0
        }

        /**
     Finds the nearest value to a given number out of a given array of float values

     - Parameters:
        - number: reference float we are trying to find the closest value to
        - values: array of floats we would like to compare against
     */
        fileprivate func nearest(to number: CGFloat, inValues values: [CGFloat]) -> CGFloat {
            guard let nearestVal = values.min(by: { abs(number - $0) < abs(number - $1) })
            else { return number }
            return nearestVal
        }
    }

    // MARK: - UIScrollView Observer

    extension PanModalPresentationController {

        /**
     Creates & stores an observer on the given scroll view's content offset.
     This allows us to track scrolling without overriding the scrollView delegate
     */
        fileprivate func observe(scrollView: UIScrollView?) {
            scrollObserver?.invalidate()
            scrollObserver = scrollView?.observe(\.contentOffset, options: .old) {
                [weak self] scrollView, change in

                /**
             Incase we have a situation where we have two containerViews in the same presentation
             */
                guard self?.containerView != nil
                else { return }

                self?.didPanOnScrollView(scrollView, change: change)
            }
        }

        /**
     Scroll view content offset change event handler

     Also when scrollView is scrolled to the top, we disable the scroll indicator
     otherwise glitchy behaviour occurs

     This is also shown in Apple Maps (reverse engineering)
     which allows us to seamlessly transition scrolling from the panContainerView to the scrollView
     */
        fileprivate func didPanOnScrollView(
            _ scrollView: UIScrollView, change: NSKeyValueObservedChange<CGPoint>
        ) {

            guard
                !presentedViewController.isBeingDismissed,
                !presentedViewController.isBeingPresented
            else { return }

            if !isPresentedViewAnchored && scrollView.contentOffset.y > 0 {

                /**
             Hold the scrollView in place if we're actively scrolling and not handling top bounce
             */
                haltScrolling(scrollView)

            } else if scrollView.isScrolling || isPresentedViewAnimating {

                if isPresentedViewAnchored {
                    /**
                 While we're scrolling upwards on the scrollView,
                 store the last content offset position
                 */
                    trackScrolling(scrollView)
                } else {
                    /**
                 Keep scroll view in place while we're panning on main view
                 */
                    haltScrolling(scrollView)
                }

            } else if presentedViewController.view.isKind(of: UIScrollView.self)
                && !isPresentedViewAnimating && scrollView.contentOffset.y <= 0
            {

                /**
             In the case where we drag down quickly on the scroll view and let go,
             `handleScrollViewTopBounce` adds a nice elegant touch.
             */
                handleScrollViewTopBounce(scrollView: scrollView, change: change)
            } else {
                trackScrolling(scrollView)
            }
        }

        /**
     Halts the scroll of a given scroll view & anchors it at the `scrollViewYOffset`
     */
        fileprivate func haltScrolling(_ scrollView: UIScrollView) {
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollViewYOffset), animated: false)
            scrollView.showsVerticalScrollIndicator = false
        }

        /**
     As the user scrolls, track & save the scroll view y offset.
     This helps halt scrolling when we want to hold the scroll view in place.
     */
        fileprivate func trackScrolling(_ scrollView: UIScrollView) {
            scrollViewYOffset = max(scrollView.contentOffset.y, 0)
            scrollView.showsVerticalScrollIndicator = true
        }

        /**
     To ensure that the scroll transition between the scrollView & the modal
     is completely seamless, we need to handle the case where content offset is negative.

     In this case, we follow the curve of the decelerating scroll view.
     This gives the effect that the modal view and the scroll view are one view entirely.

     - Note: This works best where the view behind view controller is a UIScrollView.
     So, for example, a UITableViewController.
     */
        fileprivate func handleScrollViewTopBounce(
            scrollView: UIScrollView, change: NSKeyValueObservedChange<CGPoint>
        ) {

            guard let oldYValue = change.oldValue?.y, scrollView.isDecelerating
            else { return }

            let yOffset = scrollView.contentOffset.y
            let presentedSize = containerView?.frame.size ?? .zero

            /**
         Decrease the view bounds by the y offset so the scroll view stays in place
         and we can still get updates on its content offset
         */
            presentedView.bounds.size = CGSize(
                width: presentedSize.width, height: presentedSize.height + yOffset)

            if oldYValue > yOffset {
                /**
             Move the view in the opposite direction to the decreasing bounds
             until half way through the deceleration so that it appears
             as if we're transferring the scrollView drag momentum to the entire view
             */
                presentedView.frame.origin.y = longFormYPosition - yOffset
            } else {
                scrollViewYOffset = 0
                //            snap(toYPosition: longFormYPosition)
            }

            scrollView.showsVerticalScrollIndicator = false
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    extension PanModalPresentationController: UIGestureRecognizerDelegate {

        /**
     Do not require any other gesture recognizers to fail
     */
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return false
        }

        /**
     Allow simultaneous gesture recognizers only when the other gesture recognizer's view
     is the pan scrollable view
     */
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return otherGestureRecognizer.view == presentable?.panScrollable
        }
    }

    // MARK: - UIBezierPath

    extension PanModalPresentationController {

        /**
     Draws top rounded corners on a given view
     We have to set a custom path for corner rounding
     because we render the dragIndicator outside of view bounds
     */
        fileprivate func addRoundedCorners(to view: UIView) {
            let radius = presentable?.cornerRadius ?? 0
            let path = UIBezierPath(
                roundedRect: view.bounds,
                byRoundingCorners: [.topLeft, .topRight],
                cornerRadii: CGSize(width: radius, height: radius))

            // Draw around the drag indicator view, if displayed
            if presentable?.showDragIndicator == true {
                let indicatorLeftEdgeXPos =
                    view.bounds.width / 2.0 - Constants.dragIndicatorSize.width / 2.0
                drawAroundDragIndicator(
                    currentPath: path, indicatorLeftEdgeXPos: indicatorLeftEdgeXPos)
            }

            // Set path as a mask to display optional drag indicator view & rounded corners
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            view.layer.mask = mask

            // Improve performance by rasterizing the layer
            view.layer.shouldRasterize = true
            view.layer.rasterizationScale = UIScreen.main.scale
        }

        /**
     Draws a path around the drag indicator view
     */
        fileprivate func drawAroundDragIndicator(
            currentPath path: UIBezierPath, indicatorLeftEdgeXPos: CGFloat
        ) {

            let totalIndicatorOffset =
                Constants.indicatorYOffset + Constants.dragIndicatorSize.height

            // Draw around drag indicator starting from the left
            path.addLine(to: CGPoint(x: indicatorLeftEdgeXPos, y: path.currentPoint.y))
            path.addLine(
                to: CGPoint(x: path.currentPoint.x, y: path.currentPoint.y - totalIndicatorOffset))
            path.addLine(
                to: CGPoint(
                    x: path.currentPoint.x + Constants.dragIndicatorSize.width,
                    y: path.currentPoint.y))
            path.addLine(
                to: CGPoint(x: path.currentPoint.x, y: path.currentPoint.y + totalIndicatorOffset))
        }
    }

    // MARK: - Helper Extensions

    extension UIScrollView {

        /**
     A flag to determine if a scroll view is scrolling
     */
        fileprivate var isScrolling: Bool {
            return isDragging && !isDecelerating || isTracking
        }
    }
#endif
