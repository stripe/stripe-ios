//
//  UIViewController+Stripe_KeyboardAvoiding.m
//  Stripe
//
//  Created by Jack Flintermann on 4/15/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "UIViewController+Stripe_KeyboardAvoiding.h"
#import "UIView+Stripe_FirstResponder.h"

// This is a private class that is only a UIViewController subclass by virtue of the fact
// that that makes it easier to attach to another UIViewController as a child.
@interface STPKeyboardDetectingViewController : UIViewController
@property(weak, nonatomic) UIScrollView *scrollView;
@property(nonatomic) CGPoint originalContentOffset;
@property(nonatomic) CGFloat currentScroll;
@end

@implementation STPKeyboardDetectingViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView {
    UIView *view = [UIView new];
    view.backgroundColor = [UIColor clearColor];
    view.autoresizingMask = UIViewAutoresizingNone;
    self.view = view;
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    // The following is effectively detecting if the keyboard is about to appear.
    // If that's the case, we'll assume the scrollView has its contentOffset set
    // to the correct value by this point in time (i.e. if it's inside a UINavController).
    CGRect oldFrame = [notification.userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    if (!CGRectIntersectsRect(self.view.window.frame, oldFrame)) {
        self.originalContentOffset = self.scrollView.contentOffset;
    }
    
    CGPoint newOffset = [self offsetForKeyboardNotification:notification];
    // As of iOS 8, this all takes place inside the necessary animation block
    // https://twitter.com/SmileyKeith/status/684100833823174656
    [self updateOffsetIfNecessary:newOffset];
}

// This is a hack that shouldn't get called very often. When changing the first responder in rapid
// succession (like tabbing through a form), UIKeyboardWillChangeFrameNotification is not always fired.
// This catches cases where this occurs after-the-fact, and cleans things up by scrolling
// to the correct position.
- (void)keyboardDidChangeFrame:(NSNotification *)notification {
    CGPoint offset = [self offsetForKeyboardNotification:notification];
    [UIView animateWithDuration:0.1 animations:^{
        [self updateOffsetIfNecessary:offset];
    }];
}

- (void)updateOffsetIfNecessary:(CGPoint)offset {
    if (!CGPointEqualToPoint(self.scrollView.contentOffset, offset)) {
        self.scrollView.contentOffset = offset;
        self.currentScroll = offset.y - self.originalContentOffset.y;
    }
}

- (CGPoint)offsetForKeyboardNotification:(NSNotification *)notification {
    CGFloat padding = 15;
    CGRect newFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardRectInScrollViewFrame = [self.scrollView convertRect:newFrame fromView:nil];
    CGFloat minKeyboardY = CGRectGetMinY(keyboardRectInScrollViewFrame);
    
    UIView *currentFirstResponder = [self.scrollView stp_findFirstResponder];
    CGRect responderRectInScrollViewFrame = [currentFirstResponder convertRect:currentFirstResponder.bounds toView:self.scrollView];
    // It's necessary to track and add the currentScroll here because the scroll view won't properly
    // convert the rect of the first responder when its contentOffset != 0.
    CGFloat maxViewY = CGRectGetMaxY(responderRectInScrollViewFrame) + padding + self.currentScroll;
    
    CGFloat offsetAmount = MIN(minKeyboardY - maxViewY, 0);
    CGPoint newOffset = self.originalContentOffset;
    newOffset.y -= offsetAmount;
    return newOffset;
}

@end

@implementation UIViewController (Stripe_KeyboardAvoiding)

- (void)stp_beginAvoidingKeyboardWithScrollView:(UIScrollView *)scrollView {
    STPKeyboardDetectingViewController *keyboardAvoiding = [STPKeyboardDetectingViewController new];
    keyboardAvoiding.scrollView = scrollView;
    [self addChildViewController:keyboardAvoiding];
    [self.view addSubview:keyboardAvoiding.view];
    [keyboardAvoiding didMoveToParentViewController:self];
}

@end
