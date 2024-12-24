//
//  PayWithLinkButton.swift
//  StripePaymentSheet
//
//  Created by Cameron Sabol on 9/1/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripePayments
@_spi(STP) import StripePaymentsUI
@_spi(STP) import StripeUICore

/// A button for paying with Link.
/// For internal SDK use only
@objc(STP_Internal_PayWithLinkButton)
final class PayWithLinkButton: UIControl {

    struct Constants {
        static let defaultSize: CGSize = .init(width: 200, height: 44)
        static let logoSize: CGSize = .init(width: 48, height: 16)
        static let cardBrandSize: CGSize = .init(width: 28, height: 18)
        static let arrowSize: CGSize = .init(width: 17, height: 13)
        static let separatorSize: CGSize = .init(width: 1, height: 22)
        static let margins: NSDirectionalEdgeInsets = .init(top: 7, leading: 16, bottom: 7, trailing: 10)
        static let cardBrandInsets: UIEdgeInsets = .init(top: 1, left: 0, bottom: 0, right: 0)
        static let arrowInsets: UIEdgeInsets = .init(top: 1, left: 0, bottom: 0, right: 0)
    }

    fileprivate struct LinkAccountStub: PaymentSheetLinkAccountInfoProtocol {
        let email: String
        let redactedPhoneNumber: String?
        let isRegistered: Bool
        let isLoggedIn: Bool
    }

    /// Link account of the current user.
    var linkAccount: PaymentSheetLinkAccountInfoProtocol? = LinkAccountContext.shared.account {
        didSet {
            updateUI()
        }
    }

    var cornerRadius: CGFloat = ElementsUI.defaultCornerRadius {
        didSet {
            setNeedsLayout()
        }
    }

    override var isHighlighted: Bool {
        didSet {
            applyStyle()
        }
    }

    override var isEnabled: Bool {
        didSet {
            applyStyle()
        }
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: Constants.defaultSize.height)
    }

    private let titleBaseFont: UIFont = UIFont.systemFont(ofSize: 16, weight: .medium)

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            .scaled(withTextStyle: .callout, maximumPointSize: 16)

        // Cut off the end of the email if needed, the customer doesn't care as much about the domain
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.lineBreakMode = .byTruncatingTail

        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var last4Label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            .scaled(withTextStyle: .callout, maximumPointSize: 16)
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var payWithLinkView: UILabel = {
        let linkView = UILabel()
        linkView.textAlignment = .center
        linkView.lineBreakMode = .byTruncatingMiddle
        linkView.adjustsFontForContentSizeCategory = true
        linkView.translatesAutoresizingMaskIntoConstraints = false
        linkView.font = UIFont.systemFont(ofSize: 20, weight: .medium)
            .scaled(withTextStyle: .callout, maximumPointSize: 21)

        let payWithLinkString = NSMutableAttributedString(string: String.Localized.pay_with_link)

        // Create the Link logo attachment
        let linkImage = Image.link_logo_bw.makeImage(template: false)
        let linkAttachment = NSTextAttachment(image: linkImage)

        let linkLogoRatio = linkImage.size.width / linkImage.size.height

        let linkTextSpacing = 0.073 // the total top+bottom space outside the Link logo

        let linkLogoHeight = (linkView.font.capHeight + (linkView.font.pointSize * 0.1)) *
        (1.0 + linkTextSpacing)
        let linkY = (linkTextSpacing) * linkLogoHeight
        linkAttachment.bounds = CGRect(x: 0, y: -linkY, width: linkLogoHeight * linkLogoRatio, height: linkLogoHeight)

        // Add a spacer before the Link logo and after the Link logo
        let range = payWithLinkString.mutableString.range(of: "Link")
        if range.location != NSNotFound {
            payWithLinkString.insert(Self.makeSpacerString(width: 1), at: range.location + range.length)
            payWithLinkString.insert(Self.makeSpacerString(width: 1), at: range.location)

            // Add the Link attachment
            payWithLinkString.replaceOccurrences(of: "Link", with: linkAttachment)
        }

        linkView.attributedText = payWithLinkString
        return linkView
    }()

    private lazy var payWithStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            payWithLinkView,
        ].compactMap({ $0 }))
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.alignment = .center
        return stackView
    }()

    private lazy var emailSeparatorView: UIView = Self.makeSeparatorView()
    private lazy var emailStackView: UIStackView = {
        let logoView = Self.makeLogoView()
        let stackView = UIStackView(arrangedSubviews: [
            logoView,
            emailSeparatorView,
            emailLabel,
        ].compactMap({ $0 }))
        stackView.spacing = 10
        stackView.setCustomSpacing(12, after: logoView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.alignment = .center
        return stackView
    }()

    private lazy var cardBrandSeparatorView: UIView = Self.makeSeparatorView()
    private lazy var cardBrandView: UIImageView = {
        let brandView = UIImageView(image: STPImageLibrary.unknownCardCardImage())
        brandView.translatesAutoresizingMaskIntoConstraints = false
        brandView.contentMode = .scaleAspectFill

        NSLayoutConstraint.activate([
            brandView.widthAnchor.constraint(equalToConstant: Constants.cardBrandSize.width),
            brandView.heightAnchor.constraint(equalToConstant: Constants.cardBrandSize.height),
        ])

        return brandView
    }()

    private lazy var cardStackView: UIStackView = {
        let logoView = Self.makeLogoView()
        let stackView = UIStackView(arrangedSubviews: [
            logoView,
            cardBrandSeparatorView,
            cardBrandView,
            last4Label,
        ].compactMap({ $0 }))
        stackView.spacing = 10
        stackView.setCustomSpacing(5, after: cardBrandView)
        stackView.setCustomSpacing(8, after: last4Label)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = .fill
        stackView.alignment = .center
        return stackView
    }()

    enum LinkAccountState {
        case noValidAccount
        case hasCard(last4: String, brand: STPCardBrand)
        case hasEmail(email: String)
    }

    var linkAccountState: LinkAccountState {
        if !(linkAccount?.isRegistered ?? false) {
            return .noValidAccount
        }

        if let email = linkAccount?.email {
            return .hasEmail(email: email)
        }

        return .noValidAccount
    }

    init() {
        super.init(frame: CGRect(origin: .zero, size: Constants.defaultSize))
        isAccessibilityElement = true
        self.linkAccount = LinkAccountContext.shared.account
        setupUI()
        applyStyle()
        updateUI()
        // Listen for account changes
        LinkAccountContext.shared.addObserver(self, selector: #selector(onAccountChange(_:)))
    }
    @objc
    func onAccountChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.linkAccount = notification.object as? PaymentSheetLinkAccount
        }
    }
    deinit {
        // Stop listening for account changes
        LinkAccountContext.shared.removeObserver(self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyCornerRadius()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        bounds.contains(point) ? self : nil
    }

}

