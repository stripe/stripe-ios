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

    private let didSelect: () -> Void
    private var isSelected: Bool = false {
        didSet {
            layer.cornerRadius = 12
            if isSelected {
                layer.borderColor = UIColor.textActionPrimaryFocused.cgColor
                layer.borderWidth = 2
                let shadowWidthOffset: CGFloat = 0
                layer.shadowPath = CGPath(
                    roundedRect: CGRect(x: shadowWidthOffset / 2, y: 0, width: bounds.width - shadowWidthOffset, height: bounds.height),
                    cornerWidth: layer.cornerRadius,
                    cornerHeight: layer.cornerRadius,
                    transform: nil
                )
                layer.shadowColor = UIColor.black.cgColor
                layer.shadowRadius = 1.5 / UIScreen.main.nativeScale
                layer.shadowOpacity = 0.23
                layer.shadowOffset = CGSize(
                    width: 0,
                    height: 1 / UIScreen.main.nativeScale
                )
            } else {
                layer.borderColor = UIColor.borderDefault.cgColor
                layer.borderWidth = 1
                layer.shadowOpacity = 0
            }
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
        let selectionView = CheckboxView()
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
        didSelect: @escaping () -> Void
    ) {
        self.didSelect = didSelect
        super.init(frame: .zero)

        // necessary so the shadow does not appear under text
        backgroundColor = .customBackgroundColor

        if isDisabled {
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

#if DEBUG

import SwiftUI

private struct AccountPickerRowViewUIViewRepresentable: UIViewRepresentable {

    let institutionIconUrl: String?
    let title: String
    let subtitle: String?
    let balanceString: String?
    let isSelected: Bool
    let isDisabled: Bool

    init(
        institutionIconUrl: String? = nil,
        title: String,
        subtitle: String?,
        balanceString: String?,
        isSelected: Bool,
        isDisabled: Bool
    ) {
        self.institutionIconUrl = institutionIconUrl
        self.title = title
        self.subtitle = subtitle
        self.balanceString = balanceString
        self.isSelected = isSelected
        self.isDisabled = isDisabled
    }

    func makeUIView(context: Context) -> AccountPickerRowView {
        let view = AccountPickerRowView(
            isDisabled: isDisabled,
            didSelect: {}
        )
        view.set(
            institutionIconUrl: institutionIconUrl,
            title: title,
            subtitle: subtitle,
            balanceString: balanceString,
            isSelected: isSelected
        )
        return view
    }

    func updateUIView(
        _ uiView: AccountPickerRowView,
        context: Context
    ) {
        uiView.set(
            institutionIconUrl: institutionIconUrl,
            title: title,
            subtitle: subtitle,
            balanceString: balanceString,
            isSelected: isSelected
        )
    }
}

struct AccountPickerRowView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            ScrollView {
                VStack(spacing: 16) {
                    AccountPickerRowViewUIViewRepresentable(
                        institutionIconUrl: "https://b.stripecdn.com/connections-statics-srv/assets/BrandIcon--stripe-4x.png",
                        title: "Joint Checking Very Long Name To Truncate",
                        subtitle: "••••6789",
                        balanceString: nil,
                        isSelected: true,
                        isDisabled: false
                    ).frame(height: 88)
                    AccountPickerRowViewUIViewRepresentable(
                        title: "Joint Checking Very Long Name To Truncate",
                        subtitle: "••••6789",
                        balanceString: nil,
                        isSelected: true,
                        isDisabled: false
                    ).frame(height: 76)
                    AccountPickerRowViewUIViewRepresentable(
                        title: "Joint Checking Very Long Name To Truncate",
                        subtitle: "••••6789",
                        balanceString: "$3285.53",
                        isSelected: false,
                        isDisabled: false
                    ).frame(height: 76)
                    AccountPickerRowViewUIViewRepresentable(
                        title: "Joint Checking",
                        subtitle: nil,
                        balanceString: "$3285.53",
                        isSelected: false,
                        isDisabled: false
                    ).frame(height: 76)
                    AccountPickerRowViewUIViewRepresentable(
                        title: "Joint Checking",
                        subtitle: "Not available",
                        balanceString: nil,
                        isSelected: false,
                        isDisabled: true
                    ).frame(height: 76)
                }.padding()
            }
        }
    }
}

#endif
