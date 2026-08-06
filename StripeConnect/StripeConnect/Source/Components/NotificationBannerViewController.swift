//
//  NotificationBannerViewController.swift
//  StripeConnectTests
//
//  Created by Mel Ludowise on 9/25/24.
//

import UIKit

@_spi(DashboardOnly)
public class NotificationBannerViewController: UIViewController {

    public enum InitialLoadState: Equatable {
        /// The banner is fetching and rendering its initial content.
        case loading
        /// The initial load completed, including when there are no notifications to display.
        case loaded
        /// The initial load failed.
        case failed
    }

    struct Props: Encodable {
        let collectionOptions: AccountCollectionOptions

        enum CodingKeys: String, CodingKey {
            case collectionOptions = "setCollectionOptions"
        }
    }

    private(set) var webVC: ConnectComponentWebViewController!

    public weak var delegate: NotificationBannerViewControllerDelegate?

    /// The current state of the banner's initial load. Read this immediately after
    /// creation, then observe `notificationBanner(_:didChangeInitialLoadState:)`.
    public private(set) var initialLoadState: InitialLoadState = .loading

    /// The navigation title shown by notification tasks presented from the banner.
    public var taskTitle: String?

    private var bannerHeightConstraint: NSLayoutConstraint?
    private var didReceiveInitialNotifications = false
    private var didMeasureContentAfterInitialNotifications = false
    private var pendingContentHeight: CGFloat = 0
    private var settleWorkItem: DispatchWorkItem?

    private let componentManager: EmbeddedComponentManager
    private let collectionOptions: AccountCollectionOptions
    private let loadContent: Bool
    private let analyticsClientFactory: ComponentAnalyticsClientFactory
    private var notificationBannerTaskController: NotificationBannerTaskController?

    init(componentManager: EmbeddedComponentManager,
         collectionOptions: AccountCollectionOptions,
         loadContent: Bool,
         analyticsClientFactory: @escaping ComponentAnalyticsClientFactory) {
        self.componentManager = componentManager
        self.collectionOptions = collectionOptions
        self.loadContent = loadContent
        self.analyticsClientFactory = analyticsClientFactory
        super.init(nibName: nil, bundle: nil)

        webVC = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .notificationBanner,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory,
            layoutMode: .sizesToContent { [weak self] height in
                self?.contentHeightDidChange(height)
            }
        ) {
            Props(collectionOptions: collectionOptions)
        } didFailLoadWithError: { [weak self] error in
            guard let self else { return }
            self.transitionInitialLoad(to: .failed)
            self.delegate?.notificationBanner(self, didFailLoadWithError: error)
        }

        webVC.addMessageHandler(OnNotificationsChangeHandler { [weak self] value in
            guard let self else { return }
            if self.initialLoadState == .loading {
                self.didReceiveInitialNotifications = true
                self.didMeasureContentAfterInitialNotifications = false
                self.settleWorkItem?.cancel()
                self.webVC.requestContentHeightUpdate()
            }
            self.delegate?.notificationBanner(
                self,
                didChangeWithTotal: value.total,
                andActionRequired: value.actionRequired
            )
        })

        webVC.addMessageHandler(OpenNotificationBannerTaskMessageHandler(
            analyticsClient: webVC.analyticsClient
        ) { [weak self] task in
            self?.presentNotificationBannerTask(task)
        })

        webVC.view.alpha = 0
        addChildAndPinView(webVC)

        let heightConstraint = view.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.isActive = true
        bannerHeightConstraint = heightConstraint
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func contentHeightDidChange(_ height: CGFloat) {
        pendingContentHeight = height

        switch initialLoadState {
        case .loading where didReceiveInitialNotifications:
            didMeasureContentAfterInitialNotifications = true
            scheduleFinishLoadingIfSettled()
        case .loaded:
            publishContentHeight(height)
        case .loading, .failed:
            break
        }
    }

    private func scheduleFinishLoadingIfSettled() {
        settleWorkItem?.cancel()
        guard initialLoadState == .loading,
              didReceiveInitialNotifications,
              didMeasureContentAfterInitialNotifications else { return }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.initialLoadState == .loading else { return }
            self.publishContentHeight(self.pendingContentHeight)
            self.webVC.view.alpha = 1
            self.transitionInitialLoad(to: .loaded)
        }
        settleWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }

    private func publishContentHeight(_ height: CGFloat) {
        guard bannerHeightConstraint?.constant != height else { return }
        bannerHeightConstraint?.constant = height
        delegate?.notificationBanner(self, didChangeContentHeight: height)
    }

    private func transitionInitialLoad(to state: InitialLoadState) {
        guard initialLoadState == .loading, state != .loading else { return }
        settleWorkItem?.cancel()
        initialLoadState = state
        delegate?.notificationBanner(self, didChangeInitialLoadState: state)
    }

    private func presentNotificationBannerTask(_ task: OpenNotificationBannerTaskMessageHandler.Payload) {
        guard notificationBannerTaskController == nil else { return }

        let taskController = NotificationBannerTaskController(
            componentManager: componentManager,
            collectionOptions: collectionOptions,
            task: task,
            title: taskTitle,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory,
            didFailLoadWithError: { [weak self] error in
                guard let self else { return }
                self.delegate?.notificationBanner(self, didFailLoadWithError: error)
            },
            didDismiss: { [weak self] in
                guard let self else { return }
                self.notificationBannerTaskController = nil
                self.webVC.sendMessage(RefreshNotificationBannerSender.sender())
            }
        )

        guard taskController.present(from: self) else { return }
        notificationBannerTaskController = taskController
    }
}

@_spi(DashboardOnly)
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

    /**
     Triggered when the banner's content height changes. The banner sizes itself to
     this height, so hosts generally don't need to react.
     - Parameters:
       - notificationBanner: The notification banner component that changed
       - height: The new content height of the banner, in points
     */
    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeContentHeight height: CGFloat)

    /**
     Triggered when the banner's initial load state changes.
     - Parameters:
       - notificationBanner: The notification banner component whose loading state changed
       - initialLoadState: The new initial-load state
     */
    func notificationBanner(
        _ notificationBanner: NotificationBannerViewController,
        didChangeInitialLoadState initialLoadState: NotificationBannerViewController.InitialLoadState
    )
}

@_spi(DashboardOnly)
public extension NotificationBannerViewControllerDelegate {
    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didFailLoadWithError error: Error) { }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeWithTotal total: Int,
                            andActionRequired actionRequired: Int) { }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeContentHeight height: CGFloat) { }

    func notificationBanner(
        _ notificationBanner: NotificationBannerViewController,
        didChangeInitialLoadState initialLoadState: NotificationBannerViewController.InitialLoadState
    ) { }
}
