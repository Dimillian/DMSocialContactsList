//
//  DMAppDelegate.h
//  DMSocialContactsList
//
//  Created by Thomas Ricouard on 19/12/12.
//  Copyright (c) 2012 Thomas Ricouard. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DMContactlistViewController;

@interface DMAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) DMContactlistViewController *viewController;

@end
