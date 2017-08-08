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
#import "NSString+FontAwesome.h"

typedef NS_ENUM(NSInteger, ContactsListsPredicateScope)
{
    predicateScopeRecent = 0,
	predicateScopeActive = 1,
	predicateScopeRemoved = 2
};

@interface ContactsListsViewController () <NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate>

@property (strong, nonatomic) NSArray *filteredList;
@property (strong, nonatomic) NSFetchRequest *searchFetchRequest;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) NSPredicate *selectedListPredicate;
@property (nonatomic, strong) NSArray *selectedListSortDescriptors;
@property (nonatomic, strong) NSString *selectedListEntity;
@property (nonatomic, strong) NSString *selectedListSectionNameKeyPath;
@property (nonatomic, strong) PersonPicker *personPicker;
@property ContactsListsPredicateScope selectedList;

@end

@implementation ContactsListsViewController

- (void)awakeFromNib {
	[super awakeFromNib];
	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;
	self.ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];
	[self selectContactsPredicateAndSortDescriptors];

}

- (void)viewDidLoad {
	[super viewDidLoad];
		// Do any additional setup after loading the view, typically from a nib.
    self.screenName = @"PeopleScreen";
	self.tableView.dataSource = self;
	self.tableView.delegate = self;

	self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Edit", nil);

	UIImage *backgroundImage = [AppUtils getDynamicBackgroundImage];
	if(backgroundImage != nil) {
		self.backgroundView.image = backgroundImage;
		self.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
	}

    [self.moreButton addTarget:self action:@selector(presentActionSheet:)forControlEvents:UIControlEventTouchUpInside];
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
    // Hide the search bar until user scrolls up
	CGRect newBounds = self.tableView.bounds;
	newBounds.origin.y = newBounds.origin.y + self.searchController.searchBar.bounds.size.height;
	self.tableView.bounds = newBounds;

	[self adjustSearchBar];
	self.definesPresentationContext = YES;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
    // make the model try to refresh whenever the app becomes active
	[[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(handleSyncing) name:UIApplicationDidBecomeActiveNotification object:nil];
	[self handleSyncing];
    [self showInstructionsIfNeeded];
}

- (void)adjustSearchBar{
    // if this isn't done, the textfield gets positioned too far left some of the time :(  Apple Bug
    //	[self.searchController.searchBar setPositionAdjustment: UIOffsetMake (0.0, 0.0) forSearchBarIcon: UISearchBarIconSearch];
	self.tableView.tableHeaderView = self.searchController.searchBar;
}

- (void) handleSyncing {
	if (self.ceaselessContacts.syncing == YES) {
		self.syncingOverlay.hidden = NO;
		[self.activityIndicator startAnimating];
		self.segment.enabled = NO;
		self.moreButton.enabled = NO;
		self.navigationItem.rightBarButtonItem.enabled = NO;
		self.tableView.userInteractionEnabled = NO;
		self.tableView.sectionIndexMinimumDisplayRowCount = INT_MAX;
        [self hideInstructions];
		NSLog (@"syncing");
		NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

        //listen for contacts to finish syncing
		[notificationCenter addObserver: self
							   selector: @selector (enableTable)
								   name: kContactsSyncedNotification
								 object: nil];
	} else {
		[self enableTable];
	}

}
- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear: animated];

}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:kContactsSyncedNotification
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIApplicationDidBecomeActiveNotification
												  object:nil];
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
			person = [self personAtIndexPath:indexPath];
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

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
	[super setEditing:editing animated:animated];
	if (editing) {
		self.tableView.allowsMultipleSelectionDuringEditing = YES;
		[self.tableView setEditing:editing animated:YES];
		switch (self.segment.selectedSegmentIndex) {
            // case 0 - for recent contacts there is no action to be taken.
			case 1: { //can't just set the rightBarButtonItem title because it doesn't pick up font
				UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Remove", nil) style: UIBarButtonItemStylePlain target:self action: @selector(editingDoneButtonPressed)];
				self.navigationItem.rightBarButtonItem = removeButton;
				break;
			}
			case 2:{ //can't just set the rightBarButtonItem title because it doesn't pick up font
				UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithTitle: NSLocalizedString(@"Add", nil) style: UIBarButtonItemStylePlain target:self action: @selector(editingDoneButtonPressed)];
				self.navigationItem.rightBarButtonItem = addButton;
				break;
			}
			default:
				break;
		}

		NSLog(@"editMode on");
	} else {
		if (!self.searchController.active) {

			NSArray *selectedCells = [self.tableView indexPathsForSelectedRows];
				//enumerate backwards so that the index does not get updated by previous removals
			for (NSIndexPath *indexPath in [selectedCells reverseObjectEnumerator]) {
				PersonIdentifier *person = [self personAtIndexPath:indexPath];
				switch (self.segment.selectedSegmentIndex) {
                    // case 0 - for recent contacts there is no action to be taken.
					case 1:
						person.removedDate = [NSDate date];
						break;
					case 2:
						person.removedDate = nil;
						break;
					default:
						break;
				}
				[self save];
			}
		}

		[self.tableView setEditing:editing animated:NO];
		[self.tableView reloadData];
			//can't just set the title because it won't be an editing button 
		self.navigationItem.rightBarButtonItem = self.editButtonItem;
		NSLog(@"editmode off");
	}
}

