//
//  STDSChallengeResponseSelectionInfo.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A protocol that encapsulates information about an individual selection inside of a challenge response.
@protocol STDSChallengeResponseSelectionInfo

/// The name of the selection option.
@property (nonatomic, readonly) NSString *name;

/// The value of the selection option.
@property (nonatomic, readonly) NSString *value;

@end

NS_ASSUME_NONNULL_END
