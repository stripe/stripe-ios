//
//  MockSourceProvider.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 3/28/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Stripe

class MockSTPSourceProvider: NSObject, STPSourceProvider {

    var selectedSource: STPSource?
    var sources: [STPSource]? = []
    var onRetrieveSources: (() -> ())?
    var onAddSource: (STPSource -> ())?
    var onSelectSource: (STPSource -> ())?

    /// If set, the appropriate functions will complete with these errors
    var retrieveSourcesError: NSError?
    var addSourceError: NSError?
    var selectSourceError: NSError?

    func retrieveSources(completion: STPSourceCompletionBlock) {
        onRetrieveSources?()
        if let e = retrieveSourcesError {
            completion(nil, nil, e)
        }
        else {
            completion(selectedSource, sources, nil)
        }
    }

    func addSource(source: STPSource, completion: STPSourceCompletionBlock) {
        onAddSource?(source)
        if let e = addSourceError {
            completion(nil, nil, e)
        }
        else {
            sources?.append(source)
            completion(selectedSource, sources, nil)
        }
    }

    func selectSource(source: STPSource, completion: STPSourceCompletionBlock) {
        onSelectSource?(source)
        if let e = selectSourceError {
            completion(nil, nil, e)
        }
        else {
            selectedSource = source
            completion(selectedSource, sources, nil)
        }
    }

}
