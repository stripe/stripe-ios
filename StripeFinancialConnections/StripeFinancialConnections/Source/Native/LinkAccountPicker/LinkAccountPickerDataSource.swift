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
    var partnerToCoreAuths: [String: String]? { get set }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var dataAccessNotice: FinancialConnectionsDataAccessNotice? { get }
    var acquireConsentOnPrimaryCtaClick: Bool { get }

    func updateSelectedAccounts(_ selectedAccounts: [FinancialConnectionsAccountTuple])
    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse>
    func selectNetworkedAccounts(
        _ selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) -> Future<ShareNetworkedAccountsResponse>
    func markConsentAcquired() -> Future<FinancialConnectionsSessionManifest>
}

final class LinkAccountPickerDataSourceImplementation: LinkAccountPickerDataSource {

    let manifest: FinancialConnectionsSessionManifest
    var nextPaneOnAddAccount: FinancialConnectionsSessionManifest.NextPane?
    var partnerToCoreAuths: [String: String]?
    let analyticsClient: FinancialConnectionsAnalyticsClient
    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    private let consumerSession: ConsumerSessionData
    var dataAccessNotice: FinancialConnectionsDataAccessNotice? {
        var selectedAccountDataAccessNotice: FinancialConnectionsDataAccessNotice?
        if
            let networkedAccountsResponse,
            let returningNetworkingUserAccountPicker = networkedAccountsResponse.display?.text?.returningNetworkingUserAccountPicker,
            !selectedAccounts.isEmpty
        {
            // Bank accounts can have multiple types (ex. linked account, and manual entry account).
            //
            // Example output:
            // ["bctmacct", "csmrbankacct"]
            let selectedAccountTypes = Set(selectedAccounts
                .map({ $0.partnerAccount.id.split(separator: "_").first })
                .compactMap({ $0 }))
            if selectedAccountTypes.count > 1 {
                // if user selected multiple different account types,
                // present a special data access notice
                selectedAccountDataAccessNotice = returningNetworkingUserAccountPicker.multipleAccountTypesSelectedDataAccessNotice
            } else {
                // we get here if user selected:
                // 1) one account
                // 2) or, multiple accounts of the same account type
                selectedAccountDataAccessNotice = selectedAccounts.first?.accountPickerAccount.dataAccessNotice
            }
        }
        return selectedAccountDataAccessNotice ?? consentDataAccessNotice
    }
    private let consentDataAccessNotice: FinancialConnectionsDataAccessNotice?
    private var networkedAccountsResponse: FinancialConnectionsNetworkedAccountsResponse?
    var acquireConsentOnPrimaryCtaClick: Bool {
        return networkedAccountsResponse?.acquireConsentOnPrimaryCtaClick ?? false
    }

    private(set) var selectedAccounts: [FinancialConnectionsAccountTuple] = [] {
        didSet {
            delegate?.linkAccountPickerDataSource(self, didSelectAccounts: selectedAccounts)
        }
    }
    weak var delegate: LinkAccountPickerDataSourceDelegate?

    init(
        manifest: FinancialConnectionsSessionManifest,
        apiClient: any FinancialConnectionsAPI,
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
        self.consentDataAccessNotice = dataAccessNotice
    }

    func fetchNetworkedAccounts() -> Future<FinancialConnectionsNetworkedAccountsResponse> {
        return apiClient.fetchNetworkedAccounts(
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSession.clientSecret
        )
        .chained { [weak self] response in
            self?.networkedAccountsResponse = response
            self?.nextPaneOnAddAccount = response.nextPaneOnAddAccount
            self?.partnerToCoreAuths = response.partnerToCoreAuths
            return Promise(value: response)
        }
    }

    func updateSelectedAccounts(_ selectedAccounts: [FinancialConnectionsAccountTuple]) {
        self.selectedAccounts = selectedAccounts
    }

    func selectNetworkedAccounts(
        _ selectedAccounts: [FinancialConnectionsPartnerAccount]
    ) -> Future<ShareNetworkedAccountsResponse> {
        return apiClient.selectNetworkedAccounts(
            selectedAccountIds: selectedAccounts.map({ $0.id }),
            clientSecret: clientSecret,
            consumerSessionClientSecret: consumerSession.clientSecret,
            consentAcquired: acquireConsentOnPrimaryCtaClick
        )
    }

    func markConsentAcquired() -> Future<FinancialConnectionsSessionManifest> {
        return apiClient.markConsentAcquired(clientSecret: clientSecret)
    }
}
