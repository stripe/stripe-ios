//
//  InstitutionTableViewTests.swift
//  StripeFinancialConnectionsTests
//

@testable import StripeFinancialConnections
import UIKit
import XCTest

final class InstitutionTableViewTests: XCTestCase {
    func testUnfreezingHighlightClearsTableSelectionAndCellHighlight() {
        // Given a selected institution with its pressed state frozen
        let institution = FinancialConnectionsInstitution(
            id: "institution_id",
            name: "Test Bank",
            url: nil,
            icon: nil,
            logo: nil
        )
        let institutionTableView = InstitutionTableView(
            frame: CGRect(x: 0, y: 0, width: 320, height: 480),
            allowManualEntry: false,
            institutionSearchDisabled: true,
            appearance: .link
        )
        institutionTableView.load(institutions: [institution], isUserSearching: false)
        institutionTableView.layoutIfNeeded()
        let indexPath = IndexPath(row: 0, section: 0)
        institutionTableView.tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
        institutionTableView.setHighlightFrozen(true, forInstitution: institution)

        // When the pressed state is unfrozen after dismissing the OAuth prepane
        institutionTableView.setHighlightFrozen(false, forInstitution: institution)

        // Then UIKit no longer suppresses the row's neighboring separators
        XCTAssertNil(institutionTableView.tableView.indexPathForSelectedRow)
        let cell = institutionTableView.tableView.cellForRow(at: indexPath)
        XCTAssertFalse(cell?.isHighlighted == true)
    }
}
