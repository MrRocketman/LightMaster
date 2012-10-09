//
//  MNControlBoxLibraryManagerViewController.h
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class MNData;

@interface MNControlBoxLibraryManagerViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>
{
    IBOutlet MNData *data;
    int controlBoxIndex; // Can't use a pointer here - things go HORRIBLY wrong if you do
    
    IBOutlet NSTextField *idTextField;
    IBOutlet NSTextField *descriptionTextField;
    
    IBOutlet NSTableView *channelsTableView;
    IBOutlet NSButton *addChannelButton;
    IBOutlet NSButton *deleteChannelButton;
}

@property() int controlBoxIndex;

- (void)updateContent;

- (IBAction)addChannelButtonPress:(id)sender;
- (IBAction)deleteChannelButtonPress:(id)sender;

@end
