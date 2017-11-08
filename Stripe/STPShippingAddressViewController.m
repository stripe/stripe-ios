//
//  STPShippingAddressViewController.m
//  Stripe
//
//  Created by Ben Guo on 8/29/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPShippingAddressViewController.h"

#import "NSArray+Stripe.h"
#import "STPAddress.h"
#import "STPAddressViewModel.h"
#import "STPColorUtils.h"
#import "STPCoreTableViewController+Private.h"
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentActivityIndicatorView.h"
#import "STPPaymentContext+Private.h"
#import "STPSectionHeaderView.h"
#import "STPShippingMethodsViewController.h"
#import "STPTheme.h"
#import "UIBarButtonItem+Stripe.h"
#import "UINavigationController+Stripe_Completion.h"
#import "UITableViewCell+Stripe_Borders.h"
#import "UIViewController+Stripe_KeyboardAvoiding.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"
#import "UIViewController+Stripe_ParentViewController.h"

@interface STPShippingAddressViewController ()<STPAddressViewModelDelegate, UITableViewDelegate, UITableViewDataSource, STPShippingMethodsViewControllerDelegate>
@property (nonatomic) STPPaymentConfiguration *configuration;
@property (nonatomic) NSString *currency;
@property (nonatomic) PKShippingMethod *selectedShippingMethod;
@property (nonatomic, weak) UIImageView *imageView;
@property (nonatomic) UIBarButtonItem *nextItem;
@property (nonatomic) BOOL loading;
@property (nonatomic) STPPaymentActivityIndicatorView *activityIndicator;
@property (nonatomic) STPAddressViewModel *addressViewModel;
@property (nonatomic) STPAddress *billingAddress;
@property (nonatomic) BOOL hasUsedBillingAddress;
@property (nonatomic) STPSectionHeaderView *addressHeaderView;
@end

@implementation STPShippingAddressViewController

- (instancetype)init {
    return [self initWithConfiguration:[STPPaymentConfiguration sharedConfiguration] theme:[STPTheme defaultTheme] currency:nil shippingAddress:nil selectedShippingMethod:nil prefilledInformation:nil];
}

- (instancetype)initWithPaymentContext:(STPPaymentContext *)paymentContext {
    STPAddress *billingAddress = nil;
    id<STPPaymentMethod> paymentMethod = paymentContext.selectedPaymentMethod;
    if ([paymentMethod isKindOfClass:[STPCard class]]) {
        STPCard *card = (STPCard *)paymentMethod;
        billingAddress = [card address];
    }
    STPUserInformation *prefilledInformation;
    if (paymentContext.prefilledInformation != nil) {
        prefilledInformation = [paymentContext.prefilledInformation copy];
    } else {
        prefilledInformation = [STPUserInformation new];
    }
    prefilledInformation.billingAddress = billingAddress;
    STPShippingAddressViewController *instance = [self initWithConfiguration:paymentContext.configuration
                                                                       theme:paymentContext.theme
                                                                    currency:paymentContext.paymentCurrency
                                                             shippingAddress:paymentContext.shippingAddress
                                                      selectedShippingMethod:paymentContext.selectedShippingMethod
                                                        prefilledInformation:prefilledInformation];
    instance.delegate = paymentContext;
    return instance;
}

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                                theme:(STPTheme *)theme
                             currency:(NSString *)currency
                      shippingAddress:(STPAddress *)shippingAddress
               selectedShippingMethod:(PKShippingMethod *)selectedShippingMethod
                 prefilledInformation:(STPUserInformation *)prefilledInformation {
    self = [super initWithTheme:theme];
    if (self) {
        _configuration = configuration;
        _currency = currency ?: @"usd";
        _selectedShippingMethod = selectedShippingMethod;
        _billingAddress = prefilledInformation.billingAddress;
        _hasUsedBillingAddress = NO;
        _addressViewModel = [[STPAddressViewModel alloc] initWithRequiredShippingFields:configuration.requiredShippingAddressFields];
        _addressViewModel.delegate = self;
        if (shippingAddress != nil) {
            _addressViewModel.address = shippingAddress;
        }
        else if (prefilledInformation.shippingAddress != nil) {
            _addressViewModel.address = prefilledInformation.shippingAddress;
        }
        self.title = [self titleForShippingType:self.configuration.shippingType];
    }
    return self;
}

