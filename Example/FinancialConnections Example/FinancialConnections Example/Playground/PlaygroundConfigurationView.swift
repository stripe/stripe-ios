//
//  PlaygroundConfigurationView.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 4/8/24.
//

import SwiftUI

@available(iOS 14.0, *)
struct PlaygroundConfigurationView: View {

    @ObservedObject var viewModel: PlaygroundConfigurationViewModel

    var body: some View {
        Form {
            Section {
                ZStack {
                    TextEditor(text: $viewModel.configurationJSONString)
                    // ZStack + Text is a hack to auto-scale the `TextEditor`
                    Text(viewModel.configurationJSONString).opacity(0)
                }
                Button(action: viewModel.didSelectSaveConfiguration) {
                    Text("Save Configuration")
                }
            }

            Section {
                Button(action: viewModel.didSelectResetToDefaults) {
                    Text("Reset To Defaults")
                }
            }
        }
        .navigationTitle("Manage Configuration")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: viewModel.didSelectClose) {
                    Text("Close")
                }
            }
        }
        .onAppear {
            viewModel.onAppear()
        }
    }
}

@available(iOS 14.0, *)
struct PlaygroundConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlaygroundConfigurationView(
                viewModel: PlaygroundConfigurationViewModel(
                    playgroundConfiguration: PlaygroundConfiguration.shared,
                    didSelectClose: {}
                )
            )
        }
    }
}
