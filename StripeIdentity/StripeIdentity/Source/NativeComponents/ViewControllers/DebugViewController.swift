//
//  DebugViewController.swift
//  StripeIdentity
//
//  Created by Chen Cen on 4/17/23.
//

import Foundation
@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
final class DebugViewController: IdentityFlowViewController {
    private let debugView = DebugView()
    init(
        sheetController: VerificationSheetControllerProtocol
    ) {
        super.init(
            sheetController: sheetController, analyticsScreenName: .debug, shouldShowCancelButton: false
        )
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateUI()
    }

    func updateUI() {
        debugView.configure(with: .init(didTapButton: { [weak self] buttonType in
            self?.didTapButton(buttonType)
        }))
        configure(backButtonTitle: nil, viewModel: .init(headerViewModel: nil, contentView: debugView, buttons: []))
    }

    private func didTapButton(_ type: DebugView.DebugButton) {
        switch type {
        case .completed:
            finishWithResult(result: .flowCompleted)
        case .cancelled:
            finishWithResult(result: .flowCanceled)
        case .failed:
            finishWithResult(result: .flowFailed(error: IdentityVerificationSheetError.testModeSampleError))
        case .preview:
            self.sheetController?.loadAndUpdateUI(skipTestMode: true)
        }
    }

    private func finishWithResult(result: IdentityVerificationSheet.VerificationFlowResult) {
        sheetController?.overrideTestModeReturnValue(result: result)
        dismiss(animated: true)
    }
}

extension StripeUICore.Button {
    fileprivate convenience init(
        title: String,
        target: Any?,
        action: Selector
    ) {
        self.init()
        self.title = title
        addTarget(target, action: action, for: .touchUpInside)
        self.configuration = .identityPrimary()
    }
}
