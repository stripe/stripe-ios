//
//  STPStringUtils.m
//  Stripe
//
//  Created by Brian Dorfman on 9/7/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPStringUtils.h"

@implementation STPStringUtils

+ (void)parseRangesFromString:(NSString *)string
                     withTags:(NSSet<NSString *> *)tags 
                   completion:(STPTaggedSubstringsCompletionBlock)completion {
    if (!completion) {
        return;
    }
    
    NSMutableDictionary<NSValue *, NSString *> *interiorRangesToTags = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, NSValue *> *tagsToRange = [NSMutableDictionary new];
    
    for (NSString *tag in tags) {
        [self parseRangeFromString:string 
                           withTag:tag
                        completion:^(NSString *__unused newString, NSRange tagRange) {
                            if (tagRange.location == NSNotFound) {
                                tagsToRange[tag] = [NSValue valueWithRange:tagRange];
                            } else {
                                NSRange interiorRange = NSMakeRange(tagRange.location + tag.length + 2, 
                                                            tagRange.length);
                                interiorRangesToTags[[NSValue valueWithRange:interiorRange]] = tag;
                            }
                        }];
        
    }
    
    NSArray<NSValue *> *sortedRanges = [[interiorRangesToTags allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSValue *  _Nonnull obj1, NSValue *  _Nonnull obj2) {
        NSRange range1 = obj1.rangeValue;
        NSRange range2 = obj2.rangeValue;
        
        if (range1.location < range2.location) {
            return NSOrderedAscending;
        } else if (range1.location > range2.location) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    
    NSMutableString *modifiedString = string.mutableCopy;
    
    NSUInteger deletedCharacters = 0;
    
    
    for (NSValue *rangeValue in sortedRanges) {
        NSString *tag = interiorRangesToTags[rangeValue];
        NSRange interiorTagRange = [rangeValue rangeValue];
        if (interiorTagRange.location != NSNotFound) {
            interiorTagRange.location -= deletedCharacters;
            NSInteger beginningTagLength = tag.length + 2;
            NSRange beginningTagRange = NSMakeRange(interiorTagRange.location - beginningTagLength, 
                                                    beginningTagLength);
            
            [modifiedString deleteCharactersInRange:beginningTagRange];
            interiorTagRange.location -= beginningTagLength;
            deletedCharacters += beginningTagLength;
            
            NSInteger endingTagLength = beginningTagLength + 1;
            NSRange endingTagRange = NSMakeRange(interiorTagRange.location + interiorTagRange.length, 
                                                 endingTagLength);
            
            [modifiedString deleteCharactersInRange:endingTagRange];
            deletedCharacters += endingTagLength;
            tagsToRange[tag] = [NSValue valueWithRange:interiorTagRange];
        }
    }
    
    completion(modifiedString.copy, tagsToRange.copy);
}

+ (void)parseRangeFromString:(NSString *)string 
                     withTag:(NSString *)tag
                  completion:(STPTaggedSubstringCompletionBlock)completion {
    if (!completion) {
        return;
    }
    
    NSString *startingTag = [NSString stringWithFormat:@"<%@>", tag];
    NSRange startingTagRange = [string rangeOfString:startingTag];
    if (startingTagRange.location == NSNotFound) {
        completion(string, startingTagRange);
        return;
    }
    
    NSString *finalString = [string stringByReplacingCharactersInRange:startingTagRange
                                                            withString:@""];
    NSString *endingTag = [NSString stringWithFormat:@"</%@>", tag];
    NSRange endingTagRange = [finalString rangeOfString:endingTag];
    if (endingTagRange.location == NSNotFound) {
        completion(string, endingTagRange);
        return;
    }
    
    finalString = [finalString stringByReplacingCharactersInRange:endingTagRange
                                                       withString:@""];
    NSRange finalTagRange = NSMakeRange(startingTagRange.location, 
                                        endingTagRange.location - startingTagRange.location);
    
    completion(finalString, finalTagRange);
}

+ (NSString *)expirationDateStringFromString:(NSString *)string {
    // This code was adapted from Stripe.js
    static dispatch_once_t onceToken;
    static NSRegularExpression *regex = nil;
    dispatch_once(&onceToken, ^{
        regex = [[NSRegularExpression alloc] initWithPattern:@"^(\\d{2}\\D{1,3})(\\d{1,4})?"
                                                     options:0
                                                       error:NULL];
    });
    NSTextCheckingResult *result = [[regex matchesInString:string options:0 range:NSMakeRange(0, string.length)] firstObject];
    if (result && [result numberOfRanges] > 1 && [result rangeAtIndex:2].length == 4) {
        // If a 4-digit year was pasted, shorten it to the last 2 digits
        NSRange range = [result rangeAtIndex:2];
        range.length = 2;
        range.location = range.location + 2;
        NSString *month = [string substringWithRange:[result rangeAtIndex:1]];
        NSString *year = [string substringWithRange:range];
        return [NSString stringWithFormat:@"%@%@", month, year];
    }
    
    return string;
}

@end
