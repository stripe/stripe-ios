//
//  STPPaymentOptionsInternalViewController.m
//  Stripe
//
//  Created by Jack Flintermann on 6/9/16.
//  Copyright © 2016 Stripe, Inc. All rights reserved.
//

#import "STPPaymentOptionsInternalViewController.h"

#import "NSArray+Stripe.h"
#import "STPAddCardViewController.h"
#import "STPAddCardViewController+Private.h"
#import "STPBankSelectionViewController.h"
#import "STPCoreTableViewController.h"
#import "STPCoreTableViewController+Private.h"
#import "STPCustomerContext.h"
#import "STPImageLibrary.h"
#import "STPImageLibrary+Private.h"
#import "STPLocalizationUtils.h"
#import "STPPaymentMethod.h"
#import "STPPaymentMethodParams.h"
#import "STPPaymentOptionTableViewCell.h"
#import "STPPaymentOptionTuple.h"
#import "STPPromise.h"
#import "UITableViewCell+Stripe_Borders.h"
#import "UIViewController+Stripe_NavigationItemProxy.h"
#import "UIViewController+Stripe_Promises.h"

static NSString * const PaymentOptionCellReuseIdentifier = @"PaymentOptionCellReuseIdentifier";

static NSInteger const PaymentOptionSectionCardList = 0;
static NSInteger const PaymentOptionSectionAddCard = 1;
static NSInteger const PaymentOptionSectionAPM = 2;

@interface STPPaymentOptionsInternalViewController () <UITableViewDataSource, UITableViewDelegate, STPAddCardViewControllerDelegate, STPBankSelectionViewControllerDelegate>

@property (nonatomic, strong, readwrite) STPPaymentConfiguration *configuration;
@property (nonatomic, strong, nullable, readwrite) id<STPBackendAPIAdapter> apiAdapter;
@property (nonatomic, strong, nullable, readwrite) STPUserInformation *prefilledInformation;
@property (nonatomic, strong, nullable, readwrite) STPAddress *shippingAddress;
@property (nonatomic, strong, readwrite) NSArray<id<STPPaymentOption>> *paymentOptions;
@property (nonatomic, strong, nullable, readwrite) id<STPPaymentOption> selectedPaymentOption;
@property (nonatomic, weak, nullable, readwrite) id<STPPaymentOptionsInternalViewControllerDelegate> delegate;

@property (nonatomic, strong, readwrite) UIImageView *cardImageView;

@end

@implementation STPPaymentOptionsInternalViewController

- (instancetype)initWithConfiguration:(STPPaymentConfiguration *)configuration
                      customerContext:(nullable STPCustomerContext *)customerContext
                                theme:(STPTheme *)theme
                 prefilledInformation:(nullable STPUserInformation *)prefilledInformation
                      shippingAddress:(nullable STPAddress *)shippingAddress
                   paymentOptionTuple:(STPPaymentOptionTuple *)tuple
                             delegate:(id<STPPaymentOptionsInternalViewControllerDelegate>)delegate {
    self = [super initWithTheme:theme];
    if (self) {
        _configuration = configuration;
        // This parameter may be a custom API adapter, and not a CustomerContext.
        _apiAdapter = customerContext;
        _prefilledInformation = prefilledInformation;
        _shippingAddress = shippingAddress;
        _paymentOptions = tuple.paymentOptions;
        _selectedPaymentOption = tuple.selectedPaymentOption;
        _delegate = delegate;

        self.title = STPLocalizedString(@"Payment Method", @"Title for Payment Method screen");
    }
    return self;
}

- (void)createAndSetupViews {
    [super createAndSetupViews];

    // Table view
    [self.tableView registerClass:[STPPaymentOptionTableViewCell class] forCellReuseIdentifier:PaymentOptionCellReuseIdentifier];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView reloadData];

    // Table header view
    UIImageView *cardImageView = [[UIImageView alloc] initWithImage:[STPImageLibrary largeCardFrontImage]];
    cardImageView.contentMode = UIViewContentModeCenter;
    cardImageView.frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, cardImageView.bounds.size.height + (57.0f * 2.0f));
    cardImageView.image = [STPImageLibrary largeCardFrontImage];
    cardImageView.tintColor = self.theme.accentColor;
    self.cardImageView = cardImageView;

    self.tableView.tableHeaderView = cardImageView;

    // Table view editing state
    [self.tableView setEditing:NO animated:NO];
    [self reloadRightBarButtonItemWithTableViewIsEditing:self.tableView.isEditing animated:NO];
    
    self.stp_navigationItemProxy.leftBarButtonItem.accessibilityIdentifier = @"PaymentOptionsViewControllerCancelButtonIdentifier";
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    // Resetting it re-calculates the size based on new view width
    // UITableView requires us to call setter again to actually pick up frame
    // change on footers
    if (self.tableView.tableFooterView) {
        self.customFooterView = self.tableView.tableFooterView;
    }
}

