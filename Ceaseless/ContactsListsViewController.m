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
#import "CeaselessLocalContacts.h"
#import "PersonIdentifier.h"
#import "Name.h"
#import "PersonViewController.h"
#import "PersonView.h"
#import "AppUtils.h"

typedef NS_ENUM(NSInteger, ContactsListsPredicateScope)
{
	predicateScopeActive = 0,
	predicateScopeFavorites = 1,
	predicateScopeRemoved = 2
};

@interface ContactsListsViewController () <NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating>

@property (strong, nonatomic) NSArray *filteredList;
@property (strong, nonatomic) NSFetchRequest *searchFetchRequest;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSString *selectedListPredicate;
@property (nonatomic, strong) PersonPicker *personPicker;
@property ContactsListsPredicateScope selectedList;

@end

@implementation ContactsListsViewController

- (void)awakeFromNib {
	[super awakeFromNib];
	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;
	self.ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];
	[self selectContactsPredicate];

}

- (void)viewDidLoad {
	[super viewDidLoad];
		// Do any additional setup after loading the view, typically from a nib.

	self.tableView.dataSource = self;
	self.tableView.delegate = self;


	UIImage *backgroundImage = [AppUtils getDynamicBackgroundImage];
	if(backgroundImage != nil) {
		self.backgroundView.image = backgroundImage;
		self.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
	}

		//searchController cannot be set up in IB, so set it up here
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	self.searchController.searchResultsUpdater = self;
	self.searchController.dimsBackgroundDuringPresentation = NO;
	self.searchController.searchBar.barTintColor = UIColorFromRGBWithAlpha(0x00012f , 0.4);
	self.searchController.searchBar.tintColor = [UIColor whiteColor];
	self.searchController.searchBar.scopeButtonTitles = @[NSLocalizedString(@"",@"")];
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
//	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:animated];
	[super viewWillDisappear:animated];
}
- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
		// Dispose of any resources that can be recreated.
	self.searchFetchRequest = nil;

}

