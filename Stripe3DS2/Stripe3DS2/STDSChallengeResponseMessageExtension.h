//
//  STDSChallengeResponseMessageExtension.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A protocol that encapsulates an individual message extension inside of a challenge response.
@protocol STDSChallengeResponseMessageExtension

/// The name of the extension data set as defined by the extension owner.
@property (nonatomic, readonly) NSString *name;

/// A unique identifier for the extension.
@property (nonatomic, readonly) NSString *identifier;

/// A Boolean value indicating whether the recipient must understand the contents of the extension to interpret the entire message.
@property (nonatomic, readonly, getter = isCriticalityIndicator) BOOL criticalityIndicator;

/// The data carried in the extension.
@property (nonatomic, readonly) NSDictionary *data;

@end

NS_ASSUME_NONNULL_END
