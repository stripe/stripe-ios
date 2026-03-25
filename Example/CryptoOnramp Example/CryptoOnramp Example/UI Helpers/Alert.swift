//
//  Alert.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 9/29/25.
//

import Foundation

/// A basic alert struct for displaying an alert in SwiftUI.
struct Alert: Identifiable {
    var id: String { title + message }
    let title: String
    let message: String
}
