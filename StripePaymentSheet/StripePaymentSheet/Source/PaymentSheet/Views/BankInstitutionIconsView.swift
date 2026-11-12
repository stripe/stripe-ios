//
//  BankInstitutionIconsView.swift
//  StripePaymentSheet
//

@_spi(InternalOnlyAPI) import StripeCore
import UIKit

/// Shows featured bank institution icons on the trailing end of the instant debits "Bank" row, e.g. Chase, Bank of America, Wells Fargo.
/// Displays 3 fixed icons followed by 1 icon that rotates through the remaining institutions, matching Stripe.js.
/// - Note: Hidden until `FeaturedInstitutionsLoader` has enough icons, and while `isSuppressed` is true (e.g. the row shows a "Change" button).
@MainActor
final class BankInstitutionIconsView: UIView {

    static let iconSize: CGFloat = 24
    static let iconSpacing: CGFloat = 4
    static let iconCornerRadius: CGFloat = 6
    static let fixedIconCount = 3
    static let rotationInterval: TimeInterval = 2
    static let rotationAnimationDuration: TimeInterval = 0.5
    static let fadeInDuration: TimeInterval = 0.25

    /// The width needed to show every icon slot.
    static var fullWidth: CGFloat {
        let slotCount = CGFloat(fixedIconCount + 1)
        return slotCount * iconSize + (slotCount - 1) * iconSpacing
    }

    private enum DisplayMode {
        /// Fixed icons plus the rotating icon
        case full
        /// Only the rotating icon, cycling through every institution
        case compact
        /// Not enough room for a single icon
        case none
    }

    private let loader: FeaturedInstitutionsLoader
    private var icons: [UIImage] = []
    private var displayMode: DisplayMode = .full
    private var rotationIndex = 0
    private var rotationTimer: Timer?

    /// When true, the icons are hidden, e.g. while the row shows a "Change" button after a bank is linked.
    var isSuppressed: Bool = false {
        didSet {
            guard isSuppressed != oldValue else { return }
            updateVisibility()
        }
    }

