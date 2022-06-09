//
//  AuthFlowDataManager.swift
//  StripeFinancialConnections
//
//  Created by Vardges Avetisyan on 6/7/22.
//

import Foundation
@_spi(STP) import StripeCore

protocol AuthFlowDataManager {
    var manifest: FinancialConnectionsSessionManifest { get }
    func setDelegate(delegate: AuthFlowDataManagerDelegate?)

    // MARK: - Mutating Calls
    
    func consentAcquired()
}

protocol AuthFlowDataManagerDelegate: AnyObject {
    func authFlowDataManagerDidUpdateManifest(_ dataManager: AuthFlowDataManager)
    func authFlow(dataManager: AuthFlowDataManager,
                  failedToUpdateManifest error: Error)
}

class AuthFlowAPIDataManager: AuthFlowDataManager {

    // MARK: - Properties
    weak var delegate: AuthFlowDataManagerDelegate?
    private(set) var manifest: FinancialConnectionsSessionManifest {
        didSet {
            delegate?.authFlowDataManagerDidUpdateManifest(self)
        }
    }
    private let api: FinancialConnectionsAPIClient
    private let clientSecret: String

    // MARK: - Init
    
    init(with initial: FinancialConnectionsSessionManifest,
         api: FinancialConnectionsAPIClient,
         clientSecret: String) {
        self.manifest = initial
        self.api = api
        self.clientSecret = clientSecret
    }

    // MARK: - FlowDataManager
    
    func setDelegate(delegate: AuthFlowDataManagerDelegate?) {
        self.delegate = delegate
    }

    func consentAcquired() {
        api.markConsentAcquired(clientSecret: clientSecret)
            .observe(on: nil) { [weak self] result in
                guard let self = self else { return }
                switch(result) {
                case .failure(let error):
                    self.delegate?.authFlow(dataManager: self, failedToUpdateManifest: error)
                case .success(let manifest):
                    self.manifest = manifest
                }
        }
    }
}
