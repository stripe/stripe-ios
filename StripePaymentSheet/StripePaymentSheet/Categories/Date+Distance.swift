//
//  Date+Distance.swift
//  StripeiOS
//
//  Created by Nick Porter on 9/9/22.
//  Copyright © 2022 Stripe, Inc. All rights reserved.
//

import Foundation

extension Date {
    
    public func compatibleDistance(to other: Date) -> TimeInterval {
        if #available(iOS 13.0, *) {
            return self.distance(to: other)
        }
        
        return TimeInterval(
            Calendar.autoupdatingCurrent.dateComponents([Calendar.Component.second], from: self, to: other).second ?? 0
        )
    }
}
