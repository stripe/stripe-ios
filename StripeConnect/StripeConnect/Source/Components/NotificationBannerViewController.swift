//
//  NotificationBannerViewController.swift
//  StripeConnectTests
//
//  Created by Mel Ludowise on 9/25/24.
//

import UIKit

/// Shows the connected account's open tasks, like onboarding requirements and risk interventions,
/// that can affect capabilities such as accepting payments and receiving payouts.
@_spi(PrivatePreviewConnect) @_spi(DashboardOnly)
public class NotificationBannerViewController: UIViewController {

    struct Props: Encodable {
        let collectionOptions: AccountCollectionOptions

        enum CodingKeys: String, CodingKey {
            case collectionOptions = "setCollectionOptions"
        }
    }

    private(set) var webVC: ConnectComponentWebViewController!

    public weak var delegate: NotificationBannerViewControllerDelegate?

    private let contentView = InlineComponentView()

    private var contentHeight: CGFloat?

    init(componentManager: EmbeddedComponentManager,
         collectionOptions: AccountCollectionOptions,
         loadContent: Bool,
         analyticsClientFactory: ComponentAnalyticsClientFactory) {
        super.init(nibName: nil, bundle: nil)
        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .notificationBanner,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory
        ) {
            Props(collectionOptions: collectionOptions)
        } didFailLoadWithError: { [weak self] error in
            guard let self else { return }
            delegate?.notificationBanner(self, didFailLoadWithError: error)
        }

        webVC.addMessageHandler(OnNotificationsChangeHandler { [weak self] value in
            guard let self else { return }
            delegate?.notificationBanner(self, didChangeNotificationsWithTotal: value.total, actionRequired: value.actionRequired)
        })
        webVC.didChangeContentHeight = { [weak self] height in
            self?.contentHeightDidChange(height)
        }

        addChildAndPinView(webVC)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func loadView() {
        view = contentView
    }

    private func contentHeightDidChange(_ height: CGFloat) {
        guard height != contentHeight else { return }
        contentHeight = height
        contentView.contentHeight = height
        delegate?.notificationBanner(self, didChangeContentHeight: height)
    }
}

@_spi(PrivatePreviewConnect) @_spi(DashboardOnly)
public protocol NotificationBannerViewControllerDelegate: AnyObject {

    /**
     Triggered when an error occurs loading the notification banner component
     - Parameters:
       - notificationBanner: The notification banner component that errored when loading
       - error: The error that occurred when loading the component
     */
    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didFailLoadWithError error: Error)

    /**
     Triggered when the total number of notifications or notifications with required actions changes.
     - Parameters:
       - notificationBanner: The notification banner component that changed
       - total: The total number of notifications in the banner
       - actionRequired: The number of notifications that require user action
     */
    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeNotificationsWithTotal total: Int,
                            actionRequired: Int)

    /**
     Triggered when the banner's content height changes, before the next layout pass.
     Reports 0 when there's nothing to show.
     - Parameters:
       - notificationBanner: The notification banner component that changed
       - height: The banner's new content height, in points
     */
    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeContentHeight height: CGFloat)

    /**
     Triggered when the total number of notifications or notifications with required actions updates
     - Parameters:
       - notificationBanner: The notification banner component that changed
       - total: The total number of notifications in the banner
       - actionRequired: The number of notifications that require user action
     */
    @available(*, deprecated, renamed: "notificationBanner(_:didChangeNotificationsWithTotal:actionRequired:)")
    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeWithTotal total: Int,
                            andActionRequired actionRequired: Int)
}

@_spi(PrivatePreviewConnect) @_spi(DashboardOnly)
public extension NotificationBannerViewControllerDelegate {
    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didFailLoadWithError error: Error) { }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeNotificationsWithTotal total: Int,
                            actionRequired: Int) {
        LegacyNotificationsForwarder.shared.forward(
            total: total,
            actionRequired: actionRequired,
            from: notificationBanner,
            to: self
        )
    }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeContentHeight height: CGFloat) { }

    @available(*, deprecated, renamed: "notificationBanner(_:didChangeNotificationsWithTotal:actionRequired:)")
    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeWithTotal total: Int,
                            andActionRequired actionRequired: Int) { }
}

// Calls the deprecated requirement from a deprecated witness, because this module treats warnings as errors.
private protocol LegacyNotificationsForwarding {
    func forward(total: Int,
                 actionRequired: Int,
                 from notificationBanner: NotificationBannerViewController,
                 to delegate: NotificationBannerViewControllerDelegate)
}

private struct LegacyNotificationsForwarder: LegacyNotificationsForwarding {
    static let shared: LegacyNotificationsForwarding = LegacyNotificationsForwarder()

    @available(*, deprecated)
    func forward(total: Int,
                 actionRequired: Int,
                 from notificationBanner: NotificationBannerViewController,
                 to delegate: NotificationBannerViewControllerDelegate) {
        delegate.notificationBanner(notificationBanner, didChangeWithTotal: total, andActionRequired: actionRequired)
    }
}
