//
//  PlaygroundManageConfigurationView.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 4/8/24.
//

import SwiftUI

struct PlaygroundManageConfigurationView: View {

    @ObservedObject var viewModel: PlaygroundManageConfigurationViewModel

    var body: some View {
        Form {
            Section {
                ZStack {
                    TextEditor(text: $viewModel.configurationString)
                    // ZStack + Text is a hack to auto-scale the `TextEditor`
                    Text(viewModel.configurationString).opacity(0)
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

struct PlaygroundManageConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlaygroundManageConfigurationView(
                viewModel: PlaygroundManageConfigurationViewModel(
                    playgroundConfiguration: PlaygroundConfiguration.shared,
                    didSelectClose: {}
                )
            )
        }
    }
}
