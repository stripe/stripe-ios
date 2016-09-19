//
//  CheckoutRowView.swift
//  Stripe iOS Example (Simple)
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
    fileprivate let topSeparator = UIView()
    fileprivate let bottomSeparator = UIView()

    convenience init(title: String, detail: String, tappable: Bool = true, theme: STPTheme) {
        self.init()
        self.title = title
        self.detail = detail

        self.backgroundColor = theme.secondaryBackgroundColor
        self.backgroundView.addTarget(self, action: #selector(didTap), for: .touchUpInside)
        if !tappable {
            self.backgroundView.isUserInteractionEnabled = false
            self.backgroundColor = theme.primaryBackgroundColor
        }
        self.addSubview(self.backgroundView)
        self.bottomSeparator.backgroundColor = theme.secondaryForegroundColor
        self.addSubview(self.bottomSeparator)
        self.topSeparator.backgroundColor = theme.secondaryForegroundColor
        self.addSubview(self.topSeparator)
        self.titleLabel.text = title
        self.titleLabel.backgroundColor = UIColor.clear
        self.titleLabel.textAlignment = .left;
        self.titleLabel.font = theme.font
        self.titleLabel.textColor = theme.primaryForegroundColor
        self.addSubview(self.titleLabel)
        self.detailLabel.text = detail
        self.detailLabel.backgroundColor = UIColor.clear
        self.detailLabel.textColor = UIColor.lightGray
        self.detailLabel.textAlignment = .right;
        self.detailLabel.font = theme.font
        self.detailLabel.textColor = theme.secondaryForegroundColor
        self.addSubview(self.detailLabel)
        var red: CGFloat = 0
        theme.primaryBackgroundColor.getRed(&red, green: nil, blue: nil, alpha: nil)
        self.activityIndicator.activityIndicatorViewStyle = red < 0.5 ? .white : .gray
        self.addSubview(self.activityIndicator)
    }

    override func layoutSubviews() {
        self.topSeparator.frame = CGRect(x: 0, y: -1, width: self.bounds.width, height: 1)
        self.backgroundView.frame = self.bounds
        self.titleLabel.frame = self.bounds.offsetBy(dx: 10, dy: 0)
        self.detailLabel.frame = self.bounds.offsetBy(dx: -10, dy: 0)
        self.bottomSeparator.frame = CGRect(x: 0, y: self.bounds.maxY - 1,
                                                width: self.bounds.width, height: 1)
        let height = self.bounds.height
        self.activityIndicator.frame = CGRect(x: self.bounds.maxX - height, y: 0,
                                                  width: height, height: height)
    }

    func didTap() {
        self.onTap()
    }

}
