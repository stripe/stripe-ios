//
//  IncentiveTagView.swift
//  StripePaymentSheet
//
//  Created by Till Hellmund on 10/9/24.
//

import UIKit

class IncentiveTagView: UIView {

    private let label = UILabel()

    init(
        tinyMode: Bool = false,
        text: String? = nil
    ) {
        super.init(frame: .zero)
        setupView(tinyMode: tinyMode)
        
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

    private func setupView(tinyMode: Bool) {
        // Set the background color and rounded corners
        self.backgroundColor = UIColor(red: 48/255, green: 177/255, blue: 48/255, alpha: 1)
        self.layer.cornerRadius = 4

        // Set up label styles
        label.textColor = .white
        label.numberOfLines = 0
        label.font = tinyMode ? UIFont.preferredFont(forTextStyle: .caption1) : UIFont.preferredFont(forTextStyle: .body)
        label.text = ""

        // Add padding using layout margins
        self.layoutMargins = UIEdgeInsets(
            top: tinyMode ? 0 : 4,
            left: tinyMode ? 4 : 8,
            bottom: tinyMode ? 0 : 4,
            right: tinyMode ? 4 : 8
        )

        // Add label to the view
        addSubview(label)

        // Set label constraints
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: self.layoutMarginsGuide.topAnchor),
            label.leadingAnchor.constraint(equalTo: self.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: self.layoutMarginsGuide.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: self.layoutMarginsGuide.bottomAnchor)
        ])
    }
}
