//
//  PanModalPresentable+Defaults.swift
//  PanModal
//
//  Copyright © 2018 Tiny Speck, Inc. All rights reserved.
//

#if os(iOS)
    import UIKit

    /**
     Default values for the PanModalPresentable.
     */
    @available(iOSApplicationExtension, unavailable)
    @available(macCatalystApplicationExtension, unavailable)
    public extension PanModalPresentable where Self: UIViewController {
        var topOffset: CGFloat {
            return topLayoutOffset + 21.0
        }

        var shortFormHeight: PanModalHeight {
            return longFormHeight
        }

        var longFormHeight: PanModalHeight {
            guard let scrollView = panScrollable
            else { return .maxHeight }

            // called once during presentation and stored
            scrollView.layoutIfNeeded()
            return .contentHeight(scrollView.contentSize.height)
        }

        var cornerRadius: CGFloat {
            return 8.0
        }

        var springDamping: CGFloat {
            return 0.8
        }

        var transitionDuration: Double {
            return PanModalAnimator.Constants.defaultTransitionDuration
        }

        var transitionAnimationOptions: UIView.AnimationOptions {
            return [.curveEaseInOut, .allowUserInteraction, .beginFromCurrentState]
        }

        var panModalBackgroundColor: UIColor {
            return UIColor.black.withAlphaComponent(0.7)
        }

        var dragIndicatorBackgroundColor: UIColor {
            return UIColor.lightGray
        }

        var scrollIndicatorInsets: UIEdgeInsets {
            let top = shouldRoundTopCorners ? cornerRadius : 0
            return UIEdgeInsets(top: CGFloat(top), left: 0, bottom: bottomLayoutOffset, right: 0)
        }

        var anchorModalToLongForm: Bool {
            return true
        }

        var allowsExtendedPanScrolling: Bool {
            guard let scrollView = panScrollable
            else { return false }

            scrollView.layoutIfNeeded()
            return scrollView.contentSize.height > (scrollView.frame.height - bottomLayoutOffset)
        }

        var allowsDragToDismiss: Bool {
            return true
        }

        var allowsTapToDismiss: Bool {
            return true
        }

        var isUserInteractionEnabled: Bool {
            return true
        }

        var isHapticFeedbackEnabled: Bool {
            return true
        }

        var shouldRoundTopCorners: Bool {
            return isPanModalPresented
        }

        var showDragIndicator: Bool {
            return shouldRoundTopCorners
        }

        func shouldRespond(to _: UIPanGestureRecognizer) -> Bool {
            return true
        }

        func willRespond(to _: UIPanGestureRecognizer) {}

        func shouldTransition(to _: PanModalPresentationController.PresentationState) -> Bool {
            return true
        }

        func shouldPrioritize(panModalGestureRecognizer _: UIPanGestureRecognizer) -> Bool {
            return false
        }

        func willTransition(to _: PanModalPresentationController.PresentationState) {}

        func panModalWillDismiss() {}

        func panModalDidDismiss() {}

        var shouldConfigureScrollViewInsets: Bool {
            return true
        }
    }
#endif
