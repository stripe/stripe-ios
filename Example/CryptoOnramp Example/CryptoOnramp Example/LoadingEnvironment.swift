//
//  LoadingEnvironment.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/28/25.
//

import SwiftUI

private struct LoadingStateKey: EnvironmentKey {
    static let defaultValue: Binding<Bool> = .constant(false)
}

extension EnvironmentValues {
    var isLoading: Binding<Bool> {
        get { self[LoadingStateKey.self] }
        set { self[LoadingStateKey.self] = newValue }
    }
}
