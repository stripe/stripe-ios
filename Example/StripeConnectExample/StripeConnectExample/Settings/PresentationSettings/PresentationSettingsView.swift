//
//  PresentationSettingsView.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 9/27/24.
//

import SwiftUI

struct PresentationSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var presentationSettings: PresentationSettings

    var saveEnabled: Bool {
        AppSettings.shared.presentationSettings != presentationSettings
    }

    @ViewBuilder
    var body: some View {
        List {
            Section {
                OptionListRow(title: "Navigation push",
                              subtitle: "Pushes the component view controller onto the navigation stack.",
                              selected: presentationSettings.presentationStyleIsPush,
                              onSelected: {
                    presentationSettings.presentationStyleIsPush = true
                })
                OptionListRow(title: "Present modally",
                              subtitle: "Modally presents the component view controller.",
                              selected: !presentationSettings.presentationStyleIsPush,
                              onSelected: {
                    presentationSettings.presentationStyleIsPush = false
                })
            } header: {
                Text("Show component view controller using")
            }

            Section {
                Toggle(isOn: $presentationSettings.embedInNavBar) {
                    Text("Navigation bar")
                    navbarDescriptionText
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Toggle(isOn: $presentationSettings.embedInTabBar) {
                    Text("Tab bar")
                    Text("Embeds the view controller in a `UITabBarController`.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Embed component in")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("View Controller Options")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    AppSettings.shared.presentationSettings = presentationSettings
                    dismiss()
                } label: {
                    Text("Save")
                }
                .disabled(!saveEnabled)
            }
        }
        .environment(\.horizontalSizeClass, .compact)
    }

    var navbarDescriptionText: Text {
        if presentationSettings.presentationStyleIsPush {
            return Text("Disable this setting to hide the navigation bar on push.")
        } else {
            return Text("Embeds the view controller in a `UINavigationController`.")
        }
    }
}
