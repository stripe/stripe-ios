@available(iOS 15, *)
class SupplementalFunctions {
    private let handleCheckScanSubmitted: CheckScanningController.HandleCheckScanSubmittedFn?

    init(handleCheckScanSubmitted: CheckScanningController.HandleCheckScanSubmittedFn? = nil) {
        self.handleCheckScanSubmitted = handleCheckScanSubmitted
    }

    fileprivate enum CodingKeys: String, CodingKey {
        case handleCheckScanSubmitted = "setHandleCheckScanSubmitted"
    }

    fileprivate func encodeFields(to container: inout KeyedEncodingContainer<CodingKeys>) throws {
        if handleCheckScanSubmitted != nil {
            try container.encode(true, forKey: .handleCheckScanSubmitted)
        }
    }

    func call(_ args: SupplementalFunctionArgs) async throws -> SupplementalFunctionReturnValue? {
        switch args {
        case .handleCheckScanSubmitted(let value):
            if let fn = self.handleCheckScanSubmitted {
                try await fn(value)
                return .handleCheckScanSubmitted
            }
        }

        return nil
    }
}

@available(iOS 15, *)
protocol HasSupplementalFunctions: Encodable {
    var supplementalFunctions: SupplementalFunctions { get }

    associatedtype CodingKeys: CodingKey
    func encodeFields(to container: inout KeyedEncodingContainer<CodingKeys>) throws
}

@available(iOS 15, *)
extension HasSupplementalFunctions {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try encodeFields(to: &container)

        // Results in a flat encoding (i.e., no nested `supplementalFunctions` object in the props)
        var supplementalContainer = encoder.container(keyedBy: SupplementalFunctions.CodingKeys.self)
        try supplementalFunctions.encodeFields(to: &supplementalContainer)
    }

    func encodeFields(to container: inout KeyedEncodingContainer<CodingKeys>) throws {
        // default no-op
    }
}

enum SupplementalFunctionName: String, Codable {
    case handleCheckScanSubmitted
}

@available(iOS 15, *)
enum SupplementalFunctionArgs: Equatable {
    case handleCheckScanSubmitted(CheckScanningController.CheckScanDetails)

    static func decode(from decoder: Decoder, functionName: SupplementalFunctionName) throws -> SupplementalFunctionArgs {
        var container = try decoder.unkeyedContainer()

        switch functionName {
        case .handleCheckScanSubmitted:
            if container.count != 1 {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected a singleton array for handleCheckScanSubmitted, but got length \(String(describing: container.count))")
            }
            let args = try container.decode(CheckScanningController.CheckScanDetails.self)
            return .handleCheckScanSubmitted(args)
        }
    }
}

enum SupplementalFunctionReturnValue: Encodable {
    case handleCheckScanSubmitted

    func encode(to encoder: Encoder) throws {
        // For future cases with associated values do:
        // try value.encode(to: encoder)
        switch self {
        case .handleCheckScanSubmitted:
            // No data
            break
        }
    }
}
