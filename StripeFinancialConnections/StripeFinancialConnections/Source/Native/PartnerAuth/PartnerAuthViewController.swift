//
//  PartnerAuthViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/25/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol PartnerAuthViewControllerDelegate: AnyObject {
    func partnerAuthViewControllerUserDidSelectAnotherBank(_ viewController: PartnerAuthViewController)
    func partnerAuthViewControllerDidRequestToGoBack(_ viewController: PartnerAuthViewController)
    func partnerAuthViewControllerUserDidSelectEnterBankDetailsManually(_ viewController: PartnerAuthViewController)
    func partnerAuthViewController(_ viewController: PartnerAuthViewController, didReceiveTerminalError error: Error)
    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didCompleteWithAuthSession authSession: FinancialConnectionsAuthSession
    )
    func partnerAuthViewController(
        _ viewController: PartnerAuthViewController,
        didReceiveEvent event: FinancialConnectionsEvent
    )
}

final class PartnerAuthViewController: UIViewController {

    private let dataSource: PartnerAuthDataSource
    private let sharedPartnerAuthViewController: SharedPartnerAuthViewController

    private var institution: FinancialConnectionsInstitution {
        return dataSource.institution
    }
    weak var delegate: PartnerAuthViewControllerDelegate?

    init(dataSource: PartnerAuthDataSource) {
        self.dataSource = dataSource
        self.sharedPartnerAuthViewController = SharedPartnerAuthViewController(
            dataSource: dataSource.sharedPartnerAuthDataSource
        )
        super.init(nibName: nil, bundle: nil)
        sharedPartnerAuthViewController.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .customBackgroundColor

        addChild(sharedPartnerAuthViewController)
        view.addAndPinSubview(sharedPartnerAuthViewController.view)
        sharedPartnerAuthViewController.didMove(toParent: self)

        dataSource
            .analyticsClient
            .logPaneLoaded(pane: .partnerAuth)
        createAuthSession()
    }

    private func createAuthSession() {
        assertMainQueue()

        sharedPartnerAuthViewController.showEstablishingConnectionLoadingView(true)
        dataSource
            .createAuthSession()
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                // order is important so be careful of moving
                self.sharedPartnerAuthViewController.showEstablishingConnectionLoadingView(false)
                switch result {
                case .success(let authSession):
                    self.sharedPartnerAuthViewController.startWithAuthSession(authSession)
                case .failure(let error):
                    self.showErrorView(error)
                }
            }
    }

    private func showErrorView(_ error: Error) {
        // all Partner Auth errors hide the back button
        // and all errors end up in user having to exit
        // PartnerAuth to try again
        navigationItem.hidesBackButton = true

        let allowManualEntryInErrors = (dataSource.manifest.allowManualEntry && !dataSource.reduceManualEntryProminenceInErrors)
        let errorView: UIView?
        if let error = error as? StripeError,
            case .apiError(let apiError) = error,
            let extraFields = apiError.allResponseFields["extra_fields"] as? [String: Any],
            let institutionUnavailable = extraFields["institution_unavailable"] as? Bool,
            institutionUnavailable
        {
            let institutionIconView = InstitutionIconView(size: .large, showWarning: true)
            institutionIconView.setImageUrl(institution.icon?.default)
            let primaryButtonConfiguration = ReusableInformationView.ButtonConfiguration(
                title: String.Localized.select_another_bank,
                action: { [weak self] in
                    guard let self = self else { return }
                    self.delegate?.partnerAuthViewControllerUserDidSelectAnotherBank(self)
                }
            )
            if let expectedToBeAvailableAt = extraFields["expected_to_be_available_at"] as? TimeInterval {
                let expectedToBeAvailableDate = Date(timeIntervalSince1970: expectedToBeAvailableAt)
                let dateFormatter = DateFormatter()
                dateFormatter.timeStyle = .short
                let expectedToBeAvailableTimeString = dateFormatter.string(from: expectedToBeAvailableDate)
                errorView = ReusableInformationView(
                    iconType: .view(institutionIconView),
                    title: String(
                        format: STPLocalizedString(
                            "%@ is undergoing maintenance",
                            "Title of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."
                        ),
                        institution.name
                    ),
                    subtitle: {
                        let beginningOfSubtitle: String = {
                            if IsToday(expectedToBeAvailableDate) {
                                return String(
                                    format: STPLocalizedString(
                                        "Maintenance is scheduled to end at %@.",
                                        "The first part of a subtitle/description of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."
                                    ),
                                    expectedToBeAvailableTimeString
                                )
                            } else {
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateStyle = .short
                                let expectedToBeAvailableDateString = dateFormatter.string(
                                    from: expectedToBeAvailableDate
                                )
                                return String(
                                    format: STPLocalizedString(
                                        "Maintenance is scheduled to end on %@ at %@.",
                                        "The first part of a subtitle/description of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."
                                    ),
                                    expectedToBeAvailableDateString,
                                    expectedToBeAvailableTimeString
                                )
                            }
                        }()
                        let endOfSubtitle: String = {
                            if allowManualEntryInErrors {
                                return STPLocalizedString(
                                    "Please enter your bank details manually or select another bank.",
                                    "The second part of a subtitle/description of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."
                                )
                            } else {
                                return STPLocalizedString(
                                    "Please select another bank or try again later.",
                                    "The second part of a subtitle/description of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."
                                )
                            }
                        }()
                        return beginningOfSubtitle + " " + endOfSubtitle
                    }(),
                    primaryButtonConfiguration: primaryButtonConfiguration,
                    secondaryButtonConfiguration: allowManualEntryInErrors
                        ? ReusableInformationView.ButtonConfiguration(
                            title: String.Localized.enter_bank_details_manually,
                            action: { [weak self] in
                                guard let self = self else { return }
                                self.delegate?.partnerAuthViewControllerUserDidSelectEnterBankDetailsManually(self)
                            }
                        ) : nil
                )
                dataSource.analyticsClient.logExpectedError(
                    error,
                    errorName: "InstitutionPlannedDowntimeError",
                    pane: .partnerAuth
                )
            } else {
                errorView = ReusableInformationView(
                    iconType: .view(institutionIconView),
                    title: String(
                        format: STPLocalizedString(
                            "%@ is currently unavailable",
                            "Title of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."
                        ),
                        institution.name
                    ),
                    subtitle: {
                        if allowManualEntryInErrors {
                            return STPLocalizedString(
                                "Please enter your bank details manually or select another bank.",
                                "The subtitle/description of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."
                            )
                        } else {
                            return STPLocalizedString(
                                "Please select another bank or try again later.",
                                "The subtitle/description of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."
                            )
                        }
                    }(),
                    primaryButtonConfiguration: primaryButtonConfiguration,
                    secondaryButtonConfiguration: allowManualEntryInErrors
                        ? ReusableInformationView.ButtonConfiguration(
                            title: String.Localized.enter_bank_details_manually,
                            action: { [weak self] in
                                guard let self = self else { return }
                                self.delegate?.partnerAuthViewControllerUserDidSelectEnterBankDetailsManually(self)
                            }
                        ) : nil
                )
                dataSource.analyticsClient.logExpectedError(
                    error,
                    errorName: "InstitutionUnplannedDowntimeError",
                    pane: .partnerAuth
                )
            }
        } else {
            dataSource.analyticsClient.logUnexpectedError(
                error,
                errorName: "PartnerAuthError",
                pane: .partnerAuth
            )

            // if we didn't get specific errors back, we don't know
            // what's wrong, so show a generic error
            delegate?.partnerAuthViewController(self, didReceiveTerminalError: error)
            errorView = nil

            // keep showing the loading view while we transition to
            // terminal error
            sharedPartnerAuthViewController.showEstablishingConnectionLoadingView(true)
        }

        if let errorView = errorView {
            view.addAndPinSubviewToSafeArea(errorView)
        }
    }

    private func authorizeAuthSession(_ authSession: FinancialConnectionsAuthSession) {
        sharedPartnerAuthViewController.showConnectingToBankView(true)
        dataSource
            .authorizeAuthSession(authSession)
            .observe(on: .main) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let authSession):
                    self.delegate?.partnerAuthViewController(self, didCompleteWithAuthSession: authSession)

                    // hide the loading view after a delay to prevent
                    // the screen from flashing _while_ the transition
                    // to the next screen takes place
                    //
                    // note that it should be impossible to view this screen
                    // after a successful `authorizeAuthSession`, so
                    // calling `showEstablishingConnectionLoadingView(false)` is
                    // defensive programming anyway
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                        self?.sharedPartnerAuthViewController.showConnectingToBankView(false)
                    }
                case .failure(let error):
                    self.sharedPartnerAuthViewController.showConnectingToBankView(false) // important to come BEFORE showing error view so we avoid showing back button
                    self.showErrorView(error)
                    assert(self.navigationItem.hidesBackButton)
                }
            }
    }

    private func navigateBack() {
        delegate?.partnerAuthViewControllerDidRequestToGoBack(self)
    }
}

