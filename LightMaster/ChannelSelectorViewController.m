//
//  ChannelSelectorViewController.m
//  LightMaster
//
//  Created by James Adams on 12/21/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import "ChannelSelectorViewController.h"

@implementation ChannelSelectorViewController

@synthesize data;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Custom initialization code here
    }
    
    return self;
}

- (void)setControlBox:(NSMutableDictionary *)newControlBox
{
    if(newControlBox != controlBox)
    {
        controlBox = newControlBox;
        group = nil;
        [tableView reloadData];
    }
}

- (void)setGroup:(NSMutableDictionary *)newGroup
{
    if(newGroup != group)
    {
        group = newGroup;
        controlBox = nil;
        [tableView reloadData];
    }
}

- (void)setChannelIndex:(int)newChannelIndex
{
    channelIndex = newChannelIndex;
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:channelIndex] byExtendingSelection:NO];
}

- (IBAction)selectButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectChannelIndexForCommand" object:[NSNumber numberWithInt:(int)[tableView selectedRow]] userInfo:nil];
}

- (void)reload
{
    [tableView reloadData];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(controlBox != nil)
    {
        //NSLog(@"channelsCount:%d", [data channelsCountForControlBox:controlBox]);
        return [data channelsCountForControlBox:controlBox];
    }
    else if(group != nil)
    {
        return [data itemsCountForGroup:group];
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(controlBox != nil)
    {
        if([[aTableColumn identifier] isEqualToString:@"Number"])
        {
            NSNumber *numberForChannel = [data numberForChannel:[data channelAtIndex:(int)rowIndex forControlBox:controlBox]];
            return [NSNumber numberWithInt:[numberForChannel intValue] + 1];
        }
        else if([[aTableColumn identifier] isEqualToString:@"Color"])
        {
            return [data colorForChannel:[data channelAtIndex:(int)rowIndex forControlBox:controlBox]];
        }
        else if([[aTableColumn identifier] isEqualToString:@"Description"])
        {
            return [data descriptionForChannel:[data channelAtIndex:(int)rowIndex forControlBox:controlBox]];
        }
        else if([[aTableColumn identifier] isEqualToString:@"Control Box"])
        {
            return [data descriptionForControlBox:controlBox];
        }
    }
    else if(group != nil)
    {
        if([[aTableColumn identifier] isEqualToString:@"Number"])
        {
            NSNumber *numberForChannel = [data numberForChannel:[data channelAtIndex:(int)[data channelIndexForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:group]] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:group]]]]];
            return [NSNumber numberWithInt:[numberForChannel intValue] + 1];
        }
        else if([[aTableColumn identifier] isEqualToString:@"Color"])
        {
            return [data colorForChannel:[data channelAtIndex:(int)[data channelIndexForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:group]] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:group]]]]];
        }
        else if([[aTableColumn identifier] isEqualToString:@"Description"])
        {
            return [data descriptionForChannel:[data channelAtIndex:(int)[data channelIndexForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:group]] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:group]]]]];
        }
        else if([[aTableColumn identifier] isEqualToString:@"Control Box"])
        {
            return [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:group]]]];
        }
    }
    
    return @"nil";
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //NSLog(@"tableView selected:%d", (int)[tableView selectedRow]);
    
    if([tableView selectedRow] > -1)
    {
        [selectButton setEnabled:YES];
    }
    else
    {
        [selectButton setEnabled:NO];
    }
}

@end
