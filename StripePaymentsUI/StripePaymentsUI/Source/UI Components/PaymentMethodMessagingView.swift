//
//  PaymentMethodMessagingView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 9/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit
import WebKit

/// 🏗 Under construction
///
/// A view that displays promotional text and images for payment methods like Afterpay and Klarna. For example, "As low as 4 interest-free payments of $9.75". When tapped, this view presents a full-screen SFSafariViewController to the customer with additional information about the payment methods being displayed.
///
/// You can embed this into your checkout or product screens to promote payment method options to your customer.
///
/// - Note: You must initialize this class by calling `PaymentMethodMessagingView.create(configuration:completion:)`
@objc(STP_Internal_PaymentMethodMessagingView)
@_spi(STP) public final class PaymentMethodMessagingView: UIView {
    // MARK: Initializers

    /// Asynchronously creates a `PaymentMethodMessagingView` for the given configuration.
    /// - Parameter configuration: A Configuration object containing details like the payment methods to display and the purchase amount.
    /// - Parameter completion: A completion block called when the view is loaded or failed to load.
    /// - Note: You must use this method to initialize a `PaymentMethodMessagingView`.
    public static func create(
        configuration: Configuration,
        completion: @escaping (Result<PaymentMethodMessagingView, Swift.Error>) -> Void
    ) {
        assert(!configuration.paymentMethods.isEmpty)
        assert(configuration.apiClient.publishableKey?.nonEmpty != nil)
        assert(!configuration.countryCode.isEmpty)
        let loadStartTime = Date()
        let parameters = Self.makeMessagingContentEndpointParams(configuration: configuration)
        var request = configuration.apiClient.configuredRequest(
            for: APIEndpoint,
            additionalHeaders: [:]
        )
        request.stp_addParameters(toURL: parameters)
        Task {
            do {
                let response = try await loadContent(configuration: configuration)
                let attributedString = try await makeAttributedString(
                    from: response.display_l_html,
                    configuration: configuration
                )
                let view = PaymentMethodMessagingView(
                    attributedString: attributedString,
                    modalURL: response.learn_more_modal_url,
                    configuration: configuration
                )
                let loadDuration = Date().timeIntervalSince(loadStartTime)
                Self.analyticsClient.log(
                    analytic: Analytic.loadSucceeded(duration: loadDuration),
                    apiClient: configuration.apiClient
                )
                completion(.success(view))
            } catch {
                let loadDuration = Date().timeIntervalSince(loadStartTime)
                Self.analyticsClient.log(
                    analytic: Analytic.loadFailed(duration: loadDuration),
                    apiClient: configuration.apiClient
                )
                completion(.failure(error))
            }
        }
    }

    init(
        attributedString: NSAttributedString,
        modalURL: String,
        configuration: Configuration
    ) {
        Self.analyticsClient.addClass(toProductUsageIfNecessary: PaymentMethodMessagingView.self)
        self.modalURL = URL(string: "https://" + modalURL)
        self.configuration = configuration
        super.init(frame: .zero)
        directionalLayoutMargins = .init(top: 12, leading: 12, bottom: 12, trailing: 12)
        backgroundColor = UIColor.systemBackground
        label.attributedText = attributedString
        label.textColor = configuration.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
            label.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
        ])
        addSubview(dummyLabelForDynamicType)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Overrides

#if !canImport(CompositorServices)
    // Overriden so we can respond to changing dark mode by updating the image color
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        Task {
            var attributedString = label.attributedText
            if previousTraitCollection?.isDarkMode != traitCollection.isDarkMode {
                // Update images by reloading content from the server
                let content = try await Self.loadContent(configuration: configuration)
                attributedString = try await Self.makeAttributedString(
                    from: content.display_l_html,
                    configuration: configuration
                )
            }
            if adjustsFontForContentSizeCategory {
                // Adjust the font size
                let adjustedFontSize =
                    dummyLabelForDynamicType.font?.pointSize ?? configuration.font.pointSize
                attributedString = attributedString?.withFontSize(adjustedFontSize)
            }
            label.attributedText = attributedString
            label.textColor = configuration.textColor
        }
    }
