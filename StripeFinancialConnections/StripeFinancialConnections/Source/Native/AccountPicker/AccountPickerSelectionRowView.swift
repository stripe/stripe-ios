//
//  AccountPickerSelectionRowView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/10/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class AccountPickerSelectionRowView: UIView {

    enum SelectionType {
        case checkbox
        case radioButton
    }

    private let selectionType: SelectionType
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
            selectionView.isSelected = isSelected
        }
    }

    private lazy var selectionView: SelectionView = {
        let selectionView: SelectionView
        switch selectionType {
        case .checkbox:
            selectionView = CheckboxView()
        case .radioButton:
            selectionView = RadioButtonView()
        }
        selectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            selectionView.widthAnchor.constraint(equalToConstant: 20),
            selectionView.heightAnchor.constraint(equalToConstant: 20),
        ])
        return selectionView
    }()

    private lazy var labelRowView: AccountPickerLabelRowView = {
        return AccountPickerLabelRowView()
    }()

    init(
        selectionType: SelectionType,
        isDisabled: Bool,
        didSelect: @escaping () -> Void
    ) {
        self.selectionType = selectionType
        self.didSelect = didSelect
        super.init(frame: .zero)

        let horizontalStackView = CreateHorizontalStackView(
            arrangedSubviews: [
                selectionView,
                labelRowView,
            ]
        )
        if isDisabled {
            horizontalStackView.alpha = 0.25
        }
        addAndPinSubviewToSafeArea(horizontalStackView)

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapView))
        addGestureRecognizer(tapGestureRecognizer)

        isSelected = false  // activate the setter to draw border
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLeadingTitle(
        _ leadingTitle: String,
        trailingTitle: String?,
        subtitle: String?,
        isSelected: Bool
    ) {
        labelRowView.setLeadingTitle(
            leadingTitle,
            trailingTitle: trailingTitle,
            subtitle: subtitle
        )
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
        top: 12,
        leading: 12,
        bottom: 12,
        trailing: 12
    )
    return horizontalStackView
}

// MARK: - Helpers

private protocol SelectionView: UIView {
    var isSelected: Bool { get set }
}
extension CheckboxView: SelectionView {}
extension RadioButtonView: SelectionView {}

#if DEBUG

import SwiftUI

private struct AccountPickerSelectionRowViewUIViewRepresentable: UIViewRepresentable {

    let type: AccountPickerSelectionRowView.SelectionType
    let leadingTitle: String
    let trailingTitle: String?
    let subtitle: String?
    let isSelected: Bool
    let isDisabled: Bool
    let isLinked: Bool

    func makeUIView(context: Context) -> AccountPickerSelectionRowView {
        let view = AccountPickerSelectionRowView(
            selectionType: type,
            isDisabled: isDisabled,
            didSelect: {}
        )
        view.setLeadingTitle(
            leadingTitle,
            trailingTitle: trailingTitle,
            subtitle: subtitle,
            isSelected: isSelected
        )
        return view
    }

    func updateUIView(_ uiView: AccountPickerSelectionRowView, context: Context) {
        uiView.setLeadingTitle(
            leadingTitle,
            trailingTitle: trailingTitle,
            subtitle: subtitle,
            isSelected: isSelected
        )
    }
}

struct AccountPickerSelectionRowView_Previews: PreviewProvider {
    static var previews: some View {
        if #available(iOS 14.0, *) {
            ScrollView {
                VStack(spacing: 10) {
                    VStack(spacing: 2) {
                        Text("Checkmark")
                        AccountPickerSelectionRowViewUIViewRepresentable(
                            type: .checkbox,
                            leadingTitle: "Joint Checking Very Long Name To Truncate",
                            trailingTitle: "••••6789",
                            subtitle: "$2,000",
                            isSelected: true,
                            isDisabled: false,
                            isLinked: true
                        ).frame(height: 60)
                        AccountPickerSelectionRowViewUIViewRepresentable(
                            type: .checkbox,
                            leadingTitle: "Joint Checking",
                            trailingTitle: nil,
                            subtitle: nil,
                            isSelected: false,
                            isDisabled: false,
                            isLinked: false
                        ).frame(height: 60)
                        AccountPickerSelectionRowViewUIViewRepresentable(
                            type: .checkbox,
                            leadingTitle: "Joint Checking",
                            trailingTitle: nil,
                            subtitle: "Must be US checking account",
                            isSelected: false,
                            isDisabled: true,
                            isLinked: false
                        ).frame(height: 60)
                    }
                    VStack(spacing: 2) {
                        Text("Radiobutton")
                        AccountPickerSelectionRowViewUIViewRepresentable(
                            type: .radioButton,
                            leadingTitle: "Student Savings",
                            trailingTitle: "••••6789",
                            subtitle: "$2,000.32",
                            isSelected: true,
                            isDisabled: false,
                            isLinked: false
                        ).frame(height: 60)
                        AccountPickerSelectionRowViewUIViewRepresentable(
                            type: .radioButton,
                            leadingTitle: "Student Savings",
                            trailingTitle: nil,
                            subtitle: "••••••••4321",
                            isSelected: false,
                            isDisabled: false,
                            isLinked: true
                        ).frame(height: 60)
                        AccountPickerSelectionRowViewUIViewRepresentable(
                            type: .radioButton,
                            leadingTitle: "Student Savings",
                            trailingTitle: nil,
                            subtitle: "Must be checking or savings account",
                            isSelected: false,
                            isDisabled: true,
                            isLinked: true
                        ).frame(height: 60)
                    }
                }.padding()
            }
        }
    }
}

#endif
