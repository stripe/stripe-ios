//
//  AccountPickerSelectionListView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/22/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol AccountPickerSelectionListViewDelegate: AnyObject {
    func accountPickerSelectionListView(
        _ view: AccountPickerSelectionListView,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    )
}

final class AccountPickerSelectionListView: UIView {

    private let selectionType: AccountPickerSelectionType
    private let enabledAccounts: [FinancialConnectionsPartnerAccount]
    private let disabledAccounts: [FinancialConnectionsPartnerAccount]
    private let appearance: FinancialConnectionsAppearance
    weak var delegate: AccountPickerSelectionListViewDelegate?

    private lazy var verticalStackView: UIStackView = {
        let verticalStackView = UIStackView()
        verticalStackView.spacing = 12
        verticalStackView.axis = .vertical
        return verticalStackView
    }()

    init(
        selectionType: AccountPickerSelectionType,
        enabledAccounts: [FinancialConnectionsPartnerAccount],
        disabledAccounts: [FinancialConnectionsPartnerAccount],
        appearance: FinancialConnectionsAppearance
    ) {
        self.selectionType = selectionType
        self.enabledAccounts = enabledAccounts
        self.disabledAccounts = disabledAccounts
        self.appearance = appearance
        super.init(frame: .zero)
        addAndPinSubviewToSafeArea(verticalStackView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func selectAccounts(_ selectedAccounts: [FinancialConnectionsPartnerAccount]) {
        // clear all previous state
        verticalStackView.arrangedSubviews.forEach { arrangedSubview in
            arrangedSubview.removeFromSuperview()
        }

        // list enabled accounts
        enabledAccounts.forEach { account in
            let accountRowView = AccountPickerRowView(
                isDisabled: false,
                isFaded: false,
                appearance: appearance,
                didSelect: { [weak self] in
                    guard let self = self else { return }
                    var selectedAccounts = selectedAccounts
                    if let index = selectedAccounts.firstIndex(where: { $0.id == account.id }) {
                        selectedAccounts.remove(at: index)
                    } else {
                        if self.selectionType == .multiple {
                            selectedAccounts.append(account)
                        } else {  // single select
                            selectedAccounts = [account]  // select only one account
                        }
                    }
                    self.delegate?.accountPickerSelectionListView(self, didSelectAccounts: selectedAccounts)
                }
            )
            let rowInfo = AccountPickerHelpers.rowInfo(forAccount: account)
            accountRowView.set(
                title: rowInfo.accountName,
                subtitle: rowInfo.accountNumbers,
                balanceString: rowInfo.balanceString,
                isSelected: selectedAccounts.contains(where: { $0.id == account.id })
            )
            verticalStackView.addArrangedSubview(accountRowView)
        }

        // list disabled accounts
        disabledAccounts.forEach { disabledAccount in
            let accountRowView = AccountPickerRowView(
                isDisabled: true,
                isFaded: true,
                appearance: appearance,
                didSelect: {
                    // can't select disabled accounts
                }
            )
            let rowInfo = AccountPickerHelpers.rowInfo(forAccount: disabledAccount)
            accountRowView.set(
                title: rowInfo.accountName,
                subtitle: disabledAccount.allowSelectionMessage,
                balanceString: nil,
                isSelected: false
            )
            verticalStackView.addArrangedSubview(accountRowView)
        }
    }
}
