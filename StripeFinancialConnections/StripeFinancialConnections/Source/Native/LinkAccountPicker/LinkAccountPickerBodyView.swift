//
//  LinkAccountPickerBodyView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/13/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
protocol LinkAccountPickerBodyViewDelegate: AnyObject {
    func linkAccountPickerBodyView(
        _ view: LinkAccountPickerBodyView,
        didSelectAccount selectedAccount: FinancialConnectionsPartnerAccount
    )
    func linkAccountPickerBodyViewSelectedNewBankAccount(
        _ view: LinkAccountPickerBodyView
    )
}

@available(iOSApplicationExtension, unavailable)
final class LinkAccountPickerBodyView: UIView {

    private let accounts: [FinancialConnectionsPartnerAccount]
    weak var delegate: LinkAccountPickerBodyViewDelegate?
    
    private lazy var verticalStackView: UIStackView = {
        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 12
        return verticalStackView
    }()

    init(accounts: [FinancialConnectionsPartnerAccount]) {
        self.accounts = accounts
        super.init(frame: .zero)
        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func selectAccount(_ selectedAccount: FinancialConnectionsPartnerAccount?) {
        // clear all previous state
        verticalStackView.arrangedSubviews.forEach { arrangedSubview in
            arrangedSubview.removeFromSuperview()
        }

        // list all accounts
        accounts.forEach { account in
            let accountRowView = LinkAccountPickerRowView(
                isDisabled: false,
                didSelect: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.linkAccountPickerBodyView(
                        self,
                        didSelectAccount: account
                    )
                }
            )
            let rowTitles = AccountPickerHelpers.rowTitles(forAccount: account)
            accountRowView.configure(
                institutionImageUrl: nil, // TODO(kgaidis): get image url from backend
                leadingTitle: rowTitles.leadingTitle,
                trailingTitle: rowTitles.trailingTitle,
                subtitle: AccountPickerHelpers.rowSubtitle(forAccount: account),
                isSelected: selectedAccount?.id == account.id
            )
            verticalStackView.addArrangedSubview(accountRowView)
        }
        
        let newAccountRowView = LinkAccountPickerNewAccountRowView(
            didSelect: { [weak self] in
                guard let self = self else { return }
                self.delegate?.linkAccountPickerBodyViewSelectedNewBankAccount(self)
            }
        )
        verticalStackView.addArrangedSubview(newAccountRowView)
    }
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct LinkAccountPickerBodyViewUIViewRepresentable: UIViewRepresentable {

    func makeUIView(context: Context) -> LinkAccountPickerBodyView {
        LinkAccountPickerBodyView(
            accounts: [
                FinancialConnectionsPartnerAccount(
                    id: "abc",
                    name: "Advantage Plus Checking",
                    displayableAccountNumbers: "1324",
                    linkedAccountId: nil,
                    balanceAmount: 100000,
                    currency: "USD",
                    supportedPaymentMethodTypes: [.usBankAccount],
                    allowSelection: true,
                    allowSelectionMessage: nil
                )
            ]
        )
    }

    func updateUIView(_ uiView: LinkAccountPickerBodyView, context: Context) {
        uiView.selectAccount(nil)
    }
}

@available(iOSApplicationExtension, unavailable)
struct LinkAccountPickerBodyView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading) {
            Spacer()
            LinkAccountPickerBodyViewUIViewRepresentable()
                .frame(maxHeight:120)
                .padding()
            Spacer()
        }
    }
}

#endif
