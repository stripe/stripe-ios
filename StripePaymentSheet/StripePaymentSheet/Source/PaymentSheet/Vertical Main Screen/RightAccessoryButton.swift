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
    final class RightAccessoryButton: UIButton {
        
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
                    return Image.icon_chevron_right.makeImage(template: true)
                }
            }
            
            var imageEdgeInsets: UIEdgeInsets {
                switch self {
                case .edit:
                    return .zero
                case .viewMore:
                    return UIEdgeInsets(top: 2, left: 4, bottom: 0, right: 0)
                }
            }
        }
        
        // Overridden so auto layout properly accounts for the image offset (if any) and positions the button correctly
        override var intrinsicContentSize: CGSize {
            let size = super.intrinsicContentSize
            
            // TODO(porter) Figure out how to handle this for VisionOS, the alternative (`UIButton.Configuration) was introduced in iOS 15 and we currently support below iOS 15.
            #if !canImport(CompositorServices)
            return CGSize(width: size.width + imageEdgeInsets.left + imageEdgeInsets.right,
                          height: size.height + imageEdgeInsets.top + imageEdgeInsets.bottom)
            #else
            return size
            #endif
        }
        
        init(accessoryType: AccessoryType, appearance: PaymentSheet.Appearance) {
            super.init(frame: .zero)
            setTitle(accessoryType.text, for: .normal)
            setTitleColor(appearance.colors.primary, for: .normal) // TODO read secondary action color
            titleLabel?.font = appearance.scaledFont(for: appearance.font.base.medium, style: .caption1, maximumPointSize: 20)
            setImage(accessoryType.accessoryImage, for: .normal)
            imageView?.tintColor = appearance.colors.primary // TODO read secondary action color
            semanticContentAttribute = .forceRightToLeft
            // TODO(porter) Figure out how to handle this for VisionOS, the alternative (`UIButton.Configuration) was introduced in iOS 15 and we currently support below iOS 15.
            #if !canImport(CompositorServices)
            imageEdgeInsets = accessoryType.imageEdgeInsets
            #endif
            
            accessibilityLabel = accessoryType.text
            accessibilityIdentifier = accessoryType.text
            
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
