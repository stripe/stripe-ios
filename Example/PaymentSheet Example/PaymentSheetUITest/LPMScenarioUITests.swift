//
//  LPMScenarioUITests.swift
//  PaymentSheetUITest
//

import XCTest

/// Checks that each playground LPM scenario offers its payment method in PaymentSheet.
/// This creates an intent for every supported payment method, so it only runs when `STP_VALIDATE_LPM_SCENARIOS` is set,
/// e.g. `TEST_RUNNER_STP_VALIDATE_LPM_SCENARIOS=1 ci_scripts/run_tests.rb --test PaymentSheetUITest/LPMScenarioUITests`.
class LPMScenarioUITests: PaymentSheetUITestCase {
    override func setUpWithError() throws {
        try XCTSkipIf(
            ProcessInfo.processInfo.environment["STP_VALIDATE_LPM_SCENARIOS"] == nil,
            "Set STP_VALIDATE_LPM_SCENARIOS to validate every LPM scenario"
        )
        try super.setUpWithError()
    }

    func testEveryScenarioOffersItsPaymentMethod() {
        // Only the scenarios named in STP_LPM_SCENARIOS (comma separated) if set, otherwise all of them
        let requestedIDs = ProcessInfo.processInfo.environment["STP_LPM_SCENARIOS"]?.split(separator: ",").map(String.init)
        let scenarios = LPMScenario.all.filter { requestedIDs?.contains($0.id) ?? true }
        var failures: [String] = []
        for scenario in scenarios {
            XCTContext.runActivity(named: scenario.id) { activity in
                if let failure = validate(scenario, activity: activity) {
                    failures.append("\(scenario.id): \(failure)")
                }
            }
        }
        XCTAssert(failures.isEmpty, "Scenarios that didn't offer their payment method:\n" + failures.joined(separator: "\n"))
    }

    /// Returns a description of the failure, or nil if PaymentSheet offered the scenario's payment method
    private func validate(_ scenario: LPMScenario, activity: XCTActivity) -> String? {
        // Given the playground with default settings
        app.terminate()
        app.launchEnvironment["STP_PLAYGROUND_DATA"] = PaymentSheetTestPlaygroundSettings.defaultValues().base64Data
        app.launch()
        let presentButton = app.buttons["Present PaymentSheet"]
        guard waitForEnabled(presentButton) else {
            return "Playground didn't load"
        }

        // ...and the scenario chosen from the LPM picker
        _ = app.buttons["Choose LPM"].waitForExistenceAndTap()
        let searchField = app.searchFields.firstMatch
        guard searchField.waitForExistence(timeout: 5) else {
            return "LPM picker didn't appear"
        }
        searchField.tap()
        searchField.typeText(scenario.id)
        attachScreenshot(named: "picker_\(scenario.id)", to: activity)
        guard app.buttons["lpm_scenario_\(scenario.id)"].waitForExistenceAndTap() else {
            return "LPM picker didn't list the scenario"
        }
        // Wait for the playground to start and then finish reloading with the new settings
        _ = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == false"), object: presentButton)], timeout: 5)
        guard waitForEnabled(presentButton) else {
            attachScreenshot(named: "reload_failed_\(scenario.id)", to: activity)
            return "Playground didn't reload"
        }

        // When PaymentSheet is presented
        presentButton.tap()
        let loadSucceeded = XCTNSPredicateExpectation(predicate: NSPredicate { [weak self] _, _ in
            self?.analyticsLog.contains { $0[string: "event"] == "mc_load_succeeded" } ?? false
        }, object: nil)
        let loadResult = XCTWaiter.wait(for: [loadSucceeded], timeout: 30)
        // Give the sheet time to finish animating in before the screenshot
        _ = app.buttons["UIButton.Close"].waitForExistence(timeout: 5)
        attachScreenshot(named: scenario.id, to: activity)

        // Then the load succeeded with the scenario's payment method
        guard loadResult == .completed,
              let orderedLPMs = analyticsLog.last(where: { $0[string: "event"] == "mc_load_succeeded" })?[string: "ordered_lpms"]
        else {
            return "PaymentSheet didn't load"
        }
        guard orderedLPMs.split(separator: ",").contains(Substring(scenario.id)) else {
            return "ordered_lpms was \"\(orderedLPMs)\""
        }
        return nil
    }

    private func attachScreenshot(named name: String, to activity: XCTActivity) {
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        activity.add(screenshot)
    }

    private func waitForEnabled(_ element: XCUIElement) -> Bool {
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: element)
        return XCTWaiter.wait(for: [enabled], timeout: 30) == .completed
    }
}