- (void)reloadRightBarButtonItemWithTableViewIsEditing:(BOOL)tableViewIsEditing animated:(BOOL)animated {
    UIBarButtonItem *barButtonItem;

    if (!tableViewIsEditing) {
        if ([self isAnyPaymentOptionDetachable]) {
            // Show edit button
            barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(handleEditButtonTapped:)];
        } else {
            // Show no button
            barButtonItem = nil;
        }
    } else {
        // Show done button
        barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleDoneButtonTapped:)];
    }

    [self.stp_navigationItemProxy setRightBarButtonItem:barButtonItem animated:animated];
}

- (BOOL)isAnyPaymentOptionDetachable {
    for (id<STPPaymentOption> paymentOption in self.cardPaymentOptions) {
        if ([self isPaymentOptionDetachable:paymentOption]) {
            return YES;
        }
    }

    return NO;
}

- (BOOL)isPaymentOptionDetachable:(id<STPPaymentOption>)paymentOption {
    if (!self.configuration.canDeletePaymentOptions) {
        // Feature is disabled
        return NO;
    }

    if (!self.apiAdapter) {
        // Cannot detach payment methods without customer context
        return NO;
    }

    if (![self.apiAdapter respondsToSelector:@selector(detachPaymentMethodFromCustomer:completion:)]) {
        // Cannot detach payment methods if customerContext is an apiAdapter
        // that doesn't implement detachPaymentMethod
        return NO;
    }

    if (!paymentOption) {
        // Cannot detach non-existent payment method
        return NO;
    }

    if (![paymentOption isKindOfClass:[STPPaymentMethod class]]) {
        // Cannot detach non-payment method
        return NO;
    }

    // Payment method can be deleted from customer
    return YES;
}

- (NSArray<id<STPPaymentOption>> *)cardPaymentOptions {
    return [self.paymentOptions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id<STPPaymentOption> _Nullable evaluatedObject, NSDictionary<NSString *,id> * __unused _Nullable bindings) {
        if ([evaluatedObject isKindOfClass:[STPPaymentMethodParams class]]) {
            STPPaymentMethodParams *paymentMethodParams = (STPPaymentMethodParams *)evaluatedObject;
            if (paymentMethodParams.type != STPPaymentMethodTypeCard) {
                return NO;
            }
        }
        return YES;
    }]];
}

- (NSArray<id<STPPaymentOption>> *)apmPaymentOptions {
    return [self.paymentOptions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id<STPPaymentOption> _Nullable evaluatedObject, NSDictionary<NSString *,id> * __unused _Nullable bindings) {
        if ([evaluatedObject isKindOfClass:[STPPaymentMethodParams class]]) {
            STPPaymentMethodParams *paymentMethodParams = (STPPaymentMethodParams *)evaluatedObject;
            if (paymentMethodParams.type == STPPaymentMethodTypeFPX) { // Add other APMs as we gain support for them in Basic Integration
                return YES;
            }
        }
        return NO;
    }]];
}


- (void)updateWithPaymentOptionTuple:(STPPaymentOptionTuple *)tuple {
    if ([self.paymentOptions isEqualToArray:tuple.paymentOptions] &&
        [self.selectedPaymentOption isEqual:tuple.selectedPaymentOption]) {
        return;
    }

    self.paymentOptions = tuple.paymentOptions;
    self.selectedPaymentOption = tuple.selectedPaymentOption;

    // Reload card list section
    NSMutableIndexSet *sections = [NSMutableIndexSet indexSetWithIndex:PaymentOptionSectionCardList];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)setCustomFooterView:(UIView *)footerView {
    _customFooterView = footerView;
    [self.stp_willAppearPromise voidOnSuccess:^{
        CGSize size = [footerView sizeThatFits:CGSizeMake(self.view.bounds.size.width, CGFLOAT_MAX)];
        footerView.frame = CGRectMake(0, 0, size.width, size.height);

        self.tableView.tableFooterView = footerView;
    }];
}

#pragma mark - Button Handlers

- (void)handleCancelTapped:(__unused id)sender {
    [self.delegate internalViewControllerDidCancel];
}

