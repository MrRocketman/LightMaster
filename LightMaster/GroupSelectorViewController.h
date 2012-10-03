//
//  ControlBoxSelectorViewController.h
//  LightMaster
//
//  Created by James Adams on 12/21/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Data.h"

@interface GroupSelectorViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>
{
    Data *__weak data;
    
    IBOutlet NSTableView *tableView;
    IBOutlet NSButton *selectButton;
}

@property(readwrite, weak) Data *data;

- (IBAction)selectButtonPress:(id)sender;

- (void)reload;

@end
