//
//  AccountPickerAccountLoadFailureView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/23/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
final class AccountPickerAccountLoadErrorView: UIView {

    init(
        institution: FinancialConnectionsInstitution,
        didSelectAnotherBank: @escaping () -> Void,
        didSelectTryAgain: (() -> Void)?,  // if nil, don't show button
        didSelectEnterBankDetailsManually: (() -> Void)?  // if nil, don't show button
    ) {
        super.init(frame: .zero)

        let subtitle: String
        let secondaryButtonConfiguration: ReusableInformationView.ButtonConfiguration?
        let primaryButtonConfiguration: ReusableInformationView.ButtonConfiguration

        if let didSelectTryAgain = didSelectTryAgain {
            subtitle = STPLocalizedString(
                "Please select another bank or try again.",
                "The subtitle/description of a screen that shows an error. The error appears after we failed to load users bank accounts. Here we instruct the user to select another bank or to try loading their bank accounts again."
            )
            secondaryButtonConfiguration = ReusableInformationView.ButtonConfiguration(
                title: String.Localized.select_another_bank,
                action: didSelectAnotherBank
            )
            primaryButtonConfiguration = ReusableInformationView.ButtonConfiguration(
                title: "Try again",  // TODO: once we localize, pull in the string from StripeCore `String.Localized.tryAgain`
                action: didSelectTryAgain
            )
        } else if let didSelectEnterBankDetailsManually = didSelectEnterBankDetailsManually {
            subtitle = STPLocalizedString(
                "Please enter your bank details manually or select another bank.",
                "The subtitle/description of a screen that shows an error. The error appears after we failed to load users bank accounts. Here we instruct the user to enter their bank details manually or to try selecting another bank."
            )
            secondaryButtonConfiguration = ReusableInformationView.ButtonConfiguration(
                title: String.Localized.enter_bank_details_manually,
                action: didSelectEnterBankDetailsManually
            )
            primaryButtonConfiguration = ReusableInformationView.ButtonConfiguration(
                title: String.Localized.select_another_bank,
                action: didSelectAnotherBank
            )
        } else {
            subtitle = STPLocalizedString(
                "Please select another bank.",
                "The subtitle/description of a screen that shows an error. The error appears after we failed to load users bank accounts. Here we instruct the user to try selecting another bank."
            )
            secondaryButtonConfiguration = nil
            primaryButtonConfiguration = ReusableInformationView.ButtonConfiguration(
                title: String.Localized.select_another_bank,
                action: didSelectAnotherBank
            )
        }
        let institutionIconView = InstitutionIconView(
            size: .large,
            showWarning: true
        )
        institutionIconView.setImageUrl(institution.icon?.default)
        let reusableInformationView = ReusableInformationView(
            iconType: .view(institutionIconView),
            title: String(
                format: STPLocalizedString(
                    "There was a problem accessing your %@ account",
                    "The title of a screen that shows an error. The error appears after we failed to load users bank accounts. Here we describe to the user that we had issues with the bank. '%@' gets replaced by the name of the bank."
                ),
                institution.name
            ),
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

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct AccountPickerAccountLoadErrorViewUIViewRepresentable: UIViewRepresentable {

    let institutionName: String
    let didSelectTryAgain: (() -> Void)?
    let didSelectEnterBankDetailsManually: (() -> Void)?

    func makeUIView(context: Context) -> AccountPickerAccountLoadErrorView {
        AccountPickerAccountLoadErrorView(
            institution: FinancialConnectionsInstitution(
                id: "123",
                name: institutionName,
                url: nil,
                icon: nil,
                logo: nil
            ),
            didSelectAnotherBank: {},
            didSelectTryAgain: didSelectTryAgain,
            didSelectEnterBankDetailsManually: didSelectEnterBankDetailsManually
        )
    }

    func updateUIView(_ uiView: AccountPickerAccountLoadErrorView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct AccountPickerAccountLoadErrorView_Previews: PreviewProvider {
    static var previews: some View {
        AccountPickerAccountLoadErrorViewUIViewRepresentable(
            institutionName: "Chase",
            didSelectTryAgain: {},
            didSelectEnterBankDetailsManually: {}
        )

        AccountPickerAccountLoadErrorViewUIViewRepresentable(
            institutionName: "Ally",
            didSelectTryAgain: nil,
            didSelectEnterBankDetailsManually: {}
        )

        AccountPickerAccountLoadErrorViewUIViewRepresentable(
            institutionName: "Chase",
            didSelectTryAgain: {},
            didSelectEnterBankDetailsManually: nil
        )

        AccountPickerAccountLoadErrorViewUIViewRepresentable(
            institutionName: "Chase",
            didSelectTryAgain: nil,
            didSelectEnterBankDetailsManually: nil
        )
    }
}

#endif
