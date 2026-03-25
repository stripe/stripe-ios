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
    private let institutionSearchDisabled: Bool
    private let appearance: FinancialConnectionsAppearance
    let tableView: UITableView
    private let dataSource: UITableViewDiffableDataSource<Section, FinancialConnectionsInstitution>
    weak var delegate: InstitutionTableViewDelegate?
    // the sticky header view for section 0 of the table view
    weak var searchBarContainerView: UIView? {
        didSet {
            // as soon as the search bar is set, we want to
            // force-layout the UITableView so it lays out
            // the header that contains the search bar;
            //
            // correct search bar layout is important to
            // position the loading view
            tableView.reloadData()
        }
    }
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
            appearance: appearance,
            didSelect: { [weak self] in
                guard let self = self else { return }
                FeedbackGeneratorAdapter.buttonTapped()
                self.delegate?.institutionTableView(
                    self,
                    didSelectManuallyAddYourAccountWithInstitutions: self.institutions
                )
            }
        )
        return manualEntryTableFooterView
    }()
    private lazy var searchMoreBanksTableFooterView: InstitutionTableFooterView? = {
        if institutionSearchDisabled {
            return nil
        } else {
            let manualEntryTableFooterView = InstitutionTableFooterView(
                title: STPLocalizedString(
                    "Search for more banks",
                    "The title of a button that appears at the bottom of a list of banks. The purpose of the button is to give users the option to search for more banks than we feature in the initial list of banks (where only the most popular ones will appear)."
                ),
                subtitle: nil,
                image: .search,
                appearance: appearance,
                didSelect: { [weak self] in
                    guard let self = self else { return }
                    FeedbackGeneratorAdapter.buttonTapped()
                    self.delegate?.institutionTableViewDidSelectSearchForMoreBanks(self)
                }
            )
            return manualEntryTableFooterView
        }
    }()
    private var loadingView: UIView?
    private var lastTableViewWidthForSearchBarSizing: CGFloat?

    init(
        frame: CGRect,
        allowManualEntry: Bool,
        institutionSearchDisabled: Bool,
        appearance: FinancialConnectionsAppearance
    ) {
        self.allowManualEntry = allowManualEntry
        self.institutionSearchDisabled = institutionSearchDisabled
        self.appearance = appearance
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
            cell.customize(with: institution, appearance: appearance)
            return cell
        }
        dataSource.defaultRowAnimation = .fade
        super.init(frame: frame)
        tableView.backgroundColor = FinancialConnectionsAppearance.Colors.background
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
        if #available(iOS 15.0, *) {
            // do not set this because it can cause unexpected
            // scrolling behavior
            tableView.sectionHeaderTopPadding = 0
        }
        tableView.register(InstitutionTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.delegate = self
        addAndPinSubview(tableView)
        // calling `load` activates the `UITableView` data source
        // by appening a section, which in turn will display
        // the section header (which contains the search bar)
        load(institutions: [], isUserSearching: false)
        showLoadingView(false)
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

        // resize loading view to always be below header view
        let loadingViewY: CGFloat
        if let searchBarContainerView = searchBarContainerView {
            let searchBarContainerViewFrame = searchBarContainerView.convert(
                searchBarContainerView.bounds,
                to: self
            )
            loadingViewY = searchBarContainerViewFrame.maxY
        } else if let tableHeaderView = tableView.tableHeaderView {
            let headerFrame = tableHeaderView.convert(tableHeaderView.bounds, to: self)
            loadingViewY = headerFrame.maxY
        } else {
            loadingViewY = 0
        }
        loadingView?.frame = CGRect(
            x: 0,
            y: loadingViewY,
            width: bounds.width,
            height: bounds.height - loadingViewY
        )
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
        dataSource.apply(snapshot, animatingDifferences: false, completion: nil)

        // clear state (some of this is defensive programming)
        showError(false, isUserSearching: isUserSearching)

        if isUserSearching {
            if institutions.isEmpty {
                showTableFooterView(
                    true,
                    view: InstitutionNoResultsView(
                        appearance: appearance,
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
        if show {
            if loadingView?.superview == nil {
                let loadingView = InstitutionTableLoadingView()
                addAndPinSubviewToSafeArea(loadingView)
                self.loadingView = loadingView
            }
        } else {
            loadingView?.removeFromSuperview()
            loadingView = nil
        }

        // ensure the loading view is resized to account for header view
        setNeedsLayout()
        layoutIfNeeded()
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

    func setTableHeaderView(_ tableHeaderView: UIView?) {
        if let tableHeaderView {
            tableView.setTableHeaderViewWithCompressedFrameSize(tableHeaderView)
        } else {
            tableView.tableHeaderView = nil
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

    func showLoadingView(
        _ show: Bool,
        forInstitution institution: FinancialConnectionsInstitution
    ) {
        guard
            let index = institutions.firstIndex(where: { $0.id == institution.id }),
            let loadingCell = tableView.cellForRow(
                at: IndexPath(row: index, section: 0)
            ) as? InstitutionTableViewCell
        else {
            return
        }
        loadingCell.showLoadingView(show)
    }

    /// Grays out all visible rows except the one with `institution`.
    func showOverlayView(
        _ show: Bool,
        exceptForInstitution institution: FinancialConnectionsInstitution? = nil
    ) {
        let exceptInstitutionCell: UITableViewCell? = {
            if
                let institution,
                let index = institutions.firstIndex(where: { $0.id == institution.id }),
                let cell = tableView.cellForRow(
                    at: IndexPath(row: index, section: 0)
                )
            {
                return cell
            } else {
                return nil
            }
        }()

        tableView
            .visibleCells
            .forEach { visibleCell in
                guard
                    let visibleCell = visibleCell as? InstitutionTableViewCell,
                    visibleCell !== exceptInstitutionCell
                else {
                    return
                }
                visibleCell.showOverlayView(show)
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

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section == 0 else {
            return nil
        }
        return searchBarContainerView
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section == 0 else {
            return 0
        }
        guard let searchBarContainerView = searchBarContainerView else {
            return 0
        }
        let width = tableView.bounds.width
        // `lastTableViewWidthForSearchBarSizing` fixes an issue
        // where resizing the searchBar sometimes caused a layout
        // glitch each time a search character was inputted
        // this logic ensures that we resize search bar only
        // when needed
        guard lastTableViewWidthForSearchBarSizing != width else {
            return searchBarContainerView.bounds.height
        }
        lastTableViewWidthForSearchBarSizing = width

        searchBarContainerView.frame = CGRect(
            origin: searchBarContainerView.frame.origin,
            size: CGSize(width: width, height: 100)
        )
        searchBarContainerView.layoutSubviews()
        searchBarContainerView.layoutIfNeeded()
        let size = searchBarContainerView.systemLayoutSizeFitting(
            CGSize(width: width, height: .greatestFiniteMagnitude)
        )
        return size.height
    }
}
