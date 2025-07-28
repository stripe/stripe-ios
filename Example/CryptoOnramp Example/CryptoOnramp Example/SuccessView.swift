//
//  SuccessView.swift
//  CryptoOnramp Example
//
//  Created by Michael Liberatore on 7/28/25.
//

import SwiftUI
import UIKit

struct SuccessView: View {
    let message: LocalizedStringKey
    let customerId: String
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                Text(message)
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            VStack(spacing: 8) {
                Text("Customer ID")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                Text(customerId)
                    .font(.subheadline.monospaced())
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)

            Spacer()
            
            Button("Restart") {
                if let navigationController = UIApplication.shared.findTopNavigationController() {
                    navigationController.popToRootViewController(animated: true)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.bottom)
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    NavigationView {
        SuccessView(
            message: "Registration Successful!",
            customerId: "cus_example123456789"
        )
    }
}
