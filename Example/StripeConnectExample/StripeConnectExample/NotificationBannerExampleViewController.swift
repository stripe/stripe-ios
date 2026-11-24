//
//  NotificationBannerExampleViewController.swift
//  StripeConnect Example
//

@_spi(PrivatePreviewConnect) import StripeConnect
import UIKit

/// A sample home screen with the notification banner above the app's own content, which is placeholder data.
/// The screen takes its colors, font, and corner radius from the selected appearance, so the banner blends in.
class NotificationBannerExampleViewController: UIViewController {

    fileprivate struct Activity {
        let title: String
        let detail: String
        let amount: String
    }

    private static let activities = [
        Activity(title: "Jordan Lee", detail: "Payment · Today, 9:41 AM", amount: "+$84.00"),
        Activity(title: "Bank account ••6789", detail: "Payout · Yesterday", amount: "−$3,000.00"),
        Activity(title: "Sam Park", detail: "Payment · Yesterday", amount: "+$126.50"),
        Activity(title: "Alex Kim", detail: "Refund · Nov 20", amount: "−$24.50"),
        Activity(title: "Riley Chen", detail: "Payment · Nov 19", amount: "+$310.00"),
    ]

    private let notificationBanner: NotificationBannerViewController
    private let stackView = UIStackView()
    private var style = Style(appearance: AppSettings.shared.appearanceInfo.appearance)

    init(embeddedComponentManager: EmbeddedComponentManager) {
        notificationBanner = embeddedComponentManager.createNotificationBannerViewController()
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.directionalLayoutMargins = .init(top: 16, leading: 16, bottom: 24, trailing: 16)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stackView)
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
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
        stackView.addArrangedSubview(notificationBanner.view)
        // No gap while the banner has nothing to show
        stackView.setCustomSpacing(0, after: notificationBanner.view)
        notificationBanner.didMove(toParent: self)

        reloadContent()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appearanceDidChange),
                                               name: .appearanceDidChange,
                                               object: nil)
    }

    @objc private func appearanceDidChange() {
        style = Style(appearance: AppSettings.shared.appearanceInfo.appearance)
        reloadContent()
    }

    /// Rebuilds the placeholder content below the banner with the current style
    private func reloadContent() {
        view.backgroundColor = style.background
        stackView.arrangedSubviews
            .filter { $0 !== notificationBanner.view }
            .forEach { $0.removeFromSuperview() }

        let sectionHeader = makeLabel("Recent activity", textStyle: .headline, weight: .semibold)
        [makeBalanceCard(), sectionHeader, makeActivityCard()].forEach(stackView.addArrangedSubview)
        stackView.setCustomSpacing(8, after: sectionHeader)
    }
}

// MARK: - NotificationBannerViewControllerDelegate

extension NotificationBannerExampleViewController: NotificationBannerViewControllerDelegate {
    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeContentHeight height: CGFloat) {
        stackView.setCustomSpacing(height > 0 ? stackView.spacing : 0, after: notificationBanner.view)
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didFailLoadWithError error: Error) {
        notificationBanner.view.isHidden = true
        ToastManager.shared.show("Error loading the notification banner")
    }
}

// MARK: - Placeholder content

private extension NotificationBannerExampleViewController {
    /// The appearance values the placeholder content uses, with the same defaults as the components
    struct Style {
        let background: UIColor
        let text: UIColor
        let secondaryText: UIColor
        let border: UIColor
        let cornerRadius: CGFloat
        let font: UIFont?

        init(appearance: EmbeddedComponentManager.Appearance) {
            background = appearance.colors.background ?? .white
            text = appearance.colors.text ?? UIColor(red: 0.21, green: 0.25, blue: 0.32, alpha: 1)
            secondaryText = appearance.colors.secondaryText ?? UIColor(red: 0.42, green: 0.45, blue: 0.5, alpha: 1)
            border = appearance.colors.border ?? UIColor(red: 0.84, green: 0.85, blue: 0.87, alpha: 1)
            cornerRadius = appearance.cornerRadius.base ?? 6
            font = appearance.typography.font
        }
    }

    func makeBalanceCard() -> UIView {
        let caption = makeLabel("Available balance", textStyle: .subheadline, color: style.secondaryText)
        let balance = makeLabel("$12,480.55", textStyle: .largeTitle, weight: .bold)
        let payout = makeLabel("Next payout of $3,210.00 on Dec 2", textStyle: .footnote, color: style.secondaryText)

        let stackView = UIStackView(arrangedSubviews: [caption, balance, payout])
        stackView.axis = .vertical
        stackView.spacing = 4
        stackView.setCustomSpacing(8, after: balance)
        return makeCard(containing: stackView)
    }

    func makeActivityCard() -> UIView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        for (index, activity) in Self.activities.enumerated() {
            if index > 0 {
                let separator = UIView()
                separator.backgroundColor = style.border
                separator.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
                stackView.addArrangedSubview(separator)
            }
            stackView.addArrangedSubview(makeActivityRow(activity))
        }
        return makeCard(containing: stackView, margins: .init(top: 4, leading: 16, bottom: 4, trailing: 16))
    }

    func makeActivityRow(_ activity: Activity) -> UIView {
        let text = UIStackView(arrangedSubviews: [
            makeLabel(activity.title, textStyle: .body),
            makeLabel(activity.detail, textStyle: .footnote, color: style.secondaryText),
        ])
        text.axis = .vertical
        text.spacing = 2

        let amount = makeLabel(activity.amount, textStyle: .body, weight: .semibold)
        amount.setContentHuggingPriority(.required, for: .horizontal)
        amount.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [text, amount])
        row.alignment = .center
        row.spacing = 12
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = .init(top: 12, leading: 0, bottom: 12, trailing: 0)
        return row
    }

    func makeCard(containing content: UIView,
                  margins: NSDirectionalEdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)) -> UIView {
        let card = UIView()
        card.layer.borderWidth = 1
        card.layer.borderColor = style.border.resolvedColor(with: traitCollection).cgColor
        card.layer.cornerRadius = style.cornerRadius
        card.directionalLayoutMargins = margins
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: card.layoutMarginsGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: card.layoutMarginsGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: card.layoutMarginsGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: card.layoutMarginsGuide.bottomAnchor),
        ])
        return card
    }

    func makeLabel(_ text: String,
                   textStyle: UIFont.TextStyle,
                   weight: UIFont.Weight = .regular,
                   color: UIColor? = nil) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = color ?? style.text
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        let size = UIFont.preferredFont(forTextStyle: textStyle).pointSize
        let font = style.font.map { font in
            UIFont(descriptor: font.fontDescriptor.addingAttributes([
                .traits: [UIFontDescriptor.TraitKey.weight: weight],
            ]), size: size)
        } ?? .systemFont(ofSize: size, weight: weight)
        label.font = UIFontMetrics(forTextStyle: textStyle).scaledFont(for: font)
        return label
    }
}
