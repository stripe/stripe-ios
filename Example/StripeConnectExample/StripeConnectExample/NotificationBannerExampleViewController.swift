//
//  NotificationBannerExampleViewController.swift
//  StripeConnect Example
//

@_spi(PrivatePreviewConnect) import StripeConnect
import UIKit

/// Shows the notification banner at the top of a scrolling screen, above the app's own content
class NotificationBannerExampleViewController: UIViewController {

    private let notificationBanner: NotificationBannerViewController
    private let summaryLabel = UILabel()

    init(embeddedComponentManager: EmbeddedComponentManager) {
        notificationBanner = embeddedComponentManager.createNotificationBannerViewController()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        summaryLabel.numberOfLines = 0
        summaryLabel.font = .preferredFont(forTextStyle: .body)
        summaryLabel.textColor = .secondaryLabel
        summaryLabel.text = "Loading notifications…"

        let summaryContainer = UIView()
        summaryContainer.directionalLayoutMargins = .init(top: 16, leading: 20, bottom: 16, trailing: 20)
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryContainer.addSubview(summaryLabel)
        NSLayoutConstraint.activate([
            summaryLabel.topAnchor.constraint(equalTo: summaryContainer.layoutMarginsGuide.topAnchor),
            summaryLabel.leadingAnchor.constraint(equalTo: summaryContainer.layoutMarginsGuide.leadingAnchor),
            summaryLabel.trailingAnchor.constraint(equalTo: summaryContainer.layoutMarginsGuide.trailingAnchor),
            summaryLabel.bottomAnchor.constraint(equalTo: summaryContainer.layoutMarginsGuide.bottomAnchor),
        ])

        let stackView = UIStackView(arrangedSubviews: [summaryContainer])
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        notificationBanner.delegate = self
        addChild(notificationBanner)
        stackView.insertArrangedSubview(notificationBanner.view, at: 0)
        notificationBanner.didMove(toParent: self)
    }
}

// MARK: - NotificationBannerViewControllerDelegate

extension NotificationBannerExampleViewController: NotificationBannerViewControllerDelegate {
    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeContentHeight height: CGFloat) {
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeNotificationsWithTotal total: Int,
                            actionRequired: Int) {
        summaryLabel.text = "\(total) notifications, \(actionRequired) require action"
    }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didFailLoadWithError error: Error) {
        notificationBanner.view.isHidden = true
        summaryLabel.text = "Error loading the notification banner: \((error as NSError).debugDescription)"
    }
}
