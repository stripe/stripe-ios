//
//  ManualEntrySuccessTableView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/29/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

private struct Label {
    let title: String
    let isHighlighted: Bool
    
    init(title: String, isHighlighted: Bool = false) {
        self.title = title
        self.isHighlighted = isHighlighted
    }
}

final class ManualEntrySuccessTransactionTableView: UIView {
    
    init(
        microdepositVerificationMethod: MicrodepositVerificationMethod,
        accountNumberLast4: String
    ) {
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateTableTitleView(
                    title: "••••\(accountNumberLast4) BANK STATEMENT"
                ),
                CreateTableView(
                    rows: CreateRows(
                        microdepositVerificationMethod: microdepositVerificationMethod
                    )
                ),
            ]
        )
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 7
        verticalStackView.isLayoutMarginsRelativeArrangement = true
        verticalStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: 14,
            leading: 20,
            bottom: 14,
            trailing: 20
        )
        verticalStackView.backgroundColor = .backgroundContainer
        verticalStackView.layer.cornerRadius = 5
        verticalStackView.layer.borderColor = UIColor.borderNeutral.cgColor
        verticalStackView.layer.borderWidth = 1.0 / UIScreen.main.nativeScale
        addAndPinSubview(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Helpers

private func CreateRows(
    microdepositVerificationMethod: MicrodepositVerificationMethod
) -> [[Label]] {
    var rows: [[Label]] = []
    if microdepositVerificationMethod == .descriptorCode {
        rows.append([
            Label(title: "SMXXXX", isHighlighted: true),
            Label(title: "$0.01"),
            Label(title: "ACH CREDIT")
        ])
    } else {
        for _ in 0..<2 {
            rows.append([
                Label(title: "AMTS"),
                Label(title: "$0.XX", isHighlighted: true),
                Label(title: "ACH CREDIT")
            ])
        }
    }
    rows.append([
        Label(title: "GROCERIES"),
        Label(title: "$56.12"),
        Label(title: "VISA")
    ])
    
    return rows
}

private func CreateTableTitleView(title: String) -> UIView {
    let iconImageView = UIImageView()
    if #available(iOSApplicationExtension 13.0, *) {
        iconImageView.image = UIImage(systemName: "building.columns.fill")?
            .withTintColor(.secondaryLabel, renderingMode: .alwaysOriginal)
    } else {
        // Fallback on earlier versions
    }
    NSLayoutConstraint.activate([
        iconImageView.widthAnchor.constraint(equalToConstant: 16),
        iconImageView.heightAnchor.constraint(equalToConstant: 16),
    ])
    
    let titleLabel = UILabel()
    if #available(iOSApplicationExtension 13.0, *) {
        titleLabel.font = .monospacedSystemFont(ofSize: 16, weight: .bold)
    } else {
        // Fallback on earlier versions
        assertionFailure()
    }
    titleLabel.textColor = .textSecondary
    titleLabel.numberOfLines = 0
    titleLabel.text = title
    
    let horizontalStackView = UIStackView(
        arrangedSubviews: [
            iconImageView,
            titleLabel,
        ]
    )
    horizontalStackView.axis = .horizontal
    horizontalStackView.spacing = 5
    return horizontalStackView
}

