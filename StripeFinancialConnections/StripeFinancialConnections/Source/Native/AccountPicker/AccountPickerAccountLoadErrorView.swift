//
//  AccountPickerAccountLoadFailureView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/23/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

final class AccountPickerAccountLoadErrorView: UIView {
    
    init(
        institution: FinancialConnectionsInstitution,
        didSelectAnotherBank: @escaping () -> Void,
        didSelectTryAgain: (() -> Void)?, // if nil, don't show button
        didSelectEnterBankDetailsManually: (() -> Void)? // if nil, don't show button
    ) {
        super.init(frame: .zero)
        let subtitle: String
        let secondaryButtonConfiguration: ReusableInformationView.ButtonConfiguration?
        let primaryButtonConfiguration: ReusableInformationView.ButtonConfiguration
        if let didSelectTryAgain = didSelectTryAgain {
            subtitle = "Please select another bank or try again."
            secondaryButtonConfiguration = ReusableInformationView.ButtonConfiguration(
                title: "Select another bank",
                action: didSelectAnotherBank
            )
            primaryButtonConfiguration = ReusableInformationView.ButtonConfiguration(
                title: "Try again",
                action: didSelectTryAgain
            )
        } else if let didSelectEnterBankDetailsManually = didSelectEnterBankDetailsManually {
            subtitle = "Please enter your bank details manually or select another bank."
            secondaryButtonConfiguration = ReusableInformationView.ButtonConfiguration(
                title: "Enter bank details manually",
                action: didSelectEnterBankDetailsManually
            )
            primaryButtonConfiguration = ReusableInformationView.ButtonConfiguration(
                title: "Select another bank",
                action: didSelectAnotherBank
            )
        } else {
            subtitle = "Please select another bank."
            secondaryButtonConfiguration = nil
            primaryButtonConfiguration = ReusableInformationView.ButtonConfiguration(
                title: "Select another bank",
                action: didSelectAnotherBank
            )
        }
        
        let reusableInformationView = ReusableInformationView(
            iconType: .icon, // TODO(kgaidis): set institution image with exclamation error
            title: "There was a problem accessing your \(institution.name) account",
            subtitle: subtitle,
            primaryButtonConfiguration: primaryButtonConfiguration,
            secondaryButtonConfiguration: secondaryButtonConfiguration
        )
        addAndPinSubview(reusableInformationView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
