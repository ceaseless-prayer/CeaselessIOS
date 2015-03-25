//
//  PersonViewController.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/6/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import "DataViewController.h"
#import "PersonView.h"
#import "PersonNotesViewController.h"
#import "NoteViewController.h"

@interface PersonViewController : DataViewController <UITableViewDelegate, NoteViewControllerDelegate>
//    @property (strong, nonatomic) IBOutlet PersonView *personView;
@property (strong, nonatomic) PersonNotesViewController *personNotesViewController;
@property (strong, nonatomic) UIStoryboard *mainStoryboard;

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (void)setDynamicViewConstraintsToView: (UIView *) parentView forSubview: (UIView *) newSubview;


@end