//
//  LoadingEnvironment.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/28/25.
//

import SwiftUI

extension EnvironmentValues {

    /// Whether asynchronous loading is currently occurring (e.g. performing a network request).
    var isLoading: Binding<Bool> {
        get { self[LoadingStateKey.self] }
        set { self[LoadingStateKey.self] = newValue }
    }
}

private struct LoadingStateKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}
