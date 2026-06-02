//
//  StripeCryptoOnrampErrorRenderer.swift
//  StripeCryptoOnramp
//

import Foundation

/// Renders rich Crypto Onramp developer diagnostics with a consistent visual grammar.
@_spi(CryptoOnrampAlpha)
public enum StripeCryptoOnrampErrorRenderer {

    /// Renders a developer-facing message from concrete-error content and shared metadata.
    ///
    /// - Parameters:
    ///   - developerBody: The main diagnostic content owned by the concrete error.
    ///   - code: A stable code identifying this error.
    ///   - nextStep: A suggested action for resolving the error.
    ///   - docURL: Documentation for this error, if available.
    ///   - sdkVersion: The Stripe iOS SDK version.
    ///   - additionalSDKVersions: Additional wrapper SDK versions, formatted as `name@version`.
    public static func render(
        developerBody: String,
        code: String,
        nextStep: String,
        docURL: URL?,
        sdkVersion: String,
        additionalSDKVersions: [String] = []
    ) -> String {
        return render(
            developerBody: developerBody,
            code: code,
            nextStep: nextStep,
            docURLString: docURL?.absoluteString,
            sdkVersions: ["stripe-ios@\(sdkVersion)"] + additionalSDKVersions
        )
    }

    static func renderAPIErrorDeveloperMessage(
        context: APIErrorContext,
        summary: String,
        code: String,
        sdkVersion: String,
        nextStep: String,
        additionalSDKVersions: [String] = []
    ) -> String {
        return render(
            developerBody: apiErrorDeveloperBody(summary: summary, context: context),
            code: code,
            nextStep: nextStep,
            docURL: context.docURL,
            sdkVersion: sdkVersion,
            additionalSDKVersions: additionalSDKVersions
        )
    }

    private static func render(
        developerBody: String,
        code: String,
        nextStep: String,
        docURLString: String?,
        sdkVersions: [String]
    ) -> String {
        var lines = [
            developerBody,
            "",
            "Code: \(code)",
            "Next step: \(nextStep)",
        ]

        if let docURLString {
            lines.append("Docs: \(docURLString)")
        }

        if !sdkVersions.isEmpty {
            lines.append("SDK: \(sdkVersions.joined(separator: ", "))")
        }

        return lines.joined(separator: "\n")
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
