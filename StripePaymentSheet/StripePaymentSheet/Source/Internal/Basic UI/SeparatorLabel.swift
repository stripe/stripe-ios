//
//  SeparatorLabel.swift
//  StripePaymentSheet
//
//  Created by Ramon Torres on 11/7/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

import UIKit

/// A separator with label.
/// For internal SDK use only
@objc(STP_Internal_SeparatorLabel)
final class SeparatorLabel: UIView {

    struct Constants {
        static let spacing: CGFloat = 10
    }

    var text: String? {
        get {
            return label.text
        }
        set {
            label.text = newValue
        }
    }

    var font: UIFont {
        get {
            return label.font
        }
        set {
            label.font = newValue
        }
    }

    var textColor: UIColor {
        get {
            return label.textColor
        }
        set {
            label.textColor = newValue
        }
    }

    var adjustsFontForContentSizeCategory: Bool {
        get {
            return label.adjustsFontForContentSizeCategory
        }
        set {
            label.adjustsFontForContentSizeCategory = newValue
        }
    }

    var separatorColor: UIColor? {
        get {
            return leftLineView.backgroundColor
        }
        set {
            leftLineView.backgroundColor = newValue
            rightLineView.backgroundColor = newValue
        }
    }

    private let label: UILabel = {
        let label = UILabel()
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private let leftLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .opaqueSeparator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let rightLineView: UIView = {
        let view = UIView()
        view.backgroundColor = .opaqueSeparator
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    convenience init(text: String) {
        self.init(frame: .zero)
        self.text = text
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(leftLineView)
        addSubview(label)
        addSubview(rightLineView)

        NSLayoutConstraint.activate([
            // Left line
            leftLineView.heightAnchor.constraint(equalToConstant: 1),
            leftLineView.leadingAnchor.constraint(equalTo: leadingAnchor),
            leftLineView.topAnchor.constraint(equalTo: centerYAnchor),

            // Label
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.leadingAnchor.constraint(
                equalTo: leftLineView.trailingAnchor, constant: Constants.spacing),
            label.trailingAnchor.constraint(
                equalTo: rightLineView.leadingAnchor, constant: -Constants.spacing),

            // Right line
            rightLineView.heightAnchor.constraint(equalToConstant: 1),
            rightLineView.trailingAnchor.constraint(equalTo: trailingAnchor),
            rightLineView.topAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

}
