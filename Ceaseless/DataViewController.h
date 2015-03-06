//
//  DataViewController.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/2/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PersonView.h"
#import "ScriptureView.h"

@interface DataViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIView *cardView;
@property (weak, nonatomic) IBOutlet UIView *shadowView;
@property (strong, nonatomic) PersonView *personView;
@property (strong, nonatomic) ScriptureView *scriptureView;
@property (strong, nonatomic) id dataObject;
@property (nonatomic) NSUInteger index;

@end