private func CreateTableView(rows: [[Label]]) -> UIView {
    let transactionColumnTuple = CreateColumnView(
        title: "Transaction",
        rowLabels: rows.compactMap { $0[0] }
    )
    let amountColumnTuple = CreateColumnView(
        title: "Amount",
        alignment: .trailing,
        rowLabels: rows.compactMap { $0[1] }
    )
    let typeColumnTuple = CreateColumnView(
        title: "Type",
        rowLabels: rows.compactMap { $0[2] }
    )
    
    let columnHorizontalStackView = UIStackView(
        arrangedSubviews: [
            transactionColumnTuple.stackView,
            amountColumnTuple.stackView,
            typeColumnTuple.stackView,
        ]
    )
    columnHorizontalStackView.axis = .horizontal
    columnHorizontalStackView.distribution = .fillProportionally
    
    // Add spacing between columns.
    //
    // "Amount" column is `.trailing` aligned, so
    // it needs extra spacing to avoid interferring
    // with "Type" column.
    columnHorizontalStackView.setCustomSpacing(10, after: amountColumnTuple.stackView)
    columnHorizontalStackView.spacing = 1 // otherwise..have "1" spacing
    
    // Add separator to each column.
    //
    // The sparator needs to be the width of `UIStackView`,
    // so we first need to create the `UIStackView`,
    // and then we use its `widthAnchor` to set the separator
    // width.
    for columnTuple in [transactionColumnTuple, amountColumnTuple, typeColumnTuple] {
        let separatorView = UIView()
        separatorView.backgroundColor = .borderNeutral
        
        separatorView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        columnTuple.stackView.insertArrangedSubview(separatorView, at: 1)
        columnTuple.stackView.setCustomSpacing(10, after: separatorView)
        NSLayoutConstraint.activate([
            separatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.nativeScale),
            separatorView.widthAnchor.constraint(equalTo: columnTuple.stackView.widthAnchor),
        ])
    }
    
    // Make all rows equal height.
    //
    // UIStackView can't align content across multiple
    // independent UIStackView's. As a result, here we
    // align the row height across all the UIStackView's.
    let numberOfRows = min(
        transactionColumnTuple.rowViews.count,
        amountColumnTuple.rowViews.count,
        typeColumnTuple.rowViews.count
    )
    for i in 0..<numberOfRows {
        let transactionRowView = transactionColumnTuple.rowViews[i]
        let amountRowView = amountColumnTuple.rowViews[i]
        let typeRowView = typeColumnTuple.rowViews[i]

        NSLayoutConstraint.activate([
            transactionRowView.heightAnchor.constraint(equalTo: amountRowView.heightAnchor),
            amountRowView.heightAnchor.constraint(equalTo: typeRowView.heightAnchor),
        ])
    }
    return columnHorizontalStackView
}

private func CreateColumnView(
    title: String,
    prioritize: Bool = false,
    alignment: UIStackView.Alignment = .leading,
    rowLabels: [Label]
) -> (stackView: UIStackView, rowViews: [UIView]) {
    let verticalStackView = UIStackView()
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 4 // spacing for rows
    verticalStackView.alignment = alignment

    // Title
    let titleLabel = UILabel()
    if #available(iOSApplicationExtension 13.0, *) {
        titleLabel.font = .monospacedSystemFont(ofSize: 16, weight: .bold)
    } else {
        assertionFailure()
    }
    titleLabel.textColor = .textSecondary
    titleLabel.text = title
    titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
    verticalStackView.addArrangedSubview(titleLabel)
    verticalStackView.setCustomSpacing(5, after: titleLabel)

    // Rows
    var rowViews: [UIView] = []
    for label in rowLabels {
        let rowLabel = UILabel()
        if #available(iOSApplicationExtension 13.0, *) {
            rowLabel.font = .monospacedSystemFont(ofSize: 16, weight: .bold)
        } else {
            assertionFailure()
        }
        rowLabel.numberOfLines = 0
        rowLabel.textColor = label.isHighlighted ? .textBrand : .textPrimary
        rowLabel.text = label.title
        rowLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        rowLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        verticalStackView.addArrangedSubview(rowLabel)
        rowViews.append(rowLabel)
    }
    
    // Spacer
    verticalStackView.addArrangedSubview(UIView())
    
    return (verticalStackView, rowViews)
}


#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
private struct ManualEntrySuccessTransactionTableViewUIViewRepresentable: UIViewRepresentable {
    
    let microdepositVerificationMethod:  MicrodepositVerificationMethod
    let accountNumberLast4: String
    
    func makeUIView(context: Context) -> ManualEntrySuccessTransactionTableView {
        ManualEntrySuccessTransactionTableView(
            microdepositVerificationMethod: microdepositVerificationMethod,
            accountNumberLast4: accountNumberLast4
        )
    }
    
    func updateUIView(_ uiView: ManualEntrySuccessTransactionTableView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct ManualEntrySuccessTransactionTableView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack(spacing: 16) {
                ManualEntrySuccessTransactionTableViewUIViewRepresentable(
                    microdepositVerificationMethod: .amounts,
                    accountNumberLast4: "6789"
                )
                .frame(maxHeight: 200)
                .frame(maxWidth: 320)
                ManualEntrySuccessTransactionTableViewUIViewRepresentable(
                    microdepositVerificationMethod: .descriptorCode,
                    accountNumberLast4: "6789"
                )
                .frame(maxHeight: 200)
                .frame(maxWidth: 320)
            }
            .padding()
            .background(Color(UIColor.customBackgroundColor))
        }
    }
}

#endif
