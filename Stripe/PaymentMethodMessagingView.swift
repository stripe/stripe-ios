//
//  PaymentMethodMessagingView.swift
//  StripeiOS
//
//  Created by Yuki Tokuhiro on 9/26/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import UIKit
import SafariServices
import WebKit
@_spi(STP) import StripeUICore
@_spi(STP) import StripeCore

/**
 🏗 Under construction
 
 A view that displays promotional text and images for payment methods like Afterpay and Klarna. For example, "As low as 4 interest-free payments of $9.75". When tapped, this view presents a full-screen SFSafariViewController to the customer with additional information about the payment methods being displayed.
 
 You can embed this into your checkout or product screens to promote payment method options to your customer.
 
 - Note: You must initialize this class by calling `PaymentMethodMessagingView.create(configuration:completion:)`
 */
@_spi(STP) public final class PaymentMethodMessagingView: UIView {
    // MARK: Initializers
    
    /// Asynchronously creates a `PaymentMethodMessagingView` for the given configuration.
    /// - Parameter configuration: A Configuration object containing details like the payment methods to display and the purchase amount.
    /// - Parameter completion: A completion block called when the view is loaded or failed to load.
    /// - Note: You must use this method to initialize a `PaymentMethodMessagingView`.
    @available(iOS 13, *)
    public static func create(configuration: Configuration, completion: @escaping (Result<PaymentMethodMessagingView, Swift.Error>) -> ()) {
        assert(configuration.apiClient.publishableKey?.nonEmpty != nil)
        let loadStartTime = Date()
        let parameters = Self.makeMessagingContentEndpointParams(configuration: configuration)
        var request = configuration.apiClient.configuredRequest(for: APIEndpoint, additionalHeaders: [:])
        request.stp_addParameters(toURL: parameters)
        
        configuration.apiClient.get(
            url: APIEndpoint,
            parameters: parameters
        ) { (result: Result<PaymentMethodMessagingContentResponse, Swift.Error>) in
            let loadDuration = Date().timeIntervalSince(loadStartTime)
//
//            let mockHTML =
//            """
//            <img src=\"https://cdn.glitch.global/954beed2-51a3-4c6b-93cc-df61c4bfce70/Klarna.png?v=1666291694995\"><img src=\"https://cdn.glitch.global/954beed2-51a3-4c6b-93cc-df61c4bfce70/apple_pay.png?v=1666291694995\">
//            <br/>
//            As low as 4 interest-free payments of <b> $24.75 </b> 🎉
//            """
//            makeAttributedString(from: mockHTML, font: configuration.font, textColor: configuration.textColor) { result in
//                switch result {
//                case .success(let attributedString):
//                    let view = PaymentMethodMessagingView(attributedString: attributedString, modalURL: "stripe.com", configuration: configuration)
//                    STPAnalyticsClient.sharedClient.log(analytic: Analytic.loadSucceeded(duration: loadDuration), apiClient: configuration.apiClient)
//                    completion(.success(view))
//                case .failure(let error):
//                    STPAnalyticsClient.sharedClient.log(analytic: Analytic.loadFailed(duration: loadDuration), apiClient: configuration.apiClient)
//                    completion(.failure(error))
//                }
//            }

            
            switch result {
            case .failure(let error):
                STPAnalyticsClient.sharedClient.log(analytic: Analytic.loadFailed(duration: loadDuration), apiClient: configuration.apiClient)
                completion(.failure(error))
            case .success(let response):
                makeAttributedString(from: response.display_l_html, font: configuration.font, textColor: configuration.textColor) { result in
                    switch result {
                    case .success(let attributedString):
                        let view = PaymentMethodMessagingView(attributedString: attributedString, modalURL: response.learn_more_modal_url, configuration: configuration)
                        STPAnalyticsClient.sharedClient.log(analytic: Analytic.loadSucceeded(duration: loadDuration), apiClient: configuration.apiClient)
                        completion(.success(view))
                    case .failure(let error):
                        STPAnalyticsClient.sharedClient.log(analytic: Analytic.loadFailed(duration: loadDuration), apiClient: configuration.apiClient)
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    public init(attributedString: NSAttributedString, modalURL: String, configuration: Configuration) {
        analyticsClient.addClass(toProductUsageIfNecessary: PaymentMethodMessagingView.self)
        self.baseHTML = ""
        self.modalURL = URL(string: modalURL)
        self.configuration = configuration
        super.init(frame: .zero)
        backgroundColor = CompatibleColor.systemBackground
        textView.attributedText = attributedString
        textView.textColor = configuration.textColor
        
        addAndPinSubview(textView)
        addSubview(dummyLabelForDynamicType)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tap)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Overrides
    
    public override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    // Overriden so we can respond to changing dark mode by updating the image color
    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // This avoids an exception that happens when this method is called on the main thread and the app is backgrounded
        DispatchQueue.main.async {
            
            self.updateUI()
        }
    }
    
    // MARK: Internal
    
    static let APIEndpoint: URL = URL(string: "https://qa-ppm.stripe.com/content")!
    let baseHTML: String
    let modalURL: URL?
    let configuration: Configuration
    var analyticsClient: STPAnalyticsClientProtocol = STPAnalyticsClient.sharedClient
    
    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.isSelectable = false
        textView.backgroundColor = nil
        return textView
    }()
    
    func updateUI() {
        if adjustsFontForContentSizeCategory {
            let adjustedFontSize = dummyLabelForDynamicType.font?.pointSize ?? configuration.font.pointSize
            textView.attributedText.enumerateAttributes(in: NSRange(0..<textView.attributedText.length)) { attributes, range, stop in
                // Ignore text attachments (images) - setting the font size on these causes the image to disappear
                guard attributes[NSAttributedString.Key.attachment] == nil else {
                   return
                }
                guard let font = attributes[NSAttributedString.Key.font] as? UIFont else {
                   return
                }
                let adjustedFont = font.withSize(adjustedFontSize)
                textView.textStorage.setAttributes([.font: adjustedFont], range: range)
            }
        }
//        let attributedText = Self.makeAttributedString(from: baseHTML, font: font, textColor: textColor)
//        textView.attributedText = attributedText
//        textView.textColor = textColor
    }
    
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
    lazy var dummyLabelForDynamicType: UILabel = {
        let view =  UILabel()
        view.text = "Dummy text"
        view.font = configuration.font
        view.adjustsFontForContentSizeCategory = true
        view.isHidden = true
        return view
    }()
}

// MARK: - Helpers

extension PaymentMethodMessagingView {
    static func makeAttributedString(from html: String, font: UIFont, textColor: UIColor, completion: @escaping (Result<NSAttributedString, Swift.Error>) -> ()) {
        // To set the font, we prepend CSS to the given `html` before converting it to an NSAttributedString
        let isSystemFont = font.familyName == UIFont.systemFont(ofSize: font.pointSize).familyName
        // If the specified font is the same family as the system font, use "-apple-system" as the family name. Otherwise, the html renderer will only use the non-bold variation of the system font, breaking any bold font configurations.
        let fontFamily = isSystemFont ? "-apple-system" : font.familyName
        let css = """
            <style>
            body {
                font-family: "\(fontFamily)";
                font-size: \(font.pointSize);
            }
            </style>
        """
        
        // If textColor is closer to white than black, replace the image URLs with dark-mode variants
//        var html = html
//        if
//            textColor.contrastRatio(to: .white) < textColor.contrastRatio(to: .black),
//            let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
//        {
//            let matches = detector.matches(in: html, options: [], range: NSRange(location: 0, length: html.count))
//            for match in matches {
//                guard
//                    let originalURL = match.url,
//                    originalURL.pathExtension == "png"
//                else { continue }
//                // lastPathComponent looks something like "/klarna.png" - change it to "/klarna_dark.png"
//                let newLastPathComponent = originalURL.lastPathComponent.replacingOccurrences(of: ".png", with: "_dark.png")
//                // Make a new URL using the new path
//                let newURL = originalURL.deletingLastPathComponent().appendingPathComponent(newLastPathComponent)
//                // Replace the old URL with the new URL
//                html = html.replacingOccurrences(of: originalURL.absoluteString, with: newURL.absoluteString)
//            }
//        }
        
        NSAttributedString.loadFromHTML(string: css + html, options: [:]) { attributedString, attributeDict, error in
            guard let attributedString = attributedString else {
                completion(.failure(error ?? Error.failedToInitializeAttributedString))
                return
            }
            // Set images to 3x
            attributedString.enumerateAttribute(.attachment, in: NSRange(0..<attributedString.length)) { value, range, stop in
                guard
                    let value = value as? NSTextAttachment,
                    let imageData = value.fileWrapper?.regularFileContents,
                    let scaledImage = UIImage(data: imageData, scale: 3)
                else { return }
                value.image = scaledImage
            }
            completion(.success(attributedString))
        }
    }
    
    static func makeMessagingContentEndpointParams(configuration: Configuration) -> [String: Any] {
        return [
            "payment_methods": configuration.paymentMethods.map { (paymentMethod) -> String in
                switch paymentMethod {
                case .klarna: return "klarna"
                case .afterpayClearpay: return "afterpay_clearpay"
                }
            },
            "currency": configuration.currency,
            "amount": configuration.amount,
            "locale": configuration.locale,
            "country": configuration.countryCode,
            "client": "ios",
            "logo_color": isDarkMode() ? configuration.imageColor.userInterfaceStyleDark : configuration.imageColor.userInterfaceStyleLight
        ]
    }
}

extension PaymentMethodMessagingView: STPAnalyticsProtocol {
    @_spi(STP) public static var stp_analyticsIdentifier = "PaymentMethodMessagingView"
}
 
extension PaymentMethodMessagingView {
    func log(analytic: Analytic) {
        analyticsClient.log(analytic: analytic, apiClient: configuration.apiClient)
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
        var params: [String : Any] {
            switch self {
            case .loadFailed(duration: let duration), .loadSucceeded(duration: let duration):
                return [
                    "duration": duration
                ]
            case .tapped:
                return [:]
            }
        }
    }
}

struct PaymentMethodMessagingContentResponse: Decodable {
    let display_l_html: String
    let learn_more_modal_url: String
}
