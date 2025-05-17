//
//  LinkPaymentTypePicker-Cell.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 5/15/25.
//

import UIKit

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore

extension LinkPaymentTypePicker {

    final class Cell: UIControl {
        enum Constants {
            static let height: CGFloat = 72
            static let contentSpacing: CGFloat = 16
            static let contentInset: CGFloat = 20
            static let chevronSize: CGSize = .init(width: 24, height: 24)
            static let iconBackgroundSize = CGSize(width: 40, height: 40)
        }

        private let paymentType: PaymentType

        private lazy var icon: UIImageView = {
            let iconView = UIImageView()
            iconView.image = paymentType.icon
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false
            return iconView
        }()

        private lazy var label: UILabel = {
            let label = UILabel()
            label.text = paymentType.label
            label.font = LinkUI.font(forTextStyle: .body)
            label.textColor = .linkPrimaryText
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        private lazy var chevron: UIImageView = {
            let chevron = UIImageView()
            chevron.image = Image.icon_chevron_right.makeImage(template: true)
            chevron.contentMode = .center
            chevron.tintColor = .linkPrimaryText
            chevron.translatesAutoresizingMaskIntoConstraints = false
            return chevron
        }()

        private lazy var containerView: UIView = {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            return view
        }()

        override var isHighlighted: Bool {
            didSet {
                if isHighlighted {
                    backgroundColor = .linkControlHighlight
                } else {
                    backgroundColor = .clear
                }
            }
        }

        init(type: PaymentType) {
            self.paymentType = type
            super.init(frame: .zero)
            setupViews()
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        private func setupViews() {
            addSubview(containerView)
            containerView.addSubview(icon)
            containerView.addSubview(label)
            containerView.addSubview(chevron)

            NSLayoutConstraint.activate([
                containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.contentInset),
                containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.contentInset),
                containerView.topAnchor.constraint(equalTo: topAnchor),
                containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
                containerView.heightAnchor.constraint(equalToConstant: Constants.height),

                icon.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                icon.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                icon.widthAnchor.constraint(equalToConstant: Constants.iconBackgroundSize.width),
                icon.heightAnchor.constraint(equalToConstant: Constants.iconBackgroundSize.height),

                label.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: Constants.contentSpacing),
                label.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                label.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -Constants.contentSpacing),

                chevron.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                chevron.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                chevron.widthAnchor.constraint(equalToConstant: Constants.chevronSize.width),
                chevron.heightAnchor.constraint(equalToConstant: Constants.chevronSize.height),
            ])
        }

        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            if self.point(inside: point, with: event) {
                return self
            }

            return nil
        }
    }
}
