//
//  AccountPickerRowView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 1/5/24.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class AccountPickerRowView: UIView {

    private let appearance: FinancialConnectionsAppearance
    private let didSelect: () -> Void
    private var isSelected: Bool = false {
        didSet {
            updateLayer()
            checkboxView.isSelected = isSelected
        }
    }
    private lazy var horizontalStackView: UIStackView = {
        return CreateHorizontalStackView(
            arrangedSubviews: [
                labelView,
                checkboxView,
            ]
        )
    }()
    private lazy var institutionIconView: InstitutionIconView = {
        return InstitutionIconView()
    }()
    private lazy var checkboxView: CheckboxView = {
        let selectionView = CheckboxView(appearance: appearance)
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            selectionView.widthAnchor.constraint(equalToConstant: 16),
            selectionView.heightAnchor.constraint(equalToConstant: 16),
        ])
        return selectionView
    }()
    private lazy var labelView: AccountPickerRowLabelView = {
        return AccountPickerRowLabelView()
    }()

    init(
        isDisabled: Bool,
        isFaded: Bool,
        appearance: FinancialConnectionsAppearance,
        didSelect: @escaping () -> Void
    ) {
        self.appearance = appearance
        self.didSelect = didSelect
        super.init(frame: .zero)

        // necessary so the shadow does not appear under text
        backgroundColor = FinancialConnectionsAppearance.Colors.background

        if isFaded {
            horizontalStackView.alpha = 0.25
        }
        addAndPinSubviewToSafeArea(horizontalStackView)

        if !isDisabled {
            let tapGestureRecognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(didTapView)
            )
            addGestureRecognizer(tapGestureRecognizer)
        }

        isSelected = false  // activate the setter to draw border
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // `isSelected` controls the shadow, which is driven
        // by the layout, so this refreshes
        // shadow layout
        let isSelected = self.isSelected
        self.isSelected = isSelected
    }

    func set(
        institutionIconUrl: String? = nil,
        title: String,
        subtitle: String?,
        underlineSubtitle: Bool = false,
        balanceString: String? = nil,
        isSelected: Bool
    ) {
        if let institutionIconUrl = institutionIconUrl {
            let needToInsertInstitutionIconView = (institutionIconView.superview == nil)
            if needToInsertInstitutionIconView {
                horizontalStackView.insertArrangedSubview(institutionIconView, at: 0)
            }
            institutionIconView.setImageUrl(institutionIconUrl)
        } else {
            institutionIconView.removeFromSuperview()
        }

        labelView.set(
            title: title,
            subtitle: subtitle,
            underlineSubtitle: underlineSubtitle,
            balanceString: balanceString
        )
        set(isSelected: isSelected)
    }

    func set(isSelected: Bool) {
        self.isSelected = isSelected
    }

    @objc private func didTapView() {
        self.didSelect()
    }

    private func updateLayer() {
        layer.cornerRadius = 12
        if isSelected {
            layer.borderColor = appearance.colors.border.cgColor
            layer.borderWidth = 2
            let shadowWidthOffset: CGFloat = 0
            layer.shadowPath = CGPath(
                roundedRect: CGRect(x: shadowWidthOffset / 2, y: 0, width: bounds.width - shadowWidthOffset, height: bounds.height),
                cornerWidth: layer.cornerRadius,
                cornerHeight: layer.cornerRadius,
                transform: nil
            )
            layer.shadowColor = FinancialConnectionsAppearance.Colors.shadow.cgColor
            layer.shadowRadius = 1.5 / UIScreen.main.nativeScale
            layer.shadowOpacity = 0.23
            layer.shadowOffset = CGSize(
                width: 0,
                height: 1 / UIScreen.main.nativeScale
            )
        } else {
            layer.borderColor = FinancialConnectionsAppearance.Colors.borderNeutral.cgColor
            layer.borderWidth = 1
            layer.shadowOpacity = 0
        }
    }

    // CGColor's need to be manually updated when the system theme changes.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        updateLayer()
    }
}

private func CreateHorizontalStackView(arrangedSubviews: [UIView]) -> UIStackView {
    let horizontalStackView = UIStackView(arrangedSubviews: arrangedSubviews)
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 12
    horizontalStackView.alignment = .center
    horizontalStackView.isLayoutMarginsRelativeArrangement = true
    horizontalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
        top: 16,
        leading: 16,
        bottom: 16,
        trailing: 16
    )
    return horizontalStackView
}