// MARK: - UI

private extension PayWithLinkButton {

    static func makeSpacerString(width: CGFloat) -> NSAttributedString {
        let spacerAttachment = NSTextAttachment()
        spacerAttachment.bounds = CGRect(x: 0, y: 0, width: width, height: 0)
        return NSAttributedString(attachment: spacerAttachment)
    }

    static func makeLogoView() -> UIImageView {
        let logoView = UIImageView(image: Image.link_logo_bw.makeImage(template: false))
        logoView.translatesAutoresizingMaskIntoConstraints = false
        logoView.contentMode = .scaleAspectFill

        NSLayoutConstraint.activate([
            logoView.widthAnchor.constraint(equalToConstant: Constants.logoSize.width),
            logoView.heightAnchor.constraint(equalToConstant: Constants.logoSize.height),
        ])

        return logoView
    }

    static func makeSeparatorView() -> UIView {
        let lineView = UIView()
        lineView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            lineView.widthAnchor.constraint(equalToConstant: Constants.separatorSize.width),
            lineView.heightAnchor.constraint(equalToConstant: Constants.separatorSize.height),
        ])

        return lineView
    }

    func setupUI() {
        directionalLayoutMargins = Constants.margins
        addSubview(payWithStackView)
        addSubview(emailStackView)
        addSubview(cardStackView)

        NSLayoutConstraint.activate([
            payWithStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            payWithStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            payWithStackView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),

            emailStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            emailStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            emailStackView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),

            // Keep the views within the button, compressing the email if needed
            emailStackView.leadingAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor),
            emailStackView.trailingAnchor.constraint(lessThanOrEqualTo: layoutMarginsGuide.trailingAnchor),

            cardStackView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            cardStackView.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            cardStackView.centerXAnchor.constraint(equalTo: layoutMarginsGuide.centerXAnchor),

        ])
    }

    func updateUI() {
        switch linkAccountState {
        case .hasCard(let last4, let brand):
            let cardImage = STPImageLibrary.cardBrandImage(for: brand)
                .withAlignmentRectInsets(
                    Constants.cardBrandInsets
                )
            cardBrandView.image = cardImage
            last4Label.text = last4

            cardStackView.isHidden = false
            payWithLinkView.isHidden = true
            emailStackView.isHidden = true
            payWithStackView.isHidden = true
        case .hasEmail(let email):
            emailLabel.text = email

            payWithLinkView.isHidden = true
            cardStackView.isHidden = true
            emailStackView.isHidden = false
            payWithStackView.isHidden = true
        case .noValidAccount:
            emailStackView.isHidden = true
            cardStackView.isHidden = true
            payWithStackView.isHidden = false
            payWithLinkView.isHidden = false
        }
        updateAccessibilityContent()
    }

}

