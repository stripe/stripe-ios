//
//  STDSChallengeResponseImageObject.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSChallengeResponseImageObject.h"

#import "NSDictionary+DecodingHelpers.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSChallengeResponseImageObject()

@property (nonatomic, nullable) NSURL *mediumDensityURL;
@property (nonatomic, nullable) NSURL *highDensityURL;
@property (nonatomic, nullable) NSURL *extraHighDensityURL;

@end

@implementation STDSChallengeResponseImageObject

- (instancetype)initWithMediumDensityURL:(NSURL * _Nullable)mediumDensityURL highDensityURL:(NSURL * _Nullable)highDensityURL extraHighDensityURL:(NSURL * _Nullable)extraHighDensityURL {
    self = [super init];
    
    if (self) {
        _mediumDensityURL = mediumDensityURL;
        _highDensityURL = highDensityURL;
        _extraHighDensityURL = extraHighDensityURL;
    }
    
    return self;
}

+ (nullable instancetype)decodedObjectFromJSON:(nullable NSDictionary *)json error:(NSError * _Nullable __autoreleasing * _Nullable)outError {
    if (json == nil) {
        return nil;
    }
    
    NSURL *mediumDensityURL = [json _stds_urlForKey:@"medium" required:NO error:nil];
    NSURL *highDensityURL = [json _stds_urlForKey:@"high" required:NO error:nil];
    NSURL *extraHighDensityURL = [json _stds_urlForKey:@"extraHigh" required:NO error:nil];
    
    return [[STDSChallengeResponseImageObject alloc] initWithMediumDensityURL:mediumDensityURL
                                                               highDensityURL:highDensityURL
                                                          extraHighDensityURL:extraHighDensityURL];
}

@end

NS_ASSUME_NONNULL_END
