//
//  CheckoutView.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 4/25/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import UIKit


class CheckoutView: UIView {

    var product: String = "" {
        didSet {
            self.productImage.text = product
            self.setNeedsLayout()
        }
    }
    var paymentInProgress: Bool = false {
        didSet {
            UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseIn, animations: {
                if self.paymentInProgress {
                    self.activityIndicator.startAnimating()
                    self.activityIndicator.alpha = 1
                    self.buyButton.alpha = 0
                }
                else {
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator.alpha = 0
                    self.buyButton.alpha = 1
                }
                }, completion: nil)
        }
    }
    let paymentRow = CheckoutRowView(title: "Payment", detail: "Add card")
    let totalRow = CheckoutRowView(title: "Total", detail: "", tappable: false)
    let buyButton = BuyButton(enabled: false)

    private let rowHeight: CGFloat = 44
    private let productImage = UILabel()
    private let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.whiteColor()
        self.addSubview(self.totalRow)
        self.addSubview(self.paymentRow)

        self.productImage.font = UIFont.systemFontOfSize(70)
        self.addSubview(self.productImage)
        self.addSubview(self.buyButton)
        self.activityIndicator.alpha = 0
        self.addSubview(self.activityIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = CGRectGetWidth(self.bounds)
        self.productImage.sizeToFit()
        self.productImage.center = CGPointMake(width/2.0,
                                               CGRectGetHeight(self.productImage.bounds)/2.0 + rowHeight)
        self.paymentRow.frame = CGRectMake(0, CGRectGetMaxY(self.productImage.frame) + rowHeight,
                                           width, rowHeight)
        self.totalRow.frame = CGRectMake(0, CGRectGetMaxY(self.paymentRow.frame),
                                         width, rowHeight)
        self.buyButton.frame = CGRectMake(0, 0, 88, 44)
        self.buyButton.center = CGPointMake(width/2.0, CGRectGetMaxY(self.totalRow.frame) + rowHeight*1.5)
        self.activityIndicator.center = self.buyButton.center
    }

}
