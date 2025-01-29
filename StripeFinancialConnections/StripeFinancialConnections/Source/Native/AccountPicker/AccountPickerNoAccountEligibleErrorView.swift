//
//  AccountPickerNoAccountAvailableErrorView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/23/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

// Same as Stripe.js `AccountNoneEligibleForPaymentMethodFailure`
final class AccountPickerNoAccountEligibleErrorView: UIView {

    init(
        institution: FinancialConnectionsInstitution,
        bussinessName: String?,
        institutionSkipAccountSelection: Bool,
        numberOfIneligibleAccounts: Int,
        paymentMethodType: FinancialConnectionsPaymentMethodType,
        appearance: FinancialConnectionsAppearance,
        didSelectAnotherBank: @escaping () -> Void
    ) {
        super.init(frame: .zero)
        assert(
            numberOfIneligibleAccounts >= 1,
            "this error should never be displayed if 0 accounts were selected by the user"
        )

        // Financial Connections support credit cards, but not in all flows
        // (ex. ACH only supports checking/savings).
        let supportedAccountTypes: String = {
            if paymentMethodType == .link {
                return STPLocalizedString(
                    "US checking",
                    "A type of payment account. We will insert this string into other messages to explain users what payment accounts are eligible for payments. For example, we may display a message that says 'The accounts you selected aren't US checking accounts.'"
                )
            } else {
                return STPLocalizedString(
                    "checking or savings",
                    "A type of payment account. We will insert this string into other messages to explain users what payment accounts are eligible for payments. For example, we may display a message that says 'The accounts you selected aren't checking or savings accounts.'"
                )
            }
        }()
        let subtitleFirstSentence: String = {
            if let bussinessName = bussinessName {
                if numberOfIneligibleAccounts == 1 {
                    let localizedString = STPLocalizedString(
                        "We found 1 %@ account but you can only link %@ accounts to %@.",
                        "A description/subtitle that instructs the user that the bank account they selected is not eligible. For example, maybe the user selected a credit card, but we only accept debit cards. The first '%@' is replaced by the name of the bank. The second '%@' is replaced by the supported payment accounts (ex. US checking). The third '%@' is replaced by the business name (Ex. Coca-Cola Inc). For example, it may read 'We found 1 Chase account but you can only link checking or savings to Coca-Cola Inc.'"
                    )
                    return String(format: localizedString, institution.name, supportedAccountTypes, bussinessName)
                } else {
                    let localizedString = STPLocalizedString(
                        "We found %d %@ accounts but you can only link %@ accounts to %@.",
                        "A description/subtitle that instructs the user that the bank accounts they selected are not eligible. For example, maybe the user selected credit cards, but we only accept debit cards. The '%d' is replaced by the number of ineligible accounts. The first '%@' is replaced by the name of the bank. The second '%@' is replaced by the supported payment accounts (ex. US checking). The third '%@' is replaced by the business name (Ex. Coca-Cola Inc). For example, it may read 'We found 2 Chase accounts but you can only link checking or savings to Coca-Cola Inc.'"
                    )
                    return String(
                        format: localizedString,
                        numberOfIneligibleAccounts,
                        institution.name,
                        supportedAccountTypes,
                        bussinessName
                    )
                }
            } else {
                if numberOfIneligibleAccounts == 1 {
                    let localizedString = STPLocalizedString(
                        "We found 1 %@ account but you can only link %@ accounts.",
                        "A description/subtitle that instructs the user that the bank account they selected is not eligible. For example, maybe the user selected a credit card, but we only accept debit cards. The first '%@' is replaced by the name of the bank. The second '%@' is replaced by the supported payment accounts (ex. US checking). For example, it may read 'We found 1 Chase account but you can only link checking or savings.'"
                    )
                    return String(format: localizedString, institution.name, supportedAccountTypes)
                } else {
                    let localizedString = STPLocalizedString(
                        "We found %d %@ accounts but you can only link %@ accounts.",
                        "A description/subtitle that instructs the user that the bank accounts they selected are not eligible. For example, maybe the user selected credit cards, but we only accept debit cards. The '%d' is replaced by the number of ineligible accounts. The first '%@' is replaced by the name of the bank. The second '%@' is replaced by the supported payment accounts (ex. US checking). For example, it may read 'We found 2 Chase accounts but you can only link checking or savings.'"
                    )
                    return String(
                        format: localizedString,
                        numberOfIneligibleAccounts,
                        institution.name,
                        supportedAccountTypes
                    )
                }
            }
        }()
        let subtitleSecondSentence: String = {
            if institutionSkipAccountSelection {
                return STPLocalizedString(
                    "Please try selecting another bank account.",
                    "The subtitle/description of a screen that shows an error. The error appears after user selected bank accounts, but we found that none of them are eligible to be linked. Here we instruct the user to try selecting another bank account at the same bank."
                )
            } else {
                return STPLocalizedString(
                    "Please try selecting another bank.",
                    "The subtitle/description of a screen that shows an error. The error appears after user selected bank accounts, but we found that none of them are eligible to be linked. Here we instruct the user to try selecting another bank account at a different bank."
                )
            }
        }()

        let paneLayoutView = PaneLayoutView(
            contentView: PaneLayoutView.createContentView(
                iconView: {
                    let institutionIconView = InstitutionIconView()
                    institutionIconView.setImageUrl(institution.icon?.default)
                    return institutionIconView
                }(),
                title: {
                    if institutionSkipAccountSelection {
                        if numberOfIneligibleAccounts == 1 {
                            return STPLocalizedString(
                                    "The account you selected isn't available for payments",
                                    "The title of a screen that shows an error. The error appears after we failed to load users bank accounts. Here we describe to the user that the account they selected isn't eligible."
                                )
                        } else {
                            return STPLocalizedString(
                                    "The accounts you selected aren't available for payments",
                                    "The title of a screen that shows an error. The error appears after we failed to load users bank accounts. Here we describe to the user that the accounts they selected aren't eligible. '%@' gets replaced by the eligible type of bank accounts, i.e. checking or savings. For example, maybe user selected a credit card, but we only support debit cards."
                                )
                        }
                    } else {
                        return STPLocalizedString(
                            "No payment accounts available",
                            "The title of a screen that shows an error. The error appears after we failed to load users bank accounts. Here we describe to the user that the accounts they selected aren't eligible. '%@' gets replaced by the eligible type of bank accounts, i.e. checking or savings. For example, maybe user selected a credit card, but we only support debit cards."
                        )
                    }
                }(),
                subtitle: subtitleFirstSentence + " " + subtitleSecondSentence,
                contentView: nil
            ),
            footerView: PaneLayoutView.createFooterView(
                primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                    title: {
                        if institutionSkipAccountSelection {
                            return STPLocalizedString(
                                "Connect another account",
                                "The title of a button. The button presents the user an option to select another bank account. For example, we may show this button after user failed to link their primary bank account, but maybe the user can try to link their secondary bank account!"
                            )
                        } else {
                            return String.Localized.select_another_bank
                        }
                    }(),
                    action: didSelectAnotherBank
                ),
                appearance: appearance
            ).footerView
        )
        paneLayoutView.addTo(view: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#if DEBUG

import SwiftUI

private struct AccountPickerNoAccountEligibleErrorViewUIViewRepresentable: UIViewRepresentable {

    let institutionName: String
    let businessName: String?
    let institutionSkipAccountSelection: Bool
    let numberOfIneligibleAccounts: Int
    let paymentMethodType: FinancialConnectionsPaymentMethodType

    func makeUIView(context: Context) -> AccountPickerNoAccountEligibleErrorView {
        AccountPickerNoAccountEligibleErrorView(
            institution: FinancialConnectionsInstitution(
                id: "123",
                name: institutionName,
                url: nil,
                icon: nil,
                logo: nil
            ),
            bussinessName: businessName,
            institutionSkipAccountSelection: institutionSkipAccountSelection,
            numberOfIneligibleAccounts: numberOfIneligibleAccounts,
            paymentMethodType: paymentMethodType,
            appearance: .stripe,
            didSelectAnotherBank: {}
        )
    }

    func updateUIView(_ uiView: AccountPickerNoAccountEligibleErrorView, context: Context) {}
}

struct AccountPickerNoAccountEligibleErrorView_Previews: PreviewProvider {
    static var previews: some View {
        AccountPickerNoAccountEligibleErrorViewUIViewRepresentable(
            institutionName: "Chase",
            businessName: "The Coca-Cola Company",
            institutionSkipAccountSelection: false,
            numberOfIneligibleAccounts: 1,
            paymentMethodType: .link
        )

        AccountPickerNoAccountEligibleErrorViewUIViewRepresentable(
            institutionName: "Chase",
            businessName: "The Coca-Cola Company",
            institutionSkipAccountSelection: false,
            numberOfIneligibleAccounts: 3,
            paymentMethodType: .usBankAccount
        )

        AccountPickerNoAccountEligibleErrorViewUIViewRepresentable(
            institutionName: "Chase",
            businessName: nil,
            institutionSkipAccountSelection: false,
            numberOfIneligibleAccounts: 1,
            paymentMethodType: .link
        )

        AccountPickerNoAccountEligibleErrorViewUIViewRepresentable(
            institutionName: "Chase",
            businessName: nil,
            institutionSkipAccountSelection: true,
            numberOfIneligibleAccounts: 3,
            paymentMethodType: .unparsable
        )
    }
}

#endif
