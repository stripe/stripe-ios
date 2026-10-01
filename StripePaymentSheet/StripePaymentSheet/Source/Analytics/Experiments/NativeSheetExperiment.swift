//
//  NativeSheetExperiment.swift
//  StripePaymentSheet
//
//  Created by George Birch on 9/30/26.
//

/// Uses the Elements Session assignment and standard exposure payload for native-sheet rollout.
struct NativeSheetExperiment: LoggableExperiment {

    static let experimentName = "elements_mobile_ios_native_sheet"

    let name: String = experimentName
    let arbId: String
    let group: ExperimentGroup
    let dimensions: [String: String]

    init?(elementsSession: STPElementsSession, integrationShape: String) {
        guard let assignment = elementsSession.experimentsData?.experimentAssignments[Self.experimentName] else {
            return nil
        }
        arbId = elementsSession.experimentsData?.arbId ?? ""
        group = assignment
        dimensions = ["integration_shape": integrationShape]
    }
}

extension PaymentSheet {

    @_spi(STP) public enum NativeSheetFeatureFlags {

        /// Overrides the native-sheet experiment decision. Intended for test playgrounds only.
        @_spi(STP) public static var nativeSheetEnabledOverride: Bool?
    }
}
