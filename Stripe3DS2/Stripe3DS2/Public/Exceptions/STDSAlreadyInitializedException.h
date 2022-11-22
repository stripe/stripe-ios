//
//  STDSAlreadyInitializedException.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/22/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSException.h"

NS_ASSUME_NONNULL_BEGIN

/**
 `STDSAlreadyInitializedException` represents an exception that will be thrown in the `STDSThreeDS2Service` instance has already been initialized.

 @see STDSThreeDS2Service
 */
@interface STDSAlreadyInitializedException : STDSException

@end

NS_ASSUME_NONNULL_END
