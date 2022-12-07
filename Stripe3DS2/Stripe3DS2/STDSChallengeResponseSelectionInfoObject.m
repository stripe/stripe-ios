//
//  STDSChallengeResponseSelectionInfoObject.m
//  Stripe3DS2
//
//  Created by Andrew Harrison on 2/25/19.
//  Copyright © 2019 Stripe. All rights reserved.
//

#import "STDSChallengeResponseSelectionInfoObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface STDSChallengeResponseSelectionInfoObject()

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *value;

@end

@implementation STDSChallengeResponseSelectionInfoObject

- (instancetype)initWithName:(NSString *)name value:(NSString *)value {
    self = [super init];
    
    if (self) {
        _name = name;
        _value = value;
    }
    
    return self;
}

+ (nullable instancetype)decodedObjectFromJSON:(nullable NSDictionary *)json error:(NSError * _Nullable __autoreleasing * _Nullable)outError {
    if (json == nil) {
        return nil;
    }
    
    NSString *name = [json allKeys].firstObject;
    NSString *value = [json objectForKey:name];
    
    return [[STDSChallengeResponseSelectionInfoObject alloc] initWithName:name value:value];
}

@end

NS_ASSUME_NONNULL_END
