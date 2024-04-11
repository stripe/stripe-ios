//
//  PlaygroundManageConfigurationViewModel.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 4/8/24.
//

import Foundation

final class PlaygroundManageConfigurationViewModel: ObservableObject {

    let playgroundConfiguration: PlaygroundConfiguration
    let didSelectClose: () -> Void

    @Published var configurationString: String

    init(
        playgroundConfiguration: PlaygroundConfiguration,
        didSelectClose: @escaping () -> Void
    ) {
        self.playgroundConfiguration = playgroundConfiguration
        self.didSelectClose = didSelectClose
        self.configurationString = playgroundConfiguration.configurationString
    }

    func onAppear() {
        // reset the configuration
        configurationString = playgroundConfiguration.configurationString
    }

    func didSelectSaveConfiguration() {
        playgroundConfiguration.updateConfigurationString(configurationString)
        loadCurrentConfiguration()
    }

    func didSelectResetToDefaults() {
        playgroundConfiguration
            .updateConfigurationString(
                PlaygroundConfigurationStore.configurationStringDefaultValue
            )
        loadCurrentConfiguration()
    }

    private func loadCurrentConfiguration() {
        configurationString = playgroundConfiguration.configurationString
    }
}
