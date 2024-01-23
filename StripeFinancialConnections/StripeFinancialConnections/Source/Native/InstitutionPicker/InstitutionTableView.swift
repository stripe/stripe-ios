//
//  InstitutionTableView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 11/28/23.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

private enum Section {
    case main
}

protocol InstitutionTableViewDelegate: AnyObject {
    func institutionTableView(
        _ tableView: InstitutionTableView,
        didSelectInstitution institution: FinancialConnectionsInstitution
    )
    func institutionTableViewDidSelectSearchForMoreBanks(_ tableView: InstitutionTableView)
    func institutionTableView(
        _ tableView: InstitutionTableView,
        didSelectManuallyAddYourAccountWithInstitutions institutions: [FinancialConnectionsInstitution]
    )
    func institutionTableView(
        _ tableView: InstitutionTableView,
        didScrollInstitutions institutions: [FinancialConnectionsInstitution]
    )
}

final class InstitutionTableView: UIView {

    private let allowManualEntry: Bool
    private let tableView: UITableView
    private let dataSource: UITableViewDiffableDataSource<Section, FinancialConnectionsInstitution>
    private lazy var didSelectManualEntry: (() -> Void)? = {
        return allowManualEntry
            ? { [weak self] in
                guard let self = self else { return }
                self.delegate?.institutionTableView(
                    self,
                    didSelectManuallyAddYourAccountWithInstitutions: self.institutions
                )
            } : nil
    }()
    weak var delegate: InstitutionTableViewDelegate?
    private var institutions: [FinancialConnectionsInstitution] = []
    private var shouldLogScroll = true

    private lazy var manualEntryTableFooterView: InstitutionTableFooterView = {
        let manualEntryTableFooterView = InstitutionTableFooterView(
            title: STPLocalizedString(
                "Can't find your bank?",
                "The title of a button that appears at the bottom of search results. It appears when a user is searching for their bank. The purpose of the button is to give users the option to enter their bank account numbers manually (ex. routing and account number)."
            ),
            subtitle: STPLocalizedString(
                "Manually enter details",
                "The subtitle of a button that appears at the bottom of search results. It appears when a user is searching for their bank. The purpose of the button is to give users the option to enter their bank account numbers manually (ex. routing and account number)."
            ),
            image: .add,
            didSelect: { [weak self] in
                guard let self = self else { return }
                self.delegate?.institutionTableView(
                    self,
                    didSelectManuallyAddYourAccountWithInstitutions: self.institutions
                )
            }
        )
        return manualEntryTableFooterView
    }()
    private lazy var searchMoreBanksTableFooterView: InstitutionTableFooterView = {
        let manualEntryTableFooterView = InstitutionTableFooterView(
            title: STPLocalizedString(
                "Search for more banks",
                "The title of a button that appears at the bottom of a list of banks. The purpose of the button is to give users the option to search for more banks than we feature in the initial list of banks (where only the most popular ones will appear)."
            ),
            subtitle: nil,
            image: .search,
            didSelect: { [weak self] in
                guard let self = self else { return }
                self.delegate?.institutionTableViewDidSelectSearchForMoreBanks(self)
            }
        )
        return manualEntryTableFooterView
    }()
    private lazy var loadingContainerView: UIView = {
        let loadingContainerView = UIView()
        loadingContainerView.backgroundColor = .customBackgroundColor
        loadingContainerView.isHidden = true
        return loadingContainerView
    }()
    private lazy var loadingView: ActivityIndicator = {
        let activityIndicator = ActivityIndicator(size: .large)
        activityIndicator.color = .textDisabled
        activityIndicator.backgroundColor = .customBackgroundColor
        return activityIndicator
    }()

    init(frame: CGRect, allowManualEntry: Bool) {
        self.allowManualEntry = allowManualEntry
        let cellIdentifier = "\(InstitutionTableViewCell.self)"
        tableView = UITableView(frame: frame)
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, _, institution in
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
                    as? InstitutionTableViewCell
            else {
                fatalError(
                    "Unable to dequeue cell \(InstitutionTableViewCell.self) with cell identifier \(cellIdentifier)"
                )
            }
            cell.customize(with: institution)
            return cell
        }
        dataSource.defaultRowAnimation = .fade

