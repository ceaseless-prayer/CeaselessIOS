//
//  NotesTableViewController.m
//  Ceaseless
//
//  Created by Lori Hill on 3/10/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "PersonNotesViewController.h"
#import "AppDelegate.h"
#import "NotesTableViewCell.h"
#import "Note.h"

@interface PersonNotesViewController ()

@end

@implementation PersonNotesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//#pragma mark - Table view data source
//
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//		// Return the number of sections.
//	return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//		// Return the number of rows in the section.
//	return [self.notesArray count];
//}
//
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
// UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
//
//	cell.textLabel.text = [self.notesArray objectAtIndex: indexPath.row];
//	cell.textLabel.textColor = [UIColor whiteColor];
//	cell.detailTextLabel.textColor = [UIColor whiteColor];
//    cell.backgroundColor = [UIColor clearColor];
//	NSLog (@"cell text %@", cell.textLabel.text);
// return cell;
//}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
	return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NotesTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
		// Return NO if you do not want the specified item to be editable.
	return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
		[context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];

		NSError *error = nil;
		if (![context save:&error]) {
				// Replace this implementation with code to handle the error appropriately.
				// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			abort();
		}
	}
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];

	cell.imageView.image = [UIImage imageNamed: @"icon_ceaseless_comment"];

	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.timeStyle = NSDateFormatterNoStyle;
	dateFormatter.dateStyle = NSDateFormatterShortStyle;
	NSDate *date = [object valueForKey:@"lastUpdatedDate"];

	cell.textLabel.text = [dateFormatter stringFromDate:date];
	cell.detailTextLabel.text = [[object valueForKey:@"text"] description];

//	cell.textLabel.text = [self.notesArray objectAtIndex: indexPath.row];
//	cell.textLabel.textColor = [UIColor whiteColor];
//	cell.detailTextLabel.textColor = [UIColor whiteColor];
//	cell.backgroundColor = [UIColor clearColor];
	NSLog (@"cell text %@", cell.textLabel.text);

}

#pragma mark - Fetched results controller
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
		// In the simplest, most efficient, case, reload the table view.
 [self.tableView reloadData];
}
- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController != nil) {
		return _fetchedResultsController;
	}

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];

		// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];

		// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createDate" ascending:NO];
	NSArray *sortDescriptors = @[sortDescriptor];

	[fetchRequest setSortDescriptors:sortDescriptors];

	NSPredicate *ceaselessIdInNotes = [NSPredicate predicateWithFormat:@"%@ IN peopleTagged", self.ceaselessId];

	[fetchRequest setPredicate: ceaselessIdInNotes];
		// Edit the section name key path and cache name if appropriate.
		// nil for section name key path means "no sections".
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
	aFetchedResultsController.delegate = self;
	self.fetchedResultsController = aFetchedResultsController;

	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
			// Replace this implementation with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		abort();
	}

	return _fetchedResultsController;
}


@end
