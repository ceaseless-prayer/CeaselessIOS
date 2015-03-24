//
//  ContactsListsViewController.m
//  Ceaseless
//
//  Created by Lori Hill on 3/23/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "ContactsListsViewController.h"
#import "ContactsListTableViewCell.h"
#import "AppDelegate.h"
#import "PersonPicker.h"
#import "NonMOPerson.h"
#import "Person.h"
#import "Name.h"

typedef NS_ENUM(NSInteger, ContactsListsSearchScope)
{
	searchScopeActive = 0,
	searchScopeFavorites = 1,
	searchScopeRemoved = 2
};

@interface ContactsListsViewController () <NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>

@property (strong, nonatomic) NSArray *filteredList;
@property (strong, nonatomic) NSFetchRequest *searchFetchRequest;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSString *selectedListPredicate;
@property (nonatomic, strong) PersonPicker *personPicker;

@end

@implementation ContactsListsViewController

- (void)awakeFromNib {
	[super awakeFromNib];
	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;
	self.personPicker = [[PersonPicker alloc] init];
	[self selectContactsPredicate];

}

- (void)viewDidLoad {
	[super viewDidLoad];
		// Do any additional setup after loading the view, typically from a nib.

	self.tableView.dataSource = self;
	self.tableView.delegate = self;

//	UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.tableView.frame];
//	imageView.image = [UIImage imageNamed:@"Screen Shot 2015-02-18 at 8.22.42 AM.png"];
//	imageView.contentMode = UIViewContentModeScaleAspectFill;
//
//	self.tableView.backgroundView = imageView;

	self.tableView.estimatedRowHeight = 130.0;
	self.tableView.rowHeight = UITableViewAutomaticDimension;

		//searchController cannot be set up in IB, so set it up here
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	self.searchController.searchResultsUpdater = self;
	self.searchController.dimsBackgroundDuringPresentation = NO;
	self.searchController.searchBar.barTintColor = UIColorFromRGBWithAlpha(0x24292f , 0.4);
	self.searchController.searchBar.tintColor = [UIColor whiteColor];
//	self.searchController.searchBar.scopeButtonTitles = @[NSLocalizedString(@"Friends",@"Friends"),
//														  NSLocalizedString(@"Me",@"Me")];
	self.searchController.searchBar.delegate = self;
		//		// Hide the search bar until user scrolls up
	CGRect newBounds = self.tableView.bounds;
	newBounds.origin.y = newBounds.origin.y + self.searchController.searchBar.bounds.size.height;
	self.tableView.bounds = newBounds;

	self.tableView.tableHeaderView = self.searchController.searchBar;
	self.definesPresentationContext = YES;

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
	self.searchFetchRequest = nil;

}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
//	if ([[segue identifier] isEqualToString:@"ShowNote"]) {
//		Note *currentNote = nil;
//
//		if (self.searchController.isActive) {
//			NSIndexPath *indexPath = [((UITableViewController *)self.searchController.searchResultsController).tableView indexPathForSelectedRow];
//			currentNote = [self.filteredList objectAtIndex:indexPath.row];
//		} else {
//
//			NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
//			currentNote = [self.fetchedResultsController objectAtIndexPath:indexPath];
//		}
//
//		self.noteViewController = segue.destinationViewController;
//		self.noteViewController.currentNote = currentNote;
//	}
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	if (self.searchController.active) {
		return 1;
	} else {
		return [[self.fetchedResultsController sections] count];
	}
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (self.searchController.active) {
		return [self.filteredList count];
	} else {
		id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
		return [sectionInfo numberOfObjects];
	}
}
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 0;
}
- (ContactsListTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	ContactsListTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (void)configureCell:(ContactsListTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {

	Person *person = nil;
	if (self.searchController.active) {
		person = [self.filteredList objectAtIndex:indexPath.row];
	} else {
		person = [self.fetchedResultsController objectAtIndexPath:indexPath];
	}

	NonMOPerson *nonMOPerson = [self.personPicker getNonMOPersonForCeaselessContact:person];

		// deal with cases of no lastName or firstName
		// We had an Akbar (null) name show up.
	if([nonMOPerson.firstName length] == 0) {
		nonMOPerson.firstName = @" "; // 1 character space for initials if needed
	}
	if([nonMOPerson.lastName length] == 0) {
		nonMOPerson.lastName = @" "; // 1 character space for initials if needed
	}

	if (nonMOPerson.profileImage) {
		cell.personImageView.image = nonMOPerson.profileImage;
		cell.personImageView.contentMode = UIViewContentModeScaleAspectFit;
		cell.placeholderLabel.hidden = YES;

	} else {
		cell.personImageView.image = nil;

		NSString *firstInitial = [nonMOPerson.firstName substringToIndex: 1];
		NSString *lastInitial = [nonMOPerson.lastName substringToIndex: 1];
		cell.placeholderLabel.text = [NSString stringWithFormat: @"%@%@", firstInitial, lastInitial];
		cell.placeholderLabel.hidden = NO;

	}

	NSString *personName = [NSString stringWithFormat: @"%@ %@", nonMOPerson.firstName, nonMOPerson.lastName];
	cell.nameLabel.text = personName;

	cell.backgroundColor = [UIColor clearColor];

}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
		// Return NO if you do not want the specified item to be editable.
	return NO;
}


#pragma mark -
#pragma mark === UISearchBarDelegate ===
#pragma mark -

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
	[self updateSearchResultsForSearchController:self.searchController];

}

