//
//  UINavigationController+StripeIdentity.swift
//  StripeIdentity
//
//  Created by Jaime Park on 2/10/22.
//

import UIKit
@_spi(STP) import StripeUICore

extension UINavigationController {
    func configureBorderlessNavigationBar() {
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.copyButtonAppearance(from: UINavigationBar.appearance().standardAppearance)
            appearance.configureWithTransparentBackground()

            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
        } else {
            navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationBar.shadowImage = UIImage()
            navigationBar.backgroundColor = .clear
        }
    }

    func setNavigationBarBackgroundColor(with backgroundColor: UIColor?) {
        let bgColor = backgroundColor ?? CompatibleColor.systemBackground

        if #available(iOS 13.0, *) {
            navigationBar.standardAppearance.backgroundColor = bgColor
            navigationBar.scrollEdgeAppearance?.backgroundColor = bgColor
        } else {
            navigationBar.backgroundColor = bgColor
        }
    }
}

@available(iOS 13.0, *)
private extension UINavigationBarAppearance {
    func copyButtonAppearance(from other: UINavigationBarAppearance) {
        // Button appearances will be undefined if using the default configuration.
        // Copying the default undefined configuration will result in an
        // NSInternalInconsistencyException. We can check for undefined by
        // copying the values to an optional type and checking for nil.
        let otherButtonAppearance: UIBarButtonItemAppearance? = other.buttonAppearance
        let otherDoneButtonAppearance: UIBarButtonItemAppearance? = other.doneButtonAppearance
        let otherBackButtonAppearance: UIBarButtonItemAppearance? = other.backButtonAppearance

        if let otherButtonAppearance = otherButtonAppearance {
            buttonAppearance = otherButtonAppearance
        } else {
            buttonAppearance.configureWithDefault(for: .plain)
        }
        if let otherDoneButtonAppearance = otherDoneButtonAppearance {
            doneButtonAppearance = otherDoneButtonAppearance
        } else {
            doneButtonAppearance.configureWithDefault(for: .done)
        }
        if let otherBackButtonAppearance = otherBackButtonAppearance {
            backButtonAppearance = otherBackButtonAppearance
        } else {
            backButtonAppearance.configureWithDefault(for: .plain)
        }

        setBackIndicatorImage(other.backIndicatorImage, transitionMaskImage: other.backIndicatorTransitionMaskImage)
    }
}