#endif

    // MARK: Internal

    static let APIEndpoint: URL = URL(string: "https://ppm.stripe.com/content")!
    let modalURL: URL?
    let configuration: Configuration
    static var analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient

    lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()

    @objc func didTap() {
        guard let modalURL = modalURL else { return }
        let config = SFSafariViewController.Configuration()
        let safariController = SFSafariViewController(url: modalURL, configuration: config)
        safariController.modalPresentationStyle = .overCurrentContext
        window?.findTopMostPresentedViewController()?.present(safariController, animated: true)
        log(analytic: .tapped)
    }

    // MARK: - UIContentSizeCategoryAdjusting

    public var adjustsFontForContentSizeCategory: Bool = false
    /// Some notes on supporting `UIContentSizeCategoryAdjusting` and Dynamic Type:
    /// 1. Our textView's `adjustsFontForContentSizeCategory` property doesn't work b/c we have to specify font via CSS (see `makeAttributedString`)
    /// 2. There's no API to get the size of a font adjusted for content size category
    /// As a workaround, we'll set `configuration.font` on this label and use its font size
    private lazy var dummyLabelForDynamicType: UILabel = {
        let view = UILabel()
        view.text = "Dummy text"
        view.font = configuration.font
        view.adjustsFontForContentSizeCategory = true
        view.isHidden = true
        return view
    }()
}

// MARK: - Helpers

extension PaymentMethodMessagingView {
    /// A regex that matches <img> tags and captures its url
    static let imgTagRegex = try! NSRegularExpression(pattern: "<img src=\"(.*?)\">")

    /// - Returns: The given `html` string with <img> tags replaced with <a href> tags, and a list of the URLs contained in the replaced tags
    static func htmlReplacingImageTags(html: String) -> (String, [URL]) {
        var html = html
        var images = [URL]()
        for match in imgTagRegex.matches(in: html, range: NSRange(html.startIndex..., in: html)).reversed() {
            guard
                let rangeOfImgTag = Range(match.range, in: html),
                let rangeOfURL = Range(match.range(at: 1), in: html)
            else {
                continue
            }
            let url = html[rangeOfURL]
            html.replaceSubrange(rangeOfImgTag, with: "<a href=\"\(url)\">_</a>")
            // Fetch the image
            guard let URL = URL(string: String(url)) else { continue }
            images.append(URL)
        }
        return (html, images)
    }

    static func makeCSS(for font: UIFont) -> String {
        // To set the font, we prepend CSS to the given `html` before converting it to an NSAttributedString
        let isSystemFont = font.familyName == UIFont.systemFont(ofSize: font.pointSize).familyName
        // If the specified font is the same family as the system font, use "-apple-system" as the family name. Otherwise, the html renderer will only use the non-bold variation of the system font, breaking any bold font configurations.
        let fontFamily = isSystemFont ? "-apple-system" : font.familyName
        return """
                <style>
                body {
                    font-family: "\(fontFamily)";
                }
                </style>
            """
    }

    static func makeAttributedString(
        from html: String,
        configuration: Configuration
    ) async throws -> NSAttributedString {
        // <img> tags don't work with `NSAttributedString.loadFromHTML` on iOS 13/14. As a workaround, we'll replace <img> with <a href> in this String, and manually replace them with images later:
        // 1. Replace the <img> tags with <a href> and pull out the image URLs
        let (html, imageURLs) = htmlReplacingImageTags(html: html)
        // 2. Construct the attributed string
        let css = makeCSS(for: configuration.font)
        let (attributedString, _) = try await NSAttributedString.fromHTML(css + html, options: [:])
        // 3. Fetch the images
        var images = [URL: UIImage]()
        for imageURL in imageURLs {
            images[imageURL] = try await loadImage(url: imageURL, apiClient: configuration.apiClient)
        }
        // 4. Replace the links in the attributed string with image attachments
        let mAttributedString = NSMutableAttributedString(attributedString: attributedString)
        mAttributedString.enumerateAttribute(.link, in: NSRange(0..<mAttributedString.length)) { value, range, _ in
            guard
                let url = value as? URL,
                let image = images[url]
            else { return }
            mAttributedString.deleteCharacters(in: range)
            let textAttachment = NSTextAttachment() // Note: We don't use the NSTextAttachment(image: ) initializer b/c it has a bug where the image is always tinted to the foreground (text) color
            textAttachment.image = image
            let imageAttachment = NSAttributedString(attachment: textAttachment)
            mAttributedString.insert(imageAttachment, at: range.lowerBound)
        }
        return mAttributedString.withFontSize(configuration.font.pointSize)
    }

