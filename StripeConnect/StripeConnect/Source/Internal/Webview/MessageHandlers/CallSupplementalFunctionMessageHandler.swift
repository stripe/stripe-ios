@available(iOS 15, *)
class CallSupplementalFunctionMessageHandler: ScriptMessageHandler<CallSupplementalFunctionMessageHandler.Payload> {
    struct Payload: Decodable {
        let functionName: SupplementalFunctionName
        let invocationId: String
        let args: SupplementalFunctionArgs

        enum CodingKeys: String, CodingKey {
            case functionName, invocationId, args
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            functionName = try container.decode(SupplementalFunctionName.self, forKey: .functionName)
            invocationId = try container.decode(String.self, forKey: .invocationId)
            let argsDecoder = try container.superDecoder(forKey: .args)
            args = try SupplementalFunctionArgs.decode(from: argsDecoder, functionName: functionName)
        }
    }

    init(analyticsClient: ComponentAnalyticsClient, didReceiveMessage: @escaping (Payload) -> Void) {
        super.init(name: "callSupplementalFunction", analyticsClient: analyticsClient, didReceiveMessage: didReceiveMessage)
    }
}
