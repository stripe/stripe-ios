//
//  AccountPickerNoAccountAvailableErrorView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/23/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

// Same as Stripe.js `AccountNoneEligibleForPaymentMethodFailure`
final class AccountPickerNoAccountEligibleErrorView: UIView {
    
    init(
        institution: FinancialConnectionsInstitution,
        bussinessName: String?,
        institutionSkipAccountSelection: Bool,
        numberOfIneligibleAccounts: Int,
        paymentMethodType: String,
        didSelectAnotherBank: @escaping () -> Void,
        didSelectEnterBankDetailsManually: (() -> Void)? // if nil, don't show button
    ) {
        super.init(frame: .zero)
        assert(numberOfIneligibleAccounts >= 1, "this error should never be displayed if 0 accounts were selected by the user")
        
        // Financial Connections support credit cards, but not in all flows
        // (ex. ACH only supports checking/savings).
        let supportedAccountTypes: String = {
            if paymentMethodType == "link" {
                return "US checking"
            } else {
                return "checking or savings"
            }
        }()
        let subtitleFirstSentence: String = {
            if let bussinessName = bussinessName {
                if numberOfIneligibleAccounts == 1 {
                    return "We found 1 \(institution.name) account but you can only link \(supportedAccountTypes) to \(bussinessName)."
                } else {
                    return "We found \(numberOfIneligibleAccounts) \(institution.name) accounts but you can only link \(supportedAccountTypes) to \(bussinessName)."
                }
            } else {
                if numberOfIneligibleAccounts == 1 {
                    return "We found 1 \(institution.name) account but you can only link \(supportedAccountTypes)."
                } else {
                    return "We found \(numberOfIneligibleAccounts) \(institution.name) accounts but you can only link \(supportedAccountTypes)."
                }
            }
        }()
        let subtitleSecondSentence: String = {
            let allowManualEntry = didSelectEnterBankDetailsManually != nil
            if allowManualEntry && institutionSkipAccountSelection {
                return "Please enter your bank details manually or try selecting another bank account."
            } else if allowManualEntry {
                return "Please enter your bank details manually or try selecting another bank."
            } else if institutionSkipAccountSelection {
                return "Please try selecting another bank account."
            } else {
                return "Please try selecting another bank."
            }
        }()
        
        let reusableInformationView = ReusableInformationView(
            iconType: .icon, // TODO(kgaidis): set institution image with exclamation error
            title: {
                if institutionSkipAccountSelection {
                    if numberOfIneligibleAccounts == 1 {
                        return "The account you selected isn't a \(supportedAccountTypes) account"
                    } else {
                        return "The accounts you selected aren't \(supportedAccountTypes) accounts"
                    }
                } else {
                    return "No \(supportedAccountTypes) account available"
                }
            }(),
            subtitle: subtitleFirstSentence + " " + subtitleSecondSentence,
            primaryButtonConfiguration: ReusableInformationView.ButtonConfiguration(
                title: {
                    if institutionSkipAccountSelection  {
                        return "Select another bank" // TODO: Not sure if correct...
                    } else {
                        return "Link another account"
                    }
                }(),
                action: didSelectAnotherBank
            ),
            secondaryButtonConfiguration: {
                if let didSelectEnterBankDetailsManually = didSelectEnterBankDetailsManually {
                    return ReusableInformationView.ButtonConfiguration(
                        title: "Enter bank details manually",
                        action: didSelectEnterBankDetailsManually
                    )
                } else {
                    return nil
                }
            }()
        )
        addAndPinSubview(reusableInformationView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
