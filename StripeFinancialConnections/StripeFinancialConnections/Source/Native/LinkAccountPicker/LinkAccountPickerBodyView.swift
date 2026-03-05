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

protocol LinkAccountPickerBodyViewDelegate: AnyObject {
    func linkAccountPickerBodyView(
        _ view: LinkAccountPickerBodyView,
        didSelectAccount selectedAccountTuple: FinancialConnectionsAccountTuple
    )
    func linkAccountPickerBodyViewSelectedNewBankAccount(_ view: LinkAccountPickerBodyView)
}

final class LinkAccountPickerBodyView: UIView {

    weak var delegate: LinkAccountPickerBodyViewDelegate?
    private var partnerAccountIdToRowView: [String: AccountPickerRowView] = [:]

    init(
        accountTuples: [FinancialConnectionsAccountTuple],
        addNewAccount: FinancialConnectionsNetworkingAccountPicker.AddNewAccount,
        appearance: FinancialConnectionsAppearance
    ) {
        super.init(frame: .zero)

        let verticalStackView = UIStackView()
        verticalStackView.axis = .vertical
        verticalStackView.spacing = 16

        // add account rows
        accountTuples.forEach { accountTuple in
            let accountRowView = AccountPickerRowView(
                isDisabled: !accountTuple.accountPickerAccount.allowSelection && accountTuple.accountPickerAccount.drawerOnSelection == nil,
                isFaded: !accountTuple.accountPickerAccount.allowSelection,
                appearance: appearance,
                didSelect: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.linkAccountPickerBodyView(
                        self,
                        didSelectAccount: accountTuple
                    )
                }
            )
            let rowTitles = AccountPickerHelpers.rowInfo(
                forAccount: accountTuple.partnerAccount
            )
            accountRowView.set(
                institutionIconUrl: (accountTuple.accountPickerAccount.accountIcon?.default ?? accountTuple.partnerAccount.institution?.icon?.default ?? accountTuple.accountPickerAccount.icon?.default),
                title: rowTitles.accountName,
                subtitle: {
                    if let caption = accountTuple.accountPickerAccount.caption {
                        return caption
                    } else {
                        return rowTitles.accountNumbers
                    }
                }(),
                underlineSubtitle: accountTuple.accountPickerAccount.drawerOnSelection != nil,
                balanceString:
                    (accountTuple.accountPickerAccount.caption == nil) ? rowTitles.balanceString : nil,
                isSelected: false // initially nothing is selected
            )
            partnerAccountIdToRowView[accountTuple.partnerAccount.id] = accountRowView
            verticalStackView.addArrangedSubview(accountRowView)
        }

        // add a 'new bank account' button row
        let newAccountRowView = LinkAccountPickerNewAccountRowView(
            title: addNewAccount.body,
            imageUrl: addNewAccount.icon?.default,
            appearance: appearance,
            didSelect: { [weak self] in
                guard let self = self else { return }
                self.delegate?.linkAccountPickerBodyViewSelectedNewBankAccount(self)
            }
        )
        newAccountRowView.accessibilityIdentifier = "add_bank_account"
        verticalStackView.addArrangedSubview(newAccountRowView)

        addAndPinSubview(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func selectAccounts(_ selectedAccounts: [FinancialConnectionsAccountTuple]) {
        let selectedAccountIds = Set(selectedAccounts.map({ $0.partnerAccount.id }))
        partnerAccountIdToRowView
            .forEach { (partnerAccountId: String, rowView: AccountPickerRowView) in
                rowView.set(
                    isSelected: selectedAccountIds.contains(partnerAccountId)
                )
            }
    }
}
