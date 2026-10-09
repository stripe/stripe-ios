@_spi(STP) import StripeCore

class CallSupplementalFunctionMessageHandler: ScriptMessageHandler<CallSupplementalFunctionMessageHandler.Payload> {
    struct Payload: Decodable {
        let functionName: SupplementalFunctionName
        let documentID: String?
        let invocationId: String
        let args: SupplementalFunctionArgs

        enum CodingKeys: String, CodingKey {
            case functionName, invocationId, args, documentID
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            documentID = try container.decodeIfPresent(String.self, forKey: .documentID)
            functionName = try container.decode(SupplementalFunctionName.self, forKey: .functionName)
            invocationId = try container.decode(String.self, forKey: .invocationId)
            let argsDecoder = try container.superDecoder(forKey: .args)
            args = try SupplementalFunctionArgs.decode(from: argsDecoder, functionName: functionName)
        }
    }

    init(sourcePolicy: STPWebMessageSourcePolicy,
         analyticsClient: ComponentAnalyticsClient,
         didReceiveMessage: @escaping (Payload) -> Void) {
        super.init(name: "callSupplementalFunction", sourcePolicy: sourcePolicy, analyticsClient: analyticsClient, didReceiveMessage: didReceiveMessage)
    }
}
