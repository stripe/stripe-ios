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
    final class RightAccessoryButton: UIView, UIGestureRecognizerDelegate {

        enum AccessoryType: Equatable {
            case edit
            case viewMoreChevron
            case viewMore
            case update
            case change
            case changeWithChevron

            var text: String? {
                switch self {
                case .edit:
                    return .Localized.edit
                case .viewMoreChevron, .viewMore:
                    return .Localized.view_more
                case .update:
                    return nil
                case .change, .changeWithChevron:
                    return .Localized.change
                }
            }

            var accessoryImage: UIImage? {
                switch self {
                case .edit, .viewMore, .change:
                    return nil
                case .viewMoreChevron, .update, .changeWithChevron:
                    return Image.icon_chevron_right.makeImage(template: true).withAlignmentRectInsets(UIEdgeInsets(top: -2, left: 0, bottom: 0, right: 0))
                }
            }
        }

        private var label: UILabel {
            let label = UILabel()
            label.text = accessoryType.text
            label.font = appearance.scaledFont(for: appearance.font.base.medium, style: .footnote, maximumPointSize: 20)
            if #available(iOS 15.0, *) {
                label.minimumContentSizeCategory = .large
            }
            label.textColor = appearance.colors.primary // TODO(porter) use secondary action color
            label.adjustsFontSizeToFitWidth = true
            label.adjustsFontForContentSizeCategory = true
            label.minimumScaleFactor = 0.9
            label.isAccessibilityElement = false
            return label
        }

        private var imageView: UIImageView? {
            guard let image = accessoryType.accessoryImage else { return nil }
            let imageView = UIImageView(image: image)
            if accessoryType == .update {
                imageView.tintColor = appearance.colors.icon
            } else {
                imageView.tintColor = appearance.colors.primary // TODO(porter) use secondary action color
            }
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

        override var isHidden: Bool {
            get { super.isHidden }
            set {
                super.isHidden = newValue
                // This shouldn't be necessary, but for unknown reasons VoiceOver sometimes reads this button even when it's hidden
                isAccessibilityElement = !isHidden
            }
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
            if accessoryType == .update {
                accessibilityIdentifier = "chevron"
            }
            accessibilityTraits = [.button]
            isAccessibilityElement = true

            addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTap)))
            let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(gesture:)))
            longPressGesture.minimumPressDuration = 0.2
            longPressGesture.delegate = self
            addGestureRecognizer(longPressGesture)
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc func handleTap() {
            alpha = 0.5
            UIView.animate(withDuration: 0.2, delay: 0.1) { [self] in
                alpha = 1.0
            }
            didTap()
        }

        @objc private func handleLongPressGesture(gesture: UILongPressGestureRecognizer) {
            switch gesture.state {
            case .began:
                alpha = 0.5
            default:
                alpha = 1.0
            }
        }

        // MARK: - UIGestureRecognizerDelegate
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Without this, the long press prevents you from scrolling or our tap/pan gesture from triggering together.
            return otherGestureRecognizer is UIPanGestureRecognizer || (gestureRecognizers?.contains(otherGestureRecognizer) ?? false)
        }
    }
}

// MARK: - EventHandler
extension RowButton.RightAccessoryButton: EventHandler {
    func handleEvent(_ event: STPEvent) {
        switch event {
        case .shouldEnableUserInteraction:
            alpha = 1
        case .shouldDisableUserInteraction:
            alpha = 0.5
        default:
            break
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
    ///   - isFlatCheckmarkStyle: True if embedded and style of `flatWithCheckmark`
    /// - Returns: 'AccessoryType.viewMore' if more than one payment method is saved, 'AccessoryType.edit' if only one payment method exists and it can either be updated or removed, and 'nil' otherwise.
    static func getAccessoryButtonType(savedPaymentMethodsCount: Int,
                                       isFirstCardCoBranded: Bool,
                                       isCBCEligible: Bool,
                                       allowsRemovalOfLastSavedPaymentMethod: Bool,
                                       allowsPaymentMethodRemoval: Bool,
                                       allowsPaymentMethodUpdate: Bool,
                                       isFlatCheckmarkStyle: Bool = false) -> AccessoryType? {
        guard savedPaymentMethodsCount > 0 else { return nil }

        // If we have more than 1 saved payment method always show the "View more" button
        if savedPaymentMethodsCount > 1 {
            return isFlatCheckmarkStyle ? .viewMore : .viewMoreChevron
        }

        // We only have 1 payment method... show the edit icon if the card brand can be updated or if it can be removed
        return (isFirstCardCoBranded && isCBCEligible) || (allowsRemovalOfLastSavedPaymentMethod && allowsPaymentMethodRemoval) || allowsPaymentMethodUpdate ? .edit : nil
    }
}
