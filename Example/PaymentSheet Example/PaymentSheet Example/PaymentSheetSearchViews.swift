//
//  PaymentSheetSearchViews.swift
//  PaymentSheet Example
//
//  Created by Nick Porter on 2/17/26.
//

import SwiftUI

// MARK: - Search Bar View
@available(iOS 15.0, *)
struct SettingsSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search settings...", text: $text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            if !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(.systemGray3))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.systemGray6)))
    }
}

struct VisibleSettingsCountKey: PreferenceKey {
    static var defaultValue: Int = 0
    static func reduce(value: inout Int, nextValue: () -> Int) {
        value += nextValue()
    }
}

// MARK: - Search Helpers

/// Normalizes a camelCase or PascalCase string by inserting spaces before capital letters.
/// e.g., "cardBrandAcceptance" -> "card Brand Acceptance"
private func normalizeForSearch(_ text: String) -> String {
    var result = ""
    for char in text {
        if char.isUppercase && !result.isEmpty {
            result.append(" ")
        }
        result.append(char)
    }
    return result
}

/// Checks if a setting name matches the search text.
/// Supports both exact substring matching and camelCase-aware matching.
/// e.g., "card brand" matches "cardBrandAcceptance"
private func settingMatchesSearch(_ settingName: String, searchText: String) -> Bool {
    if searchText.isEmpty { return true }
    if settingName.localizedCaseInsensitiveContains(searchText) { return true }
    let normalized = normalizeForSearch(settingName)
    return normalized.localizedCaseInsensitiveContains(searchText)
}

/// Checks if a PickerEnum setting matches the search text by name or any of its values.
/// e.g., searching "CheckoutSession" matches the "Type" setting, "usd" matches "Currency"
private func pickerEnumMatchesSearch<S: PickerEnum>(_ enumType: S.Type, searchText: String) -> Bool {
    if searchText.isEmpty { return true }
    if settingMatchesSearch(S.enumName, searchText: searchText) { return true }
    for enumCase in S.allCases {
        if settingMatchesSearch(enumCase.displayName, searchText: searchText) {
            return true
        }
    }
    return false
}

// MARK: - Searchable Wrapper Views
@available(iOS 15.0, *)
struct SearchableSettingView<S: PickerEnum>: View {
    var setting: Binding<S>
    @Binding var searchText: String

    private var isVisible: Bool {
        pickerEnumMatchesSearch(S.self, searchText: searchText)
    }

    var body: some View {
        Group {
            if isVisible {
                SettingView(setting: setting)
            }
        }
        .preference(key: VisibleSettingsCountKey.self, value: isVisible ? 1 : 0)
    }
}

@available(iOS 15.0, *)
struct SearchableSettingPickerView<S: PickerEnum>: View {
    var setting: Binding<S>
    var disabledSettings: [S] = []
    var customDisplayLabel: String?
    var customDisplayName: ((S) -> String)?
    @Binding var searchText: String

    private var isVisible: Bool {
        if let customLabel = customDisplayLabel,
           settingMatchesSearch(customLabel, searchText: searchText) {
            return true
        }
        return pickerEnumMatchesSearch(S.self, searchText: searchText)
    }

    var body: some View {
        Group {
            if isVisible {
                SettingPickerView(
                    setting: setting,
                    disabledSettings: disabledSettings,
                    customDisplayLabel: customDisplayLabel,
                    customDisplayName: customDisplayName
                )
            }
        }
        .preference(key: VisibleSettingsCountKey.self, value: isVisible ? 1 : 0)
    }
}

@available(iOS 15.0, *)
struct SearchableView<Content: View>: View {
    let searchableName: String
    @Binding var searchText: String
    @ViewBuilder var content: () -> Content

    private var isVisible: Bool {
        settingMatchesSearch(searchableName, searchText: searchText)
    }

    var body: some View {
        Group {
            if isVisible {
                content()
            }
        }
        .preference(key: VisibleSettingsCountKey.self, value: isVisible ? 1 : 0)
    }
}

// MARK: - Searchable Section View
@available(iOS 15.0, *)
struct SearchableSection<HeaderButtons: View, Content: View>: View {
    let title: String
    @Binding var searchText: String
    @ViewBuilder var headerButtons: () -> HeaderButtons
    @ViewBuilder var content: () -> Content

    init(
        title: String,
        searchText: Binding<String>,
        @ViewBuilder headerButtons: @escaping () -> HeaderButtons,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        _searchText = searchText
        self.headerButtons = headerButtons
        self.content = content
    }

    var body: some View {
        Group {
            if searchText.isEmpty {
                HStack {
                    Text(title).font(.headline)
                    Spacer()
                    headerButtons()
                }
            }
            content()
        }
    }
}

@available(iOS 15.0, *)
extension SearchableSection where HeaderButtons == EmptyView {
    init(
        title: String,
        searchText: Binding<String>,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(title: title, searchText: searchText, headerButtons: { EmptyView() }, content: content)
    }
}

// MARK: - Empty Search Results View
@available(iOS 15.0, *)
struct EmptySearchResultsView: View {
    let searchText: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 44, weight: .thin))
                .foregroundColor(Color(.systemGray3))
            Text("No Settings Found")
                .font(.headline)
            Text("No settings match \"\(searchText)\"")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}
