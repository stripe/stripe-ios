//
//  View+WalletOwnershipVerification.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 6/29/26.
//

import SwiftUI

extension View {

    /// Presents an alert explaining that wallet ownership verification is required before continuing.
    /// - Parameters:
    ///   - isPresented: Binding that controls whether the alert is visible.
    ///   - onVerify: Called when the user chooses to start wallet ownership verification.
    ///   - onCancel: Called when the user cancels the recovery flow.
    @ViewBuilder
    func walletOwnershipVerificationRequiredAlert(
        isPresented: Binding<Bool>,
        onVerify: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        alert(
            "Wallet verification required",
            isPresented: isPresented,
            actions: {
                Button("Verify", action: onVerify)
                Button("Cancel", role: .cancel, action: onCancel)
            },
            message: {
                Text("This purchase requires you to verify ownership of the selected wallet before continuing.")
            }
        )
    }
}
