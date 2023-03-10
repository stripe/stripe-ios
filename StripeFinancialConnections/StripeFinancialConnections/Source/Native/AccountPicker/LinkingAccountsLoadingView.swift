//
//  LinkingAccountsLoadingView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/28/22.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

final class LinkingAccountsLoadingView: UIView {

    init(
        numberOfSelectedAccounts: Int,
        businessName: String?
    ) {
        super.init(frame: .zero)
        let linkingAccountsLoadingView = ReusableInformationView(
            iconType: .loading,
            title: {
                if numberOfSelectedAccounts == 1 {
                    return STPLocalizedString(
                        "Linking account",
                        "The title of the loading screen that appears when a user is in process of connecting their bank account to an application. Once the bank account is connected (or linked), the user will be able to use that bank account for payments."
                    )
                } else {
                    return STPLocalizedString(
                        "Linking accounts",
                        "The title of the loading screen that appears when a user is in process of connecting their bank accounts to an application. Once the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments."
                    )
                }
            }(),
            subtitle: {
                if numberOfSelectedAccounts == 1 {
                    if let businessName = businessName {
                        return String(
                            format: STPLocalizedString(
                                "Please wait while your account is connected to %@.",
                                "The subtitle/description of the loading screen that appears when a user is in process of connecting their bank account to an application. Once the bank account is connected (or linked), the user will be able to use the bank account for payments.  %@ will be replaced by the business name, for example, The Coca-Cola Company."
                            ),
                            businessName
                        )
                    } else {
                        return STPLocalizedString(
                            "Please wait while your account is connected to Stripe.",
                            "The subtitle/description of the loading screen that appears when a user is in process of connecting their bank account to an application. Once the bank account is connected (or linked), the user will be able to use the bank account for payments."
                        )
                    }
                } else {  // multiple bank accounts (numberOfSelectedAccounts > 1)
                    if let businessName = businessName {
                        return String(
                            format: STPLocalizedString(
                                "Please wait while your accounts are connected to %@.",
                                "The subtitle/description of the loading screen that appears when a user is in process of connecting their bank accounts to an application. Once the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments.  %@ will be replaced by the business name, for example, The Coca-Cola Company."
                            ),
                            businessName
                        )
                    } else {
                        return STPLocalizedString(
                            "Please wait while your accounts are connected to Stripe.",
                            "The subtitle/description of the loading screen that appears when a user is in process of connecting their bank accounts to an application. Once the bank accounts are connected (or linked), the user will be able to use those bank accounts for payments."
                        )
                    }
                }
            }()
        )
        addAndPinSubviewToSafeArea(linkingAccountsLoadingView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