- (void)createAndSetupViews {
    [super createAndSetupViews];

    UIBarButtonItem *nextItem;
    switch (self.configuration.shippingType) {
        case STPShippingTypeShipping:
            nextItem = [[UIBarButtonItem alloc] initWithTitle:STPLocalizedString(@"Next", @"Button to move to the next text entry field")
                                                        style:UIBarButtonItemStyleDone
                                                       target:self
                                                       action:@selector(next:)];
            break;
        case STPShippingTypeDelivery:
            nextItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                     target:self
                                                                     action:@selector(next:)];
            break;
    }
    self.nextItem = nextItem;
    self.stp_navigationItemProxy.rightBarButtonItem = nextItem;
    self.stp_navigationItemProxy.rightBarButtonItem.enabled = NO;

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[STPImageLibrary largeShippingImage]];
    imageView.contentMode = UIViewContentModeCenter;
    imageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, imageView.bounds.size.height + (57 * 2));
    self.imageView = imageView;
    self.tableView.tableHeaderView = imageView;

    self.activityIndicator = [[STPPaymentActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 20.0f, 20.0f)];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(endEditing)]];

    STPSectionHeaderView *headerView = [STPSectionHeaderView new];
    headerView.theme = self.theme;
    headerView.title = [self headerTitleForShippingType:self.configuration.shippingType];
    [headerView.button setTitle:STPLocalizedString(@"Use Billing", @"Button to fill shipping address from billing address.")
                       forState:UIControlStateNormal];
    [headerView.button addTarget:self action:@selector(useBillingAddress:)
                forControlEvents:UIControlEventTouchUpInside];
    PKAddressField requiredFields = self.configuration.requiredShippingAddressFields;
    BOOL needsAddress = (requiredFields & PKAddressFieldPostalAddress) && !self.addressViewModel.isValid;
    BOOL buttonVisible = (needsAddress
                          && [self.billingAddress containsContentForShippingAddressFields:requiredFields]
                          && !self.hasUsedBillingAddress);
    headerView.button.alpha = buttonVisible ? 1 : 0;
    [headerView setNeedsLayout];
    _addressHeaderView = headerView;

    [self updateDoneButton];
}

- (void)endEditing {
    [self.view endEditing:NO];
}

- (void)updateAppearance {
    [super updateAppearance];
    STPTheme *navBarTheme = self.navigationController.navigationBar.stp_theme ?: self.theme;
    [self.nextItem stp_setTheme:navBarTheme];
    
    self.tableView.allowsSelection = NO;

    self.imageView.tintColor = self.theme.accentColor;
    self.activityIndicator.tintColor = self.theme.accentColor;
    for (STPAddressFieldTableViewCell *cell in self.addressViewModel.addressCells) {
        cell.theme = self.theme;
    }
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self stp_beginObservingKeyboardAndInsettingScrollView:self.tableView
                                             onChangeBlock:nil];
    [[self firstEmptyField] becomeFirstResponder];
}

- (UIResponder *)firstEmptyField {
    for (STPAddressFieldTableViewCell *cell in self.addressViewModel.addressCells) {
        if (cell.contents.length == 0) {
            return cell;
        }
    }
    return nil;
}

- (void)setLoading:(BOOL)loading {
    if (loading == _loading) {
        return;
    }
    _loading = loading;
    [self.stp_navigationItemProxy setHidesBackButton:loading animated:YES];
    self.stp_navigationItemProxy.leftBarButtonItem.enabled = !loading;
    self.activityIndicator.animating = loading;
    if (loading) {
        [self.tableView endEditing:YES];
        UIBarButtonItem *loadingItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
        [self.stp_navigationItemProxy setRightBarButtonItem:loadingItem animated:YES];
    } else {
        [self.stp_navigationItemProxy setRightBarButtonItem:self.nextItem animated:YES];
    }
    for (UITableViewCell *cell in self.addressViewModel.addressCells) {
        cell.userInteractionEnabled = !loading;
        [UIView animateWithDuration:0.1f animations:^{
            cell.alpha = loading ? 0.7f : 1.0f;
        }];
    }
}

- (void)handleCancelTapped:(__unused id)sender {
    [self.delegate shippingAddressViewControllerDidCancel:self];
}

- (void)next:(__unused id)sender {
    STPAddress *address = self.addressViewModel.address;
    switch (self.configuration.shippingType) {
        case STPShippingTypeShipping: {
            self.loading = YES;
            [self.delegate shippingAddressViewController:self didEnterAddress:address completion:^(STPShippingStatus status, NSError * __nullable shippingValidationError, NSArray<PKShippingMethod *>* __nullable shippingMethods, PKShippingMethod * __nullable selectedShippingMethod) {
                self.loading = NO;
                if (status == STPShippingStatusValid) {
                    if ([shippingMethods count] > 0) {
                        STPShippingMethodsViewController *nextViewController = [[STPShippingMethodsViewController alloc] initWithShippingMethods:shippingMethods
                                                                                                                          selectedShippingMethod:selectedShippingMethod
                                                                                                                                        currency:self.currency
                                                                                                                                           theme:self.theme];
                        nextViewController.delegate = self;
                        [self.navigationController pushViewController:nextViewController animated:YES];
                    }
                    else {
                        [self.delegate shippingAddressViewController:self
                                                didFinishWithAddress:address
                                                      shippingMethod:nil];
                    }
                }
                else {
                    [self handleShippingValidationError:shippingValidationError];
                }
            }];
            break;
        }
        case STPShippingTypeDelivery:
            [self.delegate shippingAddressViewController:self
                                    didFinishWithAddress:address
                                          shippingMethod:nil];
            break;
    }
}

