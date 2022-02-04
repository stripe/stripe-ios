//
//  UINavigationBar+Link.swift
//  StripeiOS
//
//  Created by Ramon Torres on 11/11/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit
@_spi(STP) import StripeUICore

extension UINavigationBar {

    func applyLinkTheme() {
        self.tintColor = .linkNavTint
        self.isTranslucent = false

        let backButtonImage = Image.back_button.makeImage()

        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .linkBackground
            appearance.shadowColor = .clear
            appearance.setBackIndicatorImage(backButtonImage, transitionMaskImage: backButtonImage)

            self.standardAppearance = appearance
            self.scrollEdgeAppearance = appearance
        } else {
            self.backIndicatorImage = backButtonImage
            self.backIndicatorTransitionMaskImage = backButtonImage
            self.barTintColor = .linkBackground
            self.shadowImage = UIImage()
        }
    }
    
}