- (void)handleEditButtonTapped:(__unused id)sender {
    [self.tableView setEditing:YES animated:YES];
    [self reloadRightBarButtonItemWithTableViewIsEditing:self.tableView.isEditing animated:YES];
}

- (void)handleDoneButtonTapped:(__unused id)sender {
    [self _endTableViewEditing];
    [self reloadRightBarButtonItemWithTableViewIsEditing:self.tableView.isEditing animated:YES];
}

- (void)_endTableViewEditing {
    [self.tableView setEditing:NO animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    if (self.apmPaymentOptions.count > 0) {
        return 3;
    } else {
        return 2;
    }
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == PaymentOptionSectionCardList) {
        return self.cardPaymentOptions.count;
    }

    if (section == PaymentOptionSectionAddCard) {
        return 1;
    }
    
    if (section == PaymentOptionSectionAPM) {
        return self.apmPaymentOptions.count;
    }

    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    STPPaymentOptionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:PaymentOptionCellReuseIdentifier forIndexPath:indexPath];

    if (indexPath.section == PaymentOptionSectionCardList) {
        id<STPPaymentOption> paymentOption = [self.cardPaymentOptions stp_boundSafeObjectAtIndex:indexPath.row];
        BOOL selected = [paymentOption isEqual:self.selectedPaymentOption];

        [cell configureWithPaymentOption:paymentOption theme:self.theme selected:selected];
    } else if (indexPath.section == PaymentOptionSectionAddCard) {
        [cell configureForNewCardRowWithTheme:self.theme];
        cell.accessibilityIdentifier = @"PaymentOptionsTableViewAddNewCardButtonIdentifier";
    } else if (indexPath.section == PaymentOptionSectionAPM) {
        id<STPPaymentOption> paymentOption = [self.apmPaymentOptions stp_boundSafeObjectAtIndex:indexPath.row];
        if ([paymentOption isKindOfClass:[STPPaymentMethodParams class]]) {
            STPPaymentMethodParams *paymentMethodParams = (STPPaymentMethodParams *)paymentOption;
            if (paymentMethodParams.type == STPPaymentMethodTypeFPX) {
                [cell configureForFPXRowWithTheme:self.theme];
                cell.accessibilityIdentifier = @"PaymentOptionsTableViewFPXButtonIdentifier";
            }
        }
    }

    return cell;
}