- (void) editingDoneButtonPressed {
		//Remove or Add button pressed
	[self setEditing:NO animated:NO];
}
- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
	switch (self.segment.selectedSegmentIndex){
		case 1:
			return NSLocalizedString(@"Remove", nil);
			break;
		case 2:
			return NSLocalizedString(@"Add", nil);
			break;
		default:
			return @"Other";
			break;
	}
}
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

    //have to set background color programmatically here to allow checkboxes to function properly :P
	static dispatch_once_t onceToken;
	static UIView * selectedBackgroundView;
	dispatch_once(&onceToken, ^{
		selectedBackgroundView = [[UIView alloc] initWithFrame:cell.frame];
		selectedBackgroundView.backgroundColor = UIColorFromRGBWithAlpha(0x00012f , 0.4);
	});
	cell.selectedBackgroundView = selectedBackgroundView;
    [self configureCell:cell atIndexPath:indexPath];
    cell.onFavoriteChange=^(UITableViewCell *cellAffected){
		PersonIdentifier *person = nil;
		if (self.searchController.active) {
			person = [self.filteredList objectAtIndex:indexPath.row];
		} else {
			person = [self personAtIndexPath:indexPath];
		}
		if (self.selectedList == predicateScopeActive || self.selectedList == predicateScopeRecent) {
			if (person.favoritedDate == nil) {
				person.favoritedDate = [NSDate date];
				[self save];
			} else {
				person.favoritedDate = nil;
				[self save];
			}
		[self.tableView reloadData];
        }
    };
    return cell;
}

- (void)configureCell:(ContactsListTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {

	PersonIdentifier *person = nil;
	if (self.searchController.active) {
		person = [self.filteredList objectAtIndex:indexPath.row];
	} else {
		person = [self personAtIndexPath:indexPath];
	}
	switch (self.segment.selectedSegmentIndex){
        case 0: // favoriting is possible for both recent and active contacts
		case 1:
			cell.favButton.hidden = NO;
			cell.viewToImageViewConstraint.constant = 38;
			if (person.favoritedDate) {
				[cell.favButton setTitle: [NSString fontAwesomeIconStringForEnum:FAHeart] forState:UIControlStateNormal];
			} else {
				[cell.favButton setTitle: [NSString fontAwesomeIconStringForEnum:FAHeartO] forState:UIControlStateNormal];
			}
			break;
		case 2:
			cell.favButton.hidden = YES;
			cell.viewToImageViewConstraint.constant = 0;
			break;
		default:
			break;
	}

    UIImage *profileImage = [_ceaselessContacts getImageForPersonIdentifier:person];
	if (profileImage) {
		cell.personImageView.image = profileImage;
		cell.personImageView.contentMode = UIViewContentModeScaleAspectFill;
		cell.placeholderLabel.text = nil;

	} else {
		cell.personImageView.image = nil;
		cell.placeholderLabel.text = [_ceaselessContacts initialsForPerson:person];

	}

	NSString *personName = [_ceaselessContacts compositeNameForPerson:person];
	cell.nameLabel.text = personName;

	cell.backgroundColor = [UIColor clearColor];

}
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
		// Return NO if you do not want the specified item to be editable.
    return [self validPersonAtIndex:indexPath];
}

