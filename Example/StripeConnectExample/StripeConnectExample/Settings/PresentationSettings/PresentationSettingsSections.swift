//
//  PresentationSettingsView.swift
//  StripeConnect Example
//
//  Created by Mel Ludowise on 9/27/24.
//

import SwiftUI

struct PresentationSettingsSections: View {
    @Binding var presentationSettings: PresentationSettings

    @ViewBuilder
    var body: some View {
        Section {
            OptionListRow(title: "Navigation push",
                          selected: presentationSettings.presentationStyleIsPush,
                          onSelected: {
                presentationSettings.presentationStyleIsPush = true
            })
            OptionListRow(title: "Present modally",
                          selected: !presentationSettings.presentationStyleIsPush,
                          onSelected: {
                presentationSettings.presentationStyleIsPush = false
            })
        } header: {
            Text("Presentation style")
        }

        Section {
            OptionListRow(title: "Tab bar",
                          selected: presentationSettings.embedInTabBar,
                          onSelected: {
                presentationSettings.embedInTabBar.toggle()
            })
            OptionListRow(title: "Navigation bar",
                          selected: presentationSettings.embedInNavBar,
                          onSelected: {
                presentationSettings.embedInNavBar.toggle()
            })
        } header: {
            Text("Embed view controller (multiselect)")
        }
    }
}
