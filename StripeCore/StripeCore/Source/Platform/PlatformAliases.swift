#if canImport(AppKit) && !canImport(UIKit)
import AppKit

public typealias UIImage = NSImage
public typealias UIFont = NSFont
public typealias UIColor = NSColor
public typealias UIView = NSView
public typealias UIViewController = NSViewController
public typealias UIWindow = NSWindow
public typealias UIButton = NSButton

@objc public enum UIModalPresentationStyle: Int {
    case custom
    case formSheet
    case overFullScreen
}

@objc public enum UIModalTransitionStyle: Int {
    case crossDissolve
}

@objc public enum UIBarStyle: Int {
    case `default`
    case black
}

@objc public enum UIKeyboardAppearance: Int {
    case `default`
    case dark
    case light
    case alert
}

public enum UIActivityIndicatorView {
    @objc public enum Style: Int {
        case medium
        case large
        case white
        case whiteLarge
        case gray
    }
}

public enum UIBlurEffect {
    @objc public enum Style: Int {
        case extraLight
        case light
        case dark
        case regular
        case prominent
    }
}

extension NSViewController {
    public var modalPresentationStyle: UIModalPresentationStyle {
        get { .overFullScreen }
        set { }
    }

    public var modalTransitionStyle: UIModalTransitionStyle {
        get { .crossDissolve }
        set { }
    }

    public var presentedViewController: NSViewController? {
        presentedViewControllers?.first
    }

    public var isBeingDismissed: Bool {
        false
    }

    public func present(
        _ viewControllerToPresent: NSViewController,
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        presentAsModalWindow(viewControllerToPresent)
        completion?()
    }

    public func dismiss(
        animated flag: Bool,
        completion: (() -> Void)? = nil
    ) {
        dismiss(self)
        completion?()
    }
}

extension NSView {
    public var backgroundColor: NSColor? {
        get {
            guard let cgColor = layer?.backgroundColor else {
                return nil
            }
            return NSColor(cgColor: cgColor)
        }
        set {
            wantsLayer = true
            layer?.backgroundColor = newValue?.cgColor
        }
    }

    public var alpha: CGFloat {
        get { alphaValue }
        set { alphaValue = newValue }
    }

    public static func animate(
        withDuration duration: TimeInterval,
        animations: @escaping () -> Void
    ) {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = duration
            animations()
        }
    }
}
#endif