- (BOOL) validPersonAtIndex: (NSIndexPath *)indexPath {
    // After adding prayer records and history, we are concerned that a record may
    // for some reason point to a nil person. This checks for that
    // so that our users won't crash the app by tapping on a row with invalid data.
    PersonIdentifier *p = [self personAtIndexPath: indexPath];
    if (!p) {
        return NO;
    }
    return YES;
}


- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
		return UITableViewCellEditingStyleDelete;
}
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		PersonIdentifier *person = [self personAtIndexPath:indexPath];
		switch (self.segment.selectedSegmentIndex) {
			case 1:
				person.removedDate = [NSDate date];
				break;
			case 2:
				person.removedDate = nil;
				break;
			default:
				break;
		}
		[self save];
	}
}

- (void)tableView: (UITableView *)tableView didSelectRowAtIndexPath: (NSIndexPath *)indexPath {
	if (!tableView.isEditing && [self validPersonAtIndex:indexPath]) {
		[self performSegueWithIdentifier: @"ShowPerson" sender: self];
	}
}

#pragma mark -
#pragma mark === UISearchResultsUpdating ===
#pragma mark -

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
	NSString *searchString = searchController.searchBar.text;
	[self searchForText:searchString];
	self.tableView.tableHeaderView = self.searchController.searchBar;
	[self.tableView reloadData];
}