#pragma mark -
#pragma mark === UISearchResultsUpdating ===
#pragma mark -

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSString *searchString = searchController.searchBar.text;
	[self searchForText:searchString scope: searchController.searchBar.selectedScopeButtonIndex];
	[self.tableView reloadData];
}

- (void)searchForText:(NSString *)searchText scope:(ContactsListsSearchScope)scopeOption
{
		//TODO  this isn't right
//	NonMOPerson *nonMOPerson = [self.personPicker getNonMOPersonForCeaselessContact: person];

	NSString *predicateFormat = @"firstName contains[cd] %@ || lastName contains[cd] %@";

	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, self.selectedListPredicate, searchText, searchText];

	[self.searchFetchRequest setPredicate:predicate];

	NSError *error = nil;
	self.filteredList = [self.managedObjectContext executeFetchRequest:self.searchFetchRequest error:&error];
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
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Person" inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];

		// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];

		// Edit the sort key as appropriate.
//	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"lastNames.name" ascending:YES];
//
//	NSArray *sortDescriptors = @[sortDescriptor];

	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects: nil];

	[fetchRequest setSortDescriptors:sortDescriptors];

	NSPredicate *selectedContacts = [NSPredicate predicateWithFormat: self.selectedListPredicate];

	[fetchRequest setPredicate: selectedContacts];

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
- (NSFetchRequest *)searchFetchRequest
{
	if (_searchFetchRequest != nil)
  {
  return _searchFetchRequest;
  }

	_searchFetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Person" inManagedObjectContext:self.managedObjectContext];
	[_searchFetchRequest setEntity:entity];

		// Edit the sort key as appropriate.
//	((Name*) [personTagged.lastNames anyObject]).lastNameFor]
//	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"prayerRecords.@max.createDate" ascending:YES];
	NSArray *sortDescriptors = [NSArray arrayWithObjects: nil];
	[_searchFetchRequest setSortDescriptors:sortDescriptors];

	return _searchFetchRequest;
}
- (void) listAll {
		// Test listing all tagData from the store
		//  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
		//  NSManagedObjectContext *managedObjectContext = appDelegate.managedObjectContext;
	NSError * error = nil;

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Person"
											  inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];


	NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	for (Person *person in fetchedObjects) {
		NonMOPerson *nonMOPerson = [self.personPicker getNonMOPersonForCeaselessContact: person];
		NSLog(@"name: %@ %@", nonMOPerson.firstName, nonMOPerson.lastName);

	}
}

- (IBAction)contactsPicker:(id)sender {
	[self selectContactsPredicate];

}
- (void) selectContactsPredicate {
	{
	switch (self.segment.selectedSegmentIndex){
		case 0:
			self.selectedListPredicate = @"removedDate == nil";
			break;

		case 1:
			self.selectedListPredicate = @"favoritedDate != nil";
			break;

		case 2:
			self.selectedListPredicate = @"removedDate != nil";
			break;
		default:
			break;
	}
	}
}
@end
