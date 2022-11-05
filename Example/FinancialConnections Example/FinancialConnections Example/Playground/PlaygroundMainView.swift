//
//  PlaygroundMainView.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 11/1/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import SwiftUI

struct PlaygroundMainView: View {
    
    @StateObject var viewModel = PlaygroundMainViewModel()
    
    var body: some View {
        VStack {
            Form {
                Toggle("Enable Test Mode", isOn: $viewModel.enableTestMode)
            }
            VStack {
                Button(action: viewModel.didSelectShow) {
                    VStack {
                        Text("Show Auth Flow")
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(UIColor.systemGray6))
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }.padding()
            
        }
    }
}

struct PlaygroundMainView_Previews: PreviewProvider {
    static var previews: some View {
        PlaygroundMainView()
    }
}
