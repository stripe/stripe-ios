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

        enum AccessoryType {
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
    static func getAccessoryButtonType(savedPaymentMethodsCount: Int,
                                       isFirstCardCoBranded: Bool,
                                       isCBCEligible: Bool,
                                       allowsRemovalOfLastSavedPaymentMethod: Bool,
                                       paymentMethodRemove: Bool) -> AccessoryType? {
        // If we have more than 1 saved payment method always show the "View more" button
        if savedPaymentMethodsCount > 1 {
            return .viewMore
        } else if savedPaymentMethodsCount == 1 && isFirstCardCoBranded && isCBCEligible {
            // If only one card left but it is co-branded we can edit it
            return .edit
        } else if savedPaymentMethodsCount == 1 && allowsRemovalOfLastSavedPaymentMethod && paymentMethodRemove {
            // If only one payment method left and we can remove it we can edit
            return .edit
        }

        return nil
    }
}
