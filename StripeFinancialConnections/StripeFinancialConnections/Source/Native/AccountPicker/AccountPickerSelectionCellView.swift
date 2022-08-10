//
//  AccountPickerSelectionCellView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/10/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class AccountPickerSelectionCellView: UIView {
    
    private let didSelect: () -> Void
    
    private var isSelected: Bool = false {
        didSet {
            layer.cornerRadius = 8
            if isSelected {
                layer.borderColor = UIColor.textBrand.cgColor
                layer.borderWidth = 2
            } else {
                layer.borderColor = UIColor.borderNeutral.cgColor
                layer.borderWidth = 1
            }
            checkboxView.isSelected = isSelected
        }
    }
    
    private lazy var checkboxView: CheckboxView = {
        return CheckboxView()
    }()
    
    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = .stripeFont(forTextStyle: .bodyEmphasized)
        titleLabel.textColor = .textSecondary
        return titleLabel
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        subtitleLabel.font = .stripeFont(forTextStyle: .captionTightEmphasized)
        subtitleLabel.textColor = .textSecondary
        return subtitleLabel
    }()
    
    private lazy var labelStackView: UIStackView = {
        let labelStackView = UIStackView()
        labelStackView.axis = .vertical
        labelStackView.spacing = 0
        return labelStackView
    }()
    
    init(didSelect: @escaping () -> Void) {
        self.didSelect = didSelect
        super.init(frame: .zero)
        
        
        checkboxView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            checkboxView.widthAnchor.constraint(equalToConstant: 20),
            checkboxView.heightAnchor.constraint(equalToConstant: 20),
        ])
        
        labelStackView.addArrangedSubview(titleLabel)
        
        let horizontalStackView = UIStackView(
            arrangedSubviews: [
                checkboxView,
                labelStackView,
            ]
        )
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 12
        horizontalStackView.isLayoutMarginsRelativeArrangement = true
        horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 12,
            leading: 12,
            bottom: 12,
            trailing: 12
        )
        
        addAndPinSubviewToSafeArea(horizontalStackView)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        addGestureRecognizer(tapGestureRecognizer)
        
        isSelected = false // activate the setter to draw border
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTitle(_ title: String, subtitle: String?, isSelected: Bool) {
        titleLabel.text = title
        
        labelStackView.removeArrangedSubview(subtitleLabel)
        if let subtitle = subtitle {
            subtitleLabel.text = subtitle
            labelStackView.addArrangedSubview(subtitleLabel)
        }
        titleLabel.text = title
        
        self.isSelected = isSelected
    }
    
    @objc private func didTapView() {
        self.isSelected.toggle()
        self.didSelect()
    }
}
