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

let emojiBackgroundBottomPadding = CGFloat(50)
let emojiContentInset = CGFloat(2)
let defaultPadding = CGFloat(8)

class EmojiCell: UICollectionViewCell {
    struct Colors {
        let background: UIColor
        let price: UIColor
    }
    let priceLabel: UILabel
    let emojiLabel: UILabel
    let addButton: AddButton
    
    override var isSelected: Bool {
        didSet {
            if isSelected {
                contentView.backgroundColor = UIColor(red: 86/255, green: 177/255, blue: 130/255, alpha: 1)
                emojiLabel.textColor = .white
            } else {
                contentView.backgroundColor = UIColor(red: 231/255, green: 235/255, blue: 239/255, alpha: 1)
                emojiLabel.textColor = .black
            }
        }
    }
    
    override init(frame: CGRect) {
        priceLabel = UILabel()
        priceLabel.font = UIFont.boldSystemFont(ofSize: 16)
        emojiLabel = UILabel()
        emojiLabel.font = UIFont.systemFont(ofSize: 75)
        addButton = AddButton()
        addButton.backgroundColor = .clear
        super.init(frame: frame)
        contentView.layer.cornerRadius = 4
        installConstraints()
        isSelected = false
    }
    
    required init(coder: NSCoder) {
        fatalError()
    }
    
    public func configure(with viewModel: EmojiCellViewModel) {
        priceLabel.text = viewModel.price
        emojiLabel.text = viewModel.emoji
    }
    
    //MARK: - Layout
    
    private func installConstraints() {
        let emojiContentBackground = UIView()
        emojiContentBackground.backgroundColor = .white
        emojiContentBackground.layer.cornerRadius = 4
        
        for view in [emojiContentBackground, priceLabel, emojiLabel, addButton] {
            view.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(view)
        }

        NSLayoutConstraint.activate([
            // TODO: emojiContentBackground.anchorToSuperView()
            emojiContentBackground.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: emojiContentInset),
            emojiContentBackground.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -emojiContentInset),
            emojiContentBackground.topAnchor.constraint(equalTo: contentView.topAnchor, constant: emojiContentInset),
            emojiContentBackground.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -emojiBackgroundBottomPadding),
            
            emojiLabel.centerXAnchor.constraint(equalTo: emojiContentBackground.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiContentBackground.centerYAnchor),
            
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: defaultPadding),
            priceLabel.centerYAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -emojiBackgroundBottomPadding/2),
            
            addButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            addButton.topAnchor.constraint(equalTo: emojiContentBackground.bottomAnchor, constant: 10),
            addButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            addButton.widthAnchor.constraint(equalTo: addButton.heightAnchor),
            ])
    }
}

class AddButton: UIControl {
    override func draw(_ rect: CGRect) {
        let circle = UIBezierPath(ovalIn: rect)
        UIColor(red: 84/255, green: 95/255, blue: 124/255, alpha: 1).setFill()
        circle.fill()

        let width = rect.size.width / 2
        let thickness = CGFloat(2)
        let horizontalLine = UIBezierPath(rect: CGRect(
            x: width / 2,
            y: rect.size.height / 2 - thickness / 2,
            width: width,
            height: thickness))
        let verticalLine = UIBezierPath(rect: CGRect(
            x: rect.size.width / 2 - thickness / 2,
            y: rect.size.height / 4,
            width: thickness,
            height: rect.size.height / 2))
        UIColor.white.setFill()
        horizontalLine.fill()
        verticalLine.fill()
    }
}
