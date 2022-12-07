//
//  STDSJSONWebEncryption.h
//  Stripe3DS2
//
//  Created by Cameron Sabol on 1/24/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "STDSDirectoryServer.h"

@class STDSDirectoryServerCertificate;
@class STDSJSONWebSignature;

NS_ASSUME_NONNULL_BEGIN

@interface STDSJSONWebEncryption : NSObject

+ (nullable NSString *)encryptJSON:(NSDictionary *)json
                forDirectoryServer:(STDSDirectoryServer)directoryServer
                             error:(out NSError * _Nullable *)error;

+ (nullable NSString *)encryptJSON:(NSDictionary *)json
                   withCertificate:(STDSDirectoryServerCertificate *)certificate
                 directoryServerID:(NSString *)directoryServerID
                       serverKeyID:(nullable NSString *)serverKeyID
                             error:(out NSError * _Nullable *)error;

+ (nullable NSString *)directEncryptJSON:(NSDictionary *)json
                withContentEncryptionKey:(NSData *)contentEncryptionKey
                     forACSTransactionID:(NSString *)acsTransactionID
                                   error:(out NSError * _Nullable *)error;

+ (nullable NSDictionary *)decryptData:(NSData *)data
              withContentEncryptionKey:(NSData *)contentEncryptionKey
                                 error:(out NSError * _Nullable *)error;

+ (BOOL)verifyJSONWebSignature:(STDSJSONWebSignature *)jws forDirectoryServer:(STDSDirectoryServer)directoryServer;

+ (BOOL)verifyJSONWebSignature:(STDSJSONWebSignature *)jws withCertificate:(STDSDirectoryServerCertificate *)certificate rootCertificates:(NSArray<NSString *> *)rootCertificates;

@end

NS_ASSUME_NONNULL_END
