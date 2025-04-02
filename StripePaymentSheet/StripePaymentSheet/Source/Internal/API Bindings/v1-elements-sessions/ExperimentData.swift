//
//  ExperimentsData.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-04-01.
//

import Foundation

@_spi(STP) public enum ExperimentGroup: String {
    case control
    case treatment
    case holdback
}

@_spi(STP) public class ExperimentsData: NSObject, STPAPIResponseDecodable {
    @_spi(STP) public let arbId: String?
    @_spi(STP) public let experimentAssignments: [String: ExperimentGroup]

    @_spi(STP) public let allResponseFields: [AnyHashable: Any]

    @_spi(STP) public init(
        arbId: String?,
        experimentAssignments: [String: ExperimentGroup],
        allResponseFields: [AnyHashable: Any]
    ) {
        self.arbId = arbId
        self.experimentAssignments = experimentAssignments
        self.allResponseFields = allResponseFields
    }

    @_spi(STP) public static func decodedObject(
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
