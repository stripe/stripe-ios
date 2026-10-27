@testable @_spi(STP) import StripeCore
@testable @_spi(STP) import StripePaymentSheet

extension ConsumerSession {
    static func make(
        clientSecret: String,
        emailAddress: String,
        redactedFormattedPhoneNumber: String,
        unredactedPhoneNumber: String?,
        phoneNumberCountry: String?,
        verificationSessions: [VerificationSession],
        supportedPaymentDetailsTypes: Set<ParsedEnum<ConsumerPaymentDetails.DetailsType>>,
        mobileFallbackWebviewParams: MobileFallbackWebviewParams?,
        currentAuthenticationLevel: AuthenticationLevel? = nil,
        minimumAuthenticationLevel: AuthenticationLevel? = nil,
        linkBrand: LinkBrand? = nil,
        availableVerificationFactors: [VerificationFactor]? = nil,
        redactedPhoneNumber: String? = nil
    ) -> ConsumerSession {
        var payload: [String: Any] = [
            "clientSecret": clientSecret,
            "emailAddress": emailAddress,
            "redactedFormattedPhoneNumber": redactedFormattedPhoneNumber,
            "verificationSessions": verificationSessions.map(\.dictionaryValue),
            "supportPaymentDetailsTypes": supportedPaymentDetailsTypes.map(\.rawValue),
        ]
        payload["unredactedPhoneNumber"] = unredactedPhoneNumber
        payload["phoneNumberCountry"] = phoneNumberCountry
        payload["mobile_fallback_webview_params"] = mobileFallbackWebviewParams?.dictionaryValue
        payload["currentAuthenticationLevel"] = currentAuthenticationLevel?.rawValue
        payload["minimumAuthenticationLevel"] = minimumAuthenticationLevel?.rawValue
        payload["link_brand"] = linkBrand?.rawValue
        payload["redactedPhoneNumber"] = redactedPhoneNumber
        payload["availableVerificationFactors"] = availableVerificationFactors?.map { factor -> [String: Any] in
            var value: [String: Any] = ["type": factor.type.rawValue, "providesFurtherVerification": factor.providesFurtherVerification, "temporarilyDisabled": factor.temporarilyDisabled]
            value["id"] = factor.id
            return value
        }

        let data = try! JSONSerialization.data(withJSONObject: payload)
        return try! JSONDecoder().decode(ConsumerSession.self, from: data)
    }
}

private extension ConsumerSession.VerificationSession {
    var dictionaryValue: [String: String] {
        [
            "type": type.rawValue,
            "state": state.rawValue,
        ]
    }
}

private extension ConsumerSession.MobileFallbackWebviewParams {
    var dictionaryValue: [String: Any] {
        var payload: [String: Any] = [
            "webview_requirement_type": webviewRequirementType.rawValue,
        ]
        if let webviewOpenUrl {
            payload["webview_open_url"] = webviewOpenUrl.absoluteString
        }
        return payload
    }
}
