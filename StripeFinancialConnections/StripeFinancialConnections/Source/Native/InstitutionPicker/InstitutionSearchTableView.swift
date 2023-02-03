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

@available(iOSApplicationExtension, unavailable)
protocol InstitutionSearchTableViewDelegate: AnyObject {
    func institutionSearchTableView(
        _ tableView: InstitutionSearchTableView,
        didSelectInstitution institution: FinancialConnectionsInstitution
    )
    func institutionSearchTableViewDidSelectManuallyAddYourAccount(_ tableView: InstitutionSearchTableView)
}

@available(iOSApplicationExtension, unavailable)
final class InstitutionSearchTableView: UIView {

    private let allowManualEntry: Bool
    private let tableView: UITableView
    private let dataSource: UITableViewDiffableDataSource<Section, FinancialConnectionsInstitution>
    private lazy var didSelectManualEntry: (() -> Void)? = {
        return allowManualEntry
            ? { [weak self] in
                guard let self = self else { return }
                self.delegate?.institutionSearchTableViewDidSelectManuallyAddYourAccount(self)
            } : nil
    }()
    weak var delegate: InstitutionSearchTableViewDelegate?

    private lazy var tableFooterView: UIView = {
        let footerView = InstitutionSearchFooterView(didSelectManuallyAddYourAccount: didSelectManualEntry)
        let footerContainerView = UIView()
        footerContainerView.backgroundColor = .clear
        footerContainerView.addAndPinSubview(
            // we wrap `footerView` in a container to add extra padding
            footerView,
            insets: NSDirectionalEdgeInsets(
                top: 10,  // extra padding between table and footer
                leading: 0,
                bottom: 0,
                trailing: 0
            )
        )
        return footerContainerView
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
        tableView.rowHeight = 54
        tableView.contentInset = UIEdgeInsets(
            // add extra inset at the top/bottom to show the cell-selected-state separators
            top: 1.0 / UIScreen.main.nativeScale,
            left: 0,
            bottom: 1.0 / UIScreen.main.nativeScale,
            right: 0
        )
        tableView.keyboardDismissMode = .onDrag
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

        showTableFooterView(true)
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

    func loadInstitutions(_ institutions: [FinancialConnectionsInstitution]) {
        assertMainQueue()

        var snapshot = NSDiffableDataSourceSnapshot<Section, FinancialConnectionsInstitution>()
        snapshot.appendSections([Section.main])
        snapshot.appendItems(institutions, toSection: Section.main)
        dataSource.apply(snapshot, animatingDifferences: true, completion: nil)

        // clear state (some of this is defensive programming)
        showNoResultsNotice(query: nil)
        showError(false)
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

    func showNoResultsNotice(query: String?) {
        if let query = query {
            let noResultsLabel = UILabel()
            noResultsLabel.text = String(
                format: STPLocalizedString(
                    "No results for \"%@\".",
                    "A message that tells the user that we found no search results for the bank name they typed. '%@' will be replaced by the text they typed - for example, 'Bank of America'."
                ),
                query
            )
            noResultsLabel.font = .stripeFont(forTextStyle: .caption)
            noResultsLabel.textColor = .textSecondary
            noResultsLabel.textAlignment = .center
            // we use `UIStackView` even if its just a single view
            // because it allows for automatic resizing + easy margins
            let stackView = UIStackView(arrangedSubviews: [noResultsLabel])
            stackView.isLayoutMarginsRelativeArrangement = true
            stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(
                top: 0,
                leading: 24,
                bottom: 16,
                trailing: 24
            )
            tableView.setTableHeaderViewWithCompressedFrameSize(stackView)
        } else {
            tableView.tableHeaderView = nil
        }
    }

    func showError(_ show: Bool) {
        if show {
            tableView.setTableHeaderViewWithCompressedFrameSize(
                InstitutionSearchErrorView(
                    didSelectEnterYourBankDetailsManually: didSelectManualEntry
                )
            )
        } else {
            tableView.tableHeaderView = nil
        }
        showTableFooterView(!show)
    }

    // the footer is always shown, except for when there is an error searching
    private func showTableFooterView(_ show: Bool) {
        if show {
            tableView.setTableFooterViewWithCompressedFrameSize(tableFooterView)
        } else {
            tableView.tableFooterView = nil
        }
    }
}

// MARK: - UITableViewDelegate

@available(iOSApplicationExtension, unavailable)
extension InstitutionSearchTableView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let institution = dataSource.itemIdentifier(for: indexPath) {
            delegate?.institutionSearchTableView(self, didSelectInstitution: institution)
        }
    }
}
