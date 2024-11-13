//
//  IncentiveTagView.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 10/9/24.
//

import UIKit

class IncentiveTagView: UIView {

    private let containerView = UIView()
    private let labelBackground = UIView()
    private let label = UILabel()

    init(
        font: UIFont,
        tinyMode: Bool = false,
        text: String? = nil
    ) {
        super.init(frame: .zero)
        setupView(font: font, tinyMode: tinyMode)
        
        if let text {
            setText(text)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setText(_ text: String) {
        label.text = text
        self.invalidateIntrinsicContentSize()
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }

    private func setupView(font: UIFont, tinyMode: Bool) {
        // Set the background color and rounded corners
        containerView.translatesAutoresizingMaskIntoConstraints = false
        labelBackground.translatesAutoresizingMaskIntoConstraints = false
        addSubview(containerView)
        
        labelBackground.backgroundColor = UIColor(red: 48/255, green: 177/255, blue: 48/255, alpha: 1)
        labelBackground.layer.cornerRadius = tinyMode ? 4 : 8
        labelBackground.layoutMargins = UIEdgeInsets(
            top: tinyMode ? 0 : 2,
            left: tinyMode ? 4 : 8,
            bottom: tinyMode ? 0 : 2,
            right: tinyMode ? 4 : 8
        )

        // Set up label styles
        label.textColor = .white
        label.numberOfLines = 0
        // TODO: Consider tinyMode
        label.font = font
        label.adjustsFontSizeToFitWidth = true
        label.adjustsFontForContentSizeCategory = true
        label.text = ""
        label.translatesAutoresizingMaskIntoConstraints = false
        labelBackground.addSubview(label)
        
        containerView.addSubview(labelBackground)
        
        // Set containerView constraints to control sizing based on content
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
//            labelBackground.topAnchor.constraint(equalTo: containerView.layoutMarginsGuide.topAnchor),
            labelBackground.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            labelBackground.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
//            labelBackground.bottomAnchor.constraint(equalTo: containerView.layoutMarginsGuide.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: labelBackground.layoutMarginsGuide.leadingAnchor),
            label.topAnchor.constraint(equalTo: labelBackground.layoutMarginsGuide.topAnchor),
            label.trailingAnchor.constraint(equalTo: labelBackground.layoutMarginsGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: labelBackground.layoutMarginsGuide.bottomAnchor),
        ])
    }
}
