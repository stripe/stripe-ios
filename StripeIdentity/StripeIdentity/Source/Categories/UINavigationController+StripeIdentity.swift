//
//  UINavigationController+StripeIdentity.swift
//  StripeIdentity
//
//  Created by Jaime Park on 2/10/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

extension UINavigationController {
    func configureBorderlessNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.copyButtonAppearance(from: UINavigationBar.appearance().standardAppearance)
        appearance.configureWithTransparentBackground()

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
    }

    func setNavigationBarBackgroundColor(with backgroundColor: UIColor?) {
        let bgColor = backgroundColor ?? .systemBackground

        navigationBar.standardAppearance.backgroundColor = bgColor
        navigationBar.scrollEdgeAppearance?.backgroundColor = bgColor
    }
}

extension UINavigationBarAppearance {
    fileprivate func copyButtonAppearance(from other: UINavigationBarAppearance) {
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

        setBackIndicatorImage(
            other.backIndicatorImage,
            transitionMaskImage: other.backIndicatorTransitionMaskImage
        )
    }
}