#pragma mark - Saving context for changes to PersonIdentifier
- (void) save {
    // save
    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"%s: Problem saving: %@", __PRETTY_FUNCTION__, error);
    }
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
	if ([[segue identifier] isEqualToString:@"ShowPerson"]) {
		PersonIdentifier *person = nil;
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];

		if (self.searchController.isActive) {
			person = [self.filteredList objectAtIndex:indexPath.row];
		} else {
			person = [self.fetchedResultsController objectAtIndexPath:indexPath];
		}

		PersonViewController *personViewController = segue.destinationViewController;
		personViewController.dataObject = person;

	}
}
- (IBAction)unwindToContactsLists:(UIStoryboardSegue*)sender
{
		// Pull any data from the view controller which initiated the unwind segue.
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

- (NSArray *) sectionIndexTitlesForTableView: (UITableView *) tableView
{
	//add the magnifying glass to the top of the index
	return [[NSArray arrayWithObject:@"{search}"] arrayByAddingObjectsFromArray:[self.fetchedResultsController sectionIndexTitles]];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index
{
	//since search was added to the array, need to return index - 1 to get to correct title, for search, set content Offset to top of table :)
	if ([title isEqualToString: @"{search}"]) {
		[tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
		return NSNotFound;
	} else {
		return [self.fetchedResultsController sectionForSectionIndexTitle:title atIndex:index - 1];
	}
}

- (ContactsListTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    ContactsListTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    cell.onSwitchChange=^(UITableViewCell *cellAffected){
        PersonIdentifier *person = [self.fetchedResultsController objectAtIndexPath: indexPath];
        
        {
            switch (self.selectedList){
                case 0:
                    break;
                case 1:
                    person.favoritedDate = nil;
                    [self save];
                    break;
                case 2:
                    person.removedDate = nil;
                    [self save];
                    break;
                default:
                    break;
            }
        }
    };
    return cell;
}

- (void)configureCell:(ContactsListTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {

	PersonIdentifier *person = nil;
	if (self.searchController.active) {
		person = [self.filteredList objectAtIndex:indexPath.row];
	} else {
		person = [self.fetchedResultsController objectAtIndexPath:indexPath];
	}

    UIImage *profileImage = [_ceaselessContacts getImageForPersonIdentifier:person];
	if (profileImage) {
		cell.personImageView.image = profileImage;
		cell.personImageView.contentMode = UIViewContentModeScaleAspectFit;
		cell.placeholderLabel.hidden = YES;

	} else {
		cell.personImageView.image = nil;
		cell.placeholderLabel.text = [_ceaselessContacts initialsForPerson:person];
		cell.placeholderLabel.hidden = NO;

	}

	NSString *personName = [_ceaselessContacts compositeNameForPerson:person];
	cell.nameLabel.text = personName;

	if (self.selectedList == predicateScopeActive) {
		cell.rowSwitch.hidden = YES;
	} else {
		cell.rowSwitch.hidden = NO;
		cell.rowSwitch.on = YES;
	}
	cell.backgroundColor = [UIColor clearColor];

}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
		// Return NO if you do not want the specified item to be editable.
	return NO;
}

#pragma mark -
#pragma mark === UISearchResultsUpdating ===
#pragma mark -

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSString *searchString = searchController.searchBar.text;
	[self searchForText:searchString];
	[self.tableView reloadData];
}

- (void)searchForText:(NSString *)searchText
{
	NSString *buildPredicateFormat = [NSString stringWithString: self.selectedListPredicate];
	NSString *predicateFormat = [buildPredicateFormat stringByAppendingString: @" AND (representativeInfo.primaryFirstName.name BEGINSWITH[cd] %@ OR representativeInfo.primaryLastName.name BEGINSWITH[cd] %@)"];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, searchText, searchText];

	[self.searchFetchRequest setPredicate:predicate];

	NSError *error = nil;
	self.filteredList = [self.managedObjectContext executeFetchRequest:self.searchFetchRequest error:&error];
}

#pragma mark - Fetched results controller
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
		// reload the table if the contacts are not syncing, jittery otherwise
	if (self.ceaselessContacts.syncing == NO) {
		[self.tableView reloadData];
	}
}
- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController != nil) {
		return _fetchedResultsController;
	}

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"PersonIdentifier" inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];

		// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];

		// Edit the sort key as appropriate.

	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"representativeInfo.primaryLastName.name" ascending:YES selector: @selector(caseInsensitiveCompare:)];

	NSArray *sortDescriptors = @[sortDescriptor];

	[fetchRequest setSortDescriptors:sortDescriptors];

	NSPredicate *selectedContacts = [NSPredicate predicateWithFormat: self.selectedListPredicate];

	[fetchRequest setPredicate: selectedContacts];

		// Edit the section name key path and cache name if appropriate.
		// nil for section name key path means "no sections".
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath: @"representativeInfo.primaryLastName.name" cacheName:nil];
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
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"PersonIdentifier" inManagedObjectContext:self.managedObjectContext];
	[_searchFetchRequest setEntity:entity];

		// Edit the sort key as appropriate.
	NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"representativeInfo.primaryLastName.name" ascending:YES selector: @selector(caseInsensitiveCompare:)];
	NSArray *sortDescriptors = @[sortDescriptor];
	[_searchFetchRequest setSortDescriptors:sortDescriptors];

	return _searchFetchRequest;
}
- (void) listAll {
		// Test listing all tagData from the store
		//  AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
		//  NSManagedObjectContext *managedObjectContext = appDelegate.managedObjectContext;
	NSError * error = nil;

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"PersonIdentifier"
											  inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];


	NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
	for (PersonIdentifier *person in fetchedObjects) {
		NSLog(@"name: %@", [_ceaselessContacts compositeNameForPerson:person]);

	}
}

- (IBAction)contactsListSelector:(id)sender {
	[self selectContactsPredicate];
	[self.tableView reloadData];
}

- (void) selectContactsPredicate {
	{
	switch (self.segment.selectedSegmentIndex){
		case 0:
			self.selectedListPredicate = @"removedDate == nil";
			_fetchedResultsController = nil;
			self.selectedList = self.segment.selectedSegmentIndex;
			break;

		case 1:
			self.selectedListPredicate = @"favoritedDate != nil";
			_fetchedResultsController = nil;
			self.selectedList = self.segment.selectedSegmentIndex;
			break;

		case 2:
			self.selectedListPredicate = @"removedDate != nil";
			_fetchedResultsController = nil;
			self.selectedList = self.segment.selectedSegmentIndex;
			break;
		default:
			break;
	}
	}
}

@end
