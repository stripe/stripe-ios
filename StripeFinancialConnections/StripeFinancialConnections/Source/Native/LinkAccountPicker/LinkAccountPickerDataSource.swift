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
        didSelectAccount selectedAccountTuple: FinancialConnectionsAccountTuple?
    )
}

protocol LinkAccountPickerDataSource: AnyObject {

    var delegate: LinkAccountPickerDataSourceDelegate? { get set }
    var manifest: FinancialConnectionsSessionManifest { get }
    var selectedAccountTuple: FinancialConnectionsAccountTuple? { get }
    var nextPaneOnAddAccount: FinancialConnectionsSessionManifest.NextPane? { get set }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse>
    func selectNetworkedAccount(_ selectedAccount: FinancialConnectionsPartnerAccount) -> Future<FinancialConnectionsInstitutionList>
    func updateSelectedAccount(_ selectedAccountTuple: FinancialConnectionsAccountTuple)
}

final class LinkAccountPickerDataSourceImplementation: LinkAccountPickerDataSource {

    let manifest: FinancialConnectionsSessionManifest
    var nextPaneOnAddAccount: FinancialConnectionsSessionManifest.NextPane?
    let analyticsClient: FinancialConnectionsAnalyticsClient
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    private let consumerSession: ConsumerSessionData

    private(set) var selectedAccountTuple: FinancialConnectionsAccountTuple? {
        didSet {
            delegate?.linkAccountPickerDataSource(self, didSelectAccount: selectedAccountTuple)
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
        .chained { [weak self] response in
            self?.nextPaneOnAddAccount = response.nextPaneOnAddAccount
            return Promise(value: response)
        }
    }

    func updateSelectedAccount(_ selectedAccountTuple: FinancialConnectionsAccountTuple) {
        self.selectedAccountTuple = selectedAccountTuple
    }

    func selectNetworkedAccount(_ selectedAccount: FinancialConnectionsPartnerAccount) -> Future<FinancialConnectionsInstitutionList> {
        return apiClient.selectNetworkedAccounts(
            selectedAccountIds: [selectedAccount.id],
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSession.clientSecret
        )
    }
}
