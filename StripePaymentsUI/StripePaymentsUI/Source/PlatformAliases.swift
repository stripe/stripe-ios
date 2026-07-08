#if canImport(AppKit) && !canImport(UIKit)
import AppKit
import QuartzCore
@_spi(STP) import StripeUICore

typealias CABasicAnimation = QuartzCore.CABasicAnimation
typealias CAAnimationGroup = QuartzCore.CAAnimationGroup
typealias CALayer = QuartzCore.CALayer
typealias CAShapeLayer = QuartzCore.CAShapeLayer
typealias CAMediaTimingFunction = QuartzCore.CAMediaTimingFunction
typealias NSLayoutConstraint = AppKit.NSLayoutConstraint
typealias NSLayoutDimension = AppKit.NSLayoutDimension
public typealias NSTextAlignment = AppKit.NSTextAlignment
public typealias UIAction = StripeUICore.UIAction
public typealias UIAccessibility = StripeUICore.UIAccessibility
public typealias UIBarButtonItem = StripeUICore.UIBarButtonItem
public typealias UIBezierPath = StripeUICore.UIBezierPath
public typealias UIButton = StripeUICore.UIButton
public typealias UIColor = StripeUICore.UIColor
public typealias UIControl = StripeUICore.UIControl
public typealias UIContextMenuInteraction = StripeUICore.UIContextMenuInteraction
public typealias UIEdgeInsets = StripeUICore.UIEdgeInsets
public typealias UIImage = StripeUICore.UIImage
public typealias UIImageView = StripeUICore.UIImageView
public typealias UIKeyCommand = StripeUICore.UIKeyCommand
public typealias UIKeyboardAppearance = StripeUICore.UIKeyboardAppearance
public typealias UIKeyboardType = StripeUICore.UIKeyboardType
public typealias UILayoutPriority = StripeUICore.UILayoutPriority
public typealias UILabel = StripeUICore.UILabel
public typealias UIMenu = StripeUICore.UIMenu
public typealias UIPickerView = StripeUICore.UIPickerView
public typealias UIStackView = StripeUICore.UIStackView
public typealias UITextContentType = StripeUICore.UITextContentType
public typealias UITextField = StripeUICore.UITextField
public typealias UITextFieldDelegate = StripeUICore.UITextFieldDelegate
public typealias UITextPosition = StripeUICore.UITextPosition
public typealias UITextRange = StripeUICore.UITextRange
public typealias UITextView = StripeUICore.UITextView
public typealias UIView = StripeUICore.UIView
public typealias UIViewController = StripeUICore.UIViewController
public typealias UIWindow = StripeUICore.UIWindow
public typealias UIPasteboard = StripeUICore.UIPasteboard

extension NSAttributedString.Key {
    static let accessibilitySpeechPitch = NSAttributedString.Key("UIAccessibilitySpeechAttributePitch")
    static let accessibilitySpeechSpellOut = NSAttributedString.Key("UIAccessibilitySpeechAttributeSpellOut")
}

extension NSLayoutConstraint.Priority {
    static func + (lhs: NSLayoutConstraint.Priority, rhs: Int) -> NSLayoutConstraint.Priority {
        NSLayoutConstraint.Priority(rawValue: lhs.rawValue + Float(rhs))
    }
}

let CATransform3DIdentity = QuartzCore.CATransform3DIdentity

func CATransform3DScale(_ t: CATransform3D, _ sx: CGFloat, _ sy: CGFloat, _ sz: CGFloat) -> CATransform3D {
    QuartzCore.CATransform3DScale(t, sx, sy, sz)
}

final class UIScreen {
    static let main = UIScreen()

    var scale: CGFloat {
        NSScreen.main?.backingScaleFactor ?? 1
    }

    var nativeScale: CGFloat {
        scale
    }
}
#endif