- (void)searchForText:(NSString *)searchText
{
	NSString *buildPredicateFormat = @"removedDate == nil"; // only allow searching for active contacts for now.
	NSString *predicateFormat = [buildPredicateFormat stringByAppendingString: @" AND (representativeInfo.primaryFirstName.name BEGINSWITH[cd] %@ OR representativeInfo.primaryLastName.name BEGINSWITH[cd] %@ OR  (representativeInfo.primaryFirstName.name BEGINSWITH[cd] %@ AND representativeInfo.primaryLastName.name BEGINSWITH[cd] %@))"];

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

- (void)willPresentSearchController:(UISearchController *)searchController {
		//push the view up under status bar
	self.segment.hidden = YES;
	self.moreButton.hidden = YES;
	self.topToVisualEffectsViewConstraint.constant = -20;

}
- (void)didPresentSearchController:(UISearchController *)searchController {
	[self setEditing:NO animated:NO];

}
- (void)willDismissSearchController:(UISearchController *)searchController {
	self.segment.hidden = NO;
	self.moreButton.hidden = NO;
	self.topToVisualEffectsViewConstraint.constant = 0;
	[self searchControllerSetup];
}

#pragma mark -
#pragma mark === Fetched Controller Methods ===
#pragma mark -

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
		[self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeDelete:
			[self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
			break;

		default:
			return;
	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath
{
	UITableView *tableView = self.tableView;

	switch(type) {
		case NSFetchedResultsChangeInsert:
			[tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeDelete:
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;

		case NSFetchedResultsChangeUpdate:
			[tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
			break;		

		case NSFetchedResultsChangeMove:
			[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
	[self.tableView endUpdates];
}

#pragma mark - Fetched results controller
//- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
//{
//		// reload the table if the contacts are not syncing, jittery otherwise
//	if (self.ceaselessContacts.syncing == NO) {
//		[self.tableView reloadData];
//	}
//}
- (NSFetchedResultsController *)fetchedResultsController
{
	if (_fetchedResultsController != nil) {
		return _fetchedResultsController;
	}

	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		// Edit the entity name as appropriate.
	NSEntityDescription *entity = [NSEntityDescription entityForName:self.selectedListEntity inManagedObjectContext:self.managedObjectContext];
	[fetchRequest setEntity:entity];
    
    if ([self.selectedListEntity isEqual: @"PrayerRecord"]) {
        fetchRequest.relationshipKeyPathsForPrefetching = @[@"person"];
    }

		// Set the batch size to a suitable number.
	[fetchRequest setFetchBatchSize:20];

	[fetchRequest setSortDescriptors:self.selectedListSortDescriptors];

	NSPredicate *selectedContacts = self.selectedListPredicate;

	[fetchRequest setPredicate: selectedContacts];


		// Edit the section name key path and cache name if appropriate.
		// nil for section name key path means "no sections".
	NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath: self.selectedListSectionNameKeyPath cacheName:nil];
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
	[_searchFetchRequest setSortDescriptors:[self defaultSortDescriptors]];

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

- (PersonIdentifier *) personAtIndexPath: (NSIndexPath *) indexPath {
    if ([self.selectedListEntity isEqual: @"PersonIdentifier"]) {
        return [self.fetchedResultsController objectAtIndexPath:indexPath];
    } else {
        PrayerRecord *pr = [self.fetchedResultsController objectAtIndexPath:indexPath];
        return pr.person;
    }
}

- (IBAction) contactsListSelector: (id) sender {
	[self selectContactsPredicateAndSortDescriptors];
	self.tableView.editing = NO;
    self.navigationItem.rightBarButtonItem.title = NSLocalizedString(@"Edit", nil);
	[self.tableView reloadData];
}

- (NSArray *) defaultSortDescriptors {
    NSSortDescriptor *sortDescriptor1 = [NSSortDescriptor sortDescriptorWithKey:@"representativeInfo.primaryLastName.name" ascending:YES selector: @selector(caseInsensitiveCompare:)];
    NSSortDescriptor *sortDescriptor2 = [NSSortDescriptor sortDescriptorWithKey:@"representativeInfo.primaryFirstName.name" ascending:YES selector: @selector(caseInsensitiveCompare:)];
    
    return @[sortDescriptor1, sortDescriptor2];
}

- (NSDate *) historyLimitDate {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *limitDate = [defaults objectForKey:kPrayerCycleStartDate];
    NSDate *oneMonthAgo = [[NSDate date] dateByAddingTimeInterval:-60*60*24*30];
    if(!limitDate || [oneMonthAgo earlierDate:limitDate]) {
        limitDate = oneMonthAgo;
    }
    NSLog(@"Cycle start %@", limitDate);
    return limitDate;
}

- (void) selectContactsPredicateAndSortDescriptors {
	switch (self.segment.selectedSegmentIndex) {
        case 0:
            self.selectedListEntity = @"PrayerRecord";
            self.selectedListSortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createDate" ascending:NO]];
            // if you want to limit the history a user can access, uncomment the following, otherwise set the predicate to nil.
            // self.selectedListPredicate = [NSPredicate predicateWithFormat: @"createDate >= %@", [self historyLimitDate]];
            self.selectedListPredicate = nil;
            self.selectedListSectionNameKeyPath = nil;
            _fetchedResultsController = nil;
            self.selectedList = self.segment.selectedSegmentIndex;
            break;
		case 1:
            self.selectedListEntity = @"PersonIdentifier";
            self.selectedListSortDescriptors = [self defaultSortDescriptors];
            self.selectedListPredicate = [NSPredicate predicateWithFormat: @"removedDate == nil" ];
            self.selectedListSectionNameKeyPath = @"representativeInfo.sectionLastName";
			_fetchedResultsController = nil;
			self.selectedList = self.segment.selectedSegmentIndex;
			break;

		case 2:
            self.selectedListEntity = @"PersonIdentifier";
            self.selectedListSortDescriptors = [self defaultSortDescriptors];
			self.selectedListPredicate = [NSPredicate predicateWithFormat: @"removedDate != nil"];
            self.selectedListSectionNameKeyPath = @"representativeInfo.sectionLastName";
			_fetchedResultsController = nil;
			self.selectedList = self.segment.selectedSegmentIndex;
			break;
		default:
			break;
	}
}

- (void) enableTable {

	NSLog (@"enable Table");
	self.syncingOverlay.hidden = YES;
	[self.activityIndicator stopAnimating];
	self.segment.enabled = YES;
	self.moreButton.enabled = YES;
	self.navigationItem.rightBarButtonItem.enabled = YES;
	self.tableView.userInteractionEnabled = YES;
	self.tableView.sectionIndexMinimumDisplayRowCount = 20;
	[self.tableView reloadData];

}

#pragma mark - Action Sheet

-(void) presentActionSheet: (UIButton *) sender {
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:nil
                                          message:nil
                                          preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *cancelAction = [UIAlertAction
                                   actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel action")
                                   style:UIAlertActionStyleCancel
                                   handler:^(UIAlertAction *action)
                                   {
                                       NSLog(@"Cancel action");
                                   }];
    
    
    UIAlertAction *syncAddressBookAction = [UIAlertAction
                                                actionWithTitle:NSLocalizedString(@"Sync with Contacts", @"Sync with Contacts")
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction *action)
                                                {
                                                    if(ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied){
                                                        [AppUtils showAlert];
                                                    } else {
                                                        [self.ceaselessContacts ensureCeaselessContactsSynced];
                                                        [self handleSyncing];
                                                        NSLog(@"Sync with Contacts");
                                                    }
                                                }];
    
    UIAlertAction *addContactAction = [UIAlertAction
                                           actionWithTitle:NSLocalizedString(@"Add a person", @"Add a person")
                                           style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction *action)
                                           {
                                               ABNewPersonViewController *newPersonViewController = [[ABNewPersonViewController alloc] init];
                                               newPersonViewController.newPersonViewDelegate = self;
                                               UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:newPersonViewController];
                                               [self presentViewController:navController animated:YES completion:nil];
                                               
                                               CeaselessLocalContacts *clc = [CeaselessLocalContacts sharedCeaselessLocalContacts];
                                               clc.internalAddressBookChange = YES;
                                               
                                               NSLog(@"Add to Ceaseless");
                                           }];
    
    [alertController addAction:syncAddressBookAction];
    [alertController addAction:addContactAction];
    [alertController addAction:cancelAction];

    
    //this prevents crash on iPad in iOS 8 - known Apple bug
    UIPopoverPresentationController *popover = alertController.popoverPresentationController;
    if (popover)
    {
        popover.sourceView = sender;
        popover.sourceRect = sender.bounds;
        popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    }
    
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - ABNewPersonViewControllerDelegate protocol conformance
- (void)newPersonViewController:(ABNewPersonViewController *)newPersonView didCompleteWithNewPerson:(ABRecordRef)person {
    CeaselessLocalContacts *ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];
    if (person != NULL) {
        [self hideInstructions];
        ABRecordID abRecordID = ABRecordGetRecordID(person);
        
        ABAddressBookRef addressBook = [AppUtils getAddressBookRef];
        
        ABRecordRef abPerson = ABAddressBookGetPersonWithRecordID(addressBook, abRecordID);
        [ceaselessContacts updateCeaselessContactFromABRecord: abPerson];
        PersonIdentifier *ceaselessPerson = [ceaselessContacts getCeaselessContactFromABRecord:abPerson];
        
        CFRelease(addressBook);
        if (ceaselessPerson != nil) {
            PersonViewController *personViewController = [[PersonViewController alloc]init];
            personViewController.dataObject = ceaselessPerson;
            [self.navigationController pushViewController:personViewController animated:YES];
        } else {
            [[[UIAlertView alloc] initWithTitle:nil message:NSLocalizedString(@"Ceaseless only syncs contacts that have at least a first name.", nil) delegate:nil cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil] show];
        }
    } else {
        ceaselessContacts.internalAddressBookChange = NO;
    }
	[newPersonView dismissViewControllerAnimated:YES completion:nil];

}

#pragma mark - Instructions
- (void) showInstructionsIfNeeded {
    NSInteger peopleCount = [[CeaselessLocalContacts sharedCeaselessLocalContacts] numberOfActiveCeaselessContacts];
    if (![AppUtils addressBookAuthorized]) {
        [AppUtils showAlert];
    } else {
        if (peopleCount == 0) {
            [self.instructionBubble addTarget:self action:@selector(presentActionSheet:)forControlEvents:UIControlEventTouchUpInside];
            self.instructionBubble.layer.cornerRadius = 6.0f;
            [AppUtils bounceView:self.instructionBubble distance: -6.0 duration: 0.4];
            self.instructionBubble.hidden = NO;
        }
    }
}

- (void) hideInstructions {
    self.instructionBubble.hidden = YES;
}

@end
