//
//  PrayerJournalViewController.m
//  Ceaseless
//
//  Created by Lori Hill on 3/12/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "PrayerJournalViewController.h"
#import "NoteViewController.h"
#import "AppDelegate.h"
#import "NotesTableViewCell.h"

@interface PrayerJournalViewController ()

@end

@implementation PrayerJournalViewController

- (void)awakeFromNib {
	[super awakeFromNib];
	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;

}

- (void)viewDidLoad {
	[super viewDidLoad];
		// Do any additional setup after loading the view, typically from a nib.

	UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.tableView.frame];
	imageView.image = [UIImage imageNamed:@"Screen Shot 2015-02-18 at 8.22.42 AM.png"];
	imageView.contentMode = UIViewContentModeScaleAspectFill;
	
	self.tableView.backgroundView = imageView;

	}
- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear: animated];

}

- (void) viewWillDisappear:(BOOL)animated {
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
	[super viewWillDisappear:animated];
}
- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
		// Dispose of any resources that can be recreated.
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([[segue identifier] isEqualToString:@"ShowNote"]) {
		self.noteViewController = segue.destinationViewController;

		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
		Note *currentNote = [self.fetchedResultsController objectAtIndexPath:indexPath];
		self.noteViewController.currentNote = currentNote;
	}
}
- (IBAction)unwindToPrayerJournal:(UIStoryboardSegue*)sender
{
		// Pull any data from the view controller which initiated the unwind segue.
}
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
	[fetchRequest setFetchBatchSize:200];

		// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"createDate" ascending:NO];
	NSArray *sortDescriptors = @[sortDescriptor];

	[fetchRequest setSortDescriptors:sortDescriptors];

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

//- (void) listAll {
//	  // Test listing all tagData from the store
////  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
////  NSManagedObjectContext *managedObjectContext = appDelegate.managedObjectContext;
//  NSError * error = nil;
//
//  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
//  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note"
//											inManagedObjectContext:self.managedObjectContext];
//  [fetchRequest setEntity:entity];
//
//
//  NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
//  for (id managedObject in fetchedObjects) {
//
//	  NSLog(@"create date: %@", [managedObject valueForKey: @"createDate"]);
//	  NSLog(@"text: %@", [managedObject valueForKey: @"text"]);
//	  NSLog(@"last update date: %@", [managedObject valueForKey: @"lastUpdatedDate"]);
//  }
//}

@end
