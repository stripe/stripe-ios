//
//  IndividualViewController.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 9/23/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

@_spi(STP) import StripeUICore
import UIKit

@available(iOSApplicationExtension, unavailable)
final class IndividualViewController: IdentityFlowViewController {

    let individualContent: StripeAPI.VerificationPageStaticContentIndividualPage

    let individualElement: IndividualFormElement

    let missing: Set<StripeAPI.VerificationPageFieldType>

    private var isSaving = false {
        didSet {
            updateUI()
        }
    }

    init(
        individualContent: StripeAPI.VerificationPageStaticContentIndividualPage,
        missing: Set<StripeAPI.VerificationPageFieldType>,
        sheetController: VerificationSheetControllerProtocol
    ) {
        self.individualContent = individualContent
        self.missing = missing.intersection([.name, .dob, .idNumber, .address])
        individualElement = IndividualFormElement(
            individualContent: individualContent,
            missing: missing,
            countryNotListedButtonClicked: { missingType in
                sheetController.transitionToCountryNotListed(
                    missingType: missingType
                )
            }
        )
        super.init(sheetController: sheetController, analyticsScreenName: .individual)
        individualElement.delegate = self

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
        configure(
            backButtonTitle: STPLocalizedString(
                "Personal Information",
                "Back button title for returning to the individual's perssonal infomation screen"
            ),
            viewModel: .init(
                headerViewModel: .init(
                    backgroundColor: .systemBackground,
                    headerType: .plain,
                    titleText: individualContent.title
                ),
                contentView: individualElement.view,
                buttonText: individualContent.buttonText,
                state: isSaving ? .loading : (individualElement.hasValidInput ? .enabled : .disabled),
                didTapButton: { [weak self] in
                    self?.isSaving = true
                    let collectedData = self?.individualElement.collectedData
                    self?.sheetController?.saveAndTransition(from: .individual, collectedData: collectedData!) {
                        self?.isSaving = false
                    }
                }
            )
        )
    }
}

// MARK: - IdentityDataCollecting
@available(iOSApplicationExtension, unavailable)
extension IndividualViewController: IdentityDataCollecting {
    var collectedFields: Set<StripeAPI.VerificationPageFieldType> {
        return self.missing
    }
}

// MARK: - ElementDelegate
@available(iOSApplicationExtension, unavailable)
extension IndividualViewController: ElementDelegate {
    func didUpdate(element: Element) {
        self.updateUI()
    }

    func continueToNextField(element: Element) {
        // no-op
    }
}
