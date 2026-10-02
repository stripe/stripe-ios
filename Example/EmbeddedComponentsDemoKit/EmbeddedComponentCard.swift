//
//  EmbeddedComponentCard.swift
//  EmbeddedComponentsDemoKit
//

@_spi(DashboardOnly) import StripeConnect
import SwiftUI
import UIKit

/// Hosts an inline Stripe embedded component, either inside a Kestrel card or flush on the page.
///
/// Shows a native skeleton while the component loads, then fades the component in and
/// animates its height as the component's content changes.
/// Native placeholder shapes shown until a component can fully replace them.
enum EmbeddedComponentSkeleton {
    /// Generic form fields.
    case form
    /// Mirrors the payout methods component: method rows followed by add buttons.
    case payoutMethods
}

struct EmbeddedComponentCard: View {
    let componentManager: EmbeddedComponentManager?
    /// Must match the surface the component manager's appearance was built for.
    var surface: EmbeddedComponentSurface = .card
    var skeleton: EmbeddedComponentSkeleton = .form
    var skeletonHeight: CGFloat = 360
    /// When set, the skeleton reuses the height this component last rendered at, so it matches the real content.
    var cacheKey: String?
    var loadingFailedMessage = "Couldn't load this section. Check that Connect.js is running on localhost:3001."
    let makeComponent: (EmbeddedComponentManager) -> InlineComponentViewController
    var onExit: () -> Void = {}

    @Environment(\.embeddedCardStyle) private var style
    @State private var loadState: InlineComponentViewController.InitialLoadState = .loading
    @State private var componentHeight: CGFloat = 0

    private var placeholderHeight: CGFloat {
        guard let cacheKey else { return skeletonHeight }
        let cached = UserDefaults.standard.double(forKey: "embeddedComponentHeight.\(cacheKey)")
        return cached > 0 ? cached : skeletonHeight
    }

    var body: some View {
        let isLoaded = loadState == .loaded
        let placeholderHeight = placeholderHeight
        ZStack(alignment: .top) {
            if let componentManager {
                InlineComponentView(
                    componentManager: componentManager,
                    makeComponent: makeComponent,
                    onLoadStateChange: { state in
                        withAnimation(.easeOut(duration: 0.22)) { loadState = state }
                    },
                    onHeightChange: { height in
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.86)) {
                            componentHeight = height
                        }
                        if let cacheKey, height > 0 {
                            UserDefaults.standard.set(Double(height), forKey: "embeddedComponentHeight.\(cacheKey)")
                        }
                    },
                    onExit: onExit
                )
                .frame(height: isLoaded ? componentHeight : placeholderHeight)
                .padding(.vertical, surface == .card ? 12 : 0)
                .opacity(isLoaded ? 1 : 0)
            }

            if !isLoaded {
                Group {
                    switch skeleton {
                    case .form:
                        ComponentSkeleton(failed: loadState == .failed, failedMessage: loadingFailedMessage)
                            .padding(.horizontal, surface == .card ? 0 : -4)
                    case .payoutMethods:
                        PayoutMethodsSkeleton(height: placeholderHeight)
                    }
                }
                .frame(height: placeholderHeight, alignment: .top)
                .transition(.opacity)
            }
        }
        .background {
            if surface == .card {
                RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous).fill(style.card)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: surface == .card ? style.cornerRadius : 0, style: .continuous))
    }
}

private struct ComponentSkeleton: View {
    let failed: Bool
    let failedMessage: String
    @Environment(\.embeddedCardStyle) private var style

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if failed {
                Label(failedMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(style.error)
            } else {
                bar(width: 180, height: 22)
                bar(width: nil, height: 14)
                bar(width: 240, height: 14)
                Spacer().frame(height: 6)
                ForEach(0..<3, id: \.self) { _ in
                    VStack(alignment: .leading, spacing: 8) {
                        bar(width: 110, height: 12)
                        bar(width: nil, height: 48, radius: 12)
                    }
                }
            }
        }
        .padding(20)
        .shimmering(color: style.shimmer)
    }

    private func bar(width: CGFloat?, height: CGFloat, radius: CGFloat = 6) -> some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(style.skeleton)
            .frame(maxWidth: width ?? .infinity, alignment: .leading)
            .frame(width: width, height: height)
    }
}

/// Matches the payout methods component's layout and metrics, so revealing it doesn't shift anything.
private struct PayoutMethodsSkeleton: View {
    /// Total height to fill; the row count is derived from it.
    let height: CGFloat
    @Environment(\.embeddedCardStyle) private var style

    private static let buttonsHeight: CGFloat = 54
    private static let spacing: CGFloat = 12
    /// Bank accounts render taller than cards; alternate so the rows average out to the real layout.
    private static func rowHeight(_ index: Int) -> CGFloat { index.isMultiple(of: 2) ? 106 : 72 }