    // MARK: - Network helpers
    struct PaymentMethodMessagingContentResponse: Decodable {
        let display_l_html: String
        let learn_more_modal_url: String
    }

    static func loadContent(
        configuration: Configuration
    ) async throws -> PaymentMethodMessagingContentResponse {
        let parameters = Self.makeMessagingContentEndpointParams(configuration: configuration)
        var request = configuration.apiClient.configuredRequest(
            for: APIEndpoint,
            additionalHeaders: [:]
        )
        request.stp_addParameters(toURL: parameters)
        return try await withCheckedThrowingContinuation { continuation in
            configuration.apiClient.get(
                url: APIEndpoint,
                parameters: parameters
            ) { (result: Result<PaymentMethodMessagingContentResponse, Swift.Error>) in
                continuation.resume(with: result)
            }
        }
    }

    static func makeMessagingContentEndpointParams(configuration: Configuration) -> [String: Any] {
        let logoColor: String
        switch UITraitCollection.current.isDarkMode
            ? configuration.imageColor.userInterfaceStyleDark
            : configuration.imageColor.userInterfaceStyleLight
        {
        case .light:
            logoColor = "white"
        case .dark:
            logoColor = "black"
        case .color:
            logoColor = "color"
        }
        return [
            "payment_methods": configuration.paymentMethods.map { (paymentMethod) -> String in
                switch paymentMethod {
                case .klarna: return "klarna"
                case .afterpayClearpay: return "afterpay_clearpay"
                }
            },
            "currency": configuration.currency,
            "amount": configuration.amount,
            "country": configuration.countryCode,
            "client": "ios",
            "logo_color": logoColor,
            "locale": Locale.canonicalLanguageIdentifier(from: configuration.locale.identifier),
        ]
    }

    static func loadImage(url: URL, apiClient: STPAPIClient) async throws -> UIImage? {
        let request = apiClient.configuredRequest(for: url)
        let (data, _) = try await apiClient.urlSession.data(for: request)
        return UIImage(data: data, scale: 3)?.withRenderingMode(.alwaysOriginal)
    }
}

// MARK: - STPAnalyticsProtocol
extension PaymentMethodMessagingView: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier = "PaymentMethodMessagingView"
}

extension PaymentMethodMessagingView {
    func log(analytic: Analytic) {
        Self.analyticsClient.log(analytic: analytic, apiClient: configuration.apiClient)
    }

    enum Analytic: StripeCore.Analytic {
        case loadFailed(duration: TimeInterval)
        case loadSucceeded(duration: TimeInterval)
        case tapped
        var event: StripeCore.STPAnalyticEvent {
            switch self {
            case .loadFailed: return .paymentMethodMessagingViewLoadFailed
            case .loadSucceeded: return .paymentMethodMessagingViewLoadSucceeded
            case .tapped: return .paymentMethodMessagingViewTapped
            }
        }
        var params: [String: Any] {
            switch self {
            case .loadFailed(let duration), .loadSucceeded(let duration):
                return [
                    "duration": duration
                ]
            case .tapped:
                return [:]
            }
        }
    }
}

// MARK: - NSAttributedString helpers
extension NSAttributedString {
    func withFontSize(_ size: CGFloat) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: self)
        mutable.enumerateAttributes(in: NSRange(0..<mutable.length)) { attributes, range, _ in
            // Ignore text attachments (images) - setting the font size on these causes the image to disappear
            guard attributes[NSAttributedString.Key.attachment] == nil else {
                return
            }
            guard let font = attributes[NSAttributedString.Key.font] as? UIFont else {
                return
            }
            let adjustedFont = font.withSize(size)
            mutable.setAttributes([.font: adjustedFont], range: range)
        }
        return mutable
    }
}
