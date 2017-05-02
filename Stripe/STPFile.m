//
//  STPFile.m
//  Stripe
//
//  Created by Charles Scalesse on 11/30/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPFile.h"
#import "NSDictionary+Stripe.h"

@interface STPFile ()

@property (nonatomic, readwrite) NSString *fileId;
@property (nonatomic, readwrite) NSDate *created;
@property (nonatomic, readwrite) STPFilePurpose purpose;
@property (nonatomic, readwrite) NSNumber *size;
@property (nonatomic, readwrite) NSString *type;
@property (nonatomic, readwrite, copy) NSDictionary *allResponseFields;

- (BOOL)isEqualToFile:(STPFile *)file;

@end

@implementation STPFile

#pragma mark - Helpers

+ (NSDictionary<NSString *,NSNumber *>*)stringToPurpose {
    return @{
             @"dispute_evidence": @(STPFilePurposeDisputeEvidence),
             @"identity_document": @(STPFilePurposeIdentityDocument),
             };
}

+ (STPFilePurpose)purposeFromString:(NSString *)string {
    NSString *key = [string lowercaseString];
    NSNumber *value = [self stringToPurpose][key];
    if (value) {
        return (STPFilePurpose)[value integerValue];
    } else {
        return STPFilePurposeUnknown;
    }
}

+ (NSString *)stringFromPurpose:(STPFilePurpose)purpose {
    return [[[self stringToPurpose] allKeysForObject:@(purpose)] firstObject];
}

#pragma mark - Equality

- (BOOL)isEqual:(STPFile *)file {
    return [self isEqualToFile:file];
}

- (NSUInteger)hash {
    return [self.fileId hash];
}

- (BOOL)isEqualToFile:(STPFile *)file {
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

+ (instancetype)decodedObjectFromAPIResponse:(NSDictionary *)response {
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
