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
#import "PrayerJournalTableViewCell.h"
#import "CeaselessLocalContacts.h"
#import "PersonIdentifier.h"
#import "Name.h"
#import "AppUtils.h"
#import "UIImageEffects.h"

@interface PrayerJournalViewController () <NSFetchedResultsControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating, UISearchControllerDelegate>

@property (strong, nonatomic) NSArray *filteredList;
@property (strong, nonatomic) NSFetchRequest *searchFetchRequest;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) CeaselessLocalContacts *ceaselessContacts;

@end

@implementation PrayerJournalViewController

- (void)awakeFromNib {
	[super awakeFromNib];
	AppDelegate *appDelegate = (id) [[UIApplication sharedApplication] delegate];
	self.managedObjectContext = appDelegate.managedObjectContext;
    self.ceaselessContacts = [CeaselessLocalContacts sharedCeaselessLocalContacts];
}

- (void)viewDidLoad {
	[super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.screenName = @"PrayerJournalScreen";
	UIImageView *imageView = [[UIImageView alloc] initWithFrame: self.view.frame];
	imageView.contentMode = UIViewContentModeScaleAspectFill;
	UIImage *backgroundImage = [AppUtils getDynamicBackgroundImage];
	if(backgroundImage != nil) {
		self.backgroundImageView.image = backgroundImage;
	}
	
	self.tableView.estimatedRowHeight = 130.0;
	self.tableView.rowHeight = UITableViewAutomaticDimension;

	[self searchControllerSetup];

}
- (void) searchControllerSetup {
		//searchController cannot be set up in IB, so set it up here
	self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
	self.searchController.searchResultsUpdater = self;
	self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.barTintColor = UIColorFromRGBWithAlpha(0x00012f , 0.4);
    self.searchController.searchBar.translucent = YES;
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
	[super viewWillAppear: animated];
	[self adjustSearchBar];
}

- (void)adjustSearchBar{
    //if this isn't done, the textfield gets positioned to far left some of the time :(  Apple Bug
	[self.searchController.searchBar setPositionAdjustment: UIOffsetMake (0.0, 0.0) forSearchBarIcon: UISearchBarIconSearch];
	self.tableView.tableHeaderView = self.searchController.searchBar;
    self.tableView.tableHeaderView.layer.cornerRadius = 6.0f;
    self.tableView.tableHeaderView.clipsToBounds = YES;
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
	if ([[segue identifier] isEqualToString:@"ShowNote"]) {
		Note *currentNote = nil;
		NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];

		if (self.searchController.isActive) {
			currentNote = [self.filteredList objectAtIndex:indexPath.row];
		} else {

			currentNote = [self.fetchedResultsController objectAtIndexPath:indexPath];
		}

		self.noteViewController = segue.destinationViewController;
		self.noteViewController.currentNote = currentNote;
	}
}
- (IBAction)unwindToPrayerJournal:(UIStoryboardSegue*)sender
{
		// Pull any data from the view controller which initiated the unwind segue.
	[self.tableView reloadData];
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
        NSInteger rowCount = [sectionInfo numberOfObjects];
        if(rowCount == 0) {
            [self showInstructions];
        } else {
            // if we ever have a cell, it means no instructions are needed anymore
            [self hideInstructions];
        }
		return rowCount;
	}
}
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return 0;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

	PrayerJournalTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

	[self configureCell:cell atIndexPath:indexPath];
	return cell;
}

- (void)configureCell:(PrayerJournalTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
	Note *note = nil;
	if (self.searchController.active) {
		note = [self.filteredList objectAtIndex:indexPath.row];
	} else {
		note = [self.fetchedResultsController objectAtIndexPath:indexPath];
	}


	NSArray *peopleArray = [note.peopleTagged array];

	if ([peopleArray count] > 0) {
        PersonIdentifier *person = [peopleArray firstObject];
        UIImage *profileImage = [_ceaselessContacts getImageForPersonIdentifier:person];
		if (profileImage) {
			cell.topImageView.hidden = NO;
			cell.topImageView.image = profileImage;
			cell.topImageView.contentMode = UIViewContentModeScaleAspectFit;
			cell.topPlaceholderLabel.hidden = YES;
			cell.topPlaceholderLabel.text = nil;
		} else {
			cell.topPlaceholderLabel.hidden = NO;
			cell.topPlaceholderLabel.text = [_ceaselessContacts initialsForPerson: person];
			cell.topImageView.image = nil;
			cell.topImageView.hidden = YES;
		}
	} else {
			//TODO  should this be a picture of self?  nobody was tagged, but there is a note
		cell.topImageView.image = nil;
		cell.topImageView.hidden = YES;
		cell.topPlaceholderLabel.text = nil;
		cell.topPlaceholderLabel.hidden = YES;

	}

	if ([peopleArray count] > 1) {
        PersonIdentifier *person = peopleArray[1];
        UIImage *profileImage = [_ceaselessContacts getImageForPersonIdentifier:person];
		if (profileImage) {
			cell.bottomImageView.hidden = NO;
			cell.bottomImageView.image = profileImage;
			cell.bottomImageView.contentMode = UIViewContentModeScaleAspectFit;
			cell.bottomPlaceholderLabel.hidden = YES;
			cell.bottomPlaceholderLabel.text = nil;
		} else {
			cell.bottomPlaceholderLabel.hidden = NO;
			cell.bottomPlaceholderLabel.text = [_ceaselessContacts initialsForPerson: person];
			cell.bottomImageView.image = nil;
			cell.bottomImageView.hidden = YES;
		}
	} else {
		cell.bottomImageView.image = nil;
		cell.bottomImageView.hidden = YES;
		cell.bottomPlaceholderLabel.text = nil;
		cell.bottomPlaceholderLabel.hidden = YES;
	}

	NSMutableArray *namesArray = [[NSMutableArray alloc] initWithCapacity: [note.peopleTagged count]];
	for (PersonIdentifier *personTagged in note.peopleTagged) {
		NSString *personName = [_ceaselessContacts compositeNameForPerson:personTagged];
		[namesArray addObject: personName];
	}
    
	NSString *allNamesString = [namesArray componentsJoinedByString:@", "];
	cell.peopleTagged.text = allNamesString;
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	dateFormatter.timeStyle = NSDateFormatterNoStyle;
	dateFormatter.dateStyle = NSDateFormatterShortStyle;
	NSDate *date = [note valueForKey:@"lastUpdatedDate"];

	cell.date.text = [dateFormatter stringFromDate:date];
	cell.text.text = [[note valueForKey:@"text"] description];
    cell.backgroundColor = [UIColor clearColor];
	
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
	[self searchForText:searchString];
	[self adjustSearchBar];
	[self.tableView reloadData];
}

