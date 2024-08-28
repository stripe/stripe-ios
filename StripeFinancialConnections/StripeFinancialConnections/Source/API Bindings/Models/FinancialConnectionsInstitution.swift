//
//  FinancialConnectionsInstitution.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/6/22.
//

import Foundation
@_spi(STP) import StripeCore

struct FinancialConnectionsInstitution: Decodable, Hashable, Equatable {

    let id: String
    let name: String
    let url: String?
    let icon: FinancialConnectionsImage?
    let logo: FinancialConnectionsImage?
}

// MARK: - Institution List

struct FinancialConnectionsInstitutionList: Decodable {
    let data: [FinancialConnectionsInstitution]
}

struct ShareNetworkedAccountsResponse: Decodable {
    let data: [FinancialConnectionsInstitution]
    let nextPane: FinancialConnectionsSessionManifest.NextPane?
    let displayText: DisplayText?

    struct DisplayText: Decodable {
        let text: Text?

        struct Text: Decodable {
            let succcessPane: SuccessPane?

            struct SuccessPane: Decodable {
                let caption: String
                let subCaption: String
            }
        }
    }
}
