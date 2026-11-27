//
//  InlineAddressFormView.swift
//  StripePaymentSheet
//

@_spi(InternalOnlyAPI) import StripeUICore
import SwiftUI
import UIKit

// periphery:ignore
/// Displays the address fields of an `InlineAddressFormState` without a title, button, or scroll
/// view, so they can sit inline in the host's own layout. Draws nothing until address formats load.
@_spi(InternalOnlyAPI)
public struct InlineAddressFormView: View {
    @ObservedObject private var state: InlineAddressFormState
    @StateObject private var sizing = InlineAddressFormSizing()

    /// Creates a form that displays and edits `state`.
    public init(state: InlineAddressFormState) {
        self.state = state
    }

    public var body: some View {
        if let addressSectionView = state.addressSection?.view {
            InlineAddressFormRepresentable(
                addressSectionView: addressSectionView,
                sizing: sizing
            )
            .frame(maxWidth: .infinity)
            .frame(height: sizing.height)
            // Until the form takes the fields' measured height, they can draw past it.
            .opacity(sizing.height == nil ? 0 : 1)
        }
    }
}

/// The height of the fields' UIKit view, which changes as fields appear, disappear, and show
/// errors.
@MainActor
final class InlineAddressFormSizing: ObservableObject {
    @Published private(set) var height: CGFloat?

    func updateHeight(_ newHeight: CGFloat) {
        // Publish after this layout pass, which can be part of a SwiftUI update.
        Task { @MainActor [weak self] in
            self?.updateHeightNow(newHeight)
        }
    }

    private func updateHeightNow(_ newHeight: CGFloat) {
        if let height, abs(height - newHeight) <= 1 {
            return
        }

        // The first height arrives with the fields, so only later changes animate.
        if height == nil {
            height = newHeight
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                height = newHeight
            }
        }
    }
}

private struct InlineAddressFormRepresentable: UIViewRepresentable {
    let addressSectionView: UIView
    let sizing: InlineAddressFormSizing

    func makeUIView(context: Context) -> InlineAddressFormContainerView {
        InlineAddressFormContainerView(addressSectionView: addressSectionView, sizing: sizing)
    }

    func updateUIView(_ uiView: InlineAddressFormContainerView, context: Context) {}
}

/// Holds the fields' view and reports its height whenever its size changes.
private final class InlineAddressFormContainerView: UIView {
    private let addressSectionView: UIView
    private let sizing: InlineAddressFormSizing
    private var reportedSize: CGSize = .zero

    init(addressSectionView: UIView, sizing: InlineAddressFormSizing) {
        self.addressSectionView = addressSectionView
        self.sizing = sizing
        super.init(frame: .zero)

        // SwiftUI can make this view narrower or shorter than the fields, such as before they're
        // measured. Leaving their height to their own constraints, and their width optional, keeps
        // UIKit from breaking those constraints.
        addressSectionView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(addressSectionView)
        let widthConstraint = addressSectionView.widthAnchor.constraint(equalTo: widthAnchor)
        widthConstraint.priority = .required - 1
        NSLayoutConstraint.activate([
            addressSectionView.topAnchor.constraint(equalTo: topAnchor),
            addressSectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            widthConstraint,
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // The fields' height follows this view's width and the fields themselves, such as when one
        // shows an error. SwiftUI can create this view before it has a width.
        let fieldsSize = addressSectionView.frame.size
        if bounds.width > 0, fieldsSize != reportedSize {
            reportedSize = fieldsSize
            sizing.updateHeight(fieldsSize.height)
        }
    }
}
