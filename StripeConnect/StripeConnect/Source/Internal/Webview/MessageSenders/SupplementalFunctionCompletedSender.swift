struct SupplementalFunctionCompletedSender: MessageSender {
    struct Payload: Encodable {
        enum Result {
            case success(SupplementalFunctionReturnValue)
            case error(Encodable)
        }

        let functionName: SupplementalFunctionName
        let invocationId: String
        let result: Result

        enum CodingKeys: String, CodingKey {
            case functionName, invocationId, result, returnValue, error
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(functionName, forKey: .functionName)
            try container.encode(invocationId, forKey: .invocationId)

            switch result {
            case .success(let returnValue):
                try container.encode("success", forKey: .result)
                try container.encode(returnValue, forKey: .returnValue)
            case .error(let error):
                try container.encode("error", forKey: .result)
                try container.encode(error, forKey: .error)
            }
        }
    }

    let name: String = "supplementalFunctionCompleted"
    let payload: Payload
}
