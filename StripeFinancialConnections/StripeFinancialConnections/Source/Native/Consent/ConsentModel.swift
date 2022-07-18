//
//  ConsentModel.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/11/22.
//

import Foundation

// Temporary model until we get this data from backend.
struct ConsentModel {
    
    let headerText = "MERCHANT works with Stripe to link your accounts."
    
    let bodyItems: [BodyBulletItem] = [
        BodyBulletItem(
            iconUrl: URL(string: "https://www.cdn.stripe.com/image.png")!,
            text: "Stripe will allow MERCHANT to access only the [data requested](stripe://bottom-sheet). We never share your login details with them."
        ),
        BodyBulletItem(
            iconUrl: URL(string: "https://www.cdn.stripe.com/image.png")!,
            text: "Your data is encrypted for your protection."
        ),
        BodyBulletItem(
            iconUrl: URL(string: "https://www.cdn.stripe.com/image.png")!,
            text: "You can [disconnect](https://support.stripe.com/user/how-do-i-disconnect-my-linked-financial-account) your accounts at any time."
        ),
    ]
    
    let footerText = "You agree to Stripe's [Terms](https://stripe.com/legal/end-users#linked-financial-account-terms) and [Privacy Policy](https://stripe.com/privacy). [Learn more](https://stripe.com/privacy-center/legal#linking-financial-accounts)"
    
    let dataAccessNoticeModel = DataAccessNoticeModel()
    
    struct BodyBulletItem {
        let iconUrl: URL
        let text: String
    }
}

// Temporary model until we get this data from backend.
struct DataAccessNoticeModel {
    let headerText = "Data requested by MERCHANT for the accounts you link:"
    
    let bodyItems: [BodyBulletItem] = [
        BodyBulletItem(
            title: "Account owner information",
            subtitle: "Account owner name and mailing address associated with your account"
        ),
        BodyBulletItem(
            title: "Account details",
            subtitle: "Account number, routing number, account type, account nickname"
        ),
    ]
    
    let footerText = "[Learn more about data access](https://support.stripe.com/user/questions/what-data-does-stripe-access-from-my-linked-financial-account)"
    
    struct BodyBulletItem {
        let title: String
        let subtitle: String
    }
}
