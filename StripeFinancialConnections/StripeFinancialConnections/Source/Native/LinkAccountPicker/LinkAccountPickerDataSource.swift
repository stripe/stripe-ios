//
//  LinkLinkAccountPickerDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/13/23.
//

import Foundation
@_spi(STP) import StripeCore

protocol LinkAccountPickerDataSourceDelegate: AnyObject {
    func linkAccountPickerDataSource(
        _ dataSource: LinkAccountPickerDataSource,
        didSelectAccounts selectedAccounts: [FinancialConnectionsAccountTuple]
    )
}

protocol LinkAccountPickerDataSource: AnyObject {

    var delegate: LinkAccountPickerDataSourceDelegate? { get set }
    var manifest: FinancialConnectionsSessionManifest { get }
    var selectedAccounts: [FinancialConnectionsAccountTuple] { get }
    var nextPaneOnAddAccount: FinancialConnectionsSessionManifest.NextPane? { get set }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var dataAccessNotice: FinancialConnectionsDataAccessNotice? { get }

    func updateSelectedAccounts(_ selectedAccounts: [FinancialConnectionsAccountTuple])
    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse>
    func selectNetworkedAccounts(
        _ selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) -> Future<FinancialConnectionsInstitutionList>
}

final class LinkAccountPickerDataSourceImplementation: LinkAccountPickerDataSource {

    let manifest: FinancialConnectionsSessionManifest
    var nextPaneOnAddAccount: FinancialConnectionsSessionManifest.NextPane?
    let analyticsClient: FinancialConnectionsAnalyticsClient
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    private let consumerSession: ConsumerSessionData
    let dataAccessNotice: FinancialConnectionsDataAccessNotice?

    private(set) var selectedAccounts: [FinancialConnectionsAccountTuple] = [] {
        didSet {
            delegate?.linkAccountPickerDataSource(self, didSelectAccounts: selectedAccounts)
        }
    }
    weak var delegate: LinkAccountPickerDataSourceDelegate?

    init(
        manifest: FinancialConnectionsSessionManifest,
        apiClient: FinancialConnectionsAPIClient,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        clientSecret: String,
        consumerSession: ConsumerSessionData,
        dataAccessNotice: FinancialConnectionsDataAccessNotice?
    ) {
        self.manifest = manifest
        self.apiClient = apiClient
        self.analyticsClient = analyticsClient
        self.clientSecret = clientSecret
        self.consumerSession = consumerSession
        self.dataAccessNotice = dataAccessNotice
    }

    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse> {
        return apiClient.fetchNetworkedAccounts(
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSession.clientSecret
        )
        .chained { [weak self] response in
            self?.nextPaneOnAddAccount = response.nextPaneOnAddAccount
            return Promise(value: response)
        }
    }

    func updateSelectedAccounts(_ selectedAccounts: [FinancialConnectionsAccountTuple]) {
        self.selectedAccounts = selectedAccounts
    }

    func selectNetworkedAccounts(
        _ selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) -> Future<FinancialConnectionsInstitutionList> {
        return apiClient.selectNetworkedAccounts(
            selectedAccountIds: selectedAccounts.map({ $0.id }),
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSession.clientSecret
        )
    }
}
