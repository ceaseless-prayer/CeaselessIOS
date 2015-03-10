//
//  NotesTableViewController.h
//  Ceaseless
//
//  Created by Lori Hill on 3/10/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PersonNotesViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView *notesTableView;

@property (strong, nonatomic) NSArray *notesArray;


@end
