//
//  MenuViewController.h
//  Ceaseless
//
//  Created by Lori Hill on 3/20/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MenuViewControllerDelegate;


@interface MenuViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id<MenuViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *menuBackground;
@property (strong, nonatomic) NSMutableArray *menuInfoArray;

@end

@protocol MenuViewControllerDelegate <NSObject>

	// Called after the user has pressed Done.
	// The delegate is responsible for dismissing the MenuViewController.
- (void)menuViewControllerDidFinish:(MenuViewController *)menuViewController;


@end
