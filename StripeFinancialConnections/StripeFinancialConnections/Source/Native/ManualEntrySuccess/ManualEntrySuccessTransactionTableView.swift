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
    
    private let rows: [[Label]] = [
        [Label(title: "AMTS"), Label(title: "$0.XX", isHighlighted: true), Label(title: "ACH CREDIT")],
        [Label(title: "AMTS"), Label(title: "$0.XX", isHighlighted: true), Label(title: "ACH CREDIT")],
        [Label(title: "GROCERIES"), Label(title: "$56.12"), Label(title: "VISA")],
    ]
    
    init() {
        super.init(frame: .zero)
        
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 0
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
        
        let transactionColumnPair = CreateColumnView(
            title: "Transaction",
            rowLabels: rows.compactMap { $0[0] }
        )
        let amountColumnPair = CreateColumnView(
            title: "Amount",
            alignment: .trailing,
            rowLabels: rows.compactMap { $0[1] }
        )
        let typeColumnPair = CreateColumnView(
            title: "Type",
            rowLabels: rows.compactMap { $0[2] }
        )
        
        let horizontalStackView = UIStackView(
            arrangedSubviews: [
                transactionColumnPair.columnView,
                amountColumnPair.columnView,
                typeColumnPair.columnView,
            ]
        )
        horizontalStackView.axis = .horizontal
        horizontalStackView.spacing = 10
        horizontalStackView.distribution = .fillEqually
        
        verticalStackView.addArrangedSubview(horizontalStackView)
        
        for i in 0..<transactionColumnPair.rowViews.count {
            let transactionRowView = transactionColumnPair.rowViews[i]
            let amountRowView = amountColumnPair.rowViews[i]
            let typeRowView = typeColumnPair.rowViews[i]

            NSLayoutConstraint.activate([
                transactionRowView.heightAnchor.constraint(equalTo: amountRowView.heightAnchor),
                amountRowView.heightAnchor.constraint(equalTo: typeRowView.heightAnchor),
            ])
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Helpers

private func CreateColumnView(
    title: String,
    alignment: UIStackView.Alignment = .leading,
    rowLabels: [Label]
) -> (columnView: UIView, rowViews: [UIView]) {
    
    let columnTitleLabel = UILabel()
    columnTitleLabel.font = .stripeFont(forTextStyle: .body)
    columnTitleLabel.textColor = .textSecondary
    columnTitleLabel.text = title
    columnTitleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
    
    let separatorView = UIView()
    separatorView.backgroundColor = .red
    separatorView.setContentHuggingPriority(.defaultHigh, for: .vertical)
//    separatorView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    separatorView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    separatorView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        separatorView.heightAnchor.constraint(equalToConstant: 1.0 / UIScreen.main.nativeScale),
//        separatorView.widthAnchor.constraint(lessThanOrEqualToConstant: 100),
        
//        separatorView.widthAnchor.constraint(equalTo: )
        //separatorView.widthAnchor.constraint(equalToConstant: 40),
        //separatorView.widthAnchor.constraint(lessThanOrEqualToConstant: UIScreen.main.bounds.width),
//        separatorView.widthAnchor.constraint(equalToConstant: 30),
    ])
    
    
    let verticalStackView = UIStackView()
//    verticalStackView.backgroundColor = .yellow
    verticalStackView.axis = .vertical
    verticalStackView.spacing = 4 // spacing for rows
    verticalStackView.alignment = alignment
    verticalStackView.distribution = .equalSpacing
//    verticalStackView.distribution = .equalCentering
//    verticalStackView.distribution = .fill

    // Title
    verticalStackView.addArrangedSubview(columnTitleLabel)
    verticalStackView.setCustomSpacing(5, after: columnTitleLabel)
    
    // Separator
    verticalStackView.addArrangedSubview(separatorView)
    verticalStackView.setCustomSpacing(10, after: separatorView)
    
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
        //.stripeFont(forTextStyle: .caption)
        rowLabel.text = label.title
        rowLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        rowLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        verticalStackView.addArrangedSubview(rowLabel)
        
        rowViews.append(rowLabel)
    }
    
//    let spacerView =
//    spacerView.backgroundColor = .red
//    spacerView.setContentHuggingPriority(.defaultLow, for: .vertical)
//    spacerView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    verticalStackView.addArrangedSubview(UIView()) // add spacer
    
    return (verticalStackView, rowViews)
}


#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
private struct ManualEntrySuccessTransactionTableViewUIViewRepresentable: UIViewRepresentable {
    
    func makeUIView(context: Context) -> ManualEntrySuccessTransactionTableView {
        ManualEntrySuccessTransactionTableView()
    }
    
    func updateUIView(_ uiView: ManualEntrySuccessTransactionTableView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct ManualEntrySuccessTransactionTableView_Previews: PreviewProvider {
    @available(iOS 13.0.0, *)
    static var previews: some View {
        if #available(iOS 14.0, *) {
            VStack(spacing: 16) {
                ManualEntrySuccessTransactionTableViewUIViewRepresentable()
            }
            .frame(maxHeight: 200)
            .frame(maxWidth: 256)
            .padding()
            .background(Color(UIColor.customBackgroundColor))
        }
    }
}

#endif
