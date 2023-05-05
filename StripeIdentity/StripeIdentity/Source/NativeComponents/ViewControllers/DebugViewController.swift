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
        debugView.delegate = self
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

    func didTapButton(_ type: DebugView.DebugButton) {
        switch type {
        case .submit(let completeOption):
            switch completeOption {
            case .success:
                self.sheetController?.verifyAndTransition(simulateDelay: false)
            case .failure:
                self.sheetController?.unverifyAndTransition(simulateDelay: false)
            case .successAsync:
                self.sheetController?.verifyAndTransition(simulateDelay: true)
            case .failureAsync:
                self.sheetController?.unverifyAndTransition(simulateDelay: true)
            }
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

@available(iOSApplicationExtension, unavailable)
extension DebugViewController: DebugViewDelegate {
    func debugOptionsDidChange() {
        self.updateUI()
    }
}
