//
//  EmbeddedVisibilityMonitor.swift
//  StripePaymentSheet
//

import UIKit

/// Reports the first time a view is actually on screen. Scrolling doesn't lay out the view, so while it's in a window this checks
/// periodically until it fires.
@MainActor
final class EmbeddedVisibilityMonitor {
    private weak var view: UIView?
    private let isVisible: @MainActor (UIView) -> Bool
    private let onFirstVisible: () -> Void
    private var timer: Timer?
    private(set) var hasFired = false

    init(
        view: UIView,
        isVisible: @escaping @MainActor (UIView) -> Bool = EmbeddedVisibilityMonitor.isOnScreen,
        onFirstVisible: @escaping () -> Void
    ) {
        self.view = view
        self.isVisible = isVisible
        self.onFirstVisible = onFirstVisible
    }

    deinit {
        timer?.invalidate()
    }

    /// Call when the view moves into or out of a window.
    func viewDidMoveToWindow() {
        guard !hasFired else { return }
        if view?.window != nil {
            check()
            startPollingIfNeeded()
        } else {
            stopPolling()
        }
    }

    func check() {
        guard !hasFired, let view, isVisible(view) else { return }
        hasFired = true
        stopPolling()
        onFirstVisible()
    }

    private func startPollingIfNeeded() {
        guard timer == nil, !hasFired else { return }
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.check()
            }
        }
        // `.common` keeps it firing while a scroll view is tracking.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    /// Whether `view` is in a foreground window, not hidden or transparent, mostly inside the visible part of its window and
    /// clipping ancestors, and not covered by a presented view controller.
    static func isOnScreen(_ view: UIView) -> Bool {
        guard let window = view.window, !window.isHidden else { return false }
        if let scene = window.windowScene, scene.activationState != .foregroundActive {
            return false
        }
        var ancestor: UIView? = view
        var visibleRect = window.bounds
        while let current = ancestor, current !== window {
            if current.isHidden || current.alpha < 0.01 {
                return false
            }
            if current !== view, current.clipsToBounds {
                visibleRect = visibleRect.intersection(current.convert(current.bounds, to: window))
            }
            ancestor = current.superview
        }
        let frame = view.convert(view.bounds, to: window)
        let visiblePart = frame.intersection(visibleRect)
        // Half the view, or its top 100pt for a tall one.
        guard !visiblePart.isNull, visiblePart.width > 0, visiblePart.height >= min(frame.height * 0.5, 100) else {
            return false
        }
        var responder: UIResponder? = view
        while let current = responder, !(current is UIViewController) {
            responder = current.next
        }
        if let owner = responder as? UIViewController, let presented = owner.presentedViewController, !presented.isBeingDismissed {
            return false
        }
        return true
    }
}
