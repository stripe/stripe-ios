//
//  NotificationBannerExampleViewController.swift
//  StripeConnect Example
//
//  Demonstrates rendering the notification banner *inline* (not full screen),
//  sized to its content, with sample host-app content rendered below it.
//

@_spi(DashboardOnly) @_spi(PrivatePreviewConnect) import StripeConnect
import UIKit

class NotificationBannerExampleViewController: UIViewController {

    private let componentManager: EmbeddedComponentManager
    private var bannerVC: NotificationBannerViewController!
    private let bannerLoadingView = NotificationBannerSkeletonView()

    private let scrollView = UIScrollView()
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = .init(top: 12, leading: 16, bottom: 24, trailing: 16)
        return stack
    }()

    private let debugLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.textColor = .secondaryLabel
        label.text = "onNotificationsChange → (waiting)\nheight → (waiting)"
        return label
    }()

    private var lastTotal = 0
    private var lastActionRequired = 0
    private var lastHeight: CGFloat = 0
    private var bannerLoadState: NotificationBannerViewController.InitialLoadState = .loading
    private var cardViews: [UIView] = []
    private var primaryLabels: [UILabel] = []
    private var secondaryLabels: [UILabel] = []

    init(componentManager: EmbeddedComponentManager) {
        self.componentManager = componentManager
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyHostAppearance()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyHostAppearance()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Notification banner"

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
        ])

        // 1. A host-owned skeleton shown while the SDK loads the banner.
        contentStack.addArrangedSubview(bannerLoadingView)

        // 2. The inline, self-sizing notification banner.
        bannerVC = componentManager.createNotificationBannerViewController()
        bannerVC.taskTitle = "Update information"
        bannerVC.delegate = self
        addChild(bannerVC)
        contentStack.addArrangedSubview(bannerVC.view)
        bannerVC.didMove(toParent: self)
        updateBannerLoadState(bannerVC.initialLoadState, animated: false)

        // 3. Debug readout of what the banner reports.
        contentStack.addArrangedSubview(debugLabel)

        // 4. Sample host-app content, rendered *below* the banner so it's clear
        //    the banner is inline and pushes app content down as it grows.
        contentStack.addArrangedSubview(makeSectionHeader("Your app content"))
        contentStack.addArrangedSubview(makeBalanceCard())
        for payment in Self.samplePayments {
            contentStack.addArrangedSubview(makeRow(title: payment.0, subtitle: payment.1, amount: payment.2))
        }

        applyHostAppearance()
    }

    // MARK: - Sample host-app UI

    private static let samplePayments: [(String, String, String)] = [
        ("Acme Coffee Co.", "Today, 9:41 AM", "$4.50"),
        ("Blue Bottle", "Today, 8:12 AM", "$6.25"),
        ("Corner Bakery", "Yesterday", "$12.80"),
        ("Downtown Deli", "Yesterday", "$18.40"),
        ("Elm St. Grocers", "Mar 12", "$54.10"),
    ]

    private func makeSectionHeader(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text.uppercased()
        label.font = .preferredFont(forTextStyle: .footnote)
        secondaryLabels.append(label)
        return label
    }

    private func makeBalanceCard() -> UIView {
        let card = makeCard()
        let title = UILabel()
        title.text = "Available balance"
        title.font = .preferredFont(forTextStyle: .subheadline)
        secondaryLabels.append(title)
        let amount = UILabel()
        amount.text = "$2,438.19"
        amount.font = .systemFont(ofSize: 34, weight: .bold)
        primaryLabels.append(amount)
        let stack = UIStackView(arrangedSubviews: [title, amount])
        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)
        pin(stack, in: card, insets: .init(top: 16, left: 16, bottom: 16, right: 16))
        return card
    }

    private func makeRow(title: String, subtitle: String, amount: String) -> UIView {
        let card = makeCard()
        let name = UILabel()
        name.text = title
        name.font = .preferredFont(forTextStyle: .body)
        primaryLabels.append(name)
        let sub = UILabel()
        sub.text = subtitle
        sub.font = .preferredFont(forTextStyle: .caption1)
        secondaryLabels.append(sub)
        let left = UIStackView(arrangedSubviews: [name, sub])
        left.axis = .vertical
        left.spacing = 2

        let amountLabel = UILabel()
        amountLabel.text = amount
        amountLabel.font = .preferredFont(forTextStyle: .body)
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        primaryLabels.append(amountLabel)

        let row = UIStackView(arrangedSubviews: [left, amountLabel])
        row.axis = .horizontal
        row.alignment = .center
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        pin(row, in: card, insets: .init(top: 12, left: 16, bottom: 12, right: 16))
        return card
    }

    private func makeCard() -> UIView {
        let card = UIView()
        cardViews.append(card)
        return card
    }

    private func applyHostAppearance() {
        let appearance = AppSettings.shared.appearanceInfo.appearance
        let backgroundColor = appearance.colors.background ?? .systemGroupedBackground
        let surfaceColor = appearance.colors.offsetBackground
            ?? appearance.colors.background
            ?? .secondarySystemGroupedBackground
        let textColor = appearance.colors.text ?? .label
        let secondaryTextColor = appearance.colors.secondaryText ?? .secondaryLabel
        let cornerRadius = appearance.cornerRadius.base ?? 8
        let borderColor = appearance.colors.border?.resolvedColor(with: traitCollection)

        view.backgroundColor = backgroundColor
        scrollView.backgroundColor = backgroundColor
        debugLabel.textColor = secondaryTextColor
        debugLabel.font = themedFont(
            fallback: .monospacedSystemFont(ofSize: 12, weight: .regular),
            appearance: appearance
        )

        for card in cardViews {
            card.backgroundColor = surfaceColor
            card.layer.cornerRadius = cornerRadius
            card.layer.borderWidth = borderColor == nil ? 0 : 1
            card.layer.borderColor = borderColor?.cgColor
        }
        for label in primaryLabels {
            label.textColor = textColor
            label.font = themedFont(fallback: label.font, appearance: appearance)
        }
        for label in secondaryLabels {
            label.textColor = secondaryTextColor
            label.font = themedFont(fallback: label.font, appearance: appearance)
        }

        bannerLoadingView.apply(appearance: appearance)
    }

    private func themedFont(
        fallback: UIFont,
        appearance: EmbeddedComponentManager.Appearance
    ) -> UIFont {
        guard let themeFont = appearance.typography.font else { return fallback }
        return UIFontMetrics.default.scaledFont(for: themeFont.withSize(fallback.pointSize))
    }

    private func pin(_ subview: UIView, in container: UIView, insets: UIEdgeInsets) {
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: container.topAnchor, constant: insets.top),
            subview.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: insets.left),
            subview.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -insets.right),
            subview.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -insets.bottom),
        ])
    }

    private func updateDebugLabel() {
        debugLabel.text = "loadState → \(bannerLoadState)\nonNotificationsChange → total: \(lastTotal), actionRequired: \(lastActionRequired)\nheight → \(Int(lastHeight))pt"
    }

    private func updateBannerLoadState(_ loadState: NotificationBannerViewController.InitialLoadState,
                                       animated: Bool) {
        bannerLoadState = loadState
        updateDebugLabel()

        switch loadState {
        case .loading:
            bannerLoadingView.isHidden = false
            bannerLoadingView.startAnimating()
        case .loaded, .failed:
            hideBannerLoadingView(animated: animated)
        @unknown default:
            hideBannerLoadingView(animated: animated)
        }
    }

    private func hideBannerLoadingView(animated: Bool) {
        let animations = {
            self.bannerLoadingView.alpha = 0
            self.bannerLoadingView.isHidden = true
            self.contentStack.layoutIfNeeded()
        }
        let completion: (Bool) -> Void = { _ in
            self.bannerLoadingView.stopAnimating()
            self.bannerLoadingView.alpha = 1
        }

        if animated {
            UIView.animate(withDuration: 0.2,
                           animations: animations,
                           completion: completion)
        } else {
            animations()
            completion(true)
        }
    }
}