    private var rows: Int {
        var remaining = height - Self.buttonsHeight
        var count = 0
        while remaining - (Self.rowHeight(count) + Self.spacing) >= -Self.spacing / 2 {
            remaining -= Self.rowHeight(count) + Self.spacing
            count += 1
        }
        return max(1, count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<rows, id: \.self) { index in
                HStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(style.skeleton)
                        .frame(width: 32, height: 32)
                    VStack(alignment: .leading, spacing: 10) {
                        bar(width: index == 0 ? 170 : 120, height: 16)
                        bar(width: index == 0 ? 190 : 90, height: 14)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: Self.rowHeight(index))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(style.skeleton, lineWidth: 1.5)
                )
            }
            HStack(spacing: 10) {
                Capsule().fill(style.skeleton).frame(width: 178, height: 54)
                Capsule().fill(style.skeleton).frame(width: 150, height: 54)
            }
        }
        .padding(.horizontal, 16)
        .shimmering(color: style.shimmer)
    }

    private func bar(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(style.skeleton)
            .frame(width: width, height: height)
    }
}

/// Colors for `EmbeddedComponentCard`, set once per app with `.environment(\.embeddedCardStyle, ...)`.
struct EmbeddedCardStyle {
    var card: Color
    var skeleton: Color
    var shimmer: Color
    var error: Color
    var cornerRadius: CGFloat = 20
}

private struct EmbeddedCardStyleKey: EnvironmentKey {
    static let defaultValue = EmbeddedCardStyle(
        card: Color(white: 0.11),
        skeleton: Color(white: 0.15),
        shimmer: .white.opacity(0.08),
        error: .red
    )
}

extension EnvironmentValues {
    var embeddedCardStyle: EmbeddedCardStyle {
        get { self[EmbeddedCardStyleKey.self] }
        set { self[EmbeddedCardStyleKey.self] = newValue }
    }
}

/// A moving highlight used for native loading skeletons.
struct Shimmer: ViewModifier {
    var color: Color = .white.opacity(0.08)
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(colors: [.clear, color, .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: proxy.size.width * 0.6)
                        .offset(x: phase * proxy.size.width * 1.6)
                }
                .mask(content)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.3).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

extension View {
    func shimmering(color: Color = .white.opacity(0.08)) -> some View { modifier(Shimmer(color: color)) }
}

/// Bridges an `InlineComponentViewController` into SwiftUI.
///
/// The component reports its content height; SwiftUI owns the frame so height changes
/// animate with the rest of the screen instead of snapping.
private struct InlineComponentView: UIViewControllerRepresentable {
    let componentManager: EmbeddedComponentManager
    let makeComponent: (EmbeddedComponentManager) -> InlineComponentViewController
    var onLoadStateChange: (InlineComponentViewController.InitialLoadState) -> Void
    var onHeightChange: (CGFloat) -> Void
    var onExit: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> ContainerViewController {
        let component = makeComponent(componentManager)
        component.delegate = context.coordinator
        return ContainerViewController(content: component)
    }

    func updateUIViewController(_ viewController: ContainerViewController, context: Context) {
        context.coordinator.parent = self
    }

    final class Coordinator: InlineComponentViewControllerDelegate {
        var parent: InlineComponentView

        init(parent: InlineComponentView) { self.parent = parent }

        func inlineComponent(
            _ component: InlineComponentViewController,
            didChangeInitialLoadState initialLoadState: InlineComponentViewController.InitialLoadState
        ) {
            if initialLoadState == .loaded {
                parent.onHeightChange(component.contentHeight)
            }
            parent.onLoadStateChange(initialLoadState)
        }

        func inlineComponent(_ component: InlineComponentViewController, didChangeContentHeight height: CGFloat) {
            parent.onHeightChange(height)
        }

        func inlineComponentDidExit(_ component: InlineComponentViewController) {
            parent.onExit()
        }

        func inlineComponent(_ component: InlineComponentViewController, didFailLoadWithError error: Error) {
            print("Inline component failed to load: \(error)")
        }
    }

    /// Pins the component to the top so a shrinking or growing SwiftUI frame reveals it smoothly.
    final class ContainerViewController: UIViewController {
        let content: UIViewController

        init(content: UIViewController) {
            self.content = content
            super.init(nibName: nil, bundle: nil)
        }

        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .clear
            view.clipsToBounds = true
            addChild(content)
            content.view.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(content.view)
            NSLayoutConstraint.activate([
                content.view.topAnchor.constraint(equalTo: view.topAnchor),
                content.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                content.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            ])
            content.didMove(toParent: self)
        }
    }
}
