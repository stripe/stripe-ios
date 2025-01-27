//
//  FinancialConnectionsNetworkedAccountsResponse.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 6/16/23.
//

import Foundation

struct FinancialConnectionsNetworkedAccountsResponse: Decodable {
    let data: [FinancialConnectionsPartnerAccount]
    let display: Display?
    let nextPaneOnAddAccount: FinancialConnectionsSessionManifest.NextPane?
    let acquireConsentOnPrimaryCtaClick: Bool?
    let partnerToCoreAuths: [String: String]?

    struct Display: Decodable {
        let text: Text?

        struct Text: Decodable {
            let returningNetworkingUserAccountPicker: FinancialConnectionsNetworkingAccountPicker?
        }
    }
}

struct FinancialConnectionsNetworkingAccountPicker: Decodable {
    let title: String
    let defaultCta: String
    let addNewAccount: AddNewAccount
    let accounts: [FinancialConnectionsNetworkingAccountPicker.Account]
    let aboveCta: String?
    let multipleAccountTypesSelectedDataAccessNotice: FinancialConnectionsDataAccessNotice?

    struct AddNewAccount: Decodable {
        let body: String
        let icon: FinancialConnectionsImage?
    }

    struct Account: Decodable {
        let id: String
        let allowSelection: Bool
        // ex. "Select to repair and connect"
        let caption: String?
        // ex. "Repair and connect account"
        let selectionCta: String?
        // trailing icon on the account row
        let icon: FinancialConnectionsImage?
        let selectionCtaIcon: FinancialConnectionsImage?
        let drawerOnSelection: FinancialConnectionsGenericInfoScreen?
        let accountIcon: FinancialConnectionsImage?
        let dataAccessNotice: FinancialConnectionsDataAccessNotice?
    }
}
