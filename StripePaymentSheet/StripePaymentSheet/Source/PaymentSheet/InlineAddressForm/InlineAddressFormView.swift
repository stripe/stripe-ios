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
            .onChange(of: state.enteredAddress) { _ in
                // An edit can add or remove fields, such as when the country changes.
                sizing.updateHeight(of: addressSectionView)
            }
        }
    }
}

/// Measures the fields' UIKit view, whose height changes as fields appear and disappear.
@MainActor
final class InlineAddressFormSizing: ObservableObject {
    @Published private(set) var height: CGFloat?

    private var width: CGFloat = 0

    func updateHeight(of view: UIView, width: CGFloat? = nil) {
        if let width, width > 0 {
            self.width = width
        }

        // Measure after the current layout pass, once the view has its new fields.
        Task { @MainActor [weak self] in
            self?.updateHeightNow(of: view)
        }
    }

    private func updateHeightNow(of view: UIView) {
        let fittingWidth = width > 0 ? width : view.bounds.width
        guard fittingWidth > 0 else { return }

        let newHeight = view.systemLayoutSizeFitting(
            CGSize(
                width: fittingWidth,
                height: UIView.layoutFittingCompressedSize.height
            ),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height

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

    func updateUIView(_ uiView: InlineAddressFormContainerView, context: Context) {
        // A field can resize without changing the address, such as when it shows an error.
        sizing.updateHeight(of: addressSectionView)
    }
}

/// Holds the fields' view and measures it whenever its width changes.
private final class InlineAddressFormContainerView: UIView {
    private let addressSectionView: UIView
    private let sizing: InlineAddressFormSizing
    private var measuredWidth: CGFloat = 0

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

        // SwiftUI can create this view before it has a width, and a width change alone doesn't
        // call `updateUIView`.
        if bounds.width > 0, bounds.width != measuredWidth {
            measuredWidth = bounds.width
            sizing.updateHeight(of: addressSectionView, width: bounds.width)
        }
    }
}
