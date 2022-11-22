//
//  STDSDirectoryServerCertificate+Internal.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 4/2/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STDSDirectoryServerCertificate.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSDirectoryServerCertificate (Internal)

/// Verifies the certificate chain represented by certificates where each element is a base64 encoded (NOT base64url) certificate
+ (BOOL)_verifyCertificateChain:(NSArray<NSString *> *)certificates withRootCertificates:(NSArray<NSString *> *)rootCertificates;

@end

NS_ASSUME_NONNULL_END
