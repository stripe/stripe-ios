//
//  CookieStore.swift
//  StripeiOS
//
//  Created by Ramon Torres on 12/21/21.
//  Copyright © 2021 Stripe, Inc. All rights reserved.
//

/// A protocol that cookie storage objects should conform to.
///
/// Provides an interface for basic CRUD functionality.
protocol LinkCookieStore {
    /// Writes a cookie to the store.
    /// - Parameters:
    ///   - key: Cookie identifier.
    ///   - value: Cookie value.
    ///   - allowSync: True if this cookie should be sync'd  across devices
    func write(key: LinkCookieKey, value: String, allowSync: Bool)

    /// Retrieves a cookie by key.
    /// - Parameter key: Cookie identifier.
    /// - Returns: The cookie value, or `nil` if it doesn't exist.
    func read(key: LinkCookieKey) -> String?

    /// Deletes a stored cookie identified by key.
    /// - Parameter key: Cookie identifier.
    func delete(key: LinkCookieKey)
}

extension LinkCookieStore {
    func write(key: LinkCookieKey, value: String) {
        self.write(key: key, value: value, allowSync: false)
    }
}

// MARK: - Helpers

extension LinkCookieStore {

    func formattedSessionCookies() -> [String: [String]]? {
        guard let value = read(key: .session) else {
            return nil
        }

        return [
            "verification_session_client_secrets": [value]
        ]
    }

    func updateSessionCookie(with authSessionClientSecret: String?) {
        // Update the session cookie according to these rules:
        //
        // +-----------------------------+---------+
        // | authSessionClientSecret     | Action  |
        // +-----------------------------+---------+
        // |  nil                        | No-op   |
        // |-----------------------------|---------|
        // |  Empty (zero-length) string | Delete  |
        // |-----------------------------|---------|
        // |  Any other value            | Store   |
        // +-----------------------------+---------+
        guard let authSessionClientSecret = authSessionClientSecret else {
            return
        }

        if authSessionClientSecret.isEmpty {
            delete(key: .session)
        } else {
            write(key: .session, value: authSessionClientSecret, allowSync: true)
        }
    }

    func clear() {
        delete(key: .session)
        delete(key: .lastLogoutEmail)
        delete(key: .lastSignupEmail)
    }
}
