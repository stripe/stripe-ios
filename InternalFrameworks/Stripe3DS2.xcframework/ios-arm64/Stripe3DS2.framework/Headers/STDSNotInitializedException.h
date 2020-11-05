//
//  STDSNotInitializedException.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 2/13/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSException.h"

NS_ASSUME_NONNULL_BEGIN

/**
 `STDSNotInitializedException` represents an exception that will be thrown by
 the the Stripe3DS2 SDK if methods are called without initializing `STDSThreeDS2Service`.

 @see STDSThreeDS2Service
 */
@interface STDSNotInitializedException : STDSException

@end

NS_ASSUME_NONNULL_END
