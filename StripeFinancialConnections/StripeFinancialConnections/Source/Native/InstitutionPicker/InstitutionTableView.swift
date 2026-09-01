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
    private var cardBackgroundView: UIView?
    private var cardTopCornerPatchLayer: CAShapeLayer?
    private let cardCornerRadius: CGFloat = 12

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
                showsDividerAboveContent: true,
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
        if appearance.colors == .link {
            tableView.backgroundColor = .clear
            // No cornerRadius/masksToBounds on the tableView itself — cardBackgroundView provides
            // the visual card rounding. Keeping masksToBounds=false lets the scroll indicator
            // escape the card inset and render at the screen edge.
            tableView.verticalScrollIndicatorInsets = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: 0,
                right: -Constants.Layout.defaultHorizontalMargin
            )
            tableView.separatorStyle = .singleLine
            tableView.separatorColor = FinancialConnectionsAppearance.Colors.dividerOnCard
            tableView.separatorInset = UIEdgeInsets(top: 0, left: 72, bottom: 0, right: 0)
        } else {
            tableView.backgroundColor = FinancialConnectionsAppearance.Colors.background
            tableView.separatorInset = .zero
            tableView.separatorStyle = .none
        }
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 72
        let hairline = 1.0 / UIScreen.main.nativeScale
        tableView.contentInset = UIEdgeInsets(
            // Link theme: no top inset — a hairline gap lets cell content peek above the sticky
            // search bar header when scrolled. Stripe theme keeps the hairline to show separators.
            top: appearance.colors == .link ? 0 : hairline,
            left: 0,
            bottom: hairline,
            right: 0
        )
        tableView.keyboardDismissMode = .onDrag
        // do not set this because it can cause unexpected
        // scrolling behavior
        tableView.sectionHeaderTopPadding = 0
        tableView.register(InstitutionTableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.delegate = self
        addAndPinSubview(tableView)
        if appearance.colors == .link {
            let cardBg = UIView()
            cardBg.backgroundColor = appearance.colors.iconBackground
            cardBg.layer.cornerRadius = cardCornerRadius
            cardBg.layer.masksToBounds = true
            // Insert behind tableView so cells render on top
            insertSubview(cardBg, belowSubview: tableView)
            cardBackgroundView = cardBg

            // Cells scrolling behind the sticky search bar header can peek out just below
            // it, painting their square corners over where the card's rounded top corners
            // should show. This layer sits above the table view and re-patches just the two
            // corner notches with the page background color so the rounding stays visible.
            let cornerPatchLayer = CAShapeLayer()
            layer.addSublayer(cornerPatchLayer)
            cardTopCornerPatchLayer = cornerPatchLayer
            updateCardTopCornerPatchLayerColor()
        }
        // calling `load` activates the `UITableView` data source
        // by appening a section, which in turn will display
        // the section header (which contains the search bar)
        load(institutions: [], isUserSearching: false)
        showLoadingView(false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // CGColor's need to be manually updated when the system theme changes.
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }

        updateCardTopCornerPatchLayerColor()
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

        updateCardBackgroundViewFrame()

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

    private func updateCardBackgroundViewFrame() {
        guard let cardBackgroundView = cardBackgroundView else { return }
        let numberOfRows = tableView.numberOfRows(inSection: 0)
        guard numberOfRows > 0 else {
            cardBackgroundView.isHidden = true
            cardTopCornerPatchLayer?.isHidden = true
            return
        }
        cardBackgroundView.isHidden = false
        cardTopCornerPatchLayer?.isHidden = false
        // Compute card top: first cell visual position, clamped to the search bar's actual
        // current bottom edge (its own height alone isn't enough — at rest, the non-sticky
        // `tableHeaderView` above it also pushes it down) so the card never slides underneath
        // the search bar, whether it's stuck to the top or still in its natural position.
        // Card extends 16pt beyond the first/last row so the card background
        // provides uniform padding around the rows, matching the 16pt inset used
        // for each row's own leading/trailing content margin.
        let cardPadding: CGFloat = 16
        let firstCellRect = tableView.rectForRow(at: IndexPath(row: 0, section: 0))
        let searchBarContainerBottom = searchBarContainerView.map { $0.convert($0.bounds, to: self).maxY } ?? 0
        let cardTop = max(searchBarContainerBottom, firstCellRect.minY - tableView.contentOffset.y - cardPadding)
        // Compute card bottom: footer bottom (or last cell bottom) in wrapper coordinates.
        // Content space → wrapper space: subtract contentOffset.y (tableView is pinned to wrapper).
        let contentBottom: CGFloat
        if let footerView = tableView.tableFooterView {
            contentBottom = footerView.frame.maxY - tableView.contentOffset.y
        } else {
            let lastRow = IndexPath(row: numberOfRows - 1, section: 0)
            contentBottom = tableView.rectForRow(at: lastRow).maxY - tableView.contentOffset.y
        }
        let cardBottom = max(cardTop, min(bounds.height, contentBottom + cardPadding))
        cardBackgroundView.frame = CGRect(
            x: 0,
            y: cardTop,
            width: bounds.width,
            height: cardBottom - cardTop
        )
        updateCardTopCornerPatchLayer(cardFrame: cardBackgroundView.frame)
    }

    private func updateCardTopCornerPatchLayerColor() {
        cardTopCornerPatchLayer?.fillColor = FinancialConnectionsAppearance.Colors.background.cgColor
    }

    private func updateCardTopCornerPatchLayer(cardFrame: CGRect) {
        guard let cardTopCornerPatchLayer = cardTopCornerPatchLayer else { return }
        let radius = cardCornerRadius
        let patchFrame = CGRect(
            x: cardFrame.minX,
            y: cardFrame.minY,
            width: cardFrame.width,
            height: radius
        )
        cardTopCornerPatchLayer.frame = patchFrame

        // Each notch is the corner square minus the quarter-circle the card's own rounded
        // corner traces — exactly the sliver a peeking (square-cornered) row would otherwise
        // paint over. Both notches are fully contained within the strip's own bounds, so
        // (unlike an XOR-with-an-oversized-rect approach) no extra clipping is needed.
        let path = UIBezierPath()

        // Top-left notch.
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: radius, y: 0))
        path.addArc(
            withCenter: CGPoint(x: radius, y: radius),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: .pi,
            clockwise: false
        )
        path.close()

        // Top-right notch.
        path.move(to: CGPoint(x: patchFrame.width, y: 0))
        path.addLine(to: CGPoint(x: patchFrame.width - radius, y: 0))
        path.addArc(
            withCenter: CGPoint(x: patchFrame.width - radius, y: radius),
            radius: radius,
            startAngle: -.pi / 2,
            endAngle: 0,
            clockwise: true
        )
        path.close()

        cardTopCornerPatchLayer.path = path.cgPath
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
        setNeedsLayout()

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
        setNeedsLayout()
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

    /// Freezes/unfreezes the highlighted (pressed) background of the row for `institution`.
    func setHighlightFrozen(
        _ frozen: Bool,
        forInstitution institution: FinancialConnectionsInstitution
    ) {
        guard
            let index = institutions.firstIndex(where: { $0.id == institution.id }),
            let cell = tableView.cellForRow(
                at: IndexPath(row: index, section: 0)
            ) as? InstitutionTableViewCell
        else {
            return
        }
        cell.setHighlightFrozen(frozen)
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

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCardBackgroundViewFrame()
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
