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
    func accountPickerSelectionViewDidSelectAccounts(_ accounts: [FinancialConnectionsPartnerAccount])
}

enum AccountPickerSelectionType {
    case single
    // TODO(kgaidis): there's  two types of single select (radio button + dropdown)
    case multi
}

final class AccountPickerSelectionView: UIView {
    
    private let type: AccountPickerSelectionType
    private let accounts: [FinancialConnectionsPartnerAccount]
    private weak var delegate: AccountPickerSelectionViewDelegate?
    
    init(
        type: AccountPickerSelectionType,
        accounts: [FinancialConnectionsPartnerAccount],
        delegate: AccountPickerSelectionViewDelegate
    ) {
        self.type = type
        self.accounts = accounts
        self.delegate = delegate
        super.init(frame: .zero)
        
        let verticalStackView = UIStackView()
        verticalStackView.spacing = 12
        verticalStackView.axis = .vertical
        
        switch type {
        case .single:
            fatalError("not implemented")
        case .multi:
            accounts.forEach { account in
                
                let accountCellView = AccountPickerSelectionCellView(didSelect: {})
                accountCellView.setTitle(
                    account.name,
                    subtitle: account.balanceAmount.map({"\($0)"}),
                    isSelected: Bool.random()
                )
                
                verticalStackView.addArrangedSubview(accountCellView)
            }
        }
   
        addAndPinSubviewToSafeArea(verticalStackView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
