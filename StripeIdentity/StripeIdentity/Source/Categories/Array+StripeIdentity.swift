//
//  Array+StripeIdentity.swift
//  StripeIdentity
//
//  Created by Mel Ludowise on 5/10/22.
//

import Foundation

// Borrowed from https://stackoverflow.com/a/47210788/4133371
extension Array {
    func sum<T: FloatingPoint>(with transform: (Element) -> T) -> T {
        return self.reduce(0) { partialResult, element in
            return partialResult + transform(element)
        }
    }

    func average<T: FloatingPoint>(with transform: (Element) -> T) -> T {
        return sum(with: transform) / T(self.count)
    }

    func standardDeviation<T: FloatingPoint>(with transform: (Element) -> T) -> T {
        let mean = average(with: transform)

        let v: T = reduce(0) { partialResult, element in
            let distanceToMean = transform(element) - mean
            return partialResult + (distanceToMean * distanceToMean)
        }

        return sqrt(v / (T(self.count) - 1))
    }
}