// MARK: - Styling

private extension PayWithLinkButton {

    var effectiveCornerRadius: CGFloat {
        // Matches the formula used by `PKPaymentButton` for calculating
        // the effective corner radius. The effective corner radius is snapped
        // to half the button's height if the corner radius is
        // greater or equals than approx. 1/3 of the height (`threshold`).
        let threshold = 0.32214

        return cornerRadius >= bounds.height * threshold
        ? bounds.height / 2
        : cornerRadius
    }

    func applyStyle() {
        // Foreground
        let foregroundColor = self.foregroundColor(for: state)
        titleLabel.textColor = foregroundColor
        payWithLinkView.tintColor = foregroundColor
        payWithLinkView.textColor = foregroundColor
        emailStackView.tintColor = foregroundColor
        payWithStackView.tintColor = foregroundColor
        cardStackView.tintColor = foregroundColor
        emailLabel.textColor = foregroundColor

        // Background
        backgroundColor = backgroundColor(for: state)

        // Separators
        emailSeparatorView.backgroundColor = separatorColor(for: state)
        cardBrandSeparatorView.backgroundColor = separatorColor(for: state)
    }

    func applyCornerRadius() {
        layer.cornerCurve = .continuous

        layer.cornerRadius = effectiveCornerRadius
    }

    func foregroundColor(for state: State) -> UIColor {
        switch state {
        case .highlighted:
            return UIColor.linkPrimaryButtonForeground.withAlphaComponent(0.8)
        default:
            return UIColor.linkPrimaryButtonForeground
        }
    }

    func backgroundColor(for state: State) -> UIColor {
        switch state {
        case .highlighted:
            return UIColor.linkBrand.darken(by: 0.2)
        case .disabled:
            return UIColor.linkBrand.withAlphaComponent(0.5)
        default:
            return UIColor.linkBrand
        }
    }

    func separatorColor(for state: State) -> UIColor {
        switch state {
        case .highlighted:
            return UIColor.linkBrand400.darken(by: 0.2)
        case .disabled:
            return UIColor.linkBrand400.withAlphaComponent(0.5)
        default:
            return UIColor.linkBrand400
        }
    }

}

// MARK: - Accessibility

private extension PayWithLinkButton {

    func updateAccessibilityContent() {
        if isEnabled {
            accessibilityTraits = [.button]
        } else {
            accessibilityTraits = [.button, .notEnabled]
        }

        // To use Xcode SwiftUI Previews, comment out the following `accessibilityLabel` setter:
        accessibilityLabel = String.Localized.pay_with_link

        switch linkAccountState {
        case .hasCard(let last4, let brand):
            accessibilityValue = "\(STPCardBrandUtilities.stringFrom(brand) ?? "Unknown") \(last4)"
        case .hasEmail(let email):
            accessibilityValue = email
        case .noValidAccount:
            accessibilityValue = nil
        }
    }

}

// For previews in Xcode
#if DEBUG
import SwiftUI

struct UIViewPreview<View: UIView>: UIViewRepresentable {
    let view: View

    init(_ builder: @escaping () -> View) {
        view = builder()
    }

    // MARK: UIViewRepresentable
    func makeUIView(context: Context) -> UIView {
        return view
    }

    func updateUIView(_ view: UIView, context: Context) {
        view.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        view.setContentHuggingPriority(.defaultHigh, for: .vertical)
    }
}

private func makeAccountStub(email: String, isRegistered: Bool, lastPM: LinkPMDisplayDetails?) -> PayWithLinkButton.LinkAccountStub {
    return PayWithLinkButton.LinkAccountStub(
        email: email,
        redactedPhoneNumber: nil,
        isRegistered: isRegistered,
        isLoggedIn: false
    )
}

struct LinkButtonPreviews_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            UIViewPreview {
                let lb = PayWithLinkButton()
                return lb
            }.padding()
            UIViewPreview {
                let lb = PayWithLinkButton()
                lb.linkAccount = makeAccountStub(email: "theop@example.com", isRegistered: true, lastPM: nil)
                return lb
            }.padding()
            UIViewPreview {
                let lb = PayWithLinkButton()
                lb.linkAccount = makeAccountStub(email: "theopetersonmarks@longestemaildomain.com", isRegistered: true, lastPM: nil)
                return lb
            }.padding()
            UIViewPreview {
                let lb = PayWithLinkButton()
                lb.linkAccount = makeAccountStub(email: "test@test.com", isRegistered: true, lastPM: .init(last4: "3155", brand: .visa))
                return lb
            }.padding()
        }
    }
}
#endif
