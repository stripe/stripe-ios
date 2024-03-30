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

final class MerchantDataAccessView: HitTestView {

    init(
        isStripeDirect: Bool,
        businessName: String?,
        permissions: [StripeAPI.FinancialConnectionsAccount.Permissions],
        isNetworking: Bool,
        font: FinancialConnectionsFont,
        boldFont: FinancialConnectionsFont,
        alignCenter: Bool,
        didSelectLearnMore: @escaping (URL) -> Void
    ) {
        super.init(frame: .zero)

        // the asterisks are to bold the text via "markdown"
        let leadingString: String
        if isStripeDirect {
            let localizedLeadingString = STPLocalizedString(
                "Stripe can access",
                "This text is a lead-up to a disclosure that lists all of the bank data that Stripe will have access to. For example, the full text may read 'Data accessible to Stripe: Account details, transactions.'"
            )
            leadingString = localizedLeadingString
        } else {
            if let businessName = businessName {
                let localizedLeadingString = STPLocalizedString(
                    "%@ can access",
                    "This text is a lead-up to a disclosure that lists all of the bank data that a merchant (ex. Coca-Cola) will have access to. For example, the full text may read 'Data accessible to Coca-Cola: Account details, transactions.'"
                )
                leadingString = String(format: localizedLeadingString, businessName)
            } else {
                let localizedLeadingString = STPLocalizedString(
                    "This business can access",
                    "This text is a lead-up to a disclosure that lists all of the bank data that a business will have access to. For example, the full text may read 'Data accessible to this business: Account details, transactions.'"
                )
                leadingString = localizedLeadingString
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
        if isNetworking {
            finalString = "\(leadingString) \(permissionString). \(learnMoreString)"
        } else if isStripeDirect {
            finalString = "\(leadingString) \(permissionString). \(learnMoreString)"
        } else {
            finalString = "\(leadingString) \(permissionString). \(learnMoreString)"
        }

        let label = AttributedTextView(
            font: font,
            boldFont: boldFont,
            linkFont: font,
            textColor: .textDefault,
            alignCenter: alignCenter
        )
        label.setText(
            finalString,
            action: { url in
                didSelectLearnMore(url)
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
    var permissionListString = ""
    for i in 0..<permissions.count {
        permissionListString += LocalizedStringFromPermission(permissions[i])

        let isLastPermission = (i == permissions.count - 1)
        if !isLastPermission {
            let isSecondToLastPermission = (i == permissions.count - 2)
            if isSecondToLastPermission {
                permissionListString += " and "
            } else {
                permissionListString += ", "
            }
        }
    }
    return permissionListString
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

private struct MerchantDataAccessViewUIViewRepresentable: UIViewRepresentable {

    let isStripeDirect: Bool
    let businessName: String?
    let permissions: [StripeAPI.FinancialConnectionsAccount.Permissions]

    func makeUIView(context: Context) -> MerchantDataAccessView {
        MerchantDataAccessView(
            isStripeDirect: isStripeDirect,
            businessName: businessName,
            permissions: permissions,
            isNetworking: false,
            font: .body(.small),
            boldFont: .body(.smallEmphasized),
            alignCenter: Bool.random(),
            didSelectLearnMore: { _ in }
        )
    }

    func updateUIView(_ uiView: MerchantDataAccessView, context: Context) {}
}

struct MerchantDataAccessView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                Group {
                    MerchantDataAccessViewUIViewRepresentable(
                        isStripeDirect: true,
                        businessName: nil,
                        permissions: [.accountNumbers]
                    )

                    MerchantDataAccessViewUIViewRepresentable(
                        isStripeDirect: false,
                        businessName: "Rocket Rides",
                        permissions: [.accountNumbers]
                    )

                    MerchantDataAccessViewUIViewRepresentable(
                        isStripeDirect: false,
                        businessName: nil,
                        permissions: [.accountNumbers]
                    )

                    MerchantDataAccessViewUIViewRepresentable(
                        isStripeDirect: false,
                        businessName: "Rocket Rides",
                        permissions: [.accountNumbers]
                    )

                    MerchantDataAccessViewUIViewRepresentable(
                        isStripeDirect: false,
                        businessName: "Rocket Rides",
                        permissions: [.accountNumbers, .paymentMethod]
                    )

                    MerchantDataAccessViewUIViewRepresentable(
                        isStripeDirect: false,
                        businessName: "Rocket Rides",
                        permissions: [.transactions, .ownership]
                    )

                    MerchantDataAccessViewUIViewRepresentable(
                        isStripeDirect: false,
                        businessName: "Rocket Rides",
                        permissions: [.transactions, .ownership, .balances]
                    )

                    MerchantDataAccessViewUIViewRepresentable(
                        isStripeDirect: false,
                        businessName: "Rocket Rides",
                        permissions: [.accountNumbers, .paymentMethod, .transactions, .ownership, .balances]
                    )

                    MerchantDataAccessViewUIViewRepresentable(
                        isStripeDirect: false,
                        businessName: "Rocket Rides",
                        permissions: [.unparsable]
                    )

                    MerchantDataAccessViewUIViewRepresentable(
                        isStripeDirect: true,
                        businessName: nil,
                        permissions: []
                    )
                }
                .frame(height: 60)
                .padding(.horizontal)
            }
        }

    }
}

#endif
