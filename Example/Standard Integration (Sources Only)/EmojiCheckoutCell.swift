//
//  EmojiCheckoutCell.swift
//  Standard Integration (Sources Only)
//
//  Created by Yuki Tokuhiro on 5/29/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit

class EmojiCheckoutCell: UITableViewCell {
    let emojiLabel: UILabel
    let priceLabel: UILabel
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        priceLabel = UILabel()
        priceLabel.font = UIFont.systemFont(ofSize: 18, weight: .regular)
        emojiLabel = UILabel()
        emojiLabel.font = UIFont.systemFont(ofSize: 52)

        super.init(style: style, reuseIdentifier: reuseIdentifier)
        installConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func installConstraints() {
        for view in [emojiLabel, priceLabel] {
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }
       
        NSLayoutConstraint.activate([
           emojiLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
           emojiLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
           
           priceLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
           priceLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            ])
    }
    
    public func configure(with product: Product) {
        priceLabel.text = product.priceString
        emojiLabel.text = product.emoji
    }
}
