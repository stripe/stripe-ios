//
//  STPSourceListViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 1/12/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPSourceListViewController.h"
#import "STPSourceProvider.h"
#import "STPSourceCell.h"
#import "STPPaymentCardTextField.h"
#import "STPAPIClient.h"
#import "STPToken.h"
#import "STPCard.h"
#import "NSArray+Stripe_BoundSafe.h"

#define STPFloatEquals(a, b) (fabs((a) - (b)) < FLT_EPSILON)

static NSString *const STPPaymentMethodCellReuseIdentifier = @"STPPaymentMethodCellReuseIdentifier";

@interface STPSourceListViewController()<UITableViewDataSource, UITableViewDelegate, STPPaymentCardTextFieldDelegate>

@property(nonatomic, weak)id<STPSourceListViewControllerDelegate> delegate;
@property(nonatomic)id<STPSourceProvider> sourceProvider;
@property(nonatomic, nonnull)STPAPIClient *apiClient;
@property(nonatomic, weak)UITableView *tableView;
@property(nonatomic, weak)UIBarButtonItem *addButton;
@property(nonatomic)BOOL loading;
@property(nonatomic)CGRect keyboardFrame;
@property(nonatomic)UIToolbar *toolbar;
@property(nonatomic)UIBarButtonItem *cancelButton;
@property(nonatomic)UIBarButtonItem *saveButton;
@property(nonatomic)STPPaymentCardTextField *paymentCardTextField;

@end

@implementation STPSourceListViewController

- (nonnull instancetype)initWithSourceProvider:(nonnull id<STPSourceProvider>)sourceProvider
                                     apiClient:(nonnull STPAPIClient *)apiClient
                                      delegate:(nonnull id<STPSourceListViewControllerDelegate>)delegate {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _apiClient = apiClient;
        _sourceProvider = sourceProvider;
        _delegate = delegate;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChanged:) name:UIKeyboardWillChangeFrameNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSource:)];
    self.addButton = addButton;
    self.navigationItem.rightBarButtonItem = addButton;
    UITableView *tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.dataSource = self;
    tableView.delegate = self;
    [tableView registerClass:[STPSourceCell class] forCellReuseIdentifier:STPPaymentMethodCellReuseIdentifier];
    self.tableView = tableView;
    [self.view addSubview:tableView];
    
    self.toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), 44)];
    self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelNewSource:)];
    self.saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveCard:)];
    self.toolbar.items = @[self.cancelButton, [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], self.saveButton];
    
    STPPaymentCardTextField *textField = [[STPPaymentCardTextField alloc] init];
    textField.backgroundColor = [UIColor whiteColor];
    textField.inputAccessoryView = self.toolbar;
    textField.delegate = self;
    self.paymentCardTextField = textField;
    [self.view addSubview:textField];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.loading = YES;
    [self.sourceProvider retrieveSources:^(__unused id<STPSource> selectedSource, __unused NSArray<id<STPSource>> * _Nullable sources, __unused NSError * _Nullable error) {
        self.loading = NO;
        if (error) {
            NSAssert(NO, @"TODO");
            return;
        }
        [self.tableView reloadData];
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.tableView.frame = self.view.bounds;
    self.paymentCardTextField.alpha = STPFloatEquals(self.keyboardFrame.size.height, 0) ? 0 : 1;
    CGFloat keyboardY = CGRectGetMinY(self.keyboardFrame);
    self.tableView.contentInset = UIEdgeInsetsMake(self.tableView.contentInset.top, 0, self.keyboardFrame.size.height + 44, 0);
    self.paymentCardTextField.frame = CGRectMake(0, keyboardY - 44, self.view.bounds.size.width, 44);
}

- (void)keyboardChanged:(NSNotification *)notification {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[notification.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue]];
    [UIView setAnimationBeginsFromCurrentState:YES];
    self.keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self viewDidLayoutSubviews];
    [UIView commitAnimations];
}

- (void)setLoading:(BOOL)loading {
    _loading = loading;
    self.addButton.enabled = !loading;
}

- (void)addSource:(__unused id)sender {
    [self.paymentCardTextField clear];
    [self.paymentCardTextField becomeFirstResponder];
}

- (void)cancelNewSource:(__unused id)sender {
    [self.paymentCardTextField resignFirstResponder];
}

- (void)saveCard:(__unused id)sender {
    __weak STPSourceListViewController *weakself = self;
    [[STPAPIClient sharedClient] createTokenWithCard:self.paymentCardTextField.cardParams completion:^(__unused STPToken * _Nullable token, __unused NSError * _Nullable error) {
        [self.sourceProvider addSource:token completion:^(__unused id<STPSource> selectedSource, __unused NSArray<id<STPSource>> * _Nullable sources, __unused NSError * _Nullable addSourceError) {
            [weakself.tableView reloadData];
            [weakself.navigationController popViewControllerAnimated:YES];
        }];
    }];
}

- (void)paymentCardTextFieldDidChange:(STPPaymentCardTextField *)textField {
    self.saveButton.enabled = textField.isValid;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return self.sourceProvider.sources.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    STPSourceCell *cell = [tableView dequeueReusableCellWithIdentifier:STPPaymentMethodCellReuseIdentifier forIndexPath:indexPath];
    id<STPSource> source = self.sourceProvider.sources[indexPath.row];
    BOOL selected = source == self.sourceProvider.selectedSource;
    [cell configureWithSource:source selected:selected];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    id<STPSource> source = [self.sourceProvider.sources stp_boundSafeObjectAtIndex:indexPath.row];
    [self.sourceProvider selectSource:source completion:^(__unused id<STPSource>  _Nullable selectedSource, __unused NSArray<id<STPSource>> * _Nullable sources, NSError * _Nullable error) {
        if (error) {
            NSLog(@"TODO");
            return;
        }
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

@end