// MARK: - NotificationBannerViewControllerDelegate

extension NotificationBannerExampleViewController: NotificationBannerViewControllerDelegate {
    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeWithTotal total: Int,
                            andActionRequired actionRequired: Int) {
        lastTotal = total
        lastActionRequired = actionRequired
        updateDebugLabel()
    }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeContentHeight height: CGFloat) {
        lastHeight = height
        updateDebugLabel()
    }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didChangeInitialLoadState loadState: NotificationBannerViewController.InitialLoadState) {
        updateBannerLoadState(loadState, animated: true)
    }

    func notificationBanner(_ notificationBanner: NotificationBannerViewController,
                            didFailLoadWithError error: Error) {
        debugLabel.text = "Banner failed to load: \(error.localizedDescription)"
    }
}

private final class NotificationBannerSkeletonView: UIView {
    private let animatedContent = UIView()
    private var bars: [UIView] = []
    private var skeletonBorderColor: UIColor = .separator

    override init(frame: CGRect) {
        super.init(frame: frame)

        layer.borderWidth = 1
        accessibilityElementsHidden = true

        animatedContent.translatesAutoresizingMaskIntoConstraints = false
        addSubview(animatedContent)

        let title = makeBar(width: 156, height: 16)
        let subtitle = makeBar(width: 220, height: 12)
        let text = UIStackView(arrangedSubviews: [title, subtitle])
        text.axis = .vertical
        text.alignment = .leading
        text.spacing = 10
        text.translatesAutoresizingMaskIntoConstraints = false
        animatedContent.addSubview(text)

        let action = makeBar(width: 72, height: 36)
        action.layer.cornerRadius = 18
        animatedContent.addSubview(action)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 104),
            animatedContent.topAnchor.constraint(equalTo: topAnchor),
            animatedContent.leadingAnchor.constraint(equalTo: leadingAnchor),
            animatedContent.trailingAnchor.constraint(equalTo: trailingAnchor),
            animatedContent.bottomAnchor.constraint(equalTo: bottomAnchor),
            text.leadingAnchor.constraint(equalTo: animatedContent.leadingAnchor, constant: 16),
            text.trailingAnchor.constraint(lessThanOrEqualTo: action.leadingAnchor, constant: -16),
            text.centerYAnchor.constraint(equalTo: animatedContent.centerYAnchor),
            action.trailingAnchor.constraint(equalTo: animatedContent.trailingAnchor, constant: -16),
            action.centerYAnchor.constraint(equalTo: animatedContent.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.borderColor = skeletonBorderColor.resolvedColor(with: traitCollection).cgColor
    }

