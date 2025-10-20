class SupplementalFunctions {
    private let handleCheckScanSubmitted: HandleCheckScanSubmittedFn?

    init(handleCheckScanSubmitted: HandleCheckScanSubmittedFn? = nil) {
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
                return .handleCheckScanSubmitted(try await fn(value))
            }
        }

        return nil
    }
}

protocol HasSupplementalFunctions: Encodable {
    var supplementalFunctions: SupplementalFunctions { get }

    associatedtype CodingKeys: CodingKey
    func encodeFields(to container: inout KeyedEncodingContainer<CodingKeys>) throws
}

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

enum SupplementalFunctionArgs: Equatable {
    case handleCheckScanSubmitted(HandleCheckScanSubmittedArgs)

    static func decode(from decoder: Decoder, functionName: SupplementalFunctionName) throws -> SupplementalFunctionArgs {
        var container = try decoder.unkeyedContainer()

        switch functionName {
        case .handleCheckScanSubmitted:
            if container.count != 1 {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected a singleton array for handleCheckScanSubmitted, but got length \(String(describing: container.count))")
            }
            let args = try container.decode(HandleCheckScanSubmittedArgs.self)
            return .handleCheckScanSubmitted(args)
        }
    }
}

enum SupplementalFunctionReturnValue: Encodable {
    case handleCheckScanSubmitted(HandleCheckScanSubmittedReturnValue)

    func encode(to encoder: Encoder) throws {
        switch self {
        case .handleCheckScanSubmitted(let value):
            try value.encode(to: encoder)
        }
    }
}

@_spi(DashboardOnly)
public typealias HandleCheckScanSubmittedFn = ((HandleCheckScanSubmittedArgs) async throws -> (HandleCheckScanSubmittedReturnValue))

@_spi(DashboardOnly)
public struct HandleCheckScanSubmittedArgs: Decodable, Equatable {
    public var checkScanToken: String

    public init(checkScanToken: String) {
        self.checkScanToken = checkScanToken
    }
}

@_spi(DashboardOnly)
public struct HandleCheckScanSubmittedReturnValue: Encodable, Equatable {
    public init() {}
}
