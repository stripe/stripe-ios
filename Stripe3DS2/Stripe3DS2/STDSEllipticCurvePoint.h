//
//  STDSEllipticCurvePoint.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 3/20/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface STDSEllipticCurvePoint : NSObject

- (nullable instancetype)initWithX:(NSData *)x y:(NSData *)y;
- (nullable instancetype)initWithCertificateData:(NSData *)certificateData;
- (nullable instancetype)initWithKey:(SecKeyRef)key;
- (nullable instancetype)initWithJWK:(NSDictionary *)jwk;

@property (nonatomic, readonly) NSData *x;
@property (nonatomic, readonly) NSData *y;

@property (nonatomic, readonly) SecKeyRef publicKey;

@end
NS_ASSUME_NONNULL_END
