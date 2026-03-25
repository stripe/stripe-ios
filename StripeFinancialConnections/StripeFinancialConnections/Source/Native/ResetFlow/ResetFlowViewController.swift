//
//  LinkMoreAccounts.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 9/2/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol ResetFlowViewControllerDelegate: AnyObject {
    func resetFlowViewController(
        _ viewController: ResetFlowViewController,
        didSucceedWithManifest manifest: FinancialConnectionsSessionManifest
    )
    func resetFlowViewController(
        _ viewController: ResetFlowViewController,
        didFailWithError error: Error
    )
}

// Used in at least two scenarios:
// 1) User presses "Link another account" in Consent Pane
// 2) User selects "Select another bank" in an Error screen from Institution Picker
final class ResetFlowViewController: UIViewController {

    private let dataSource: ResetFlowDataSource

    weak var delegate: ResetFlowViewControllerDelegate?

    init(dataSource: ResetFlowDataSource) {
        self.dataSource = dataSource
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = FinancialConnectionsAppearance.Colors.background
        navigationItem.hidesBackButton = true

        dataSource
            .analyticsClient
            .logPaneLoaded(pane: .resetFlow)

        let loadingView = SpinnerView(appearance: dataSource.manifest.appearance)
        view.addAndPinSubviewToSafeArea(loadingView)

        dataSource.markLinkingMoreAccounts()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let manifest):
                    self.delegate?.resetFlowViewController(self, didSucceedWithManifest: manifest)
                case .failure(let error):
                    self.dataSource
                        .analyticsClient
                        .logUnexpectedError(
                            error,
                            errorName: "ResetFlowLinkMoreAccountsError",
                            pane: .resetFlow
                        )
                    self.delegate?.resetFlowViewController(self, didFailWithError: error)
                }
            }
    }
}
