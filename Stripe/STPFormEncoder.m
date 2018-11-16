//
//  STPFormEncoder.m
//  Stripe
//
//  Created by Jack Flintermann on 1/8/15.
//  Copyright (c) 2015 Stripe, Inc. All rights reserved.
//

#import "STPFormEncoder.h"

#import "STPFormEncodable.h"

FOUNDATION_EXPORT NSString * STPPercentEscapedStringFromString(NSString *string);
FOUNDATION_EXPORT NSString * STPQueryStringFromParameters(NSDictionary *parameters);

@implementation STPFormEncoder

+ (NSString *)stringByReplacingSnakeCaseWithCamelCase:(NSString *)input {
    NSArray *parts = [input componentsSeparatedByString:@"_"];
    NSMutableString *camelCaseParam = [NSMutableString string];
    [parts enumerateObjectsUsingBlock:^(NSString *part, NSUInteger idx, __unused BOOL *stop) {
        [camelCaseParam appendString:(idx == 0 ? part : [part capitalizedString])];
    }];
    
    return [camelCaseParam copy];
}

+ (NSDictionary *)dictionaryForObject:(nonnull NSObject<STPFormEncodable> *)object {
    NSDictionary *keyPairs = [self keyPairDictionaryForObject:object];
    NSString *rootObjectName = [object.class rootObjectName];
    NSDictionary *dict = rootObjectName != nil ? @{ rootObjectName: keyPairs } : keyPairs;
    return dict;
}

+ (NSDictionary *)keyPairDictionaryForObject:(nonnull NSObject<STPFormEncodable> *)object {
    NSMutableDictionary *keyPairs = [NSMutableDictionary dictionary];
    [[object.class propertyNamesToFormFieldNamesMapping] enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull propertyName, NSString *  _Nonnull formFieldName, __unused BOOL * _Nonnull stop) {
        id value = [self formEncodableValueForObject:[object valueForKey:propertyName]];
        if (value) {
            keyPairs[formFieldName] = value;
        }
    }];
    [object.additionalAPIParameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull additionalFieldName, id  _Nonnull additionalFieldValue, __unused BOOL * _Nonnull stop) {
        id value = [self formEncodableValueForObject:additionalFieldValue];
        if (value) {
            keyPairs[additionalFieldName] = value;
        }
    }];
    return [keyPairs copy];
}

+ (id)formEncodableValueForObject:(NSObject *)object {
    if ([object conformsToProtocol:@protocol(STPFormEncodable)]) {
        return [self keyPairDictionaryForObject:(NSObject<STPFormEncodable>*)object];
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dict = (NSDictionary *)object;
        NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:dict.count];

        [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull value, __unused BOOL * _Nonnull stop) {
            result[[self formEncodableValueForObject:key]] = [self formEncodableValueForObject:value];
        }];

        return result;
    } else if ([object isKindOfClass:[NSArray class]]) {
        NSArray *array = (NSArray *)object;
        NSMutableArray *result = [NSMutableArray arrayWithCapacity:array.count];

        for (NSObject *element in array) {
            [result addObject:[self formEncodableValueForObject:element]];
        }
        return result;
    } else if ([object isKindOfClass:[NSSet class]]) {
        NSSet *set = (NSSet *)object;
        NSMutableSet *result = [NSMutableSet setWithCapacity:set.count];

        for (NSObject *element in set) {
            [result addObject:[self formEncodableValueForObject:element]];
        }
        return result;
    } else {
        return object;
    }
}

+ (NSString *)stringByURLEncoding:(NSString *)string {
    return STPPercentEscapedStringFromString(string);
}

+ (NSString *)queryStringFromParameters:(NSDictionary *)parameters {
    return STPQueryStringFromParameters(parameters);
}

@end


// This code is adapted from https://github.com/AFNetworking/AFNetworking/blob/master/AFNetworking/AFURLRequestSerialization.m . The only modifications are to replace the AF namespace with the STP namespace to avoid collisions with apps that are using both Stripe and AFNetworking.
NSString * STPPercentEscapedStringFromString(NSString *string) {
    static NSString * const kSTPCharactersGeneralDelimitersToEncode = @":#[]@"; // does not include "?" or "/" due to RFC 3986 - Section 3.4
    static NSString * const kSTPCharactersSubDelimitersToEncode = @"!$&'()*+,;=";
    
    NSMutableCharacterSet * allowedCharacterSet = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowedCharacterSet removeCharactersInString:[kSTPCharactersGeneralDelimitersToEncode stringByAppendingString:kSTPCharactersSubDelimitersToEncode]];
    
    // FIXME: https://github.com/AFNetworking/AFNetworking/pull/3028
    // return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
    
    static NSUInteger const batchSize = 50;
    
    NSUInteger index = 0;
    NSMutableString *escaped = @"".mutableCopy;
    
    while (index < string.length) {
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wgnu"
        NSUInteger length = MIN(string.length - index, batchSize);
#pragma GCC diagnostic pop
        NSRange range = NSMakeRange(index, length);
        
        // To avoid breaking up character sequences such as 👴🏻👮🏽
        range = [string rangeOfComposedCharacterSequencesForRange:range];
        
        NSString *substring = [string substringWithRange:range];
        NSString *encoded = [substring stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
        [escaped appendString:encoded];
        
        index += range.length;
    }
    
    return escaped;
}

#pragma mark -

@interface STPQueryStringPair : NSObject
@property (readwrite, nonatomic, strong) id field;
@property (readwrite, nonatomic, strong) id value;

