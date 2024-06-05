//
//  SelfieWelcomeViewController.swift
//  StripeIdentity
//
//  Created by Chen Cen on 8/15/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

final class SelfieWarmupViewController: IdentityFlowViewController {
    let flowViewModel: IdentityFlowView.ViewModel

    init(
        sheetController: VerificationSheetControllerProtocol
    ) throws {
        flowViewModel = .init(
            headerViewModel: nil,
            contentView: SelfieWarmupView(),
            buttonText: String.Localized.continue,
            state: .enabled,
            didTapButton: {
                sheetController.transitionToSelfieCapture()
            }
        )
        super.init(sheetController: sheetController, analyticsScreenName: .selfieWarmup)
        configure(
            backButtonTitle: nil,
            viewModel: flowViewModel
        )
    }

    required init?(
        coder: NSCoder
    ) {
        fatalError("init(coder:) has not been implemented")
    }

}