private func IsToday(_ comparisonDate: Date) -> Bool {
    return Calendar.current.startOfDay(for: comparisonDate) == Calendar.current.startOfDay(for: Date())
}

// MARK: - SharedPartnerAuthViewControllerDelegate

extension PartnerAuthViewController: SharedPartnerAuthViewControllerDelegate {

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didSucceedWithAuthSession authSession: FinancialConnectionsAuthSession,
        considerCallingAuthorize: Bool
    ) {
        if considerCallingAuthorize && authSession.isOauthNonOptional {
            // for OAuth flows, we need to fetch OAuth results
            authorizeAuthSession(authSession)
        } else {
            // for legacy flows (non-OAuth), we do not need to fetch OAuth results, or call authorize
            delegate?.partnerAuthViewController(self, didCompleteWithAuthSession: authSession)
        }
    }

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didCancelWithAuthSession authSession: FinancialConnectionsAuthSession,
        statusWasReturned: Bool
    ) {
        if statusWasReturned {
            dataSource.recordAuthSessionEvent(
                eventName: "cancel",
                authSessionId: authSession.id
            )

            // cancel current auth session
            dataSource.cancelPendingAuthSessionIfNeeded()

            // whether legacy or OAuth, we always go back
            // if we got an explicit cancel from backend
            navigateBack()
        } else { // no status was returned
            // cancel current auth session because something went wrong
            dataSource.cancelPendingAuthSessionIfNeeded()

            if authSession.isOauthNonOptional {
                // for OAuth institutions, we remain on the pre-pane,
                // but create a brand new auth session
                 createAuthSession()
            } else {
                // for legacy (non-OAuth) institutions, we navigate back to InstitutionPickerViewController
                navigateBack()
            }
        }
    }

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didFailWithAuthSession authSession: FinancialConnectionsAuthSession
    ) {
        // cancel current auth session
        dataSource.cancelPendingAuthSessionIfNeeded()

        // show a terminal error
        showErrorView(
            FinancialConnectionsSheetError.unknown(
                debugDescription: "Shim returned a failure."
            )
        )
    }

    func sharedPartnerAuthViewControllerDidRequestToGoBack(
        _ viewController: SharedPartnerAuthViewController
    ) {
        navigateBack()
    }

    func sharedPartnerAuthViewController(
        _ viewController: SharedPartnerAuthViewController,
        didReceiveError error: Error
    ) {
        showErrorView(error)
    }
}
