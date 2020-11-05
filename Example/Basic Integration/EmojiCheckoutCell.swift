//
//  EmojiCheckoutCell.swift
//  Basic Integration
//
//  Created by Yuki Tokuhiro on 5/29/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit

class EmojiCheckoutCell: UITableViewCell {
    let emojiLabel: UILabel
    let detailLabel: UILabel
    let priceLabel: UILabel

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        priceLabel = UILabel()
        priceLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        detailLabel = UILabel()
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.textColor = .stripeDarkBlue
        emojiLabel = UILabel()
        emojiLabel.font = UIFont.systemFont(ofSize: 52)

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        installConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func installConstraints() {
        for view in [emojiLabel, priceLabel, detailLabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }

        NSLayoutConstraint.activate([
           emojiLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
           emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

           detailLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 12),
           detailLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

           priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
           priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            ])
    }

    public func configure(with product: Product, numberFormatter: NumberFormatter) {
        priceLabel.text = numberFormatter.string(from: NSNumber(value: Float(product.price)/100))!
        emojiLabel.text = product.emoji
        detailLabel.text = product.emoji.unicodeScalars.first?.properties.name?.localizedCapitalized
    }
}
