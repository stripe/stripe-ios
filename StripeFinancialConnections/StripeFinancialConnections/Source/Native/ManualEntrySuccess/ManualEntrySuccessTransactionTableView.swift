//
//  ManualEntrySuccessTableView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/29/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

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
        microdepositVerificationMethod: MicrodepositVerificationMethod?,
        accountNumberLast4: String
    ) {
        super.init(frame: .zero)
        let verticalStackView = UIStackView(
            arrangedSubviews: [
                CreateTableTitleView(
                    title: String(
                        format: STPLocalizedString(
                            "••••%@ BANK STATEMENT",
                            "The title of a table. The table shows a list of bank transactions, or, in other words, a list of payments made for purchases. The '%@' is replaced by the last 4 digits of a bank account number. For example, it could form '••••6489 BANK STATEMENT'."
                        ),
                        accountNumberLast4
                    )
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

        verticalStackView.layer.borderWidth = 1.0 / stp_screenNativeScale
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Helpers

private func CreateRows(
    microdepositVerificationMethod: MicrodepositVerificationMethod?
) -> [[Label]] {
    var rows: [[Label]] = []
    if microdepositVerificationMethod == .descriptorCode {
        rows.append([
            Label(title: "SMXXXX", isHighlighted: true),
            Label(title: "$0.01"),
            Label(title: "ACH CREDIT"),
        ])
    } else {
        for _ in 0..<2 {
            rows.append([
                Label(title: "AMTS"),
                Label(title: "$0.XX", isHighlighted: true),
                Label(title: "ACH CREDIT"),
            ])
        }
    }
    rows.append([
        Label(title: "GROCERIES"),
        Label(title: "$56.12"),
        Label(title: "VISA"),
    ])

    return rows
}

private func CreateTableTitleView(title: String) -> UIView {
    let iconImageView = UIImageView()
    iconImageView.image = Image.bank.makeImage()
        .withTintColor(.textSecondary)
    NSLayoutConstraint.activate([
        iconImageView.widthAnchor.constraint(equalToConstant: 16),
        iconImageView.heightAnchor.constraint(equalToConstant: 16),
    ])

    let titleLabel = AttributedLabel(
        font: .code(.largeEmphasized),
        textColor: .textSecondary
    )
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
        title: STPLocalizedString(
            "Transaction",
            "The title of a column of a table. The table shows a list of bank transactions, or, in other words, a list of payments made for purchases. The 'Transaction' column displays the title of the transaction, for example, 'Groceries.'"
        ),
        rowLabels: rows.compactMap { $0[0] }
    )
    let amountColumnTuple = CreateColumnView(
        title: STPLocalizedString(
            "Amount",
            "The title of a column of a table. The table shows a list of bank transactions, or, in other words, a list of payments made for purchases. The 'Amount' column displays the currency value for a transaction, for example, '$56.12.'"
        ),
        alignment: .trailing,
        rowLabels: rows.compactMap { $0[1] }
    )
    let typeColumnTuple = CreateColumnView(
        title: STPLocalizedString(
            "Type",
            "The title of a column of a table. The table shows a list of bank transactions, or, in other words, a list of payments made for purchases. The 'Type' column displays the type of transaction, for example, 'VISA' or 'ACH CREDIT'"
        ),
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
    columnHorizontalStackView.spacing = 1  // otherwise..have "1" spacing

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
            separatorView.heightAnchor.constraint(equalToConstant: 1.0 / stp_screenNativeScale),
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
    verticalStackView.spacing = 4  // spacing for rows
    verticalStackView.alignment = alignment

    // Title
    let titleLabel = AttributedLabel(
        font: .code(.largeEmphasized),
        textColor: .textSecondary
    )
    titleLabel.text = title
    titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
    verticalStackView.addArrangedSubview(titleLabel)
    verticalStackView.setCustomSpacing(5, after: titleLabel)

    // Rows
    var rowViews: [UIView] = []
    for label in rowLabels {
        let rowLabel = AttributedLabel(
            font: .code(.largeEmphasized),
            textColor: label.isHighlighted ? .textBrand : .textPrimary
        )
        rowLabel.numberOfLines = 0
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

private struct ManualEntrySuccessTransactionTableViewUIViewRepresentable: UIViewRepresentable {

    let microdepositVerificationMethod: MicrodepositVerificationMethod
    let accountNumberLast4: String

    func makeUIView(context: Context) -> ManualEntrySuccessTransactionTableView {
        ManualEntrySuccessTransactionTableView(
            microdepositVerificationMethod: microdepositVerificationMethod,
            accountNumberLast4: accountNumberLast4
        )
    }

    func updateUIView(_ uiView: ManualEntrySuccessTransactionTableView, context: Context) {}
}

struct ManualEntrySuccessTransactionTableView_Previews: PreviewProvider {
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
