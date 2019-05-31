//
//  CheckoutRowView.swift
//  Standard Integration (Sources Only)
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit
import Stripe

class CheckoutRowView: UIView {

    var loading = false {
        didSet {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn, animations: {
                if self.loading {
                    self.activityIndicator.startAnimating()
                    self.activityIndicator.alpha = 1
                    self.detailLabel.alpha = 0
                }
                else {
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
        }
    }

    var detail: String = "" {
        didSet {
            self.detailLabel.text = detail
        }
    }

    var onTap: () -> () = {}

    fileprivate let titleLabel = UILabel()
    fileprivate let detailLabel = UILabel()
    fileprivate let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    fileprivate let backgroundView = HighlightingButton()

    convenience init(title: String, detail: String, tappable: Bool = true, theme: STPTheme) {
        self.init()
        self.title = title
        self.detail = detail

        self.backgroundColor = theme.secondaryBackgroundColor
        self.backgroundView.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        self.addSubview(self.backgroundView)
        self.titleLabel.text = title
        self.titleLabel.backgroundColor = UIColor.clear
        self.titleLabel.textAlignment = .left;
        self.titleLabel.font = .systemFont(ofSize: 16, weight: .medium)
        self.titleLabel.textColor = theme.primaryForegroundColor
        self.addSubview(self.titleLabel)
        self.detailLabel.text = detail
        self.detailLabel.backgroundColor = UIColor.clear
        self.detailLabel.textAlignment = .right;
        self.detailLabel.font = .systemFont(ofSize: 16, weight: .regular)
        self.detailLabel.textColor = theme.secondaryForegroundColor
        self.addSubview(self.detailLabel)
        var red: CGFloat = 0
        theme.primaryBackgroundColor.getRed(&red, green: nil, blue: nil, alpha: nil)
        self.activityIndicator.activityIndicatorViewStyle = red < 0.5 ? .white : .gray
        self.addSubview(self.activityIndicator)
        installConstraints()
        if !tappable {
            self.backgroundView.isUserInteractionEnabled = false
            self.titleLabel.font = .systemFont(ofSize: 22, weight: .medium)
            self.detailLabel.font = .systemFont(ofSize: 22, weight: .bold)
            self.detailLabel.textColor = theme.primaryForegroundColor
        }
    }

    func installConstraints() {
        for view in [backgroundView, titleLabel, detailLabel, activityIndicator] {
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        
        backgroundView.anchorToSuperviewAnchors()
        let insetPadding = CGFloat(16)
        NSLayoutConstraint.activate([
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

}
