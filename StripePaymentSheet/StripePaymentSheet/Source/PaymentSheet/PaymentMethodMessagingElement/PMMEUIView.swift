//
//  PMMEUIView.swift
//  StripePaymentSheet
//
//  Created by George Birch on 10/9/25.
//

import Foundation
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

// Abstract class for PMME UIViews. Use PMMESinglePartnerView or PMMEMultiPartnerView instead of displaying directly
class PMMEUIView: UIStackView {

    private let infoUrl: URL
    private let appearance: PaymentMethodMessagingElement.Appearance

    // Callback to notify SwiftUI of height changes. Unneeded if used in a UIKit context.
    private let didUpdateHeight: ((CGFloat) -> Void)?
    private var previousHeight: CGFloat?

    // TODO(gbirch) add accessibilityHint property with instructions about opening info url
    init(infoUrl: URL, appearance: PaymentMethodMessagingElement.Appearance, didUpdateHeight: ((CGFloat) -> Void)?) {
        self.infoUrl = infoUrl
        self.appearance = appearance
        self.didUpdateHeight = didUpdateHeight
        super.init(frame: .zero)

        // on tap behavior for opening info url
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))

        // set interface style
        if case .alwaysDark = appearance.style {
            overrideUserInterfaceStyle = .dark
        } else if case .alwaysLight = appearance.style {
            overrideUserInterfaceStyle = .light
        }
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Calculate our natural height
        let desiredHeight = systemLayoutSizeFitting(CGSize(width: frame.width, height: UIView.layoutFittingCompressedSize.height)).height

        // Notify if changed
        if desiredHeight != previousHeight {
            didUpdateHeight?(desiredHeight)
            self.previousHeight = desiredHeight
        }
    }

    @objc private func didTap() {
        // Construct themed info url
        let themeParam = switch (appearance.style, traitCollection.isDarkMode) {
        case (.alwaysLight, _), (.automatic, false): "stripe"
        case (.alwaysDark, _), (.automatic, true): "night"
        case (.flat, _): "flat"
        }

        let queryParam = URLQueryItem(name: "theme", value: themeParam)
        guard var urlComponents = URLComponents(url: infoUrl, resolvingAgainstBaseURL: false) else {
            stpAssertionFailure("Unable to generate URL components")
            return
        }
        if urlComponents.queryItems == nil {
            urlComponents.queryItems = [queryParam]
        } else {
            urlComponents.queryItems?.append(queryParam)
        }
        guard let themedUrl = urlComponents.url else {
            stpAssertionFailure("Unable to generate themed URL")
            return
        }

        // Launch themed info url
        let safariController = SFSafariViewController(url: themedUrl)
        safariController.modalPresentationStyle = .formSheet
        window?.findTopMostPresentedViewController()?.present(safariController, animated: true)
    }
}
