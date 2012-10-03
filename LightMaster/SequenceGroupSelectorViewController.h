//
//  SequenceGroupSelectorViewController.h
//  LightMaster
//
//  Created by James Adams on 12/23/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Data.h"

@interface SequenceGroupSelectorViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>
{
    Data *__weak data;
    
    IBOutlet NSTableView *tableView;
    IBOutlet NSTextField *beingUsedLabel;
    IBOutlet NSButton *addButton;
    IBOutlet NSButton *addCopyButton;
}

@property(readwrite, weak) Data *data;

- (IBAction)addButtonPress:(id)sender;
- (IBAction)addCopyButtonPress:(id)sender;

- (void)reload;
- (void)setSelectedGroupFilePath:(NSString *)selectedGroupFilePath;

@end
