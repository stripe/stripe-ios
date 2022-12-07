//
//  STDSRuntimeException.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/22/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSException.h"

NS_ASSUME_NONNULL_BEGIN

/**
 `STDSRuntimeException` represents an exception that will be thrown by the
 Stripe3DS2 SDK if it encounters an internal error.
 */
@interface STDSRuntimeException : STDSException

@end

NS_ASSUME_NONNULL_END
