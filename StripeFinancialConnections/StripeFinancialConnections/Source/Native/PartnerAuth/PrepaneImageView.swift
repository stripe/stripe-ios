//
//  PrepaneImageView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/10/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit
import WebKit

final class PrepaneImageView: UIView {

    init(imageURLString: String) {
        super.init(frame: .zero)
        backgroundColor = .backgroundContainer
        clipsToBounds = true
        layer.cornerRadius = 8.0

        // first we load an image (or GIF) into a WebView
        let imageView = GIFImageView(gifUrlString: imageURLString)
        // the WebView is surrounded by a background that imitates the GIF presented inside of a phone
        let phoneBackgroundView = CreatePhoneBackgroundView(imageView: imageView)
        // we center the phone+gif in the middle
        let centeringView = CreateCenteringView(centeredView: phoneBackgroundView)
        addAndPinSubview(centeringView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private func CreatePhoneBackgroundView(imageView: UIView) -> UIView {
    let containerView = UIView()

    let backgroundPhoneImageView = UIImageView(image: Image.prepane_phone_background.makeImage())
    backgroundPhoneImageView.contentMode = .scaleToFill
    backgroundPhoneImageView.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(backgroundPhoneImageView)
    NSLayoutConstraint.activate([
        backgroundPhoneImageView.topAnchor.constraint(equalTo: containerView.topAnchor),
        backgroundPhoneImageView.widthAnchor.constraint(equalToConstant: 480),
        backgroundPhoneImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        backgroundPhoneImageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    containerView.addAndPinSubview(imageView)
    return containerView
}

private func CreateCenteringView(centeredView: UIView) -> UIView {
    let leftSpacerView = UIView()
    leftSpacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)

    let rightSpacerView = UIView()
    rightSpacerView.setContentHuggingPriority(.defaultLow, for: .horizontal)

    let horizontalStackView = UIStackView(
        arrangedSubviews: [leftSpacerView, centeredView, rightSpacerView]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.distribution = .equalCentering
    horizontalStackView.alignment = .center
    return horizontalStackView
}

private final class GIFImageView: UIView, WKNavigationDelegate {

    private let webView = WKWebView()

    override var intrinsicContentSize: CGSize {
        return CGSize(width: 256, height: 264)
    }

    init(gifUrlString: String) {
        super.init(frame: .zero)
        let htmlString =
            """
            <!DOCTYPE html>
            <html>
            <head>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
            * { margin: 0; padding: 0 }
            </style>
            </head>
            <body style="background-color: transparent;">
            <img src="\(gifUrlString)" align="middle" style="width:100%;height:100%;">
            </body>
            </html>
            """

        webView.scrollView.isScrollEnabled = false
        webView.isUserInteractionEnabled = false
        webView.loadHTMLString(htmlString, baseURL: nil)
        addAndPinSubview(webView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
