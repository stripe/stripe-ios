//
//  STDSException.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/22/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 An abstract class to represent 3DS2 SDK custom exceptions
 */
@interface STDSException : NSException

/**
 A description of the exception.
 */
@property (nonatomic, readonly) NSString *message;

@end

NS_ASSUME_NONNULL_END
