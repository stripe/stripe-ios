import Foundation

enum DemoConfig {

    /// Whether passwordless demo mode is enabled (i.e., a demo password is configured).
    static var isPasswordlessEnabled: Bool {
        guard let password = passwordlessPassword else { return false }
        return !password.isEmpty
    }

    /// The password to use behind the scenes when passwordless mode is enabled.
    static var passwordlessPassword: String? {
        Bundle.main.infoDictionary?["DemoPasswordlessPassword"] as? String
    }

    /// The set of emails allowed in passwordless mode, lowercased.
    static var allowedEmails: Set<String> {
        guard let raw = Bundle.main.infoDictionary?["DemoPasswordlessEmails"] as? String else {
            return []
        }
        let emails = raw
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            .filter { !$0.isEmpty }
        return Set(emails)
    }

    /// Returns `true` if the given email is on the passwordless allowlist.
    /// Supports plus-addressing: if `alice@stripe.com` is allowed,
    /// `alice+something@stripe.com` also matches.
    static func isEmailAllowed(_ email: String) -> Bool {
        let normalized = email.lowercased()
        if allowedEmails.contains(normalized) {
            return true
        }
        return allowedEmails.contains(normalizeEmail(normalized))
    }

    /// Parsed mapping of lowercased email → Solana wallet address from the
    /// `DemoSolanaWalletAddresses` Info.plist key (comma-separated `email:address` pairs).
    private static var solanaWalletAddresses: [String: String] {
        guard let raw = Bundle.main.infoDictionary?["DemoSolanaWalletAddresses"] as? String else {
            return [:]
        }
        var mapping: [String: String] = [:]
        for pair in raw.split(separator: ",") {
            let parts = pair.split(separator: ":", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let email = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
            let address = parts[1].trimmingCharacters(in: .whitespaces)
            guard !email.isEmpty, !address.isEmpty else { continue }
            mapping[email] = address
        }
        return mapping
    }

    /// Returns the configured Solana wallet address for the given email, if any.
    /// Supports plus-addressing: e.g. `alice+test@stripe.com` matches `alice@stripe.com`.
    static func solanaWalletAddress(for email: String) -> String? {
        let lowered = email.lowercased()
        if let address = solanaWalletAddresses[lowered] {
            return address
        }
        return solanaWalletAddresses[normalizeEmail(lowered)]
    }

    /// Strips the `+…` suffix from the local part of an email address.
    /// e.g. `alice+test@stripe.com` → `alice@stripe.com`
    private static func normalizeEmail(_ email: String) -> String {
        guard let atIndex = email.lastIndex(of: "@"),
              let plusIndex = email.firstIndex(of: "+"),
              plusIndex < atIndex
        else {
            return email
        }
        return String(email[email.startIndex..<plusIndex]) + String(email[atIndex...])
    }
}
