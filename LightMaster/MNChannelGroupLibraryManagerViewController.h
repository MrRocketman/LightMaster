//
//  MNChannelGroupLibraryManagerViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MNData, MNControlBoxChannelSelectorViewController;

@interface MNChannelGroupLibraryManagerViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet MNData *data;
    int channelGroupIndex;
    
    IBOutlet MNControlBoxChannelSelectorViewController *controlBoxChannelSelectorViewController;
    IBOutlet NSPopover *controlBoxChannelSelectorPopover;
    IBOutlet NSTextField *descriptionTextField;
    IBOutlet NSTableView *channelsTableView;
    IBOutlet NSButton *addChannelButton;
    IBOutlet NSButton *removeChannelButton;
}

@property() int channelGroupIndex;

- (void)updateContent;

- (IBAction)addChannelButtonPress:(id)sender;
- (IBAction)removeChannelButtonPress:(id)sender;

@end
