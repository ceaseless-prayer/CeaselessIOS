/*
 * Copyright 2014 shrtlist.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "UserIdentityPicker.h"
#import "AppUtils.h"
#import "AppDelegate.h"

@interface UserIdentityPicker () <NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSArray *people;
@property (strong, nonatomic) NSFetchRequest *searchFetchRequest;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSArray *filteredList;

@end

@implementation UserIdentityPicker

#pragma mark - View lifecycle methods
- (void)viewDidLoad
{
    [super viewDidLoad];

	UIImage *backgroundImage = [AppUtils getDynamicBackgroundImage];
	if(backgroundImage != nil) {
		self.backgroundImageView.image = backgroundImage;
	}

	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;
	self.ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];

	[self searchControllerSetup];
}

- (void) searchControllerSetup {

		//searchController cannot be set up in IB, so set it up here
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	self.searchController.searchResultsUpdater = self;
	self.searchController.dimsBackgroundDuringPresentation = NO;
	self.searchController.searchBar.barTintColor = UIColorFromRGBWithAlpha(0x00012f , 0.4);
	self.searchController.searchBar.tintColor = [UIColor lightGrayColor];
	self.searchController.searchBar.scopeButtonTitles = @[NSLocalizedString(@"",@"")];
	self.searchController.searchBar.delegate = self;
	self.searchController.delegate = self;

	[self adjustSearchBar];
	self.definesPresentationContext = YES;
}

- (void)adjustSearchBar{
		//if this isn't done, the textfield gets positioned too far left some of the time :(  Apple Bug
	[self.searchController.searchBar setPositionAdjustment: UIOffsetMake (0.0, 0.0) forSearchBarIcon: UISearchBarIconSearch];
	self.tableView.tableHeaderView = self.searchController.searchBar;

}

#pragma mark - Target-action methods

// Action receiver for the clicking of Cancel button
- (IBAction)cancelClick:(id)sender {
	[self.delegate userIdentityPickerDidCancel:self];
}

#pragma mark - UITableViewDataSource protocol conformance

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
			// do we have search text? if yes, are there search results? if yes, return number of results, otherwise, return 1 (add email row)
			// if there are no search results, the table is empty, so return 0
		return self.searchController.searchBar.text.length > 0 ? MAX( 1, self.filteredList.count ) : 0 ;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
   
    cell.accessoryType = UITableViewCellAccessoryNone;
	cell.backgroundColor = [UIColor clearColor];
		
	// If this is the last row in filteredPeople, take special action
	if (self.searchController.active) {
		if (self.filteredList.count == indexPath.row)
		{
			cell.textLabel.text	= NSLocalizedString(@"Add new contact", nil);
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		} else {
			PersonIdentifier *person = [self.filteredList objectAtIndex:indexPath.row];

			NSString *personName = [self.ceaselessContacts compositeNameForPerson:person];
			cell.textLabel.text = personName;
		}
	} else {
		PersonIdentifier *person = [self.fetchedResultsController objectAtIndexPath:indexPath];
		NSString *personName = [self.ceaselessContacts compositeNameForPerson:person];
		cell.textLabel.text = personName;
	}
 
	return cell;
}

#pragma mark - UITableViewDelegate protocol conformance

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView setHidden:YES];

	if (self.searchController.active) {
			// If this is the last row in filteredPeople, take special action
		if (indexPath.row == self.filteredList.count) {
			ABNewPersonViewController *newPersonViewController = [[ABNewPersonViewController alloc] init];
			newPersonViewController.newPersonViewDelegate = self;
			
			UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newPersonViewController];
			
			[self presentViewController:navController animated:YES completion:NULL];
		} else {
			PersonIdentifier *person = [self.filteredList objectAtIndex:indexPath.row];
			[self.delegate userIdentityPickerDidFinish:self withPerson: person];
		}
		self.searchController.searchBar.text = nil;
	} else {
		PersonIdentifier *person = [self.fetchedResultsController objectAtIndexPath:indexPath];
		[self.delegate userIdentityPickerDidFinish:self withPerson: person];
	}

}

#pragma mark -
#pragma mark === UISearchResultsUpdating ===
#pragma mark -

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSString *searchString = searchController.searchBar.text;
	[self searchForText:searchString];
	[self adjustSearchBar];
	[self.tableView reloadData];
}

- (void)searchForText:(NSString *)searchText
{
	NSString *predicateFormat = @"(representativeInfo.primaryFirstName.name BEGINSWITH[cd] %@ OR representativeInfo.primaryLastName.name BEGINSWITH[cd] %@ OR  (representativeInfo.primaryFirstName.name BEGINSWITH[cd] %@ AND representativeInfo.primaryLastName.name BEGINSWITH[cd] %@))";

	NSString *searchFirst = searchText;
	NSString *searchLast = searchText;

	if ([searchText containsString: @" "]) {
		NSArray *substrings = [searchText componentsSeparatedByString:@" "];
		if ([searchText hasSuffix: @" "]) {
			searchText = [substrings objectAtIndex:0];
			searchFirst = [substrings objectAtIndex:0];
			searchLast = searchFirst;
		} else {
			searchFirst = [substrings objectAtIndex:0];
				//when there is a first name and last name change operator to "AND" to return just that person
			searchLast = [substrings objectAtIndex:1];
		}
	}

	NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, searchText, searchText, searchFirst, searchLast];

	[self.searchFetchRequest setPredicate:predicate];

	NSError *error = nil;
	self.filteredList = [self.managedObjectContext executeFetchRequest:self.searchFetchRequest error:&error];
}
- (void)willDismissSearchController:(UISearchController *)searchController {
	[self searchControllerSetup];
}
#pragma mark - ABNewPersonViewControllerDelegate protocol conformance

- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)abRecordRef {

	PersonIdentifier *person;

    if (abRecordRef != NULL) {

		ABAddressBookRef addressBook = [AppUtils getAddressBookRef];

		ABRecordID abRecordID = ABRecordGetRecordID(abRecordRef);

		ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(addressBook, abRecordID);

		[_ceaselessContacts updateCeaselessContactFromABRecord: abPerson];
		person = [_ceaselessContacts getCeaselessContactFromABRecord: abPerson];

//		[self updateSearchResultsForSearchController:self.searchController];

		CFRelease(addressBook);

	}
	[newPersonView dismissViewControllerAnimated:NO completion:NULL];
	[self.delegate userIdentityPickerDidFinish:self withPerson: person];
}
#pragma mark - Fetched results controller
- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
		[self.tableView reloadData];
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

	NSSortDescriptor *sortDescriptor1 = [NSSortDescriptor sortDescriptorWithKey:@"representativeInfo.primaryLastName.name" ascending:YES selector: @selector(caseInsensitiveCompare:)];
	NSSortDescriptor *sortDescriptor2 = [NSSortDescriptor sortDescriptorWithKey:@"representativeInfo.primaryFirstName.name" ascending:YES selector: @selector(caseInsensitiveCompare:)];

	NSArray *sortDescriptors = @[sortDescriptor1, sortDescriptor2];

	[fetchRequest setSortDescriptors:sortDescriptors];

		// Edit the section name key path and cache name if appropriate.
		// nil for section name key path means "no sections".
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath: @"representativeInfo.sectionLastName" cacheName:nil];
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
	NSSortDescriptor *sortDescriptor1 = [NSSortDescriptor sortDescriptorWithKey:@"representativeInfo.primaryLastName.name" ascending:YES selector: @selector(caseInsensitiveCompare:)];
	NSSortDescriptor *sortDescriptor2 = [NSSortDescriptor sortDescriptorWithKey:@"representativeInfo.primaryFirstName.name" ascending:YES selector: @selector(caseInsensitiveCompare:)];
	NSArray *sortDescriptors = @[sortDescriptor1, sortDescriptor2];
	[_searchFetchRequest setSortDescriptors:sortDescriptors];

	return _searchFetchRequest;
}

@end
