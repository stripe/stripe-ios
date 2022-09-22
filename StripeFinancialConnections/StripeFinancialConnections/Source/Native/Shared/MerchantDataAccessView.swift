//
//  MerchantDataAccessView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/21/22.
//

import Foundation
import UIKit
@_spi(STP) import StripeUICore

@available(iOSApplicationExtension, unavailable)
final class MerchantDataAccessView: UIView {
    
    init(
        isStripeDirect: Bool,
        businessName: String?,
        permissions: [StripeAPI.FinancialConnectionsAccount.Permissions]
    ) {
        super.init(frame: .zero)
        
        let leadingString: String
        if isStripeDirect {
            leadingString = "*Data accessible to Stripe:*"
        } else {
            if let businessName = businessName {
                leadingString = "*Data accessible to \(businessName):*"
            } else {
                leadingString = "*Data accessible to this business:*"
            }
        }
        
        // `payment_method` is "subsumed" by `account_numbers`
        //
        // BOTH (payment_method and account_numbers are valid permissions),
        // but we want to "combine" them for better UX
        let permissions = permissions.contains(.accountNumbers) ? permissions.filter({ $0 != .paymentMethod}) : permissions
        let permissionString = FormPermissionListString(permissions)
        
        let learnMoreUrlString: String
        if isStripeDirect {
            learnMoreUrlString = "https://stripe.com/docs/linked-accounts/faqs"
        } else {
            learnMoreUrlString = "https://support.stripe.com/user/questions/what-data-does-stripe-access-from-my-linked-financial-account"
        }
        let learnMoreString = "[Learn more](\(learnMoreUrlString))"
        
        let finalString: String
        if isStripeDirect {
            finalString = "\(leadingString) \(permissionString) through Stripe. \(learnMoreString)"
        } else {
            finalString = "\(leadingString) \(permissionString). \(learnMoreString)"
        }
        
        let label = ClickableLabel()
        label.setText(
            finalString,
            font: .stripeFont(forTextStyle: .captionTight),
            boldFont: .stripeFont(forTextStyle: .captionTightEmphasized),
            linkFont: .stripeFont(forTextStyle: .captionTightEmphasized)
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
    let permissionListString = permissions
        .map { LocalizedStringFromPermission($0) }
        .joined(separator: ", ")
    
    guard let firstCharacter = permissionListString.first else {
        assertionFailure("we should always get at least one permission")
        return "No permissions available"
    }
    
    let capitalizedFirstLetter = String(firstCharacter).capitalized
    let restOfString = permissionListString[permissionListString
        .index(after: permissionListString.startIndex)..<permissionListString.endIndex]
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
        return "account details"
    case .balances:
        return "balances"
    case .ownership:
        return "account ownership details"
    case .transactions:
        return "transactions"
    case .unparsable:
        return "others"
    }
}

#if DEBUG

import SwiftUI

@available(iOS 13.0, *)
@available(iOSApplicationExtension, unavailable)
private struct MerchantDataAccessViewUIViewRepresentable: UIViewRepresentable {
    
    let isStripeDirect: Bool
    let businessName: String?
    let permissions: [StripeAPI.FinancialConnectionsAccount.Permissions]
    
    func makeUIView(context: Context) -> MerchantDataAccessView {
        MerchantDataAccessView(
            isStripeDirect: isStripeDirect,
            businessName: businessName,
            permissions: permissions
        )
    }
    
    func updateUIView(_ uiView: MerchantDataAccessView, context: Context) {}
}

@available(iOSApplicationExtension, unavailable)
struct MerchantDataAccessView_Previews: PreviewProvider {
    @available(iOS 13.0, *)
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
                businessName: "Rocket Rides",
                permissions: [.accountNumbers]
            )
                .frame(height: 30)
            
            MerchantDataAccessViewUIViewRepresentable(
                isStripeDirect: false,
                businessName: "Rocket Rides",
                permissions: [.accountNumbers,.paymentMethod]
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
            
            Spacer()
        }
        .padding()
        .padding()
        .padding()
        .padding()
    }
}

#endif
