//
//  NotificationBannerViewController.swift
//  StripeConnectTests
//
//  Created by Mel Ludowise on 9/25/24.
//

import UIKit

@_spi(DashboardOnly)
@available(iOS 15, *)
public class NotificationBannerViewController: UIViewController {

    struct Props: Encodable {
        let collectionOptions: AccountCollectionOptions

        enum CodingKeys: String, CodingKey {
            case collectionOptions = "setCollectionOptions"
        }
    }

    private(set) var webVC: ConnectComponentWebViewController!

    public weak var delegate: NotificationBannerViewControllerDelegate?

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
            self.delegate?.notificationBanner(self, didChangeWithTotal: value.total, andActionRequired: value.actionRequired)
        })

        addChildAndPinView(webVC)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@_spi(DashboardOnly)
@available(iOS 15, *)
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
     Triggered when the total number of notifications or notifications with required actions updates
     - Parameters:
       - notificationBanner: The notification banner component that changed
       - total: The total number of notifications in the banner
       - actionRequired: The number of notifications that require user action
     */
    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeWithTotal total: Int,
                            andActionRequired actionRequired: Int)
}

@_spi(DashboardOnly)
@available(iOS 15, *)
public extension NotificationBannerViewControllerDelegate {
    // Default implementation to make optional
    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didFailLoadWithError error: Error) { }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeWithTotal total: Int,
                            andActionRequired actionRequired: Int) { }
}
