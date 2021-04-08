//
//  STDSJSONWebSignature.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 4/2/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

@class STDSEllipticCurvePoint;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, STDSJSONWebSignatureAlgorithm) {
    STDSJSONWebSignatureAlgorithmES256,
    STDSJSONWebSignatureAlgorithmPS256,
    STDSJSONWebSignatureAlgorithmUnknown,
};

@interface STDSJSONWebSignature : NSObject

- (nullable instancetype)initWithString:(NSString *)jwsString;
- (nullable instancetype)initWithString:(NSString *)jwsString allowNilKey:(BOOL)allowNilKey;

@property (nonatomic, readonly) STDSJSONWebSignatureAlgorithm algorithm;

@property (nonatomic, readonly) NSData *digest;
@property (nonatomic, readonly) NSData *signature;

@property (nonatomic, readonly) NSData *payload;

/// non-nil if algorithm == STDSJSONWebSignatureAlgorithmES256
@property (nonatomic, nullable, readonly) STDSEllipticCurvePoint *ellipticCurvePoint;

/// non-nil if algorithm == STDSJSONWebSignatureAlgorithmPS256, can be non-nil for algorithm == STDSJSONWebSignatureAlgorithmES256
@property (nonatomic, nullable, readonly) NSArray<NSString *> *certificateChain;

@end

NS_ASSUME_NONNULL_END
