//
//  ExperimentsData.swift
//  StripePaymentSheet
//
//  Created by Mat Schmid on 2025-04-01.
//

import Foundation

@_spi(STP) public class ExperimentsData: NSObject, STPAPIResponseDecodable {
    @_spi(STP) public let arbId: String?
    @_spi(STP) public let experimentAssignments: [String: String]

    @_spi(STP) public let allResponseFields: [AnyHashable: Any]

    @_spi(STP) public init(
        arbId: String?,
        experimentAssignments: [String: String],
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
        let experimentAssignments = response["experiment_assignments"] as? [String: String] ?? [:]

        return ExperimentsData(
            arbId: arbId,
            experimentAssignments: experimentAssignments,
            allResponseFields: response
        ) as? Self
    }
}
