//
//  InstitutionTableViewCell.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 11/28/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class InstitutionTableViewCell: UITableViewCell {

    private lazy var institutionIconView: InstitutionIconView = {
        return InstitutionIconView(size: .main)
    }()
    private lazy var institutionCellView: InstitutionCellView = {
        return InstitutionCellView()
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        adjustBackgroundColor(isHighlighted: false)
        contentView.addAndPinSubview(institutionCellView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        adjustBackgroundColor(isHighlighted: highlighted)
    }

    private func adjustBackgroundColor(isHighlighted: Bool) {
        contentView.backgroundColor = isHighlighted ? .backgroundContainer : .customBackgroundColor
    }
}

// MARK: - Customize

extension InstitutionTableViewCell {

    func customize(with institution: FinancialConnectionsInstitution) {
        institutionIconView.setImageUrl(institution.icon?.default)

        institutionCellView.customize(
            iconView: institutionIconView,
            title: institution.name,
            subtitle: AuthFlowHelpers.formatUrlString(institution.url)
        )
    }
}

#if DEBUG

import SwiftUI

@available(iOS 14.0, *)
private struct InstitutionTableViewCellUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> InstitutionTableViewCell {
        InstitutionTableViewCell(style: .default, reuseIdentifier: "test")
    }

    func updateUIView(_ uiView: InstitutionTableViewCell, context: Context) {
        uiView.sizeToFit()
        uiView.customize(
            with: FinancialConnectionsInstitution(
                id: "abc",
                name: "Bank of America",
                url: "https://www.bankofamerica.com/",
                icon: nil,
                logo: nil
            )
        )
    }
}

@available(iOS 14.0, *)
struct InstitutionTableViewCell_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            InstitutionTableViewCellUIViewRepresentable()
                .frame(width: 343, height: 72)
            Spacer()
        }
        .background(Color.gray.opacity(0.5).ignoresSafeArea())
    }
}

#endif
