//
//  ConsentModel.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/11/22.
//

import Foundation

// Temporary model until we get this data from backend.
struct ConsentModel {
    
    private let businessName: String
    
    var dataAccessNoticeModel: DataAccessNoticeModel {
        return DataAccessNoticeModel(businessName: businessName)
    }
    
    init(businessName: String?) {
        self.businessName = businessName ?? "Unknown"
    }
}

// Temporary model until we get this data from backend.
struct DataAccessNoticeModel {
    
    struct BodyBulletItem {
        let title: String
        let subtitle: String
    }
    
    private let businessName: String
    
    var headerText: String {
        return "Data requested by \(businessName) for the accounts you link:"
    }
    
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
    
    init(businessName: String) {
        self.businessName = businessName
    }
}
