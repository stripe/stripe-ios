//
//  PlaygroundConfigurationViewModel.swift
//  FinancialConnections Example
//
//  Created by Krisjanis Gaidis on 4/8/24.
//

import Foundation

final class PlaygroundConfigurationViewModel: ObservableObject {

    let playgroundConfiguration: PlaygroundConfiguration
    let didSelectClose: () -> Void

    @Published var configurationJSONString: String

    init(
        playgroundConfiguration: PlaygroundConfiguration,
        didSelectClose: @escaping () -> Void
    ) {
        self.playgroundConfiguration = playgroundConfiguration
        self.didSelectClose = didSelectClose
        self.configurationJSONString = playgroundConfiguration.configurationJSONString
    }

    func onAppear() {
        // reset the configuration
        configurationJSONString = playgroundConfiguration.configurationJSONString
    }

    func didSelectSaveConfiguration() {
        playgroundConfiguration.setupWithConfigurationJSONString(configurationJSONString)
        loadCurrentConfiguration()
    }

    func didSelectResetToDefaults() {
        playgroundConfiguration
            .setupWithConfigurationJSONString(
                PlaygroundConfigurationJSON.configurationJSONStringDefaultValue
            )
        loadCurrentConfiguration()
    }

    private func loadCurrentConfiguration() {
        configurationJSONString = playgroundConfiguration.configurationJSONString
    }
}
