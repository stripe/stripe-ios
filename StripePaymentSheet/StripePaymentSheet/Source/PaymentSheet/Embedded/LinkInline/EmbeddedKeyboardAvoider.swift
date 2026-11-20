//
//  EmbeddedKeyboardAvoider.swift
//  StripePaymentSheet
//

@_spi(InternalOnlyAPI) import StripeUICore
import UIKit

/// Keeps a view inside the merchant's layout visible above the keyboard while it's being typed into.
///
/// The Embedded Payment Element doesn't own the screen it's on, so this scrolls the nearest ancestor scroll view, adding bottom
/// inset only when the content can't scroll far enough. Before focusing, `decide()` predicts whether that will work, so layouts
/// where it can't, like a screen that doesn't scroll, can use a dialog instead.
@MainActor
final class EmbeddedKeyboardAvoider: NSObject {
    enum Decision: Equatable {
        case inline
        case dialog(DialogReason)
    }

    enum DialogReason: String, Equatable {
        case notInWindow = "not_in_window"
        /// There's no scroll view, and the keyboard would cover the view where it is.
        case noScrollView = "no_scroll_view"
        /// The scroll view's area above the keyboard is too short for the view, e.g. at large text sizes.
        case doesNotFit = "does_not_fit"
    }

    /// Scroll view geometry in its own bounds (content) coordinate space.
    struct ScrollGeometry: Equatable {
        var boundsHeight: CGFloat
        var contentOffsetY: CGFloat
        var contentHeight: CGFloat
        var adjustedInsetTop: CGFloat
        /// Excludes any inset the avoider itself added.
        var adjustedInsetBottom: CGFloat
    }

    /// How to adjust a scroll view so the target sits inside the area the keyboard leaves visible.
    struct Plan: Equatable {
        var contentOffsetY: CGFloat
        /// Bottom inset to add when the content can't scroll far enough on its own.
        var extraBottomInset: CGFloat
    }

    /// Keyboard height last seen anywhere, used to predict whether focusing will cover the view.
    private static var lastObservedKeyboardHeight: CGFloat?

    /// Called when the view is still covered after the keyboard finished appearing.
    var onTargetObscured: (() -> Void)?

    private weak var targetView: UIView?
    private weak var adjustedScrollView: UIScrollView?
    private var appliedExtraInset: CGFloat = 0
    private var lastKeyboardFrameInWindow: CGRect?
    private(set) var isActive = false
    private let margin: CGFloat = 16
    private let accessoryHeight: CGFloat

    init(targetView: UIView, accessoryHeight: CGFloat) {
        self.targetView = targetView
        self.accessoryHeight = accessoryHeight
        super.init()
    }

    // MARK: - Geometry

    /// Returns nil when the target is already visible.
    /// - Parameters:
    ///   - target: The rect to keep visible, in the scroll view's bounds coordinate space.
    ///   - keyboardMinY: The keyboard's top edge in the same space, or `.greatestFiniteMagnitude` if it doesn't overlap.
    static func plan(geometry: ScrollGeometry, target: CGRect, keyboardMinY: CGFloat, margin: CGFloat) -> Plan? {
        let visibleTop = geometry.contentOffsetY + geometry.adjustedInsetTop
        let visibleBottom = min(geometry.contentOffsetY + geometry.boundsHeight - geometry.adjustedInsetBottom, keyboardMinY)
        let desiredTop = target.minY - margin
        let desiredBottom = target.maxY + margin

        let delta: CGFloat
        if desiredBottom - desiredTop > visibleBottom - visibleTop {
            // Too tall to fit; keep the top of the target visible.
            delta = desiredTop - visibleTop
        } else if desiredBottom > visibleBottom {
            delta = desiredBottom - visibleBottom
        } else if desiredTop < visibleTop {
            delta = desiredTop - visibleTop
        } else {
            return nil
        }

        let contentOffsetY = max(geometry.contentOffsetY + delta, -geometry.adjustedInsetTop)
        let maxContentOffsetY = geometry.contentHeight + geometry.adjustedInsetBottom - geometry.boundsHeight
        return Plan(contentOffsetY: contentOffsetY, extraBottomInset: max(0, contentOffsetY - maxContentOffsetY))
    }

    /// Whether a target of `targetHeight` fits between `visibleTop` and `visibleBottom` once the keyboard is up.
    static func canFit(targetHeight: CGFloat, margin: CGFloat, visibleTop: CGFloat, visibleBottom: CGFloat) -> Bool {
        return targetHeight + margin * 2 <= visibleBottom - visibleTop
    }

    // MARK: - Decision

    /// Predicts whether the target can stay visible once the keyboard is up.
    func decide() -> Decision {
        guard let targetView, let window = targetView.window else {
            return .dialog(.notInWindow)
        }
        let predictedHeight = Self.lastObservedKeyboardHeight ?? defaultKeyboardHeight(in: window)
        let keyboardTop = window.bounds.maxY - predictedHeight
        let targetInWindow = targetView.convert(targetView.bounds, to: nil)

        guard let scrollView = nearestScrollView() else {
            // Without a scroll view, the target has to sit above the keyboard already.
            return targetInWindow.maxY + margin <= keyboardTop ? .inline : .dialog(.noScrollView)
        }
        let scrollViewInWindow = scrollView.convert(scrollView.bounds, to: nil)
        let visibleTop = scrollViewInWindow.minY + scrollView.adjustedContentInset.top
        let visibleBottom = min(scrollViewInWindow.maxY - scrollView.adjustedContentInset.bottom, keyboardTop)
        return Self.canFit(targetHeight: targetInWindow.height, margin: margin, visibleTop: visibleTop, visibleBottom: visibleBottom)
            ? .inline
            : .dialog(.doesNotFit)
    }

