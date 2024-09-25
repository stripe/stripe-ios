//
//  AppearanceSettings.swift
//  StripeConnect Example
//
//  Created by Chris Mays on 9/5/24.
//

@_spi(PrivateBetaConnect) import StripeConnect
import SwiftUI

struct AppearanceSettings: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.viewControllerPresenter) var viewControllerPresenter

    let componentManager: EmbeddedComponentManager

    var saveEnabled: Bool {
        AppSettings.shared.appearanceInfo.id != selectedAppearance.id
    }

    @State var selectedAppearance: AppearanceInfo

    init(componentManager: EmbeddedComponentManager) {
        self.componentManager = componentManager
        _selectedAppearance = .init(initialValue: AppSettings.shared.appearanceInfo)
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(AppSettings.shared.appearanceOptions) { appearanceInfo in
                        OptionListRow(title: appearanceInfo.displayName,
                                      selected: selectedAppearance.id == appearanceInfo.id,
                                      onSelected: {
                            selectedAppearance = appearanceInfo
                        })
                    }
                } header: {
                    Text("Select a preset")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Configure Appearance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        AppSettings.shared.appearanceInfo = selectedAppearance
                        componentManager.update(appearance: selectedAppearance.appearance)
                        dismiss()
                    } label: {
                        Text("Save")
                    }
                    .disabled(!saveEnabled)
                }
            }
        }
        .environment(\.horizontalSizeClass, .compact)
    }

}