    private lazy var fixedIconViews: [UIImageView] = (0..<Self.fixedIconCount).map { _ in Self.makeIconView() }
    private let rotatingIconContainer = UIView()
    private var currentRotatingIconView = BankInstitutionIconsView.makeIconView()
    private var nextRotatingIconView = BankInstitutionIconsView.makeIconView()
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: fixedIconViews + [rotatingIconContainer])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Self.iconSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private var rotatingIcons: [UIImage] {
        switch displayMode {
        case .full:
            return Array(icons.dropFirst(Self.fixedIconCount))
        case .compact:
            return icons
        case .none:
            return []
        }
    }

    init(loader: FeaturedInstitutionsLoader) {
        self.loader = loader
        super.init(frame: .zero)
        setupUI()

        // The icons are decorative
        isAccessibilityElement = false
        accessibilityElementsHidden = true

        isHidden = true
        setIcons(loader.icons, animated: false)
        loader.addObserver(self)
    }

    func featuredInstitutionsLoaderDidUpdateIcons(_ icons: [UIImage]) {
        // Only fade in when the icons first appear, not when the rotating icons arrive later
        setIcons(icons, animated: self.icons.isEmpty)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Overrides

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Self.fullWidth, height: Self.iconSize)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // The row may compress us to make room for its labels
        let newDisplayMode: DisplayMode = {
            if bounds.width >= Self.fullWidth {
                return .full
            } else if bounds.width >= Self.iconSize {
                return .compact
            } else {
                return .none
            }
        }()
        guard newDisplayMode != displayMode else { return }
        displayMode = newDisplayMode
        updateIconViews()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        updateRotationTimer()
        logShownIfNeeded()
    }

    // MARK: Private

    private func setupUI() {
        clipsToBounds = true
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentHuggingPriority(.required, for: .horizontal)

        rotatingIconContainer.clipsToBounds = true
        rotatingIconContainer.layer.cornerRadius = Self.iconCornerRadius
        for iconView in [currentRotatingIconView, nextRotatingIconView] {
            iconView.translatesAutoresizingMaskIntoConstraints = false
            rotatingIconContainer.addSubview(iconView)
            NSLayoutConstraint.activate([
                iconView.topAnchor.constraint(equalTo: rotatingIconContainer.topAnchor),
                iconView.bottomAnchor.constraint(equalTo: rotatingIconContainer.bottomAnchor),
                iconView.leadingAnchor.constraint(equalTo: rotatingIconContainer.leadingAnchor),
                iconView.trailingAnchor.constraint(equalTo: rotatingIconContainer.trailingAnchor),
            ])
        }
        nextRotatingIconView.alpha = 0

        addSubview(stackView)
        NSLayoutConstraint.activate([
            rotatingIconContainer.widthAnchor.constraint(equalToConstant: Self.iconSize),
            rotatingIconContainer.heightAnchor.constraint(equalToConstant: Self.iconSize),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
        ])
    }

    private static func makeIconView() -> UIImageView {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = iconCornerRadius
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: iconSize),
            imageView.heightAnchor.constraint(equalToConstant: iconSize),
        ])
        return imageView
    }

    private func setIcons(_ icons: [UIImage], animated: Bool) {
        self.icons = icons
        updateIconViews()
        guard !icons.isEmpty else {
            isHidden = true
            return
        }
        if animated && !isSuppressed {
            alpha = 0
            updateVisibility()
            UIView.animate(withDuration: Self.fadeInDuration) {
                self.alpha = 1
            }
        } else {
            updateVisibility()
        }
    }

    private func updateIconViews() {
        for (index, iconView) in fixedIconViews.enumerated() {
            iconView.image = icons.stp_boundSafeObject(at: index)
            iconView.isHidden = displayMode != .full
        }
        rotatingIconContainer.isHidden = displayMode == .none
        rotationIndex = 0
        currentRotatingIconView.image = rotatingIcons.first
        currentRotatingIconView.transform = .identity
        currentRotatingIconView.alpha = 1
        nextRotatingIconView.alpha = 0
        updateRotationTimer()
        logShownIfNeeded()
    }

    private func updateVisibility() {
        isHidden = icons.isEmpty || isSuppressed
        updateRotationTimer()
        logShownIfNeeded()
    }

    private var isVisibleOnScreen: Bool {
        return window != nil && !isHidden && displayMode != .none
    }

    private func logShownIfNeeded() {
        guard isVisibleOnScreen, !icons.isEmpty else { return }
        loader.logShownIfNeeded()
    }

    private func updateRotationTimer() {
        let shouldRotate = isVisibleOnScreen && rotatingIcons.count > 1
        guard shouldRotate != (rotationTimer != nil) else { return }
        if shouldRotate {
            let timer = Timer(timeInterval: Self.rotationInterval, repeats: true) { [weak self] _ in
                // The timer is scheduled on the main run loop, so it always fires on the main thread
                MainActor.assumeIsolated {
                    self?.rotateToNextIcon()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            rotationTimer = timer
        } else {
            rotationTimer?.invalidate()
            rotationTimer = nil
        }
    }

    private func rotateToNextIcon() {
        let rotatingIcons = rotatingIcons
        guard rotatingIcons.count > 1 else { return }
        rotationIndex = (rotationIndex + 1) % rotatingIcons.count

        let outgoingView = currentRotatingIconView
        let incomingView = nextRotatingIconView
        incomingView.image = rotatingIcons[rotationIndex]
        currentRotatingIconView = incomingView
        nextRotatingIconView = outgoingView

        // Slide the next icon up from below, unless Reduce Motion is enabled; then just crossfade
        let offset = UIAccessibility.isReduceMotionEnabled ? 0 : Self.iconSize
        incomingView.transform = CGAffineTransform(translationX: 0, y: offset)
        incomingView.alpha = 0
        UIView.animate(
            withDuration: Self.rotationAnimationDuration,
            delay: 0,
            usingSpringWithDamping: 1,
            initialSpringVelocity: 0,
            options: [.beginFromCurrentState]
        ) {
            outgoingView.transform = CGAffineTransform(translationX: 0, y: -offset)
            outgoingView.alpha = 0
            incomingView.transform = .identity
            incomingView.alpha = 1
        }
    }
}
