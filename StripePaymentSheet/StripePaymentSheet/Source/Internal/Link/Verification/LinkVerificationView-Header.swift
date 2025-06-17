//
//  LinkVerificationView-Header.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 12/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripePayments
@_spi(STP) import StripeUICore
import UIKit

extension LinkVerificationView {

    final class Header: UIView, LinkNavigationHeader {
        struct Constants {
            static let logoHeight: CGFloat = 24
            static let buttonSpacing: CGFloat = 16
        }

        private let logoView: UIImageView = {
            let logoView = UIImageView(image: Image.link_logo.makeImage(template: false))
            logoView.translatesAutoresizingMaskIntoConstraints = false
            logoView.isAccessibilityElement = true
            logoView.accessibilityTraits = .header
            logoView.accessibilityLabel = STPPaymentMethodType.link.displayName
            return logoView
        }()

        let backButton: UIButton = {
            LinkSheetNavigationBar.createBackButton(
                accessibilityIdentifier: "LinkVerificationBackButton",
                appearance: LinkUI.appearance
            )
        }()

        let closeButton: UIButton = {
            LinkSheetNavigationBar.createCloseButton(
                accessibilityIdentifier: "LinkVerificationCloseButton",
                appearance: LinkUI.appearance
            )
        }()

        // Constraints for logo positioning
        private var logoLeadingToBackButtonConstraint: NSLayoutConstraint!
        private var logoLeadingToSuperviewConstraint: NSLayoutConstraint!

        override var intrinsicContentSize: CGSize {
            return CGSize(width: UIView.noIntrinsicMetric, height: 32)
        }

        init() {
            super.init(frame: .zero)

            addSubview(logoView)
            addSubview(backButton)
            addSubview(closeButton)

            // Create both sets of logo constraints
            logoLeadingToBackButtonConstraint = logoView.leadingAnchor.constraint(
                equalTo: backButton.trailingAnchor,
                constant: Constants.buttonSpacing
            )
            logoLeadingToSuperviewConstraint = logoView.leadingAnchor.constraint(equalTo: leadingAnchor)

            NSLayoutConstraint.activate([
                // Back button (left side)
                backButton.leadingAnchor.constraint(equalTo: leadingAnchor),
                backButton.centerYAnchor.constraint(equalTo: centerYAnchor),

                // Logo (positioned based on back button visibility)
                logoView.centerYAnchor.constraint(equalTo: centerYAnchor),
                logoView.heightAnchor.constraint(equalToConstant: Constants.logoHeight),

                // Close button (right side)
                closeButton.rightAnchor.constraint(equalTo: rightAnchor),
                closeButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            ])

            // Initially position logo to leading edge (no back button)
            logoLeadingToSuperviewConstraint.isActive = true
            logoLeadingToBackButtonConstraint.isActive = false

            tintColor = .linkSurfacePrimary
            logoView.tintColor = .linkTextPrimary

            // Initially hide the back button
            backButton.isHidden = true
            backButton.alpha = 0.0
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        /// Show or hide the back button based on navigation state
        func setShowsBackButton(_ showsBackButton: Bool, animated: Bool = true) {
            let updateConstraints = {
                if showsBackButton {
                    // Switch to back button layout
                    self.logoLeadingToSuperviewConstraint.isActive = false
                    self.logoLeadingToBackButtonConstraint.isActive = true
                } else {
                    // Switch to leading edge layout
                    self.logoLeadingToBackButtonConstraint.isActive = false
                    self.logoLeadingToSuperviewConstraint.isActive = true
                }
                self.layoutIfNeeded()
            }

            let updateButtonVisibility = {
                self.backButton.isHidden = !showsBackButton
                self.backButton.alpha = showsBackButton ? 1.0 : 0.0
            }

            if animated {
                UIView.animate(
                    withDuration: 0.3,
                    delay: 0,
                    usingSpringWithDamping: 0.8,
                    initialSpringVelocity: 0,
                    options: [.allowUserInteraction],
                    animations: {
                        updateConstraints()
                        updateButtonVisibility()
                    }
                )
            } else {
                updateConstraints()
                updateButtonVisibility()
            }
        }
    }

}
