//
//  AccountPickerDataSource.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 8/5/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol AccountPickerDataSourceDelegate: AnyObject {
    func accountPickerDataSource(
        _ dataSource: AccountPickerDataSource,
        didSelectAccounts selectedAccounts: [FinancialConnectionsPartnerAccount]
    )
}

protocol AccountPickerDataSource: AnyObject {

    var delegate: AccountPickerDataSourceDelegate? { get set }
    var manifest: FinancialConnectionsSessionManifest { get }
    var accountPickerPane: FinancialConnectionsAccountPickerPane? { get }
    var authSession: FinancialConnectionsAuthSession { get }
    var institution: FinancialConnectionsInstitution { get }
    var selectedAccounts: [FinancialConnectionsPartnerAccount] { get }
    var analyticsClient: FinancialConnectionsAnalyticsClient { get }
    var reduceManualEntryProminenceInErrors: Bool { get }
    var dataAccessNotice: FinancialConnectionsDataAccessNotice? { get }
    var consumerSessionClientSecret: String? { get }

    func pollAuthSessionAccounts() -> Future<FinancialConnectionsAuthSessionAccounts>
    func updateSelectedAccounts(_ selectedAccounts: [FinancialConnectionsPartnerAccount])
    func selectAuthSessionAccounts() -> Promise<FinancialConnectionsAuthSessionAccounts>
    func saveToLink(
        accounts: [FinancialConnectionsPartnerAccount],
        consumerSessionClientSecret: String
    ) -> Future<String?>
}

final class AccountPickerDataSourceImplementation: AccountPickerDataSource {

    private let apiClient: any FinancialConnectionsAPI
    private let clientSecret: String
    let accountPickerPane: FinancialConnectionsAccountPickerPane?
    let authSession: FinancialConnectionsAuthSession
    let manifest: FinancialConnectionsSessionManifest
    let institution: FinancialConnectionsInstitution
    let analyticsClient: FinancialConnectionsAnalyticsClient
    let reduceManualEntryProminenceInErrors: Bool
    let dataAccessNotice: FinancialConnectionsDataAccessNotice?
    let consumerSessionClientSecret: String?
    private let isRelink: Bool

    private(set) var selectedAccounts: [FinancialConnectionsPartnerAccount] = [] {
        didSet {
            delegate?.accountPickerDataSource(self, didSelectAccounts: selectedAccounts)
        }
    }
    weak var delegate: AccountPickerDataSourceDelegate?

    init(
        apiClient: any FinancialConnectionsAPI,
        clientSecret: String,
        accountPickerPane: FinancialConnectionsAccountPickerPane?,
        authSession: FinancialConnectionsAuthSession,
        manifest: FinancialConnectionsSessionManifest,
        institution: FinancialConnectionsInstitution,
        analyticsClient: FinancialConnectionsAnalyticsClient,
        reduceManualEntryProminenceInErrors: Bool,
        dataAccessNotice: FinancialConnectionsDataAccessNotice?,
        consumerSessionClientSecret: String?,
        isRelink: Bool
    ) {
        self.apiClient = apiClient
        self.clientSecret = clientSecret
        self.accountPickerPane = accountPickerPane
        self.authSession = authSession
        self.manifest = manifest
        self.institution = institution
        self.analyticsClient = analyticsClient
        self.reduceManualEntryProminenceInErrors = reduceManualEntryProminenceInErrors
        self.dataAccessNotice = dataAccessNotice
        self.consumerSessionClientSecret = consumerSessionClientSecret
        self.isRelink = isRelink
    }

    func pollAuthSessionAccounts() -> Future<FinancialConnectionsAuthSessionAccounts> {
        return apiClient.fetchAuthSessionAccounts(
            clientSecret: clientSecret,
            authSessionId: authSession.id,
            initialPollDelay: AuthSessionAccountsInitialPollDelay(forFlow: authSession.flow)
        )
    }

    func updateSelectedAccounts(_ selectedAccounts: [FinancialConnectionsPartnerAccount]) {
        self.selectedAccounts = selectedAccounts
    }

    func selectAuthSessionAccounts() -> Promise<FinancialConnectionsAuthSessionAccounts> {
        return apiClient.selectAuthSessionAccounts(
            clientSecret: clientSecret,
            authSessionId: authSession.id,
            selectedAccountIds: selectedAccounts.map({ $0.id })
        )
    }

    func saveToLink(
        accounts: [FinancialConnectionsPartnerAccount],
        consumerSessionClientSecret: String
    ) -> Future<String?> {
        let shouldPollAccounts = !manifest.shouldAttachLinkedPaymentMethod
        assert(
            shouldPollAccounts,
            "expected to only save accounts to link for non-payment flows"
        )
        return apiClient.saveAccountsToNetworkAndLink(
            shouldPollAccounts: shouldPollAccounts,
            selectedAccounts: accounts,
            emailAddress: nil,
            phoneNumber: nil,
            country: nil,
            consumerSessionClientSecret: consumerSessionClientSecret,
            clientSecret: clientSecret,
            isRelink: isRelink
        )
        .chained { (_, customSuccessPaneMessage) in
            return Promise(value: customSuccessPaneMessage)
        }
    }
}

private func AuthSessionAccountsInitialPollDelay(
    forFlow flow: FinancialConnectionsAuthSession.Flow?
) -> TimeInterval {
    let defaultInitialPollDelay: TimeInterval = 1.75
    guard let flow = flow else {
        return defaultInitialPollDelay
    }
    switch flow {
    case .testmode:
        fallthrough
    case .testmodeOauth:
        fallthrough
    case .testmodeOauthWebview:
        fallthrough
    case .finicityConnectV2Lite:
        // Post auth flow, Finicity non-OAuth account retrieval latency is extremely quick - p90 < 1sec.
        return 0
    case .mxConnect:
        // 10 account retrieval latency on MX non-OAuth sessions is currently 460 ms
        return 0.5
    default:
        return defaultInitialPollDelay
    }
}
