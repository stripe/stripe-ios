//
//  AccessoryButton.swift
//  StripePaymentSheet
//
//  Created by Nick Porter on 5/28/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class AccessoryButton: UIButton {

    enum AccessoryType {
        case none
        case edit
        case viewMore

        var text: String? {
            switch self {
            case .none:
                return nil
            case .edit:
                return "Edit"
            case .viewMore:
                return "View more"
            }
        }

        var accessoryImage: UIImage? {
            switch self {
            case .none, .edit:
                return nil
            case .viewMore:
                return Image.icon_chevron_right.makeImage(template: true)
            }
        }

        var imageEdgeInsets: UIEdgeInsets {
            switch self {
            case .none, .edit:
                return .zero
            case .viewMore:
                return UIEdgeInsets(top: 2, left: 4, bottom: 0, right: 0)
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + imageEdgeInsets.left + imageEdgeInsets.right,
                      height: size.height + imageEdgeInsets.top + imageEdgeInsets.bottom)
    }

    init?(accessoryType: AccessoryType, appearance: PaymentSheet.Appearance) {
        guard accessoryType != .none else { return nil }

        super.init(frame: .zero)
        setTitle(accessoryType.text, for: .normal)
        setTitleColor(appearance.colors.primary, for: .normal) // TODO read secondary action color
        titleLabel?.font = appearance.scaledFont(for: appearance.font.base.medium, style: .subheadline, maximumPointSize: 20)
        setImage(accessoryType.accessoryImage, for: .normal)
        imageView?.tintColor = appearance.colors.primary // TODO read secondary action color
        imageEdgeInsets = accessoryType.imageEdgeInsets
        semanticContentAttribute = .forceRightToLeft

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
