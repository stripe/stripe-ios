//
//  LinkSeparatorView.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 4/23/25.
//

import UIKit

class LinkSeparatorView: UIView {
    private let separatorHeight: CGFloat = 1

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .linkControlBorder
        translatesAutoresizingMaskIntoConstraints = false
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: separatorHeight)
    }
}
