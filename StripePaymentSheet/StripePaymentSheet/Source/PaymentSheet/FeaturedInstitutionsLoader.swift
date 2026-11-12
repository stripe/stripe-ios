//
//  FeaturedInstitutionsLoader.swift
//  StripePaymentSheet
//

import Foundation
@_spi(InternalOnlyAPI) import StripeCore
import UIKit

/// Fetches the featured bank institution icons shown on the trailing end of the instant debits "Bank" row.
/// The fetch is fire-and-forget: rows render without icons and `BankInstitutionIconsView` shows them once they've loaded.
@MainActor
final class FeaturedInstitutionsLoader {

    /// The number of institutions to request. Matches Stripe.js.
    static let fetchCount = 12
    /// The minimum number of icons needed to show anything. Matches Stripe.js.
    static let minimumIconCount = 4

    static func shouldFetch(elementsSession: STPElementsSession, paymentMethodTypes: [PaymentSheet.PaymentMethodType]) -> Bool {
        return elementsSession.isFeaturedInstitutionsEnabled && paymentMethodTypes.contains(where: Self.isBankRow)
    }

    static func isBankRow(_ paymentMethodType: PaymentSheet.PaymentMethodType) -> Bool {
        return paymentMethodType == .instantDebits || paymentMethodType == .linkCardBrand
    }

    /// The downloaded institution icons, in featured order. Empty until loaded, or if fewer than `minimumIconCount` icons are available.
    /// Published as soon as the first `minimumIconCount` icons are ready, then again once the rest (used by the rotating icon) finish.
    private(set) var icons: [UIImage] = [] {
        didSet {
            guard icons != oldValue else { return }
            observers.allObjects.forEach { $0.featuredInstitutionsLoaderDidUpdateIcons(icons) }
        }
    }
    private(set) var fetchTask: Task<Void, Never>?
    private let observers = NSHashTable<BankInstitutionIconsView>.weakObjects()

    private let apiClient: STPAPIClient
    private let analyticsHelper: PaymentSheetAnalyticsHelper?
    private let downloadManager: DownloadManager
    private var didLogShown = false

    init(
        apiClient: STPAPIClient,
        analyticsHelper: PaymentSheetAnalyticsHelper?,
        downloadManager: DownloadManager = .sharedManager
    ) {
        self.apiClient = apiClient
        self.analyticsHelper = analyticsHelper
        self.downloadManager = downloadManager
    }

    /// Creates a loader with icons that are already loaded. Used for tests and snapshots.
    init(icons: [UIImage]) {
        self.apiClient = .shared
        self.analyticsHelper = nil
        self.downloadManager = .sharedManager
        self.icons = icons.count >= Self.minimumIconCount ? icons : []
    }

    func fetch() {
        guard fetchTask == nil else {
            stpAssertionFailure("FeaturedInstitutionsLoader does not support multiple fetches")
            return
        }
        fetchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                let institutions = try await apiClient.featuredInstitutionsForInstantDebits(limit: Self.fetchCount).data
                let downloadedIcons = await downloadIcons(for: institutions) { [weak self] leadingIcons in
                    // Show the icons as soon as there are enough for every slot
                    guard let self, leadingIcons.count >= Self.minimumIconCount, icons.isEmpty else { return }
                    icons = leadingIcons
                }
                guard downloadedIcons.count >= Self.minimumIconCount else {
                    analyticsHelper?.logFeaturedInstitutionsInsufficient(count: downloadedIcons.count)
                    return
                }
                icons = downloadedIcons
            } catch {
                // The icons are decorative, so failing to load them (e.g. while offline) is not unexpected
                analyticsHelper?.logFeaturedInstitutionsLoadFailed(error: error)
            }
        }
    }

    /// Registers `view` to be told whenever `icons` changes. `view` is held weakly.
    func addObserver(_ view: BankInstitutionIconsView) {
        observers.add(view)
    }

    /// Returns the icons once the fetch completes. Returns immediately if there is no fetch in progress.
    func loadedIcons() async -> [UIImage] {
        await fetchTask?.value
        return icons
    }

    /// Logs that the icons were shown, at most once per loader.
    func logShownIfNeeded() {
        guard !didLogShown else { return }
        didLogShown = true
        analyticsHelper?.logFeaturedInstitutionsShown()
    }

    /// Downloads each institution's icon in parallel. Institutions without an icon, and icons that fail to download, are dropped.
    /// - Parameter onLeadingIconsReady: Called as downloads finish, with the icons downloaded so far that have no pending download ahead of them in featured order.
    /// - Returns: Every downloaded icon, in featured order.
    private func downloadIcons(
        for institutions: [FeaturedInstitution],
        onLeadingIconsReady: ([UIImage]) -> Void
    ) async -> [UIImage] {
        let iconURLs = institutions.compactMap(\.iconURL)
        let downloadManager = downloadManager
        // nil means the download failed
        var results: [Int: UIImage?] = [:]
        func leadingIcons() -> [UIImage] {
            var icons: [UIImage] = []
            for index in iconURLs.indices {
                guard let result = results[index] else { break } // Still downloading
                if let icon = result {
                    icons.append(icon)
                }
            }
            return icons
        }
        await withTaskGroup(of: (Int, UIImage?).self) { group in
            for (index, url) in iconURLs.enumerated() {
                group.addTask {
                    return (index, try? await downloadManager.downloadImage(url: url))
                }
            }
            for await (index, image) in group {
                results[index] = .some(image)
                onLeadingIconsReady(leadingIcons())
            }
        }
        return leadingIcons()
    }
}
