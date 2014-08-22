//
//  PKTextField.m
//  PaymentKit Example
//
//  Created by Michaël Villar on 3/20/13.
//  Copyright (c) 2013 Stripe. All rights reserved.
//

#import "PKTextField.h"

#define kPKTextFieldSpaceChar @"\u200B"

@implementation PKTextField

+ (NSString *)textByRemovingUselessSpacesFromString:(NSString *)string
{
    return [string stringByReplacingOccurrencesOfString:kPKTextFieldSpaceChar withString:@""];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.text = kPKTextFieldSpaceChar;
        [self addObserver:self forKeyPath:@"text" options:0 context:NULL];
    }
    return self;
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"text"];
}

- (void)drawPlaceholderInRect:(CGRect)rect
{

}

- (void)drawRect:(CGRect)rect
{
    if (self.text.length == 0 || [self.text isEqualToString:kPKTextFieldSpaceChar]) {
        CGRect placeholderRect = self.bounds;
        placeholderRect.origin.y += 0.5;
        [super drawPlaceholderInRect:placeholderRect];
    }
    else
        [super drawRect:rect];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"text"] && object == self) {
        if (self.text.length == 0) {
            if ([self.delegate respondsToSelector:@selector(pkTextFieldDidBackSpaceWhileTextIsEmpty:)])
                [self.delegate performSelector:@selector(pkTextFieldDidBackSpaceWhileTextIsEmpty:)
                                    withObject:self];
            self.text = kPKTextFieldSpaceChar;
        }
        [self setNeedsDisplay];
    }
}

@end
