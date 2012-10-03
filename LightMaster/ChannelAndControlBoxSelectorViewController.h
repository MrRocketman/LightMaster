//
//  GroupItemSelectorViewController.h
//  LightMaster
//
//  Created by James Adams on 12/21/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Data.h"

@interface ChannelAndControlBoxSelectorViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource>
{
    Data *__weak data;
    NSMutableDictionary *itemData;
    
    IBOutlet NSTableView *controlBoxTableView;
    IBOutlet NSTableView *channelsTableView;
    IBOutlet NSButton *selectButton;
}

@property(readwrite, weak) Data *data;
- (void)setItemData:(NSMutableDictionary *)newItemData;

- (IBAction)selectButtonPress:(id)sender;

- (void)reload;

@end