    private func defaultKeyboardHeight(in window: UIWindow) -> CGFloat {
        let isLandscape = window.bounds.width > window.bounds.height
        let keys: CGFloat = window.traitCollection.userInterfaceIdiom == .pad ? 320 : (isLandscape ? 162 : 216)
        let quickTypeBar: CGFloat = 44
        return keys + quickTypeBar + accessoryHeight + window.safeAreaInsets.bottom
    }

    // MARK: - Focus lifecycle

    /// Call immediately before the target's field becomes first responder.
    func activate() {
        guard !isActive else { return }
        isActive = true
        let center = NotificationCenter.default
        center.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        center.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    /// Call after the field resigns first responder. Removes any inset the avoider added and leaves the scroll position alone.
    func deactivate() {
        guard isActive else { return }
        isActive = false
        NotificationCenter.default.removeObserver(self)
        lastKeyboardFrameInWindow = nil
        restoreInset(notification: nil)
    }

    /// Call when the target changes size while focused, e.g. when an error message appears.
    func targetDidChangeSize() {
        guard isActive, lastKeyboardFrameInWindow != nil else { return }
        adjust(notification: nil)
        verify()
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let window = targetView?.window,
              let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
        let frameInWindow = window.convert(endFrame, from: window.screen.coordinateSpace)
        lastKeyboardFrameInWindow = frameInWindow
        // An empty frame means there's no keyboard on screen, or one the window can't place; neither predicts the next keyboard.
        let visibleHeight = frameInWindow.isEmpty ? 0 : max(0, window.bounds.maxY - frameInWindow.minY)
        if visibleHeight > 0 {
            Self.lastObservedKeyboardHeight = visibleHeight
        }
        adjust(notification: notification)
    }

    @objc private func keyboardDidShow(_ notification: Notification) {
        // Hosts with their own keyboard handling, like UITableViewController scrolling to the first responder's cell,
        // move content after keyboardWillChangeFrame, so adjust once more once the keyboard has settled.
        adjust(notification: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.verify()
        }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        lastKeyboardFrameInWindow = nil
        restoreInset(notification: notification)
    }

    // MARK: - Adjusting

    private func adjust(notification: Notification?) {
        guard let targetView, let keyboardFrame = lastKeyboardFrameInWindow, let scrollView = nearestScrollView() else { return }
        let keyboardInScrollView = scrollView.convert(keyboardFrame, from: nil)
        let overlapsScrollView = keyboardFrame.height > 0 && keyboardInScrollView.minY < scrollView.bounds.maxY
        let geometry = ScrollGeometry(
            boundsHeight: scrollView.bounds.height,
            contentOffsetY: scrollView.contentOffset.y,
            contentHeight: scrollView.contentSize.height,
            adjustedInsetTop: scrollView.adjustedContentInset.top,
            adjustedInsetBottom: scrollView.adjustedContentInset.bottom - appliedExtraInset
        )
        guard let plan = Self.plan(
            geometry: geometry,
            target: scrollView.convert(targetView.bounds, from: targetView),
            keyboardMinY: overlapsScrollView ? keyboardInScrollView.minY : .greatestFiniteMagnitude,
            margin: margin
        ) else { return }

        let insetChange = plan.extraBottomInset - appliedExtraInset
        appliedExtraInset = plan.extraBottomInset
        adjustedScrollView = scrollView
        let animations = {
            scrollView.contentInset.bottom += insetChange
            scrollView.verticalScrollIndicatorInsets.bottom += insetChange
            scrollView.contentOffset.y = plan.contentOffsetY
        }
        if let notification {
            UIView.animateAlongsideKeyboard(notification, animations: animations)
        } else {
            UIView.animate(withDuration: UIAccessibility.isReduceMotionEnabled ? 0 : 0.25, animations: animations)
        }
    }

    private func restoreInset(notification: Notification?) {
        guard appliedExtraInset != 0, let scrollView = adjustedScrollView else { return }
        let insetChange = appliedExtraInset
        appliedExtraInset = 0
        let animations = {
            scrollView.contentInset.bottom -= insetChange
            scrollView.verticalScrollIndicatorInsets.bottom -= insetChange
        }
        if let notification {
            UIView.animateAlongsideKeyboard(notification, animations: animations)
        } else {
            animations()
        }
    }

    /// Calls `onTargetObscured` if the keyboard or a clipping ancestor still hides part of the target.
    private func verify() {
        guard isActive, let targetView, let window = targetView.window else { return }
        var visibleRect = window.bounds.inset(by: UIEdgeInsets(top: window.safeAreaInsets.top, left: 0, bottom: 0, right: 0))
        if let keyboardFrame = lastKeyboardFrameInWindow, keyboardFrame.height > 0 {
            visibleRect.size.height = max(0, min(visibleRect.maxY, keyboardFrame.minY) - visibleRect.minY)
        }
        var ancestor = targetView.superview
        while let view = ancestor, view !== window {
            if view.clipsToBounds {
                visibleRect = visibleRect.intersection(view.convert(view.bounds, to: nil))
            }
            ancestor = view.superview
        }
        let target = targetView.convert(targetView.bounds, to: nil)
        let visible = target.intersection(visibleRect)
        let obscuredPoints = visible.isNull ? target.height : target.height - visible.height
        if obscuredPoints > 0.5 {
            onTargetObscured?()
        }
    }

    private func nearestScrollView() -> UIScrollView? {
        var ancestor = targetView?.superview
        while let view = ancestor {
            if let scrollView = view as? UIScrollView, scrollView.isScrollEnabled, !(scrollView is UITextView) {
                return scrollView
            }
            ancestor = view.superview
        }
        return nil
    }
}
