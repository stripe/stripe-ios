//
//  STPTestDataTableViewController.m
//  StripeExample
//
//  Created by Jack Flintermann on 10/1/14.
//  Copyright (c) 2014 Stripe. All rights reserved.
//

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 80000

#import "STPTestDataTableViewController.h"

@interface STPTestDataTableViewController()
@property(nonatomic)id<STPTestDataStore>store;
@end

@interface STPTestDataTableViewCell : UITableViewCell
@end

@implementation STPTestDataTableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
}
@end

@implementation STPTestDataTableViewController

- (instancetype)initWithStore:(id<STPTestDataStore>)store {
    self = [super initWithStyle:UITableViewStylePlain];
    if (self) {
        _store = store;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[STPTestDataTableViewCell class] forCellReuseIdentifier:@"cell"];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.store.allItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"
                                                            forIndexPath:indexPath];
    id item = self.store.allItems[indexPath.row];
    NSArray *descriptions = [self.store descriptionsForItem:item];
    cell.textLabel.text = descriptions[0];
    cell.detailTextLabel.text = descriptions[1];
    cell.accessoryType = ([item isEqual:self.store.selectedItem]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    self.store.selectedItem = self.store.allItems[indexPath.row];
    [self.tableView reloadData];
    if (self.callback) {
        self.callback(self.store.selectedItem);
    }
}

@end

#endif