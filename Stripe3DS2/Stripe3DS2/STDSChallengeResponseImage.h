//
//  STDSChallengeResponseImage.h
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// A protocol used to represent information about an individual image resource inside of a challenge response.
@protocol STDSChallengeResponseImage

/// A medium density image to display as the issuer image.
@property (nonatomic, readonly, nullable) NSURL *mediumDensityURL;

/// A high density image to display as the issuer image.
@property (nonatomic, readonly, nullable) NSURL *highDensityURL;

/// An extra-high density image to display as the issuer image.
@property (nonatomic, readonly, nullable) NSURL *extraHighDensityURL;

@end

NS_ASSUME_NONNULL_END
