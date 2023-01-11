//
//  AccountPickerSelectionView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/10/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

protocol AccountPickerSelectionViewDelegate: AnyObject {
    func accountPickerSelectionView(
        _ view: AccountPickerSelectionView,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    )
}

final class AccountPickerSelectionView: UIView {

    private weak var delegate: AccountPickerSelectionViewDelegate?
    private let listView: AccountPickerSelectionListView

    init(
        accountPickerType: AccountPickerType,
        enabledAccounts: [FinancialConnectionsPartnerAccount],
        disabledAccounts: [FinancialConnectionsPartnerAccount],
        institution: FinancialConnectionsInstitution,
        delegate: AccountPickerSelectionViewDelegate
    ) {
        self.delegate = delegate
        self.listView = AccountPickerSelectionListView(
            selectionType: accountPickerType == .checkbox ? .checkbox : .radioButton,
            enabledAccounts: enabledAccounts,
            disabledAccounts: disabledAccounts
        )
        super.init(frame: .zero)
        listView.delegate = self
        addAndPinSubviewToSafeArea(listView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func selectAccounts(_ selectedAccounts: [FinancialConnectionsPartnerAccount]) {
        listView.selectAccounts(selectedAccounts)
    }
}

// MARK: - AccountPickerSelectionListViewDelegate

extension AccountPickerSelectionView: AccountPickerSelectionListViewDelegate {

    func accountPickerSelectionListView(
        _ view: AccountPickerSelectionListView,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) {
        delegate?.accountPickerSelectionView(self, didSelectAccounts: selectedAccounts)
    }
}
