//
//  GroupItemSelectorViewController.m
//  LightMaster
//
//  Created by James Adams on 12/21/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import "ChannelAndControlBoxSelectorViewController.h"

@interface ChannelAndControlBoxSelectorViewController()

- (NSMutableDictionary *)selectedControlBox;

@end

@implementation ChannelAndControlBoxSelectorViewController

@synthesize data;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Custom initialization code here
    }
    
    return self;
}

- (void)setItemData:(NSMutableDictionary *)newItemData
{
    if(newItemData != itemData)
    {
        itemData = newItemData;
    }
    
    if([data controlBoxFilePathForItemData:itemData] != nil)
    {
        NSMutableArray *controlBoxFilePaths = [data controlBoxFilePaths];
        int itemDataControlBoxIndex = 0;
        itemDataControlBoxIndex = (int)[controlBoxFilePaths indexOfObject:[data controlBoxFilePathForItemData:itemData]];
        //NSLog(@"controlBoxIndex:%d", itemDataControlBoxIndex);

        [controlBoxTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:itemDataControlBoxIndex] byExtendingSelection:NO];
        [channelsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data channelIndexForItemData:itemData]] byExtendingSelection:NO];
    }
    else
    {
        [controlBoxTableView deselectAll:nil];
        [channelsTableView deselectAll:nil];
    }
}

- (NSMutableDictionary *)itemData
{
    return itemData;
}

- (NSMutableDictionary *)selectedControlBox
{
    if((int)[controlBoxTableView selectedRow] > -1)
    {
        return [data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:(int)[controlBoxTableView selectedRow]]];
    }
    
    return nil;
}

- (IBAction)selectButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectChannelIndexAndControlBoxForCurrentGroup" object:nil userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:(int)[channelsTableView selectedRow]], [data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:(int)[controlBoxTableView selectedRow]]], nil] forKeys:[NSArray arrayWithObjects:@"channelIndex", @"controlBox", nil]]];
}

- (void)reload
{
    [controlBoxTableView reloadData];
    [channelsTableView reloadData];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:controlBoxTableView]];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == controlBoxTableView)
    {
        return [data controlBoxFilePathsCount];
    }
    else if(aTableView == channelsTableView)
    {
        if((int)[controlBoxTableView selectedRow] > -1)
        {
            return [data channelsCountForControlBox:[self selectedControlBox]];
        }
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(aTableView == channelsTableView)
    {
        if([[aTableColumn identifier] isEqualToString:@"Number"])
        {
            NSNumber *numberForChannel = [data numberForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self selectedControlBox]]];
            return [NSNumber numberWithInt:[numberForChannel intValue] + 1];
        }
        else if([[aTableColumn identifier] isEqualToString:@"Color"])
        {
            return [data colorForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self selectedControlBox]]];
        }
        else if([[aTableColumn identifier] isEqualToString:@"Description"])
        {
            return [data descriptionForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self selectedControlBox]]];
        }
    }
    else if(aTableView == controlBoxTableView)
    {
        return [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:(int)rowIndex]]];
    }
    
    return @"nil";
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //NSLog(@"tableView selected:%d", (int)[tableView selectedRow]);
    if([notification object] == controlBoxTableView)
    {
        [channelsTableView reloadData];
    }
    else if([notification object] == channelsTableView)
    {
        if([channelsTableView selectedRow] > -1)
        {
            [selectButton setEnabled:YES];
        }
        else
        {
            [selectButton setEnabled:NO];
        }
    }
}

@end
