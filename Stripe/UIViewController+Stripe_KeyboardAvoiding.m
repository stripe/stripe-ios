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

- (instancetype)initWithScrollView:(UIScrollView *)scrollView;

@property(weak, nonatomic) UIScrollView *scrollView;
@property(nonatomic) CGPoint originalContentOffset;
@property(nonatomic) UIEdgeInsets originalContentInset;
@property(nonatomic) CGFloat currentScroll;
@property(nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property(nonatomic, assign)CGRect lastKeyboardFrame;
@property(nonatomic, copy)STPKeyboardFrameBlock keyboardFrameBlock;
@end

@implementation STPKeyboardDetectingViewController

- (instancetype)initWithKeyboardFrameBlock:(STPKeyboardFrameBlock)block {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        _keyboardFrameBlock = block;
    }
    return self;
}

- (instancetype)initWithScrollView:(UIScrollView *)scrollView {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
        _scrollView = scrollView;
        [_scrollView addGestureRecognizer:_tapGestureRecognizer];
        _originalContentInset = scrollView.contentInset;
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

- (void)endEditing {
    [self.scrollView endEditing:YES];
    [self.scrollView setContentOffset:self.originalContentOffset animated:YES];
}

- (void)tapped {
    [self endEditing];
}

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    // As of iOS 8, this all takes place inside the necessary animation block
    // https://twitter.com/SmileyKeith/status/684100833823174656
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = CGRectGetMaxY(self.scrollView.frame) - CGRectGetMinY(keyboardFrame);
    [self updateInsetIfNecessary:keyboardHeight];
    if (self.keyboardFrameBlock) {
        if (!CGRectEqualToRect(self.lastKeyboardFrame, keyboardFrame)) {
            // we're iOS 8 or later
            if ([[NSProcessInfo processInfo] respondsToSelector:@selector(operatingSystemVersion)]) {
                NSTimeInterval duration = [notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
                [UIView animateWithDuration:duration animations:^{
                    self.lastKeyboardFrame = keyboardFrame;
                    self.keyboardFrameBlock(keyboardFrame);
                }];
            } else {
                self.lastKeyboardFrame = keyboardFrame;
                self.keyboardFrameBlock(keyboardFrame);
            }
        }
    }
}

- (void)updateInsetIfNecessary:(CGFloat)keyboardHeight {
    UIEdgeInsets insets;
    if (keyboardHeight < FLT_EPSILON) {
        insets = self.originalContentInset;
    } else {
        insets = UIEdgeInsetsMake(
                                  self.originalContentInset.top,
                                  self.originalContentInset.left,
                                  self.originalContentInset.bottom + keyboardHeight + 20,
                                  self.originalContentInset.right
                                  );
    }
    if (!UIEdgeInsetsEqualToEdgeInsets(self.scrollView.contentInset, insets)) {
        self.scrollView.contentInset = insets;
        self.scrollView.scrollIndicatorInsets = insets;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.scrollView endEditing:YES];
    [coordinator animateAlongsideTransition:nil completion:^(__unused id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.scrollView setContentOffset:self.originalContentOffset animated:YES];
    }];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self endEditing];
}
#pragma clang diagnostic pop


@end

@implementation UIViewController (Stripe_KeyboardAvoiding)

- (void)stp_beginAvoidingKeyboardWithScrollView:(UIScrollView *)scrollView {
    STPKeyboardDetectingViewController *existing = [self stp_keyboardDetectingViewController];
    if (existing) {
        [existing removeFromParentViewController];
        [existing.view removeFromSuperview];
        [existing didMoveToParentViewController:nil];
    }
    STPKeyboardDetectingViewController *keyboardAvoiding = [STPKeyboardDetectingViewController new];
    keyboardAvoiding.scrollView = scrollView;
    [self addChildViewController:keyboardAvoiding];
    [self.view addSubview:keyboardAvoiding.view];
    [keyboardAvoiding didMoveToParentViewController:self];
}

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
