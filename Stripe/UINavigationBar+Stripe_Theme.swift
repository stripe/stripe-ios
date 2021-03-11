//
//  UINavigationBar+Stripe_Theme.swift
//  Stripe
//
//  Created by Jack Flintermann on 5/17/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

import ObjectiveC
import UIKit

/// This allows quickly setting the appearance of a `UINavigationBar` to match your
/// application. This is useful if you're presenting an `STPAddCardViewController`
/// or `STPPaymentOptionsViewController` inside a `UINavigationController`.
extension UINavigationBar {
    /// Sets the navigation bar's appearance to the desired theme. This will affect the
    /// bar's `tintColor` and `barTintColor` properties, as well as the color of the
    /// single-pixel line at the bottom of the navbar.
    /// - Parameter theme: the theme to use to style the navigation bar. - seealso: STPTheme.h
    /// @deprecated Use the `stp_theme` property instead
    @available(*, deprecated, message: "Use the `stp_theme` property instead")
    @objc
    public func stp_setTheme(_ theme: STPTheme) {
        stp_theme = theme
    }

    /// Sets the navigation bar's appearance to the desired theme. This will affect the bar's `tintColor` and `barTintColor` properties, as well as the color of the single-pixel line at the bottom of the navbar.
    /// Stripe view controllers will use their navigation bar's theme for their UIBarButtonItems instead of their own theme if it is not nil.
    /// - seealso: STPTheme.h

    @objc public var stp_theme: STPTheme? {
        get {
            return objc_getAssociatedObject(
                self, UnsafeRawPointer(&kUINavigationBarSTPThemeObjectKey))
                as? STPTheme
        }
        set(theme) {
            objc_setAssociatedObject(
                self, UnsafeRawPointer(&kUINavigationBarSTPThemeObjectKey), theme,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

            if let hairlineImageView = stp_hairlineImageView() {
                hairlineImageView.isHidden = theme != nil
            }

            guard let theme = theme else {
                return
            }

            stp_artificialHairlineView().backgroundColor = theme.tertiaryBackgroundColor
            barTintColor = theme.secondaryBackgroundColor
            tintColor = theme.accentColor
            barStyle = theme.barStyle
            isTranslucent = theme.translucentNavigationBar

            titleTextAttributes = [
                NSAttributedString.Key.font: theme.emphasisFont,
                NSAttributedString.Key.foregroundColor: theme.primaryForegroundColor,
            ]

            largeTitleTextAttributes = [
                NSAttributedString.Key.foregroundColor: theme.primaryForegroundColor
            ]

            if #available(iOS 13.0, *) {
                standardAppearance.backgroundColor = theme.secondaryBackgroundColor
                if let titleTextAttributes = titleTextAttributes {
                    standardAppearance.titleTextAttributes = titleTextAttributes
                }
                if let largeTitleTextAttributes = largeTitleTextAttributes {
                    standardAppearance.largeTitleTextAttributes = largeTitleTextAttributes
                }
                standardAppearance.buttonAppearance.normal.titleTextAttributes = [
                    NSAttributedString.Key.font: theme.font,
                    NSAttributedString.Key.foregroundColor: theme.accentColor,
                ]

                standardAppearance.buttonAppearance.highlighted.titleTextAttributes = [
                    NSAttributedString.Key.font: theme.font,
                    NSAttributedString.Key.foregroundColor: theme.accentColor,
                ]

                standardAppearance.buttonAppearance.disabled.titleTextAttributes = [
                    NSAttributedString.Key.font: theme.font,
                    NSAttributedString.Key.foregroundColor: theme.secondaryForegroundColor,
                ]

                standardAppearance.doneButtonAppearance.normal.titleTextAttributes = [
                    NSAttributedString.Key.font: theme.emphasisFont,
                    NSAttributedString.Key.foregroundColor: theme.accentColor,
                ]

                standardAppearance.doneButtonAppearance.highlighted.titleTextAttributes = [
                    NSAttributedString.Key.font: theme.emphasisFont,
                    NSAttributedString.Key.foregroundColor: theme.accentColor,
                ]

                standardAppearance.doneButtonAppearance.disabled.titleTextAttributes = [
                    NSAttributedString.Key.font: theme.emphasisFont,
                    NSAttributedString.Key.foregroundColor: theme.secondaryForegroundColor,
                ]
                scrollEdgeAppearance = standardAppearance
                compactAppearance = standardAppearance
            }
        }
    }

    func stp_artificialHairlineView() -> UIView {
        var view = viewWithTag(STPNavigationBarHairlineViewTag)
        if view == nil {
            view = UIView(frame: CGRect(x: 0, y: bounds.maxY, width: bounds.width, height: 0.5))
            view?.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
            view?.tag = STPNavigationBarHairlineViewTag
            if let view = view {
                addSubview(view)
            }
        }
        return view!
    }

    func stp_hairlineImageView() -> UIImageView? {
        return stp_hairlineImageView(self)
    }

    func stp_hairlineImageView(_ view: UIView) -> UIImageView? {
        if (view is UIImageView) && view.bounds.size.height <= 1.0 {
            return (view as? UIImageView)!
        }
        for subview in view.subviews {
            if let imageView = stp_hairlineImageView(subview) {
                return imageView
            }
        }
        return nil
    }
}

private let STPNavigationBarHairlineViewTag = 787473
private var kUINavigationBarSTPThemeObjectKey = 0
