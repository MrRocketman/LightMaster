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
    __strong NSMutableDictionary *controlBox;
    
    IBOutlet NSTextField *idTextField;
    IBOutlet NSTextField *descriptionTextField;
    
    IBOutlet NSTableView *channelsTableView;
    IBOutlet NSButton *addChannelButton;
    IBOutlet NSButton *deleteChannelButton;
}

@property(strong) NSMutableDictionary *controlBox;

- (void)updateContent;

- (IBAction)addChannelButtonPress:(id)sender;
- (IBAction)deleteChannelButtonPress:(id)sender;

@end
