//
//  PKComponent.m
//  Stripe
//
//  Created by Phil Cohen on 12/18/13.
//
//

#import "PKComponent.h"

@implementation PKComponent

- (id)initWithString:(NSString *)string
{
    return (self = [super init]);
}

- (NSString *)string
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (BOOL)isValid
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (BOOL)isPartiallyValid
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (NSString *)formattedString
{
    return [self string];
}

- (NSString *)formattedStringWithTrail
{
    return [self string];
}

@end
