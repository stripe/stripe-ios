//
//  AccountNumberRetrievalErrorView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/29/22.
//

import Foundation

@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class AccountNumberRetrievalErrorView: UIView {

    init(
        institution: FinancialConnectionsInstitution,
        appearance: FinancialConnectionsAppearance,
        didSelectAnotherBank: @escaping () -> Void,
        didSelectEnterBankDetailsManually: (() -> Void)?  // if nil, don't show button
    ) {
        super.init(frame: .zero)
        let paneLayoutView = PaneLayoutView(
            contentView: PaneLayoutView.createContentView(
                iconView: {
                    let institutionIconView = InstitutionIconView()
                    institutionIconView.setImageUrl(institution.icon?.default)
                    return institutionIconView
                }(),
                title: STPLocalizedString(
                    "Your account number couldn’t be accessed at this time",
                    "The title of a screen that shows an error. The error appears after we failed to access users bank account."
                ),
                subtitle: {
                    let isManualEntryEnabled = didSelectEnterBankDetailsManually != nil
                    if isManualEntryEnabled {
                        return STPLocalizedString(
                            "Please enter your bank details manually or select another bank.",
                            "The subtitle/description of a screen that shows an error. The error appears after we failed to access users bank account. Here we instruct the user to enter their bank details manually or to try selecting another bank."
                        )
                    } else {
                        return STPLocalizedString(
                            "Please select another bank.",
                            "The subtitle/description of a screen that shows an error. The error appears after we failed to access users bank account. Here we instruct the user to try selecting another bank."
                        )
                    }
                }(),
                contentView: nil
            ),
            footerView: PaneLayoutView.createFooterView(
                primaryButtonConfiguration: PaneLayoutView.ButtonConfiguration(
                    title: String.Localized.select_another_bank,
                    action: didSelectAnotherBank
                ),
                secondaryButtonConfiguration: {
                    if let didSelectEnterBankDetailsManually = didSelectEnterBankDetailsManually {
                        return PaneLayoutView.ButtonConfiguration(
                            title: String.Localized.enter_bank_details_manually,
                            action: didSelectEnterBankDetailsManually
                        )
                    } else {
                        return nil
                    }
                }(),
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

private struct AccountNumberRetrievalErrorViewUIViewRepresentable: UIViewRepresentable {

    let institutionName: String
    let appearance: FinancialConnectionsAppearance
    let didSelectEnterBankDetailsManually: (() -> Void)?

    func makeUIView(context: Context) -> AccountNumberRetrievalErrorView {
        AccountNumberRetrievalErrorView(
            institution: FinancialConnectionsInstitution(
                id: "123",
                name: institutionName,
                url: nil,
                icon: nil,
                logo: nil
            ),
            appearance: appearance,
            didSelectAnotherBank: {},
            didSelectEnterBankDetailsManually: didSelectEnterBankDetailsManually
        )
    }

    func updateUIView(_ uiView: AccountNumberRetrievalErrorView, context: Context) {}
}

struct AccountNumberRetrievalErrorView_Previews: PreviewProvider {
    static var previews: some View {
        AccountNumberRetrievalErrorViewUIViewRepresentable(
            institutionName: "Chase",
            appearance: .stripe,
            didSelectEnterBankDetailsManually: {}
        )

        AccountNumberRetrievalErrorViewUIViewRepresentable(
            institutionName: "Bank of America",
            appearance: .stripe,
            didSelectEnterBankDetailsManually: nil
        )
    }
}

#endif