- (void)updateDoneButton {
    self.stp_navigationItemProxy.rightBarButtonItem.enabled = self.addressViewModel.isValid;
}

- (void)handleShippingValidationError:(NSError *)error {
    [[self firstEmptyField] becomeFirstResponder];
    NSString *title = STPLocalizedString(@"Invalid Shipping Address", @"Shipping form error message");
    NSString *message = nil;
    if (error != nil) {
        title = error.localizedDescription;
        message = error.localizedFailureReason;
    }
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:STPLocalizedString(@"OK", @"ok button")
                                                        style:UIAlertActionStyleCancel
                                                      handler:nil]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)dismissWithCompletion:(STPVoidBlock)completion {
    if ([self stp_isAtRootOfNavigationController]) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:completion];
    }
    else {
        UIViewController *previous = self.navigationController.viewControllers.firstObject;
        for (UIViewController *viewController in self.navigationController.viewControllers) {
            if (viewController == self) {
                break;
            }
            previous = viewController;
        }
        [self.navigationController stp_popToViewController:previous animated:YES completion:completion];
    }
}

#pragma mark - STPAddressViewModelDelegate

- (void)addressViewModel:(__unused STPAddressViewModel *)addressViewModel addedCellAtIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)addressViewModel:(__unused STPAddressViewModel *)addressViewModel removedCellAtIndex:(NSUInteger)index {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)addressViewModelDidChange:(__unused STPAddressViewModel *)addressViewModel {
    [self updateDoneButton];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(__unused NSInteger)section {
    return self.addressViewModel.addressCells.count;
}

- (UITableViewCell *)tableView:(__unused UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.addressViewModel.addressCells stp_boundSafeObjectAtIndex:indexPath.row];
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = self.theme.secondaryBackgroundColor;
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL topRow = (indexPath.row == 0);
    BOOL bottomRow = ([self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 == indexPath.row);
    [cell stp_setBorderColor:self.theme.tertiaryBackgroundColor];
    [cell stp_setTopBorderHidden:!topRow];
    [cell stp_setBottomBorderHidden:!bottomRow];
    [cell stp_setFakeSeparatorColor:self.theme.quaternaryBackgroundColor];
    [cell stp_setFakeSeparatorLeftInset:15.0f];
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForFooterInSection:(__unused NSInteger)section {
    return 0.01f;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForFooterInSection:(__unused NSInteger)section {
    return [UIView new];
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForHeaderInSection:(__unused NSInteger)section {
    CGSize size = [self.addressHeaderView sizeThatFits:CGSizeMake(self.view.bounds.size.width, CGFLOAT_MAX)];
    return size.height;
}

- (UIView *)tableView:(__unused UITableView *)tableView viewForHeaderInSection:(__unused NSInteger)section {
    return self.addressHeaderView;
}

- (void)useBillingAddress:(__unused UIButton *)sender {
    [self.tableView beginUpdates];
    self.addressViewModel.address = self.billingAddress;
    self.hasUsedBillingAddress = YES;
    [[self firstEmptyField] becomeFirstResponder];
    [UIView animateWithDuration:0.2f animations:^{
        self.addressHeaderView.buttonHidden = YES;
    }];
    [self.tableView endUpdates];
}

- (NSString *)titleForShippingType:(STPShippingType)type {
    if (self.configuration.requiredShippingAddressFields & PKAddressFieldPostalAddress) {
        switch (type) {
            case STPShippingTypeShipping:
                return STPLocalizedString(@"Shipping", @"Title for shipping info form");
                break;
            case STPShippingTypeDelivery:
                return STPLocalizedString(@"Delivery", @"Title for delivery info form");
                break;
        }
    }
    else {
        return STPLocalizedString(@"Contact", @"Title for contact info form");
    }
}

- (NSString *)headerTitleForShippingType:(STPShippingType)type {
     if (self.configuration.requiredShippingAddressFields & PKAddressFieldPostalAddress) {
        switch (type) {
            case STPShippingTypeShipping:
                return STPLocalizedString(@"Shipping Address", @"Title for shipping address entry section");
                break;
            case STPShippingTypeDelivery:
                return STPLocalizedString(@"Delivery Address", @"Title for delivery address entry section");
                break;
        }
    }
    else {
        return STPLocalizedString(@"Contact", @"Title for contact info form");
    }
}

#pragma mark - STPShippingMethodsViewControllerDelegate

- (void)shippingMethodsViewController:(__unused STPShippingMethodsViewController *)methodsViewController
          didFinishWithShippingMethod:(PKShippingMethod *)method {
    [self.delegate shippingAddressViewController:self
                            didFinishWithAddress:self.addressViewModel.address
                                  shippingMethod:method];
}

@end