- (void)searchForText:(NSString *)searchText
{
	if (self.managedObjectContext) {

			//first search text in Notes
		NSString *predicateFormat = @"text contains[cd] %@";
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:self.managedObjectContext];
		[self.searchFetchRequest setEntity:entity];

		[self.searchFetchRequest setSortDescriptors:nil];

		NSPredicate *predicate = [NSPredicate predicateWithFormat:predicateFormat, searchText];
		[self.searchFetchRequest setPredicate:predicate];

		NSError *error = nil;
		NSArray *selectedNotes = [self.managedObjectContext executeFetchRequest:self.searchFetchRequest error:&error];

			//put the selected Notes in a Set
		NSMutableSet* selectedNotesSet = [[NSMutableSet alloc] init];
		[selectedNotesSet addObjectsFromArray: selectedNotes];

			//now search by name
		predicateFormat = @"(representativeInfo.primaryFirstName.name BEGINSWITH[cd] %@ OR representativeInfo.primaryLastName.name BEGINSWITH[cd] %@)";

		entity = [NSEntityDescription entityForName:@"PersonIdentifier" inManagedObjectContext:self.managedObjectContext];
		[self.searchFetchRequest setEntity:entity];

		[self.searchFetchRequest setSortDescriptors:nil];

			//use same search in both first and last names unless a space has been entered,
			//assume that the space separates the first and last name - there are so edge cases that this does not work on like Jessica Jo de Reuter
			//when a space is entered, assume that the second word is the last name

		NSString *searchFirst = searchText;
		NSString *searchLast = searchText;

		if ([searchText containsString: @" "]) {
			NSArray *substrings = [searchText componentsSeparatedByString:@" "];
			if ([searchText hasSuffix: @" "]) {
				searchFirst = [substrings objectAtIndex:0];
				searchLast = searchFirst;
			} else {
				searchFirst = [substrings objectAtIndex:0];
					//when there is a first name and last name change operator to "AND" to return just that person
				predicateFormat = @"(representativeInfo.primaryFirstName.name BEGINSWITH[cd] %@ AND representativeInfo.primaryLastName.name BEGINSWITH[cd] %@)";
				searchLast = [substrings objectAtIndex:1];
			}
		}

		predicate = [NSPredicate predicateWithFormat:predicateFormat, searchFirst, searchLast];

		[self.searchFetchRequest setPredicate:predicate];

		error = nil;
		NSArray *arrayOfPersonIdentifiers = [self.managedObjectContext executeFetchRequest:self.searchFetchRequest error:&error];

		for (PersonIdentifier *person in arrayOfPersonIdentifiers) {
			if ([person.notes count] > 0) {
					//add the notes to the set of Notes selected by text
				[selectedNotesSet unionSet: person.notes];
			}
		}

		NSSortDescriptor *sortDescriptorForNotes = [[NSSortDescriptor alloc] initWithKey:@"lastUpdatedDate" ascending:NO];
		NSArray *sortDescriptorsForNotes = [NSArray arrayWithObjects:sortDescriptorForNotes, nil];

			//sort the selected notes by last updated Date
		self.filteredList = [selectedNotesSet sortedArrayUsingDescriptors:sortDescriptorsForNotes];
	}
}

- (NSFetchRequest *)searchFetchRequest
{
	if (_searchFetchRequest != nil)
  {
  return _searchFetchRequest;
  }

	_searchFetchRequest = [[NSFetchRequest alloc] init];



	return _searchFetchRequest;
}

- (void)willDismissSearchController:(UISearchController *)searchController {
	[self searchControllerSetup];
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
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUpdatedDate" ascending:NO];
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

- (void) listAll {

  NSError * error = nil;

  NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
  NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note"
											inManagedObjectContext:self.managedObjectContext];
  [fetchRequest setEntity:entity];


  NSArray *fetchedObjects = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
  for (id managedObject in fetchedObjects) {

	  NSLog(@"create date: %@", [managedObject valueForKey: @"createDate"]);
	  NSLog(@"text: %@", [managedObject valueForKey: @"text"]);
	  NSLog(@"last update date: %@", [managedObject valueForKey: @"lastUpdatedDate"]);
  }
}

- (void) showInstructions {
    self.instructionBubble.layer.cornerRadius = 6.0f;
    [AppUtils bounceView:self.instructionBubble distance: -6.0 duration: 0.4];
    self.instructionBubble.hidden = NO;
}

- (void) hideInstructions {
    self.instructionBubble.hidden = YES;
}
@end
