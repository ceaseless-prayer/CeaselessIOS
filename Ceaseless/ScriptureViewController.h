//
//  ScriptureViewController.h
//  Ceaseless
//
//  Created by Christopher Lim on 3/6/15.
//  Copyright (c) 2015 Christopher Lim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DataViewController.h"
#import "ScriptureView.h"

@interface ScriptureViewController : DataViewController
    @property (strong, nonatomic) IBOutlet ScriptureView *scriptureView;
@end
