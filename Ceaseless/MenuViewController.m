//
//  MenuViewController.m
//  Ceaseless
//
//  Created by Lori Hill on 3/20/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "MenuViewController.h"
#import "AppConstants.h"
#import "AppUtils.h"

@interface MenuViewController ()

@end

@implementation MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	self.menuInfoArray = [[NSArray alloc] initWithObjects: @"People", @"Settings", @"Developer", nil];
    UIImage *background = [AppUtils getDynamicBackgroundImage];
    if(background != nil) {
        self.menuBackground.image = background;
    }
}

- (void) viewWillDisappear:(BOOL)animated {
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
	[super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.menuInfoArray count];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	cell.textLabel.text = [self.menuInfoArray objectAtIndex: indexPath.row];
	cell.backgroundColor = [UIColor clearColor];

	if (indexPath.row == 2) {
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
		cell.accessoryView = switchView;

		BOOL developerMode = [[NSUserDefaults standardUserDefaults] boolForKey: kDeveloperMode];
		[switchView setOn: developerMode animated:NO];
		[switchView addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
	}


}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
		// Return NO if you do not want the specified item to be editable.
	return NO;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row == 0) {
		[self performSegueWithIdentifier:@"ShowContactsLists" sender: self];
	}
	if (indexPath.row == 1) {
		[self performSegueWithIdentifier:@"ShowSettings" sender: self];
	}
}

- (void) switchChanged:(id)sender {
	UISwitch* switchControl = sender;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL developerMode = switchControl.on ? YES : NO;
	[defaults setBool: developerMode forKey:kDeveloperMode];
	[defaults synchronize];
	NSLog( @"The switch is %@", switchControl.on ? @"YES" : @"NO" );
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