- (BOOL)tableView:(__unused UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == PaymentOptionSectionCardList) {
        id<STPPaymentOption> paymentOption = [self.cardPaymentOptions stp_boundSafeObjectAtIndex:indexPath.row];

        if ([self isPaymentOptionDetachable:paymentOption]) {
            return YES;
        }
    }

    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == PaymentOptionSectionCardList) {
        if (editingStyle != UITableViewCellEditingStyleDelete) {
            // Showed the user a non-delete option when we shouldn't have
            [tableView reloadData];
            return;
        }

        if (!(indexPath.row < (NSInteger)self.cardPaymentOptions.count)) {
            // Data source and table view out of sync for some reason
            [tableView reloadData];
            return;
        }

        id<STPPaymentOption> paymentOptionToDelete = [self.cardPaymentOptions stp_boundSafeObjectAtIndex:indexPath.row];

        if (![self isPaymentOptionDetachable:paymentOptionToDelete]) {
            // Showed the user a delete option for a payment method when we shouldn't have
            [tableView reloadData];
            return;
        }

        STPPaymentMethod *paymentMethod = (STPPaymentMethod *)paymentOptionToDelete;

        // Kickoff request to delete payment method from customer
        [self.apiAdapter detachPaymentMethodFromCustomer:paymentMethod completion:nil];

        // Optimistically remove payment method from data source
        NSMutableArray *paymentOptions = [self.paymentOptions mutableCopy];
        [paymentOptions removeObject:paymentOptionToDelete];
        self.paymentOptions = paymentOptions;

        // Perform deletion animation for single row
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];

        BOOL tableViewIsEditing = tableView.isEditing;
        if (![self isAnyPaymentOptionDetachable]) {
            // we deleted the last available payment option, stop editing
            // (but delay to next runloop because calling tableView setEditing:animated:
            // in this function is not allowed)
            dispatch_async(dispatch_get_main_queue(), ^{
                [self _endTableViewEditing];
            });
            // manually set the value passed to reloadRightBarButtonItemWithTableViewIsEditing
            // below
            tableViewIsEditing = NO;
        }

        // Reload right bar button item text
        [self reloadRightBarButtonItemWithTableViewIsEditing:tableViewIsEditing animated:YES];

        // Notify delegate
        [self.delegate internalViewControllerDidDeletePaymentOption:paymentOptionToDelete];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == PaymentOptionSectionCardList) {
        // Update data source
        id<STPPaymentOption> paymentOption = [self.cardPaymentOptions stp_boundSafeObjectAtIndex:indexPath.row];
        self.selectedPaymentOption = paymentOption;

        // Perform selection animation
        [tableView reloadSections:[NSIndexSet indexSetWithIndex:PaymentOptionSectionCardList] withRowAnimation:UITableViewRowAnimationFade];

        // Notify delegate
        [self.delegate internalViewControllerDidSelectPaymentOption:paymentOption];
    } else if (indexPath.section == PaymentOptionSectionAddCard) {
        STPAddCardViewController *paymentCardViewController = [[STPAddCardViewController alloc] initWithConfiguration:self.configuration theme:self.theme];
        paymentCardViewController.delegate = self;
        paymentCardViewController.prefilledInformation = self.prefilledInformation;
        paymentCardViewController.shippingAddress = self.shippingAddress;
        paymentCardViewController.customFooterView = self.addCardViewControllerCustomFooterView;

        [self.navigationController pushViewController:paymentCardViewController animated:YES];
    } else if (indexPath.section == PaymentOptionSectionAPM) {
        id<STPPaymentOption> paymentOption = [self.apmPaymentOptions stp_boundSafeObjectAtIndex:indexPath.row];
        if ([paymentOption isKindOfClass:[STPPaymentMethodParams class]]) {
            STPPaymentMethodParams *paymentMethodParams = (STPPaymentMethodParams *)paymentOption;
            if (paymentMethodParams.type == STPPaymentMethodTypeFPX) {
                STPBankSelectionViewController *bankSelectionViewController = [[STPBankSelectionViewController alloc] initWithBankMethod:STPBankSelectionMethodFPX configuration:self.configuration theme:self.theme];
                bankSelectionViewController.delegate = self;
                
                [self.navigationController pushViewController:bankSelectionViewController animated:YES];
            }
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL isTopRow = (indexPath.row == 0);
    BOOL isBottomRow = ([self tableView:tableView numberOfRowsInSection:indexPath.section] - 1 == indexPath.row);

    [cell stp_setBorderColor:self.theme.tertiaryBackgroundColor];
    [cell stp_setTopBorderHidden:!isTopRow];
    [cell stp_setBottomBorderHidden:!isBottomRow];
    [cell stp_setFakeSeparatorColor:self.theme.quaternaryBackgroundColor];
    [cell stp_setFakeSeparatorLeftInset:15.0f];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if ([self tableView:tableView numberOfRowsInSection:section] == 0) {
        return 0.01f;
    }

    return 27.0f;
}

- (CGFloat)tableView:(__unused UITableView *)tableView heightForHeaderInSection:(__unused NSInteger)section {
    return 0.01f;
}

- (UITableViewCellEditingStyle)tableView:(__unused UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == PaymentOptionSectionCardList) {
        return UITableViewCellEditingStyleDelete;
    }

    return UITableViewCellEditingStyleNone;
}

- (void)tableView:(__unused UITableView *)tableView willBeginEditingRowAtIndexPath:(__unused NSIndexPath *)indexPath {
    [self reloadRightBarButtonItemWithTableViewIsEditing:YES animated:YES];
}

- (void)tableView:(UITableView *)tableView didEndEditingRowAtIndexPath:(__unused NSIndexPath *)indexPath {
    [self reloadRightBarButtonItemWithTableViewIsEditing:tableView.isEditing animated:YES];
}

#pragma mark - STPAddCardViewControllerDelegate

- (void)addCardViewControllerDidCancel:(__unused STPAddCardViewController *)addCardViewController {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)addCardViewController:(__unused STPAddCardViewController *)addCardViewController didCreatePaymentMethod:(nonnull STPPaymentMethod *)paymentMethod completion:(nonnull STPErrorBlock)completion {
    [self.delegate internalViewControllerDidCreatePaymentOption:paymentMethod completion:completion];
}

- (void)bankSelectionViewController:(__unused STPBankSelectionViewController *)bankViewController didCreatePaymentMethodParams:(STPPaymentMethodParams *)paymentMethodParams {
    [self.delegate internalViewControllerDidCreatePaymentOption:(id<STPPaymentOption>)paymentMethodParams completion:^(NSError * _Nullable __unused error) {}];
}

@end
