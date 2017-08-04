//
//  STPFile.m
//  Stripe
//
//  Created by Charles Scalesse on 11/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPFile.h"
#import "STPFile+Private.h"

#import "NSDictionary+Stripe.h"

NS_ASSUME_NONNULL_BEGIN

@interface STPFile ()

@property (nonatomic, copy, readwrite) NSString *fileId;
@property (nonatomic, copy, readwrite) NSDate *created;
@property (nonatomic, assign, readwrite) STPFilePurpose purpose;
@property (nonatomic, copy, readwrite) NSNumber *size;
@property (nonatomic, copy, readwrite) NSString *type;
@property (nonatomic, copy, readwrite, copy) NSDictionary *allResponseFields;

- (BOOL)isEqualToFile:(nullable STPFile *)file;

// See STPFile+Private.h

@end

@implementation STPFile

#pragma mark - STPFilePurpose

+ (NSDictionary<NSString *,NSNumber *> *)stringToPurposeMapping {
    return @{
             @"business_logo": @(STPFilePurposeBusinessLogo),
             @"dispute_evidence": @(STPFilePurposeDisputeEvidence),
             @"identity_document": @(STPFilePurposeIdentityDocument),
             @"incorporation_article": @(STPFilePurposeIncorporationArticle),
             @"incorporation_document": @(STPFilePurposeIncorporationDocument),
             @"invoice_statement": @(STPFilePurposeInvoiceStatement),
             @"payment_provider_transfer": @(STPFilePurposePaymentProviderTransfer),
             @"product_feed": @(STPFilePurposeProductFeed),
             };
}

+ (STPFilePurpose)purposeFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *purposeNumber = [self stringToPurposeMapping][key];

    if (purposeNumber) {
        return (STPFilePurpose)[purposeNumber integerValue];
    }

    return STPFilePurposeUnknown;
}

+ (nullable NSString *)stringFromPurpose:(STPFilePurpose)purpose {
    return [[[self stringToPurposeMapping] allKeysForObject:@(purpose)] firstObject];
}

#pragma mark - Equality

- (BOOL)isEqual:(nullable id)object {
    return [self isEqualToFile:object];
}

- (NSUInteger)hash {
    return [self.fileId hash];
}

- (BOOL)isEqualToFile:(nullable STPFile *)file {
    if (self == file) {
        return YES;
    }
    
    if (!file || ![file isKindOfClass:self.class]) {
        return NO;
    }
    
    return [self.fileId isEqualToString:file.fileId];
}

#pragma mark  - STPAPIResponseDecodable

+ (NSArray *)requiredFields {
    return @[@"id", @"created", @"size", @"purpose", @"type"];
}

+ (nullable instancetype)decodedObjectFromAPIResponse:(nullable NSDictionary *)response {
    NSDictionary *dict = [response stp_dictionaryByRemovingNullsValidatingRequiredFields:[self requiredFields]];
    if (!dict) {
        return nil;
    }
    
    STPFile *file = [[self alloc] init];
    file.fileId = dict[@"id"];
    file.created = [[NSDate alloc] initWithTimeIntervalSince1970:[dict[@"created"] doubleValue]];
    file.size = dict[@"size"];
    file.type = dict[@"type"];
    
    NSString *purpose = dict[@"purpose"];
    file.purpose = [self.class purposeFromString:purpose];
    file.allResponseFields = dict;
    
    return file;
}

@end

NS_ASSUME_NONNULL_END
