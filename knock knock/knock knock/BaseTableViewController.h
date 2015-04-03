//
//  BaseTableViewController.h
//  Knock Knock
//
//  Created by Brian Hammond on 1/29/14.
//  Copyright (c) 2014 Justin Kelly. All rights reserved.
//

#import "BaseViewController.h"

@interface BaseTableViewController : BaseViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UISearchDisplayDelegate>

@property (strong, nonatomic) UIColor *accentColor;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) UISearchDisplayController *searchController;

- (void)updateMatchesForSearchString:(NSString *)searchString;

@end
