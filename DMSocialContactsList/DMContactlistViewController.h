//
//  DMViewController.h
//  DMSocialContactsList
//
//  Created by Thomas Ricouard on 19/12/12.
//  Copyright (c) 2012 Thomas Ricouard. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DMContactlistViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UIAlertViewDelegate, UISearchBarDelegate>

@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UISearchBar *searchBar;
@end
