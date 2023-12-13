//
//  InstitutionSearchTableView.swift
//  StripeFinancialConnections
//
//  Created by Krisjanis Gaidis on 7/20/22.
//

import Foundation
@_spi(STP) import StripeCore
@_spi(STP) import StripeUICore
import UIKit

private enum Section {
    case main
}

protocol InstitutionSearchTableViewDelegate: AnyObject {
    func institutionSearchTableView(
        _ tableView: InstitutionSearchTableView,
        didSelectInstitution institution: FinancialConnectionsInstitution
    )
    func institutionSearchTableView(
        _ tableView: InstitutionSearchTableView,
        didSelectManuallyAddYourAccountWithInstitutions institutions: [FinancialConnectionsInstitution]
    )
    func institutionSearchTableView(
        _ tableView: InstitutionSearchTableView,
        didScrollInstitutions institutions: [FinancialConnectionsInstitution]
    )
}

final class InstitutionSearchTableView: UIView {

    private let allowManualEntry: Bool
    private let tableView: UITableView
    private let dataSource: UITableViewDiffableDataSource<Section, FinancialConnectionsInstitution>
    private lazy var didSelectManualEntry: (() -> Void)? = {
        return allowManualEntry
            ? { [weak self] in
                guard let self = self else { return }
                self.delegate?.institutionSearchTableView(
                    self,
                    didSelectManuallyAddYourAccountWithInstitutions: self.institutions
                )
            } : nil
    }()
    weak var delegate: InstitutionSearchTableViewDelegate?
    private var institutions: [FinancialConnectionsInstitution] = []
    private var shouldLogScroll = true

    private lazy var tableFooterView: InstitutionSearchFooterView = {
        let title: String
        let subtitle: String
        let showIcon: Bool
        let didSelect: (() -> Void)?
        if allowManualEntry {
            title = STPLocalizedString(
                "Don't see your bank?",
                "The title of a button that appears at the bottom of search results. It appears when a user is searching for their bank. The purpose of the button is to give users the option to enter their bank account numbers manually (ex. routing and account number)."
            )
            subtitle = STPLocalizedString(
                "Enter your account and routing numbers",
                "The subtitle of a button that appears at the bottom of search results. It appears when a user is searching for their bank. The purpose of the button is to give users the option to enter their bank account numbers manually (ex. routing and account number)."
            )
            showIcon = true
            didSelect = didSelectManualEntry
        } else {
            title = STPLocalizedString(
                "No results",
                "The title of a notice that appears at the bottom of search results. It appears when a user is searching for their bank, but no results are returned."
            )
            subtitle = STPLocalizedString(
                "Double check your spelling and search terms",
                "The subtitle of a notice that appears at the bottom of search results. It appears when a user is searching for their bank, but no results are returned."
            )
            showIcon = false
            didSelect = nil
        }
        let footerView = InstitutionSearchFooterView(
            title: title,
            subtitle: subtitle,
            showIcon: showIcon,
            didSelect: didSelect
        )
        return footerView
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
        let cellIdentifier = "\(InstitutionSearchTableViewCell.self)"
        tableView = UITableView(frame: frame)
        dataSource = UITableViewDiffableDataSource(tableView: tableView) { tableView, _, institution in
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)
                    as? InstitutionSearchTableViewCell
            else {
                fatalError(
                    "Unable to dequeue cell \(InstitutionSearchTableViewCell.self) with cell identifier \(cellIdentifier)"
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
        tableView.estimatedRowHeight = 54

        #if !canImport(CompositorServices)
        tableView.contentInset = UIEdgeInsets(
            // add extra inset at the top/bottom to show the cell-selected-state separators
            top: 1.0 / UIScreen.main.nativeScale,
            left: 0,
            bottom: 1.0 / UIScreen.main.nativeScale,
            right: 0
        )
        tableView.keyboardDismissMode = .onDrag
        #endif
        tableView.register(InstitutionSearchTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
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

        showTableFooterView(false)
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

    func loadInstitutions(
        _ institutions: [FinancialConnectionsInstitution],
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
        showError(false)

        if allowManualEntry {
            showTableFooterView(
                institutions.isEmpty || (showManualEntry == true),
                showTopSeparator: !institutions.isEmpty
            )
        } else {
            showTableFooterView(institutions.isEmpty, showTopSeparator: false)
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

    func showError(_ show: Bool) {
        showTableFooterView(show, showTopSeparator: false)
    }

    // the footer is always shown, except for when there is an error searching
    private func showTableFooterView(_ show: Bool, showTopSeparator: Bool = true) {
        tableFooterView.showTopSeparator = showTopSeparator
        if show {
            tableView.setTableFooterViewWithCompressedFrameSize(tableFooterView)
        } else {
            tableView.tableFooterView = nil
        }
    }
}

// MARK: - UITableViewDelegate

extension InstitutionSearchTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let institution = dataSource.itemIdentifier(for: indexPath) {
            delegate?.institutionSearchTableView(self, didSelectInstitution: institution)
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        // Every time the institutions change, we are open to sending the event again
        if shouldLogScroll {
            shouldLogScroll = false

            delegate?.institutionSearchTableView(
                self,
                didScrollInstitutions: institutions
            )
        }
    }
}
