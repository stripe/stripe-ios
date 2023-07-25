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

@available(iOSApplicationExtension, unavailable)
final class AccountNumberRetrievalErrorView: UIView {

    init(
        institution: FinancialConnectionsInstitution,
        didSelectAnotherBank: @escaping () -> Void
    ) {
        super.init(frame: .zero)
        let reusableInformationView = ReusableInformationView(
            iconType: .view(
                {
                    let institutionIconView = InstitutionIconView(
                        size: .large,
                        showWarning: true
                    )
                    institutionIconView.setImageUrl(institution.icon?.default)
                    return institutionIconView
                }()
            ),
            title: STPLocalizedString(
                "Your account number couldn’t be accessed at this time",
                "The title of a screen that shows an error. The error appears after we failed to access users bank account."
            ),
            subtitle: STPLocalizedString(
                "Please select another bank.",
                "The subtitle/description of a screen that shows an error. The error appears after we failed to access users bank account. Here we instruct the user to try selecting another bank."
            ),
            primaryButtonConfiguration: ReusableInformationView.ButtonConfiguration(
                title: String.Localized.select_another_bank,
                action: didSelectAnotherBank
            ),
            secondaryButtonConfiguration: nil
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
private struct AccountNumberRetrievalErrorViewUIViewRepresentable: UIViewRepresentable {

    let institutionName: String

    func makeUIView(context: Context) -> AccountNumberRetrievalErrorView {
        AccountNumberRetrievalErrorView(
            institution: FinancialConnectionsInstitution(
                id: "123",
                name: institutionName,
                url: nil,
                icon: nil,
                logo: nil
            ),
            didSelectAnotherBank: {}
        )
    }

    func updateUIView(_ uiView: AccountNumberRetrievalErrorView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct AccountNumberRetrievalErrorView_Previews: PreviewProvider {
    static var previews: some View {
        AccountNumberRetrievalErrorViewUIViewRepresentable(
            institutionName: "Chase"
        )
    }
}

#endif
