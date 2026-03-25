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

    private let centeringView: UIView
    private var imageLayer: CALayer?

    init(imageURLString: String) {
        // first we load an image (or GIF) into a WebView
        let imageView = GIFImageView(gifUrlString: imageURLString)
        // the WebView is surrounded by a background that imitates the GIF presented inside of a phone
        let (phoneBackgroundView, imageLayer) = CreatePhoneBackgroundView(imageView: imageView)
        self.imageLayer = imageLayer
        // we center the phone+gif in the middle
        let centeringView = CreateCenteringView(centeredView: phoneBackgroundView)
        self.centeringView = centeringView
        super.init(frame: .zero)

        // background color of the whole view
        centeringView.backgroundColor = FinancialConnectionsAppearance.Colors.backgroundHighlighted

        addAndPinSubview(
            centeringView,
            // the insets expand the view beyond the bounds
            // to stretch the `PrepaneImageView` for the
            // full width of the pane
            insets: NSDirectionalEdgeInsets(
                top: 0,
                leading: -Constants.Layout.defaultHorizontalMargin,
                bottom: 0,
                trailing: -Constants.Layout.defaultHorizontalMargin
            )
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Clip-to-bounds the top and bottom, but leave
        // left/right unclipped.
        //
        // This code is like setting `clipsToBounds = true`,
        // except for just top/bottom.
        let path = UIBezierPath(
            rect: CGRect(
                x: (bounds.width - centeringView.frame.width) / 2,
                y: 0,
                width: centeringView.frame.width,
                height: bounds.height
            )
        ).cgPath
        let maskLayer = CAShapeLayer()
        maskLayer.path = path
        layer.mask = maskLayer
    }

    // CGColor's need to be manually updated when the system theme changes.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        imageLayer?.borderColor = FinancialConnectionsAppearance.Colors.backgroundSecondary.cgColor
        imageLayer?.shadowColor = FinancialConnectionsAppearance.Colors.borderNeutral.cgColor
    }
}

private func CreatePhoneBackgroundView(imageView: UIView) -> (UIView, CALayer) {
    let containerView = UIView()
    let borderWidth: CGFloat = 8
    imageView.layer.borderWidth = borderWidth
    imageView.layer.borderColor = FinancialConnectionsAppearance.Colors.backgroundSecondary.cgColor
    imageView.layer.shadowRadius = 10
    imageView.layer.shadowColor = FinancialConnectionsAppearance.Colors.borderNeutral.cgColor
    imageView.layer.shadowOpacity = 1.0
    containerView.addAndPinSubview(
        imageView,
        insets: NSDirectionalEdgeInsets(
            top: -borderWidth,
            leading: 0,
            bottom: -borderWidth,
            trailing: 0
        )
    )
    return (containerView, imageView.layer)
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
        webView.backgroundColor = FinancialConnectionsAppearance.Colors.background
        addAndPinSubview(webView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
