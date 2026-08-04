//
//  NotificationBannerTaskController.swift
//  StripeConnect
//

import UIKit

final class NotificationBannerTaskController {
    struct Props: Encodable {
        let collectionOptions: AccountCollectionOptions
        let notificationBannerTask: OpenNotificationBannerTaskMessageHandler.Payload

        enum CodingKeys: String, CodingKey {
            case collectionOptions = "setCollectionOptions"
            case notificationBannerTask = "setMobileNotificationBannerForm"
        }
    }

    private let didDismiss: () -> Void
    private var didNotifyDismiss = false
    private(set) var webViewController: ConnectComponentWebViewController

    init(
        componentManager: EmbeddedComponentManager,
        collectionOptions: AccountCollectionOptions,
        task: OpenNotificationBannerTaskMessageHandler.Payload,
        title: String?,
        loadContent: Bool,
        analyticsClientFactory: @escaping ComponentAnalyticsClientFactory,
        didFailLoadWithError: @escaping (Error) -> Void,
        didDismiss: @escaping () -> Void
    ) {
        self.didDismiss = didDismiss
        webViewController = ConnectComponentWebViewController(
            componentManager: componentManager,
            componentType: .notificationBanner,
            loadContent: loadContent,
            analyticsClientFactory: analyticsClientFactory
        ) {
            Props(
                collectionOptions: collectionOptions,
                notificationBannerTask: task
            )
        } didFailLoadWithError: { error in
            didFailLoadWithError(error)
        }
        webViewController.title = title
        webViewController.onDismiss = { [weak self] in
            self?.notifyDismissed()
        }
    }

    func present(from viewController: UIViewController, animated: Bool = true) -> Bool {
        let presentingViewController = presentationSource(from: viewController)
        guard presentingViewController.viewIfLoaded?.window != nil,
              presentingViewController.presentedViewController == nil else {
            return false
        }

        let navigationController = UINavigationController(rootViewController: webViewController)
        navigationController.navigationBar.prefersLargeTitles = false
        navigationController.modalPresentationStyle = .fullScreen

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance

        let closeButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .done,
            target: self,
            action: #selector(close)
        )
        closeButton.accessibilityIdentifier = "closeButton"
        webViewController.navigationItem.rightBarButtonItem = closeButton

        presentingViewController.present(navigationController, animated: animated)
        return true
    }

    @objc
    private func close() {
        webViewController.dismiss(animated: true)
    }

    private func presentationSource(from viewController: UIViewController) -> UIViewController {
        var result = viewController
        while let parent = result.parent {
            result = parent
        }
        return result
    }

    private func notifyDismissed() {
        guard !didNotifyDismiss else { return }
        didNotifyDismiss = true
        didDismiss()
    }
}
