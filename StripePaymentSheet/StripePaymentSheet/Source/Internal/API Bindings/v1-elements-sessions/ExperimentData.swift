//
//  ExperimentsData.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-04-01.
//

import Foundation

enum ExperimentGroup: String {
    case control
    case treatment // periphery:ignore - decoded from API response via rawValue init; needed for experiment analytics
    case holdback
    case controlTest = "control_test" // periphery:ignore - decoded from API response via rawValue init
}

class ExperimentsData: NSObject, STPAPIResponseDecodable {
    let arbId: String?
    let experimentAssignments: [String: ExperimentGroup]

    let allResponseFields: [AnyHashable: Any]

    init(
        arbId: String?,
        experimentAssignments: [String: ExperimentGroup],
        allResponseFields: [AnyHashable: Any]
    ) {
        self.arbId = arbId
        self.experimentAssignments = experimentAssignments
        self.allResponseFields = allResponseFields
    }

    static func decodedObject(
        fromAPIResponse response: [AnyHashable: Any]?
    ) -> Self? {
        guard let response else { return nil }
        let arbId = response["arb_id"] as? String

        var experimentAssignments: [String: ExperimentGroup] = [:]
        if let assignments = response["experiment_assignments"] as? [String: String] {
            for (experimentName, groupString) in assignments {
                guard let group = ExperimentGroup(rawValue: groupString) else { continue }
                experimentAssignments[experimentName] = group
            }
        }

        return ExperimentsData(
            arbId: arbId,
            experimentAssignments: experimentAssignments,
            allResponseFields: response
        ) as? Self
    }
}