    func apply(appearance: EmbeddedComponentManager.Appearance) {
        let backgroundColor = appearance.colors.background ?? .secondarySystemGroupedBackground
        let barColor = appearance.colors.secondaryText.map { color in
            UIColor { traits in
                color.resolvedColor(with: traits).withAlphaComponent(0.18)
            }
        } ?? .tertiarySystemFill

        self.backgroundColor = backgroundColor
        layer.cornerRadius = appearance.cornerRadius.base ?? 8
        skeletonBorderColor = appearance.colors.border ?? .separator
        setNeedsLayout()
        bars.forEach { $0.backgroundColor = barColor }
    }

    func startAnimating() {
        guard animatedContent.layer.animation(forKey: "pulse") == nil else { return }
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 1
        animation.toValue = 0.45
        animation.duration = 0.8
        animation.autoreverses = true
        animation.repeatCount = .infinity
        animatedContent.layer.add(animation, forKey: "pulse")
    }

    func stopAnimating() {
        animatedContent.layer.removeAnimation(forKey: "pulse")
    }

    private func makeBar(width: CGFloat, height: CGFloat) -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .tertiarySystemFill
        view.layer.cornerRadius = height / 2
        bars.append(view)
        let widthConstraint = view.widthAnchor.constraint(equalToConstant: width)
        widthConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            widthConstraint,
            view.heightAnchor.constraint(equalToConstant: height),
        ])
        return view
    }
}
