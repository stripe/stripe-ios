//
//  ErrorViewController.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 2/7/24.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

protocol ErrorViewControllerDelegate: AnyObject {
    func errorViewControllerDidSelectAnotherBank(_ viewController: ErrorViewController)
    func errorViewControllerDidSelectManualEntry(_ viewController: ErrorViewController)
    func errorViewController(
        _ viewController: ErrorViewController,
        didSelectCloseWithError error: Error
    )
}

/// Represents the VC for `unexpected_error` pane. It's used for
/// all types of errors and the naming of "unexpected_error" is just a
/// convention from old backend naming.
final class ErrorViewController: UIViewController {

    private let dataSource: ErrorDataSource
    private(set) var isTerminal = false

    weak var delegate: ErrorViewControllerDelegate?

    init(dataSource: ErrorDataSource) {
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

        let error = dataSource.error
        let allowManualEntryInNonTerminalErrors = (dataSource.manifest.allowManualEntry && !dataSource.reduceManualEntryProminenceInErrors)
        let errorView: UIView
        if let error = dataSource.error as? StripeError,
            case .apiError(let apiError) = error,
            let extraFields = apiError.allResponseFields["extra_fields"] as? [String: Any],
            let institutionUnavailable = extraFields["institution_unavailable"] as? Bool,
            institutionUnavailable
        {
            assert(
                dataSource.institution != nil,
                "expected institution to be set before handling institution errors"
            )

            let institutionIconView = InstitutionIconView()
            institutionIconView.setImageUrl(dataSource.institution?.icon?.default)
            let primaryButtonConfiguration = PaneLayoutView.ButtonConfiguration(
                title: String.Localized.select_another_bank,
                accessibilityIdentifier: "select_another_bank_button",
                action: { [weak self] in
                    guard let self else { return }
                    self.delegate?.errorViewControllerDidSelectAnotherBank(self)
                }
            )
            if let expectedToBeAvailableAt = extraFields["expected_to_be_available_at"] as? TimeInterval {
                let expectedToBeAvailableDate = Date(timeIntervalSince1970: expectedToBeAvailableAt)
                let dateFormatter = DateFormatter()
                dateFormatter.timeStyle = .short
                let expectedToBeAvailableTimeString = dateFormatter.string(from: expectedToBeAvailableDate)
                errorView = PaneLayoutView(
                    contentView: PaneLayoutView.createContentView(
                        iconView: institutionIconView,
                        title: String(
                            format: STPLocalizedString(
                                "%@ is undergoing maintenance",
                                "Title of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."
                            ),
                            dataSource.institution?.name ?? "Bank"
                        ),
                        subtitle: {
                            let beginningOfSubtitle: String = {
                                if isToday(expectedToBeAvailableDate) {
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
                                if allowManualEntryInNonTerminalErrors {
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
                        contentView: nil
                    ),
                    footerView: PaneLayoutView.createFooterView(
                        primaryButtonConfiguration: primaryButtonConfiguration,
                        secondaryButtonConfiguration: allowManualEntryInNonTerminalErrors
                        ? PaneLayoutView.ButtonConfiguration(
                            title: String.Localized.enter_bank_details_manually,
                            action: { [weak self] in
                                guard let self = self else { return }
                                self.delegate?.errorViewControllerDidSelectManualEntry(self)
                            }
                        ) : nil,
                        appearance: dataSource.manifest.appearance
                    ).footerView
                ).createView()
                dataSource.analyticsClient.logExpectedError(
                    error,
                    errorName: "InstitutionPlannedDowntimeError",
                    pane: dataSource.referrerPane
                )
            } else {
                errorView = PaneLayoutView(
                    contentView: PaneLayoutView.createContentView(
                        iconView: institutionIconView,
                        title: String(
                            format: STPLocalizedString(
                                "%@ is currently unavailable",
                                "Title of a screen that shows an error. The error indicates that the bank user selected is currently under maintenance."
                            ),
                            dataSource.institution?.name ?? "Bank"
                        ),
                        subtitle: {
                            if allowManualEntryInNonTerminalErrors {
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
                        contentView: nil
                    ),
                    footerView: PaneLayoutView.createFooterView(
                        primaryButtonConfiguration: primaryButtonConfiguration,
                        secondaryButtonConfiguration: allowManualEntryInNonTerminalErrors
                        ? PaneLayoutView.ButtonConfiguration(
                            title: String.Localized.enter_bank_details_manually,
                            action: { [weak self] in
                                guard let self else { return }
                                self.delegate?.errorViewControllerDidSelectManualEntry(self)
                            }
                        ) : nil,
                        appearance: dataSource.manifest.appearance
                    ).footerView
                ).createView()
                dataSource.analyticsClient.logExpectedError(
                    error,
                    errorName: "InstitutionUnplannedDowntimeError",
                    pane: dataSource.referrerPane
                )
            }
        } else {
            isTerminal = true

            dataSource.analyticsClient.logUnexpectedError(
                error,
                errorName: "UnexpectedErrorPaneError",
                pane: dataSource.referrerPane
            )

            // if we didn't get specific errors back, we don't know
            // what's wrong, so show a generic error
            errorView = TerminalErrorView(
                allowManualEntry: dataSource.manifest.allowManualEntry,
                appearance: dataSource.manifest.appearance,
                didSelectManualEntry: { [weak self] in
                    guard let self else { return }
                    self.delegate?.errorViewControllerDidSelectManualEntry(self)
                },
                didSelectClose: { [weak self] in
                    guard let self else { return }
                    self.delegate?.errorViewController(self, didSelectCloseWithError: error)
                }
            )
        }

        view.addAndPinSubview(errorView)
    }
}

private func isToday(_ comparisonDate: Date) -> Bool {
    return Calendar.current.startOfDay(for: comparisonDate) == Calendar.current.startOfDay(for: Date())
}
