//
//  STDSChallengeResponseMessageExtensionObject.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STDSChallengeResponseMessageExtension.h"

#import "STDSJSONDecodable.h"

NS_ASSUME_NONNULL_BEGIN

/// An object used to represent an individual message extension inside of a challenge response.
@interface STDSChallengeResponseMessageExtensionObject: NSObject <STDSChallengeResponseMessageExtension, STDSJSONDecodable>

@end

NS_ASSUME_NONNULL_END
