//
//  EmojiCell.swift
//  Standard Integration (Sources Only)
//
//  Created by Yuki Tokuhiro on 5/29/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

import UIKit

struct EmojiCellViewModel {
    let price: String
    let emoji: String
}

class EmojiCell: UICollectionViewCell {
    var viewModel: EmojiCellViewModel?
    let priceLabel: UILabel
    let emojiLabel: UILabel
    let addButton: UIControl
    
    override init(frame: CGRect) {
        priceLabel = UILabel()
        emojiLabel = UILabel()
        addButton = UIControl() // TODO
        super.init(frame: frame)
        layer.cornerRadius = 4
        backgroundColor = .lightGray
        installConstraints()
    }
    
    required init(coder: NSCoder) {
        fatalError()
    }
    
    public func configure(with viewModel: EmojiCellViewModel) {
        self.viewModel = viewModel
        priceLabel.text = viewModel.price
        priceLabel.font = UIFont.boldSystemFont(ofSize: 14)
        emojiLabel.text = viewModel.emoji
        emojiLabel.font = UIFont.systemFont(ofSize: 55)
    }
    
    //MARK: - Layout

    let emojiContentBackgroundBottomPadding = CGFloat(44)
    let emojiContentInset = CGFloat(2)
    
    private func installConstraints() {
        let emojiContentBackground = UIView()
        emojiContentBackground.backgroundColor = .white
        emojiContentBackground.layer.cornerRadius = 4
        
        for view in [emojiContentBackground, priceLabel, emojiLabel, addButton] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }

        NSLayoutConstraint.activate([
            emojiContentBackground.leadingAnchor.constraint(equalTo: leadingAnchor, constant: emojiContentInset),
            emojiContentBackground.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -emojiContentInset),
            emojiContentBackground.topAnchor.constraint(equalTo: topAnchor, constant: emojiContentInset),
            emojiContentBackground.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -emojiContentBackgroundBottomPadding),
            
            emojiLabel.centerXAnchor.constraint(equalTo: emojiContentBackground.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiContentBackground.centerYAnchor),
            
            priceLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            priceLabel.centerYAnchor.constraint(equalTo: bottomAnchor, constant: -emojiContentBackgroundBottomPadding/2),
            
            addButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            addButton.topAnchor.constraint(equalTo: emojiContentBackground.bottomAnchor, constant: 8),
            addButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            addButton.widthAnchor.constraint(equalTo: addButton.heightAnchor),
            ])
    }
}
