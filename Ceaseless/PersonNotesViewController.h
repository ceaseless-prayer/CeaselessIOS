//
//  NotesTableViewController.h
//  Ceaseless
//
//  Created by Lori Hill on 3/10/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "PersonIdentifier.h"

@interface PersonNotesViewController : UITableViewController <UITableViewDataSource, NSFetchedResultsControllerDelegate>


@property (weak, nonatomic) IBOutlet UITableView *notesTableView;
//@property (strong, nonatomic) NSArray *notesArray;
@property (strong, nonatomic) PersonIdentifier *person;
@property (nonatomic) BOOL notesAvailable;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;


@end
