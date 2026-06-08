//
//  StripeCryptoOnrampErrorRenderer.swift
//  StripeCryptoOnramp
//

import Foundation

/// Renders rich Crypto Onramp developer diagnostics with a consistent visual grammar.
enum StripeCryptoOnrampErrorRenderer {

    /// Renders a developer-facing message from concrete-error content and shared metadata.
    ///
    /// - Parameters:
    ///   - developerBody: The main diagnostic content owned by the concrete error.
    ///   - code: A stable code identifying this error.
    ///   - nextStep: A suggested action for resolving the error.
    ///   - docURL: Documentation for this error, if available.
    ///   - sdkVersions: SDK versions included in developer diagnostics, including Stripe iOS and any additional wrapper SDK versions.
    static func render(
        developerBody: String,
        code: String,
        nextStep: String,
        docURL: URL?,
        sdkVersions: [SDKVersion] = []
    ) -> String {
        return render(
            developerBody: developerBody,
            code: code,
            nextStep: nextStep,
            docURLString: docURL?.absoluteString,
            sdkVersions: sdkVersions
        )
    }

    static func renderAPIErrorDeveloperMessage(
        context: APIErrorContext,
        summary: String,
        code: String,
        sdkVersions: [SDKVersion],
        nextStep: String
    ) -> String {
        return render(
            developerBody: apiErrorDeveloperBody(summary: summary, context: context),
            code: code,
            nextStep: nextStep,
            docURL: context.docURL,
            sdkVersions: sdkVersions
        )
    }

    private static func render(
        developerBody: String,
        code: String,
        nextStep: String,
        docURLString: String?,
        sdkVersions: [SDKVersion]
    ) -> String {
        var lines = [
            developerBody,
            "",
            "Code: \(code)",
            "",
            "Next step: \(nextStep)",
        ]

        if let docURLString {
            lines.append("Docs: \(docURLString)")
        }

        lines.append("SDK: \(sdkVersionDescription(sdkVersions: sdkVersions))")

        return lines.joined(separator: "\n")
    }

    private static func sdkVersionDescription(sdkVersions: [SDKVersion]) -> String {
        let normalizedSDKVersions = sdkVersions.isEmpty ? [.stripeIOS] : sdkVersions
        return normalizedSDKVersions.map(\.debugDescription).joined(separator: ", ")
    }

    private static func apiErrorDeveloperBody(summary: String, context: APIErrorContext) -> String {
        let requestContextLines = requestContextLines(context)
        guard !requestContextLines.isEmpty else {
            return summary
        }

        return ([
            summary,
            "",
            "Request Context:",
        ] + requestContextLines.map { "  \($0)" }).joined(separator: "\n")
    }

    private static func requestContextLines(_ context: APIErrorContext) -> [String] {
        return [
            "operation: \(context.operation)",
            context.appIdentifier.map { "app_id: \($0)" },
            context.mode.map { "mode: \($0)" },
            context.reason.map { "reason: \($0)" },
            context.requestID.map { "request_id: \($0)" },
            context.apiErrorType.map { "type: \($0)" },
        ].compactMap { $0 }
    }
}
