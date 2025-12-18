//
//  FormSpecProvider.swift
//  StripePaymentSheet
//
//  Created by Yuki Tokuhiro on 2/21/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation
@_spi(STP) import StripeCore

// Note: Local form specs file has been removed. All form specs now come from the server via loadFrom().
private let formSpecsURL = StripePaymentSheetBundleLocator.resourcesBundle.url(forResource: "form_specs", withExtension: ".json")

/// Provides FormSpecs for a given a payment method type.
/// - Note: Form specs are now loaded from the server via `loadFrom()` which is called during PaymentSheet initialization.
/// - Form specs are no longer used for form generation, only for metadata like selector icons.
class FormSpecProvider {
    enum Error: Swift.Error {
        case failedToLoadSpecs
        case formSpecsNotReady
    }
    static var shared: FormSpecProvider = FormSpecProvider()
    fileprivate var formSpecs: [String: FormSpec] = [:]

    /// Loading from disk should take place on this serial queue.
    private let formSpecsUpdateQueue = DispatchQueue(label: "com.stripe.Form.FormSpecProvider", qos: .userInitiated)

    var isLoaded: Bool {
        return !formSpecs.isEmpty
    }

    var hasLoadedFromDisk: Bool = false

    /// Loads the JSON form spec from disk into memory
    /// - Note: This is now a no-op as local form specs have been removed. All specs come from the server.
    func load(completion: ((Bool) -> Void)? = nil) {
        formSpecsUpdateQueue.async { [weak self] in
            if self?.hasLoadedFromDisk == true {
                completion?(true)
                return
            }

            // Local form specs file has been removed. Mark as loaded to prevent repeated attempts.
            self?.hasLoadedFromDisk = true

            // If there's a local file (for backwards compatibility), try to load it
            if let formSpecsURL = formSpecsURL {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                do {
                    let data = try Data(contentsOf: formSpecsURL)
                    let decodedFormSpecs = try decoder.decode([FormSpec].self, from: data)
                    self?.formSpecs = Dictionary(uniqueKeysWithValues: decodedFormSpecs.map { ($0.type, $0) })
                } catch {
                    // Local file not found or invalid - this is expected. Server specs will be loaded via loadFrom().
                }
            }

            completion?(true)
        }
    }
    
    func load() async {
        await withCheckedContinuation { continuation in
            load { _ in
                continuation.resume()
            }
        }
    }

    /// Allows overwriting of formSpecs given a NSDictionary.  Typically, the specs comes
    /// from the sessions endpoint.
    func loadFrom(_ formSpecsAny: Any) -> Bool {
        guard let formSpecs = formSpecsAny as? [NSDictionary] else {
            STPAnalyticsClient.sharedClient.logLUXESerializeFailure()
            return false
        }

        var decodedSuccessfully = true
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        for formSpec in formSpecs {
            do {
                let data = try JSONSerialization.data(withJSONObject: formSpec)
                let decodedFormSpec = try decoder.decode(FormSpec.self, from: data)
                self.formSpecs[decodedFormSpec.type] = decodedFormSpec
            } catch {
                STPAnalyticsClient.sharedClient.logLUXESpecSerilizeFailure(error: error)
                decodedSuccessfully = false
            }
        }
        return decodedSuccessfully
    }

    func formSpec(for paymentMethodType: String) -> FormSpec? {
        if formSpecs.isEmpty {
            let errorAnalytic = ErrorAnalytic(event: .unexpectedPaymentSheetError,
                                              error: Error.formSpecsNotReady,
                                              additionalNonPIIParams: ["payment_method_type": paymentMethodType])
            STPAnalyticsClient.sharedClient.log(analytic: errorAnalytic)
        }
        stpAssert(!formSpecs.isEmpty, "formSpec(for:) was called before loading form specs JSON!")
        return formSpecs[paymentMethodType]
    }
}
