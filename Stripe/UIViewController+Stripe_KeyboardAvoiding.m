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
@property(nonatomic, assign)CGRect lastKeyboardFrame;
@property(nonatomic, weak)UIView *lastResponder;
@property(nonatomic, copy)STPKeyboardFrameBlock keyboardFrameBlock;
@end

@implementation STPKeyboardDetectingViewController

- (instancetype)initWithKeyboardFrameBlock:(STPKeyboardFrameBlock)block {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldWillBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
        _keyboardFrameBlock = block;
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

- (void)textFieldWillBeginEditing:(NSNotification *)notification {
    UITextField *textField = notification.object;
    if (![textField isKindOfClass:[UITextField class]] || ![textField isDescendantOfView:self.parentViewController.view]) {
        return;
    }
    if (textField != self.lastResponder && self.keyboardFrameBlock && !CGRectIsEmpty(self.lastKeyboardFrame)) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.keyboardFrameBlock(self.lastKeyboardFrame, textField);
        } completion:nil];
    }
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    // As of iOS 8, this all takes place inside the necessary animation block
    // https://twitter.com/SmileyKeith/status/684100833823174656
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    if (self.keyboardFrameBlock) {
        if (!CGRectEqualToRect(self.lastKeyboardFrame, keyboardFrame)) {
            // we're iOS 8 or later
            UIView *responder = [self.parentViewController.view stp_findFirstResponder];
            self.lastResponder = responder;
            if ([[NSProcessInfo processInfo] respondsToSelector:@selector(operatingSystemVersion)]) {
                self.lastKeyboardFrame = keyboardFrame;
                self.keyboardFrameBlock(keyboardFrame, responder);
            } else {
                NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
                [UIView animateWithDuration:duration animations:^{
                    self.lastKeyboardFrame = keyboardFrame;
                    self.keyboardFrameBlock(keyboardFrame, responder);
                }];
            }
        }
    }
}

@end

@implementation UIViewController (Stripe_KeyboardAvoiding)

- (STPKeyboardDetectingViewController *)stp_keyboardDetectingViewController {
    return [[self.childViewControllers filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIViewController *viewController, __unused NSDictionary *bindings) {
        return [viewController isKindOfClass:[STPKeyboardDetectingViewController class]];
    }]] firstObject];
}

- (void)stp_beginObservingKeyboardWithBlock:(STPKeyboardFrameBlock)block {
    STPKeyboardDetectingViewController *existing = [self stp_keyboardDetectingViewController];
    if (existing) {
        [existing removeFromParentViewController];
        [existing.view removeFromSuperview];
        [existing didMoveToParentViewController:nil];
    }
    STPKeyboardDetectingViewController *keyboardAvoiding = [[STPKeyboardDetectingViewController alloc] initWithKeyboardFrameBlock:block];
    [self addChildViewController:keyboardAvoiding];
    [self.view addSubview:keyboardAvoiding.view];
    [keyboardAvoiding didMoveToParentViewController:self];
}

@end

void linkUIViewControllerKeyboardAvoidingCategory(void){}
