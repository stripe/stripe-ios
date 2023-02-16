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
        didSelectAccount selectedAccount: FinancialConnectionsPartnerAccount?
    )
}

protocol LinkAccountPickerDataSource: AnyObject {

    var delegate: LinkAccountPickerDataSourceDelegate? { get set }
    var manifest: FinancialConnectionsSessionManifest { get }
    var selectedAccount: FinancialConnectionsPartnerAccount? { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }

    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse>
    func selectNetworkedAccount(_ selectedAccount: FinancialConnectionsPartnerAccount) -> Future<FinancialConnectionsInstitutionList>
    func updateSelectedAccount(_ selectedAccount: FinancialConnectionsPartnerAccount)
}

final class LinkAccountPickerDataSourceImplementation: LinkAccountPickerDataSource {

    let manifest: FinancialConnectionsSessionManifest
    let analyticsClient: FinancialConnectionsAnalyticsClient
    private let apiClient: FinancialConnectionsAPIClient
    private let clientSecret: String
    private let consumerSession: ConsumerSessionData

    private(set) var selectedAccount: FinancialConnectionsPartnerAccount? {
        didSet {
            delegate?.linkAccountPickerDataSource(self, didSelectAccount: selectedAccount)
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

    func updateSelectedAccount(_ selectedAccount: FinancialConnectionsPartnerAccount) {
        self.selectedAccount = selectedAccount
    }

    func selectNetworkedAccount(_ selectedAccount: FinancialConnectionsPartnerAccount) -> Future<FinancialConnectionsInstitutionList> {
        return apiClient.selectNetworkedAccounts(
            selectedAccountIds: [selectedAccount.id],
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSession.clientSecret
        )
    }
}
