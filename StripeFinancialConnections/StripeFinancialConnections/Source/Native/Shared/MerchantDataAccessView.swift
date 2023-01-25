//
//  MerchantDataAccessView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/21/22.
//

import Foundation
import SafariServices
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
final class MerchantDataAccessView: HitTestView {

    init(
        isStripeDirect: Bool,
        businessName: String?,
        permissions: [StripeAPI.FinancialConnectionsAccount.Permissions],
        didSelectLearnMore: @escaping () -> Void
    ) {
        super.init(frame: .zero)

        // the asterisks are to bold the text via "markdown"
        let leadingString: String
        if isStripeDirect {
            let localizedLeadingString = STPLocalizedString(
                "Data accessible to Stripe:",
                "This text is a lead-up to a disclosure that lists all of the bank data that Stripe will have access to. For example, the full text may read 'Data accessible to Stripe: Account details, transactions.'"
            )
            leadingString = "**\(localizedLeadingString)**"
        } else {
            if let businessName = businessName {
                let localizedLeadingString = STPLocalizedString(
                    "Data accessible to %@:",
                    "This text is a lead-up to a disclosure that lists all of the bank data that a merchant (ex. Coca-Cola) will have access to. For example, the full text may read 'Data accessible to Coca-Cola: Account details, transactions.'"
                )
                leadingString = "**\(String(format: localizedLeadingString, businessName))**"
            } else {
                let localizedLeadingString = STPLocalizedString(
                    "Data accessible to this business:",
                    "This text is a lead-up to a disclosure that lists all of the bank data that a business will have access to. For example, the full text may read 'Data accessible to this business: Account details, transactions.'"
                )
                leadingString = "**\(localizedLeadingString)**"
            }
        }

        // `payment_method` is "subsumed" by `account_numbers`
        //
        // BOTH (payment_method and account_numbers are valid permissions),
        // but we want to "combine" them for better UX
        let permissions =
            permissions.contains(.accountNumbers) ? permissions.filter({ $0 != .paymentMethod }) : permissions
        let permissionString = FormPermissionListString(permissions)

        let learnMoreUrlString: String
        if isStripeDirect {
            learnMoreUrlString = "https://stripe.com/docs/linked-accounts/faqs"
        } else {
            learnMoreUrlString =
                "https://support.stripe.com/user/questions/what-data-does-stripe-access-from-my-linked-financial-account"
        }
        let learnMoreString = "[\(String.Localized.learn_more)](\(learnMoreUrlString))"

        let finalString: String
        if isStripeDirect {
            finalString = "\(leadingString) \(permissionString). \(learnMoreString)"
        } else {
            let localizedPermissionFullString = String(
                format: STPLocalizedString(
                    "%@ through Stripe.",
                    "A sentence that describes what users banking data is accessible to Stripe. For example, the full sentence may say 'Account details, transactions, balances through Stripe.'"
                ),
                permissionString
            )
            finalString = "\(leadingString) \(localizedPermissionFullString) \(learnMoreString)"
        }

        let label = ClickableLabel(
            font: .stripeFont(forTextStyle: .captionTight),
            boldFont: .stripeFont(forTextStyle: .captionTightEmphasized),
            linkFont: .stripeFont(forTextStyle: .captionTightEmphasized),
            textColor: .textSecondary
        )
        label.setText(
            finalString,
            action: { url in
                SFSafariViewController.present(url: url)
                didSelectLearnMore()
            }
        )
        addAndPinSubview(label)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - Helpers

private func FormPermissionListString(
    _ permissions: [StripeAPI.FinancialConnectionsAccount.Permissions]
) -> String {
    let permissionListString =
        permissions
        .map { LocalizedStringFromPermission($0) }
        .joined(separator: ", ")

    let capitalizedFirstLetter = permissionListString.prefix(1).uppercased()
    let restOfString = String(permissionListString.dropFirst())
    return capitalizedFirstLetter + restOfString
}

private func LocalizedStringFromPermission(
    _ permission: StripeAPI.FinancialConnectionsAccount.Permissions
) -> String {
    switch permission {
    case .paymentMethod:
        // `payment_method` is "subsumed" by `account_numbers`
        //
        // BOTH (payment_method and account_numbers are valid permissions),
        // but we want to "combine" them for better UX
        fallthrough
    case .accountNumbers:
        return STPLocalizedString(
            "account details",
            "A type of user banking data that Stripe can have access to. In this case, account details involve things like being able to access a banks account and routing number."
        )
    case .balances:
        return STPLocalizedString(
            "balances",
            "A type of user banking data that Stripe can have access to. In this case, balances means account balance in a bank like $1,000."
        )
    case .ownership:
        return STPLocalizedString(
            "account ownership details",
            "A type of user banking data that Stripe can have access to. In this case, account ownership details entail things like users full name or address."
        )
    case .transactions:
        return STPLocalizedString(
            "transactions",
            "A type of user banking data that Stripe can have access to. In this case, transactions entails a list of transactions user has made on their debit card. For example, 'bought $5.00 coffee at 12:00 PM'"
        )
    case .unparsable:
        return STPLocalizedString(
            "others",
            "A type of user banking data that Stripe can have access to. In this case, 'others' mean an unknown, or generic type of user data. Maybe it's the users full name, maybe its the balance of the bank account (ex. $1,000)."
        )
    }
}

#if DEBUG

import SwiftUI

@available(iOSApplicationExtension, unavailable)
private struct MerchantDataAccessViewUIViewRepresentable: UIViewRepresentable {

    let isStripeDirect: Bool
    let businessName: String?
    let permissions: [StripeAPI.FinancialConnectionsAccount.Permissions]

    func makeUIView(context: Context) -> MerchantDataAccessView {
        MerchantDataAccessView(
            isStripeDirect: isStripeDirect,
            businessName: businessName,
            permissions: permissions,
            didSelectLearnMore: {}
        )
    }

    func updateUIView(_ uiView: MerchantDataAccessView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct MerchantDataAccessView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            MerchantDataAccessViewUIViewRepresentable(
                isStripeDirect: true,
                businessName: nil,
                permissions: [.accountNumbers]
            )
            .frame(height: 30)

            MerchantDataAccessViewUIViewRepresentable(
                isStripeDirect: false,
                businessName: "Rocket Rides",
                permissions: [.accountNumbers]
            )
            .frame(height: 30)

            MerchantDataAccessViewUIViewRepresentable(
                isStripeDirect: false,
                businessName: nil,
                permissions: [.accountNumbers]
            )
            .frame(height: 30)

            MerchantDataAccessViewUIViewRepresentable(
                isStripeDirect: false,
                businessName: "Rocket Rides",
                permissions: [.accountNumbers]
            )
            .frame(height: 30)

            MerchantDataAccessViewUIViewRepresentable(
                isStripeDirect: false,
                businessName: "Rocket Rides",
                permissions: [.accountNumbers, .paymentMethod]
            )
            .frame(height: 30)

            MerchantDataAccessViewUIViewRepresentable(
                isStripeDirect: false,
                businessName: "Rocket Rides",
                permissions: [.accountNumbers, .paymentMethod, .transactions, .ownership, .balances]
            )
            .frame(height: 50)

            MerchantDataAccessViewUIViewRepresentable(
                isStripeDirect: false,
                businessName: "Rocket Rides",
                permissions: [.unparsable]
            )
            .frame(height: 30)

            MerchantDataAccessViewUIViewRepresentable(
                isStripeDirect: true,
                businessName: nil,
                permissions: []
            )
            .frame(height: 30)

            Spacer()
        }
        .padding()
        .padding()
        .padding()
        .padding()
    }
}

#endif
