//
//  CheckoutRowView.swift
//  Basic Integration
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Stripe
import UIKit

class CheckoutRowView: UIView {

    var loading = false {
        didSet {
            UIView.animate(
                withDuration: 0.3, delay: 0, options: .curveEaseIn,
                animations: {
                    if self.loading {
                        self.activityIndicator.startAnimating()
                        self.activityIndicator.alpha = 1
                        self.detailLabel.alpha = 0
                    } else {
                        self.activityIndicator.stopAnimating()
                        self.activityIndicator.alpha = 0
                        self.detailLabel.alpha = 1
                    }
                }, completion: nil)
        }
    }

    var title: String = "" {
        didSet {
            self.titleLabel.text = title
            updateAccessibilityElements()
        }
    }

    var detail: String = "" {
        didSet {
            self.detailLabel.text = detail
            updateAccessibilityElements()
        }
    }

    var onTap: () -> Void = {}

    fileprivate let titleLabel = UILabel()
    fileprivate let detailLabel = UILabel()
    fileprivate let activityIndicator = UIActivityIndicatorView(style: .gray)
    fileprivate let backgroundView = HighlightingButton()

    convenience init(title: String, detail: String, tappable: Bool = true) {
        self.init()
        self.title = title
        self.detail = detail

        self.backgroundView.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        self.backgroundView.isAccessibilityElement = false
        self.addSubview(self.backgroundView)
        self.titleLabel.text = title
        self.titleLabel.backgroundColor = UIColor.clear
        self.titleLabel.textAlignment = .left
        self.titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        self.titleLabel.isAccessibilityElement = false
        self.addSubview(self.titleLabel)
        self.detailLabel.text = detail
        self.detailLabel.backgroundColor = UIColor.clear
        self.detailLabel.textAlignment = .right
        self.detailLabel.font = .systemFont(ofSize: 16, weight: .regular)
        self.detailLabel.isAccessibilityElement = false
        self.backgroundColor = .white

        self.detailLabel.textColor = .gray
        self.activityIndicator.style = .gray
        #if canImport(CryptoKit)
            if #available(iOS 13.0, *) {
                self.backgroundColor = .systemBackground
                self.detailLabel.textColor = .secondaryLabel
                self.activityIndicator.style = .medium
            }
        #endif

        self.addSubview(self.detailLabel)
        self.addSubview(self.activityIndicator)

        installConstraints()
        if !tappable {
            self.backgroundView.isUserInteractionEnabled = false
            self.titleLabel.font = .systemFont(ofSize: 22, weight: .medium)
            self.detailLabel.font = .systemFont(ofSize: 22, weight: .bold)
            self.detailLabel.textColor = .black
            #if canImport(CryptoKit)
                if #available(iOS 13.0, *) {
                    self.detailLabel.textColor = .label
                }
            #endif
        }

        isAccessibilityElement = true
        accessibilityTraits = tappable ? [.button] : [.staticText]
        updateAccessibilityElements()
    }

    func installConstraints() {
        for view in [backgroundView, titleLabel, detailLabel, activityIndicator] {
            view.translatesAutoresizingMaskIntoConstraints = false
        }

        let insetPadding = CGFloat(16)
        NSLayoutConstraint.activate([
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insetPadding),
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: insetPadding),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insetPadding),

            detailLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insetPadding),
            detailLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: detailLabel.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: detailLabel.centerYAnchor),
        ])
    }

    @objc func didTap() {
        self.onTap()
    }

    // MARK: Private

    private func updateAccessibilityElements() {
        accessibilityIdentifier = title
        accessibilityLabel = title
        accessibilityValue = detail
    }

}
