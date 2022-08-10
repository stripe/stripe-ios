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
    
    private let type: AccountPickerType
    private let accounts: [FinancialConnectionsPartnerAccount]
    private weak var delegate: AccountPickerSelectionViewDelegate?
    
    private lazy var verticalStackView: UIStackView = {
        let verticalStackView = UIStackView()
        verticalStackView.spacing = 12
        verticalStackView.axis = .vertical
        return verticalStackView
    }()
    
    init(
        type: AccountPickerType,
        accounts: [FinancialConnectionsPartnerAccount],
        delegate: AccountPickerSelectionViewDelegate
    ) {
        self.type = type
        self.accounts = accounts
        self.delegate = delegate
        super.init(frame: .zero)
        
        addAndPinSubviewToSafeArea(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func selectAccounts(_ selectedAccounts: [FinancialConnectionsPartnerAccount]) {
        
        verticalStackView.arrangedSubviews.forEach { arrangedSubview in
            arrangedSubview.removeFromSuperview()
        }
        
        switch type {
        case .single:
            fatalError("not implemented")
        case .multi:
            let allAccountsCellView = AccountPickerSelectionCellView(
                didSelect: { [weak self] in
                    guard let self = self else { return }
                    let isAllAccountsSelected = (self.accounts.count == selectedAccounts.count)
                    var selectedAccounts = selectedAccounts
                    if isAllAccountsSelected {
                        selectedAccounts.removeAll()
                    } else {
                        selectedAccounts = self.accounts
                    }
                    self.delegate?.accountPickerSelectionView(self, didSelectAccounts: selectedAccounts)
                }
            )
            allAccountsCellView.setTitle(
                "All accounts",
                subtitle: nil,
                isSelected: (self.accounts.count == selectedAccounts.count)
            )
            verticalStackView.addArrangedSubview(allAccountsCellView)
            
            accounts.forEach { account in
                let accountCellView = AccountPickerSelectionCellView(
                    didSelect: { [weak self] in
                        guard let self = self else { return }
                        var selectedAccounts = selectedAccounts
                        if let index = selectedAccounts.firstIndex(where: { $0.id == account.id }) {
                            selectedAccounts.remove(at: index)
                        } else {
                            selectedAccounts.append(account)
                        }
                        self.delegate?.accountPickerSelectionView(self, didSelectAccounts: selectedAccounts)
                    }
                )
                accountCellView.setTitle(
                    account.name,
                    subtitle: account.balanceAmount.map({"\($0)"}),
                    isSelected: selectedAccounts.contains(where: { $0.id == account.id })
                )
                
                verticalStackView.addArrangedSubview(accountCellView)
            }
        }
    }
}
