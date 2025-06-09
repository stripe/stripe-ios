//
//  LinkButtonViewModel.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 6/9/25.
//

import SwiftUI

class LinkButtonViewModel: NSObject, ObservableObject {
    @Published private(set) var account: PaymentSheetLinkAccountInfoProtocol?

    override init() {
        super.init()
        updateAccountFromContext()
        LinkAccountContext.shared.addObserver(self, selector: #selector(updateAccountFromContext))
    }

    deinit {
        LinkAccountContext.shared.removeObserver(self)
    }

    func setAccount(_ newAccount: PaymentSheetLinkAccountInfoProtocol?) {
        setAccountIfRegistered(newAccount)
    }

    @objc private func updateAccountFromContext() {
        setAccountIfRegistered(LinkAccountContext.shared.account)
    }

    /// Sets the account only if it exists and is registered
    private func setAccountIfRegistered(_ newAccount: PaymentSheetLinkAccountInfoProtocol?) {
        if let newAccount, newAccount.isRegistered {
            self.account = newAccount
        } else {
            self.account = nil
        }
    }
}
