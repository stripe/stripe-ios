//
//  RightAccessoryButton.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/28/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

extension RowButton {
    final class RightAccessoryButton: UIView {

        enum AccessoryType: Equatable {
            case edit
            case viewMore

            var text: String? {
                switch self {
                case .edit:
                    return .Localized.edit
                case .viewMore:
                    return .Localized.view_more
                }
            }

            var accessoryImage: UIImage? {
                switch self {
                case .edit:
                    return nil
                case .viewMore:
                    return Image.icon_chevron_right.makeImage(template: true).withAlignmentRectInsets(UIEdgeInsets(top: -2, left: 0, bottom: 0, right: 0))
                }
            }
        }

        private var label: UILabel {
            let label = UILabel()
            label.text = accessoryType.text
            label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .caption1, maximumPointSize: 20)
            label.textColor = appearance.colors.primary // TODO(porter) use secondary action color
            label.adjustsFontSizeToFitWidth = true
            label.adjustsFontForContentSizeCategory = true
            label.isAccessibilityElement = false
            return label
        }

        private var imageView: UIImageView? {
            guard let image = accessoryType.accessoryImage else { return nil }
            let imageView = UIImageView(image: image)
            imageView.tintColor = appearance.colors.primary // TODO(porter) use secondary action color
            imageView.contentMode = .scaleAspectFit
            imageView.isAccessibilityElement = false
            return imageView
        }

        private var stackView: UIStackView {
            let views: [UIView] = [label, imageView].compactMap { $0 }
            let stackView = UIStackView(arrangedSubviews: views)
            stackView.spacing = 4
            return stackView
        }

        let accessoryType: AccessoryType
        let appearance: PaymentSheet.Appearance
        let didTap: () -> Void

        init(accessoryType: AccessoryType, appearance: PaymentSheet.Appearance, didTap: @escaping () -> Void) {
            self.accessoryType = accessoryType
            self.appearance = appearance
            self.didTap = didTap
            super.init(frame: .zero)
            addAndPinSubview(stackView)

            accessibilityLabel = accessoryType.text
            accessibilityIdentifier = accessoryType.text
            accessibilityTraits = [.button]

            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc func handleTap() {
            didTap()
        }
    }

}

extension RowButton.RightAccessoryButton {

    /// Determines the type of accessory button that will be displayed with the saved payment method.
    /// - Parameters:
    ///   - savedPaymentMethodsCount: The count of saved payment methods.
    ///   - isFirstCardCoBranded: True if the first saved payment method is a co-branded card, false otherwise
    ///   - isCBCEligible: True if the merchant is eligible for card brand choice, false otherwise
    ///   - allowsRemovalOfLastSavedPaymentMethod: True if we can remove the last saved payment method, false otherwise
    ///   - allowsPaymentMethodRemoval: True if removing payment methods is enabled, false otherwise
    /// - Returns: 'AccessoryType.viewMore' if more than one payment method is saved, 'AccessoryType.edit' if only one payment method exists and it can either be updated or removed, and 'nil' otherwise.
    static func getAccessoryButtonType(savedPaymentMethodsCount: Int,
                                       isFirstCardCoBranded: Bool,
                                       isCBCEligible: Bool,
                                       allowsRemovalOfLastSavedPaymentMethod: Bool,
                                       allowsPaymentMethodRemoval: Bool) -> AccessoryType? {
        guard savedPaymentMethodsCount > 0 else { return nil }

        // If we have more than 1 saved payment method always show the "View more" button
        if savedPaymentMethodsCount > 1 {
            return .viewMore
        }

        // We only have 1 payment method... show the edit icon if the card brand can be updated or if it can be removed
        return (isFirstCardCoBranded && isCBCEligible) || (allowsRemovalOfLastSavedPaymentMethod && allowsPaymentMethodRemoval) ? .edit : nil
    }
}
