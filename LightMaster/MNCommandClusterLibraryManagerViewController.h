//
//  MNCommandClusterLibraryManagerViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MNData;

@interface MNCommandClusterLibraryManagerViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
{
    int commandClusterIndex;
    IBOutlet MNData *data;
    
    IBOutlet NSTextField *descriptionTextField;
    IBOutlet NSTextField *startTimeTextField;
    IBOutlet NSTextField *endTimeTextField;
    IBOutlet NSTextField *adjustByTimeTextTextField;
    
    IBOutlet NSTextField *commandClusterControlBoxLabel;
    IBOutlet NSTextField *commandClusterChannelGroupLabel;
    IBOutlet NSButton *chooseControlBoxForCommandClusterButton;
    IBOutlet NSButton *chooseChannelGroupForCommandClusterButton;
    
    IBOutlet NSTableView *commandsTableView;
    IBOutlet NSTextField *commandChannelLabel;
    IBOutlet NSTextField *commandControlBoxLabel;
    IBOutlet NSButton *chooseChannelForCommandButton;
    IBOutlet NSButton *addCommandButton;
    IBOutlet NSButton *deleteCommandButton;
}

@property() int commandClusterIndex;

- (void)updateContent;

- (IBAction)chooseControlBoxForCommandClusterButtonPress:(id)sender;
- (IBAction)chooseChannelGroupForCommandClusterButtonPress:(id)sender;
- (IBAction)chooseChannelForCommandButtonPress:(id)sender;
- (IBAction)addCommandButtonPress:(id)sender;
- (IBAction)deleteCommandButtonPress:(id)sender;

@end