- (instancetype)initWithField:(id)field value:(id)value;

- (NSString *)stringValue;
@end

@implementation STPQueryStringPair

- (instancetype)initWithField:(id)field value:(id)value {
    self = [super init];
    if (!self) {
        return nil;
    }
    
    _field = field;
    _value = value;
    
    return self;
}

- (NSString *)stringValue {
    if (!self.value || [self.value isEqual:[NSNull null]]) {
        return [self.field description] ? : @"";
    } else {
        return [NSString stringWithFormat:@"%@=%@", [self.field description], [self.value description]];
    }
}

@end

#pragma mark -

FOUNDATION_EXPORT NSArray * STPQueryStringPairsFromKeyAndValue(NSString *key, id value);
FOUNDATION_EXPORT id STPPercentEscapedObject(id object);

NSString * STPQueryStringFromParameters(NSDictionary *parameters) {
    
    if (!parameters) {
        return @"";
    }
    
    // Escape any reserved characters. due to the implementation of `STPQueryStringPairsFromKeyAndValue`, it's much easier to do this now, as when that function is called recursively on a dictionary, `key` will (correctly) contain characters like `[]`.
    NSDictionary *escaped = STPPercentEscapedObject(parameters);
    
    NSString *descriptionSelector = NSStringFromSelector(@selector(description));
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:descriptionSelector ascending:YES selector:@selector(compare:)];
    
    // For each dictionary key-value pair, form-encode the pair (potentially recursively). Thus {foo: {bar: "baz"}} becomes the tuple, ("foo[bar]", "baz"). Each one of these tuples will become a key/value pair in the final query string (e.g. POST /v1/charges?foo[bar]=baz).
    NSMutableArray *mutablePairs = [NSMutableArray array];    
    for (id key in [escaped.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
        id value = escaped[key];
        NSArray *pairs = STPQueryStringPairsFromKeyAndValue(key, value);
        [mutablePairs addObjectsFromArray:pairs];
    }
    
    NSMutableArray *mutablePathComponents = [NSMutableArray array];
    for (STPQueryStringPair *pair in mutablePairs) {
        [mutablePathComponents addObject:[pair stringValue]];
    }
    
    return [mutablePathComponents componentsJoinedByString:@"&"];
}

// This function recursively converts an object into a version that is safe to convert into
// a form-encoded path string by escaping any reserved characters in it or its children.
id STPPercentEscapedObject(id object) {
    if (!object || object == [NSNull null]) {
        return @"";
    } else if ([object isKindOfClass:[NSArray class]]) {
        NSMutableArray *escapedArray = [NSMutableArray array];
        for (id subObject in object) {
            [escapedArray addObject:STPPercentEscapedObject(subObject)];
        }
        return escapedArray;
    } else if ([object isKindOfClass:[NSSet class]]) {
        NSMutableSet *escapedSet = [NSMutableSet set];
        for (id subObject in object) {
            [escapedSet addObject:STPPercentEscapedObject(subObject)];
        }
        return escapedSet;
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *escapedDictionary = [NSMutableDictionary dictionary];
        for (id key in object) {
            id escapedKey = STPPercentEscapedStringFromString([key description]);
            id subObject = object[key];
            escapedDictionary[escapedKey] = STPPercentEscapedObject(subObject);
        }
        return escapedDictionary;
    } else if ([object isKindOfClass:[NSNumber class]]
               && (CFBooleanGetTypeID() == CFGetTypeID((__bridge CFTypeRef)(object)))) {
        // Unbox NSNumbers containing booleans
        // https://stackoverflow.com/a/30223989/1196205
        return [object boolValue] ? @"true" : @"false";
    } else {
        return STPPercentEscapedStringFromString([object description]);
    }
}

NSArray * STPQueryStringPairsFromKeyAndValue(NSString *key, id value) {
    NSMutableArray *mutableQueryStringComponents = [NSMutableArray array];
    NSString *descriptionSelector = NSStringFromSelector(@selector(description));
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:descriptionSelector ascending:YES selector:@selector(compare:)];
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        // Sort dictionary keys to ensure consistent ordering in query string, which is important when serializing potentially ambiguous sequences, such as an array of dictionaries
        for (id nestedKey in [dictionary.allKeys sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            id nestedValue = dictionary[nestedKey];
            // Call ourselves recursively, building up a larger param string
            NSString *combinedKey = [NSString stringWithFormat:@"%@[%@]", key, nestedKey];
            [mutableQueryStringComponents addObjectsFromArray:STPQueryStringPairsFromKeyAndValue(combinedKey, nestedValue)];
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        [array enumerateObjectsUsingBlock:^(id  _Nonnull nestedValue, NSUInteger idx, __unused BOOL * _Nonnull stop) {
            [mutableQueryStringComponents addObjectsFromArray:STPQueryStringPairsFromKeyAndValue([NSString stringWithFormat:@"%@[%lu]", key, (unsigned long)idx], nestedValue)];
        }];
    } else if ([value isKindOfClass:[NSSet class]]) {
        NSSet *set = value;
        for (id obj in [set sortedArrayUsingDescriptors:@[ sortDescriptor ]]) {
            [mutableQueryStringComponents addObjectsFromArray:STPQueryStringPairsFromKeyAndValue(key, obj)];
        }
    } else {
        [mutableQueryStringComponents addObject:[[STPQueryStringPair alloc] initWithField:key value:value]];
    }
    
    return mutableQueryStringComponents;
}
