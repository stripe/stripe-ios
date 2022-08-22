//
//  AccountPickerSelectionView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/10/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

protocol AccountPickerSelectionViewDelegate: AnyObject {
    func accountPickerSelectionView(
        _ view: AccountPickerSelectionView,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    )
}

final class AccountPickerSelectionView: UIView {
    
    private weak var delegate: AccountPickerSelectionViewDelegate?
    
    private var listView: AccountPickerSelectionListView?
    private var dropdownView: AccountPickerSelectionDropdownView?
    
    init(
        accountPickerType: AccountPickerType,
        accounts: [FinancialConnectionsPartnerAccount],
        institution: FinancialConnectionsInstitution,
        delegate: AccountPickerSelectionViewDelegate
    ) {
        self.delegate = delegate
        super.init(frame: .zero)
        
        let contentView: UIView
        switch accountPickerType {
        case .checkbox:
            fallthrough
        case .radioButton:
            let listView = AccountPickerSelectionListView(
                selectionType: accountPickerType == .checkbox ? .checkbox : .radioButton,
                accounts: accounts
            )
            listView.delegate = self
            self.listView = listView
            contentView = listView
        case .dropdown:
            let dropdownView = AccountPickerSelectionDropdownView(allAccounts: accounts, institution: institution)
            dropdownView.delegate = self
            self.dropdownView = dropdownView
            contentView = dropdownView
        }
        addAndPinSubviewToSafeArea(contentView)
        
        assert(listView != nil || dropdownView != nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func selectAccounts(_ selectedAccounts: [FinancialConnectionsPartnerAccount]) {
        if let listView = listView {
            listView.selectAccounts(selectedAccounts)
        } else if let dropdownView = dropdownView {
            dropdownView.selectAccounts(selectedAccounts)
        } else {
            assertionFailure("It should be impossible to have no selection view available.")
        }
    }
}

// MARK: - AccountPickerSelectionDropdownViewDelegate

extension AccountPickerSelectionView: AccountPickerSelectionDropdownViewDelegate {
    
    func accountPickerSelectionDropdownView(
        _ view: AccountPickerSelectionDropdownView,
        didSelectAccount selectedAccount: FinancialConnectionsPartnerAccount
    ) {
        delegate?.accountPickerSelectionView(self, didSelectAccounts: [selectedAccount])
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
