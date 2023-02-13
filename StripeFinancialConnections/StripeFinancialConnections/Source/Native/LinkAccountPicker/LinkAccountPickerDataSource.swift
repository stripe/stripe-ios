//
//  LinkLinkAccountPickerDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/13/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol LinkAccountPickerDataSourceDelegate: AnyObject {
    func linkLinkAccountPickerDataSource(
        _ dataSource: LinkAccountPickerDataSource,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    )
}

protocol LinkAccountPickerDataSource: AnyObject {

    var delegate: LinkAccountPickerDataSourceDelegate? { get set }
    var manifest: FinancialConnectionsSessionManifest { get }
    var selectedAccounts: [FinancialConnectionsPartnerAccount] { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse>
    func updateSelectedAccounts(_ selectedAccounts: [FinancialConnectionsPartnerAccount])
}

final class LinkAccountPickerDataSourceImplementation: LinkAccountPickerDataSource {

    let manifest: FinancialConnectionsSessionManifest
    let analyticsClient: FinancialConnectionsAnalyticsClient
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    private let consumerSession: ConsumerSessionData

    private(set) var selectedAccounts: [FinancialConnectionsPartnerAccount] = [] {
        didSet {
            delegate?.linkLinkAccountPickerDataSource(self, didSelectAccounts: selectedAccounts)
        }
    }
    weak var delegate: LinkAccountPickerDataSourceDelegate?

    init(
        manifest: FinancialConnectionsSessionManifest,
        apiClient: FinancialConnectionsAPIClient,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        clientSecret: String,
        consumerSession: ConsumerSessionData
    ) {
        self.manifest = manifest
        self.apiClient = apiClient
        self.analyticsClient = analyticsClient
        self.clientSecret = clientSecret
        self.consumerSession = consumerSession
    }
    
    
    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse> {
        return apiClient.fetchNetworkedAccounts(
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSession.clientSecret
        )
    }

    func updateSelectedAccounts(_ selectedAccounts: [FinancialConnectionsPartnerAccount]) {
        self.selectedAccounts = selectedAccounts
    }

//    func selectAuthSessionAccounts() -> Promise<FinancialConnectionsAuthSessionAccounts> {
//        return apiClient.selectAuthSessionAccounts(
//            clientSecret: clientSecret,
//            authSessionId: authSession.id,
//            selectedAccountIds: selectedAccounts.map({ $0.id })
//        )
//    }
}
