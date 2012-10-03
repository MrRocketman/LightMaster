//
//  ChannelSelectorViewController.h
//  LightMaster
//
//  Created by James Adams on 12/21/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Data.h"

@interface ChannelSelectorViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>
{
    Data *__weak data;
    NSMutableDictionary *controlBox;
    NSMutableDictionary *group;
    int channelIndex;
    
    IBOutlet NSTableView *tableView;
    IBOutlet NSButton *selectButton;
}

@property(readwrite, weak) Data *data;
- (void)setControlBox:(NSMutableDictionary *)newControlBox;
- (void)setGroup:(NSMutableDictionary *)newGroup;
- (void)setChannelIndex:(int)newChannelIndex;

- (IBAction)selectButtonPress:(id)sender;

- (void)reload;

@end
