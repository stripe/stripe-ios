//
//  DocumentSubtypePickerView.swift
//  StripeCryptoOnramp
//
//  Created by Michael Liberatore on 9/16/26.
//

@_spi(STP) import StripeCore
@_spi(CryptoOnrampAlpha) import StripePaymentSheet
@_spi(STP) import StripeUICore
import SwiftUI

/// A sheet that commits a document subtype only when Done is pressed.
struct DocumentSubtypePickerView: View {

    /// The title displayed in the sheet's navigation bar.
    let title: String

    /// The document categories available for selection, in display order.
    let subtypes: [DocumentCollectionConfiguration.Subtype]

    /// The appearance used for the selection indicator, primary action, and color scheme.
    let appearance: LinkAppearance

    /// Called with the selected category when Done is pressed, before dismissing the sheet.
    let onCompletion: (DocumentCollectionConfiguration.Subtype) -> Void

    @State private var selectedID: String?
    @Environment(\.dismiss) private var dismiss

    /// Creates a picker with a local draft selection that is committed only when Done is pressed.
    /// - Parameters:
    ///   - title: The sheet's navigation title.
    ///   - subtypes: The document categories to display.
    ///   - selectedID: The initially selected category's identifier, or `nil` to select the first category.
    ///   - appearance: The styling for the sheet and its controls.
    ///   - onCompletion: The action that commits the selected category.
    init(
        title: String,
        subtypes: [DocumentCollectionConfiguration.Subtype],
        selectedID: String?,
        appearance: LinkAppearance,
        onCompletion: @escaping (DocumentCollectionConfiguration.Subtype) -> Void
    ) {
        self.title = title
        self.subtypes = subtypes
        self.appearance = appearance
        self.onCompletion = onCompletion
        _selectedID = State(initialValue: selectedID ?? subtypes.first?.id)
    }

    // MARK: - View

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(subtypes) { subtype in
                    Button {
                        selectedID = subtype.id
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .strokeBorder(
                                    selectedID == subtype.id ? Color(uiColor: appearance.colors?.selectedBorder ?? .textPrimary) : .documentBorder,
                                    lineWidth: selectedID == subtype.id ? 5 : 1
                                )
                                .frame(width: 20, height: 20)
                                .padding(.top, 2)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 0) {
                                Text(subtype.label)
                                    .typography(.bodyLargeEmphasized)
                                    .foregroundColor(.textPrimary)

                                if let description = subtype.description {
                                    Text(description)
                                        .typography(.bodyMedium)
                                        .foregroundColor(.textTertiary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(minHeight: 44, alignment: .topLeading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedID == subtype.id ? [.isSelected] : [])
                    .accessibilityIdentifier("document_subtype_\(subtype.id)")
                }
            }
            .padding(20)
        }
        .background(Color.surfacePrimary.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrimaryActionButton(title: UIButton.doneButtonTitle, appearance: appearance, action: {
                guard let selection = subtypes.first(where: { $0.id == selectedID }) else {
                    return
                }
                onCompletion(selection)
                dismiss()
            }, isEnabled: subtypes.contains { $0.id == selectedID })
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)
                .background(Color.surfacePrimary)
                .accessibilityIdentifier("document_subtype_done")
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            CloseToolbarItem {
                dismiss()
            }
        }
        .preferredColorScheme(appearance.colorScheme)
        .accessibilityAction(.escape) {
            dismiss()
        }
    }
}

#if DEBUG
@available(iOS 17.0, *)
#Preview("Document types") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                DocumentSubtypePickerView(
                    title: .Localized.documentType,
                    subtypes: DocumentCollectionConfiguration.preview.acceptedSubtypes,
                    selectedID: nil,
                    appearance: .previewLinkAppearance,
                    onCompletion: { _ in }
                )
            }
        }
        .transaction {
            $0.disablesAnimations = true
        }
}
#endif
