//
//  CheckoutRowView.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 4/22/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit

class CheckoutRowView: UIView {

    var loading = false {
        didSet {
            UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseIn, animations: {
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

    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
    private let backgroundView = HighlightingButton()
    private let topSeparator = UIView()
    private let bottomSeparator = UIView()

    convenience init(title: String, detail: String, tappable: Bool = true) {
        self.init()
        self.title = title
        self.detail = detail

        self.backgroundColor = UIColor.whiteColor()
        self.backgroundView.addTarget(self, action: #selector(didTap), forControlEvents: .TouchUpInside)
        if !tappable {
            self.backgroundView.userInteractionEnabled = false
            self.backgroundColor = UIColor(white: 0, alpha: 0.02)
        }
        self.addSubview(self.backgroundView)
        self.bottomSeparator.backgroundColor = UIColor(white: 0, alpha: 0.1)
        self.addSubview(self.bottomSeparator)
        self.topSeparator.backgroundColor = UIColor(white: 0, alpha: 0.1)
        self.addSubview(self.topSeparator)
        self.titleLabel.text = title
        self.titleLabel.backgroundColor = UIColor.clearColor()
        self.titleLabel.textAlignment = .Left;
        self.addSubview(self.titleLabel)
        self.detailLabel.text = detail
        self.detailLabel.backgroundColor = UIColor.clearColor()
        self.detailLabel.textAlignment = .Right;
        self.addSubview(self.detailLabel)
        self.addSubview(self.activityIndicator)
    }

    override func layoutSubviews() {
        self.topSeparator.frame = CGRectMake(0, -1, CGRectGetWidth(self.bounds), 1)
        self.backgroundView.frame = self.bounds
        self.titleLabel.frame = CGRectOffset(self.bounds, 10, 0)
        self.detailLabel.frame = CGRectOffset(self.bounds, -10, 0)
        self.bottomSeparator.frame = CGRectMake(0, CGRectGetMaxY(self.bounds) - 1,
                                                CGRectGetWidth(self.bounds), 1)
        let height = CGRectGetHeight(self.bounds)
        self.activityIndicator.frame = CGRectMake(CGRectGetMaxX(self.bounds) - height, 0,
                                                  height, height)
    }

    func didTap() {
        self.onTap()
    }

}