        super.init(frame: frame)
        tableView.backgroundColor = .customBackgroundColor
        tableView.separatorInset = .zero
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        tableView.contentInset = UIEdgeInsets(
            // add extra inset at the top/bottom to show the cell-selected-state separators
            top: 1.0 / UIScreen.main.nativeScale,
            left: 0,
            bottom: 1.0 / UIScreen.main.nativeScale,
            right: 0
        )
        tableView.keyboardDismissMode = .onDrag
        tableView.register(InstitutionTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.delegate = self
        addAndPinSubview(tableView)

        addAndPinSubview(loadingContainerView)
        loadingContainerView.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            // pin loading view to the top so it doesn't get blocked by keyboard
            loadingView.topAnchor.constraint(equalTo: loadingContainerView.topAnchor),
            loadingView.leadingAnchor.constraint(equalTo: loadingContainerView.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: loadingContainerView.trailingAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // `UITableView` does not automatically resize `tableHeaderView`
        // so here we do it manually
        if let tableHeaderView = tableView.tableHeaderView {
            let tableHeaderViewSize = tableHeaderView.systemLayoutSizeFitting(
                CGSize(
                    width: tableView.bounds.size.width,
                    height: UIView.layoutFittingCompressedSize.height
                )
            )
            if tableHeaderView.frame.size.height != tableHeaderViewSize.height {
                tableHeaderView.frame.size.height = tableHeaderViewSize.height
                tableView.tableHeaderView = tableHeaderView
            }
        }

        // `UITableView` does not automatically resize `tableFooterView`
        // so here we do it manually
        if let tableFooterView = tableView.tableFooterView {
            let tableFooterViewSize = tableFooterView.systemLayoutSizeFitting(
                CGSize(
                    width: tableView.bounds.size.width,
                    height: UIView.layoutFittingCompressedSize.height
                )
            )
            if tableFooterView.frame.size.height != tableFooterViewSize.height {
                tableFooterView.frame.size.height = tableFooterViewSize.height
                tableView.tableFooterView = tableFooterView
            }
        }
    }

    func load(
        institutions: [FinancialConnectionsInstitution],
        isUserSearching: Bool,
        showManualEntry: Bool? = nil
    ) {
        assertMainQueue()
        self.institutions = institutions
        shouldLogScroll = true

        var snapshot = NSDiffableDataSourceSnapshot<Section, FinancialConnectionsInstitution>()
        snapshot.appendSections([Section.main])
        snapshot.appendItems(institutions, toSection: Section.main)
        dataSource.apply(snapshot, animatingDifferences: true, completion: nil)

        // clear state (some of this is defensive programming)
        showError(false, isUserSearching: isUserSearching)
        
        if isUserSearching {
            if institutions.isEmpty {
                showTableFooterView(
                    true,
                    view: InstitutionNoResultsView(
                        didSelectManuallyEnterDetails: self.allowManualEntry ? { [weak self] in
                            guard let self = self else { return }
                            self.delegate?.institutionTableView(
                                self,
                                didSelectManuallyAddYourAccountWithInstitutions: []
                            )
                        } : nil
                    )
                )
            } else {
                if allowManualEntry, showManualEntry == true {
                    showTableFooterView(true, view: manualEntryTableFooterView)
                } else {
                    showTableFooterView(false, view: nil)
                }
            }
        } else {
            showTableFooterView(true, view: searchMoreBanksTableFooterView)
        }
    }

    func showLoadingView(_ show: Bool) {
        loadingContainerView.isHidden = !show
        if show {
            // do not call `startAnimating` if already animating because
            // it will cause an animation glitch otherwise
            if !loadingView.isAnimating {
                loadingView.startAnimating()
            }
        } else {
            loadingView.stopAnimating()
        }
        bringSubviewToFront(loadingContainerView)  // defensive programming to avoid loadingView being hiddden
    }

    func showError(_ showError: Bool, isUserSearching: Bool) {
        if showError {
            if allowManualEntry {
                showTableFooterView(true, view: manualEntryTableFooterView)
            } else {
                if !isUserSearching {
                    showTableFooterView(true, view: searchMoreBanksTableFooterView)
                }
            }
        } else {
            if !isUserSearching {
                showTableFooterView(true, view: searchMoreBanksTableFooterView)
            }
        }
    }
    
    // the footer is always shown, except for when there is an error searching
    private func showTableFooterView(_ show: Bool, view: UIView?) {
        if show, let view = view {
            tableView.setTableFooterViewWithCompressedFrameSize(view)
        } else {
            tableView.tableFooterView = nil
        }
    }
}

// MARK: - UITableViewDelegate

extension InstitutionTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let institution = dataSource.itemIdentifier(for: indexPath) {
            delegate?.institutionTableView(self, didSelectInstitution: institution)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Every time the institutions change, we are open to sending the event again
        if shouldLogScroll {
            shouldLogScroll = false

            delegate?.institutionTableView(
                self,
                didScrollInstitutions: institutions
            )
        }
    }
}
