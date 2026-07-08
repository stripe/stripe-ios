#if canImport(AppKit) && !canImport(UIKit)
import AppKit
@_spi(STP) import StripeCore

@objcMembers public class UIApplication: NSObject {
    public struct OpenExternalURLOptionsKey: Hashable, RawRepresentable {
        public let rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public static let universalLinksOnly = OpenExternalURLOptionsKey(
            rawValue: "UIApplicationOpenURLOptionUniversalLinksOnly"
        )
    }

    public static let shared = UIApplication()
    public static let willEnterForegroundNotification = NSApplication.willBecomeActiveNotification

    public func canOpenURL(_ url: URL) -> Bool {
        NSWorkspace.shared.urlForApplication(toOpen: url) != nil
    }

    public func open(
        _ url: URL,
        options: [OpenExternalURLOptionsKey: Any] = [:],
        completionHandler completion: ((Bool) -> Void)? = nil
    ) {
        let didOpen = NSWorkspace.shared.open(url)
        completion?(didOpen)
    }
}

@objc public protocol SFSafariViewControllerDelegate: AnyObject {
}

@objcMembers public class SFSafariViewController: NSViewController {
    public weak var delegate: SFSafariViewControllerDelegate?
    public var preferredBarTintColor: NSColor?
    public var preferredControlTintColor: NSColor?
    public enum DismissButtonStyle: Int {
        case done
        case close
        case cancel
    }
    public var dismissButtonStyle: DismissButtonStyle = .done

    public init(url: URL) {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
