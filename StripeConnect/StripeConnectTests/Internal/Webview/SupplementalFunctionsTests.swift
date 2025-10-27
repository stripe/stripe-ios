@_spi(DashboardOnly) @testable import StripeConnect
import XCTest

final class SupplementalFunctionsTests: XCTestCase {
    func testCallSucceeds() async throws {
        let handleCheckScanSubmitted: HandleCheckScanSubmittedFn = { _ in }
        let supplementalFunctions = SupplementalFunctions(handleCheckScanSubmitted: handleCheckScanSubmitted)

        let result = try await supplementalFunctions.call(.handleCheckScanSubmitted(.init(checkScanToken: "testToken")))

        XCTAssertEqual(result, SupplementalFunctionReturnValue.handleCheckScanSubmitted)
    }

    func testCallNotRegistered() async throws {
        let supplementalFunctions = SupplementalFunctions()

        let args = SupplementalFunctionArgs.handleCheckScanSubmitted(HandleCheckScanSubmittedArgs(checkScanToken: "testToken"))
        let result = try await supplementalFunctions.call(args)

        XCTAssertNil(result)
    }

    func testEncodeSupplementalFunctions() throws {
        struct Props: HasSupplementalFunctions {
            let testField: Int
            let supplementalFunctions: SupplementalFunctions

            enum CodingKeys: CodingKey {
                case testField
            }

            func encodeFields(to container: inout KeyedEncodingContainer<CodingKeys>) throws {
                try container.encode(testField, forKey: .testField)
            }
        }

        let supplementalFunctions = SupplementalFunctions(handleCheckScanSubmitted: { _ in })
        let props = Props(testField: 1, supplementalFunctions: supplementalFunctions)
        let json = String(data: try JSONEncoder().encode(props), encoding: .utf8)

        XCTAssertEqual(json, "{\"setHandleCheckScanSubmitted\":true,\"testField\":1}")
    }

    struct ArgsPayload: Decodable {
        let args: SupplementalFunctionArgs

        init(from decoder: Decoder) throws {
            self.args = try SupplementalFunctionArgs.decode(from: decoder, functionName: .handleCheckScanSubmitted)
        }
    }

    func testDecodeArgs() throws {
        let json = Data("[{\"checkScanToken\":\"testToken\"}]".utf8)

        let payload = try JSONDecoder().decode(ArgsPayload.self, from: json)

        if case .handleCheckScanSubmitted(let args) = payload.args {
            XCTAssertEqual(args.checkScanToken, "testToken")
        } else {
            XCTFail("Unexpected args")
        }
    }

    func testDecodeArgs_handleCheckScanSubmitted_invalidEmptyArray() throws {
        let json = Data("[]".utf8)
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(ArgsPayload.self, from: json),
                             "Expected a singleton array for handleCheckScanSubmitted, but got length 0")
    }

    func testDecodeArgs_handleCheckScanSubmitted_invalidLongArray() throws {
        let json = Data("[1, 2]".utf8)
        let decoder = JSONDecoder()

        XCTAssertThrowsError(try decoder.decode(ArgsPayload.self, from: json),
                             "Expected a singleton array for handleCheckScanSubmitted, but got length 2")
    }

    // This test case should be updated when there's a function with non-empty return
    func testEncodeReturnValue() throws {
        // Need a wrapper to demonstrate the encoding because .handleCheckScanSubmitted has
        // no associated value so the encoder complains that nothing was encoded
        struct Wrapper: Encodable {
            let value: SupplementalFunctionReturnValue
        }

        let data = try JSONEncoder().encode(Wrapper(value: .handleCheckScanSubmitted))
        let json = String(data: data, encoding: .utf8)

        XCTAssertEqual(json, "{\"value\":{}}")
    }
}
