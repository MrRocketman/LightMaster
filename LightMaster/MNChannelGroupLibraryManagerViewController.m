//
//  MNChannelGroupLibraryManagerViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNChannelGroupLibraryManagerViewController.h"
#import "MNData.h"
#import "MNControlBoxChannelSelectorViewController.h"

@interface MNChannelGroupLibraryManagerViewController ()

- (void)textDidBeginEditing:(NSNotification *)aNotification;
- (void)textDidEndEditing:(NSNotification *)aNotification;
- (NSMutableDictionary *)channelGroup;
- (void)addItemDataToControlBox:(NSNotification *)aNotification;

@end

@implementation MNChannelGroupLibraryManagerViewController

@synthesize channelGroupIndex;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Text Editing Notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidBeginEditing:) name:@"NSControlTextDidBeginEditingNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:@"NSControlTextDidEndEditingNotification" object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:@"NSControlTextDidChangeNotification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addItemDataToControlBox:) name:@"AddItemDataToSelectedChannelGroup" object:nil];
        
        channelGroupIndex = -1;
    }
    
    return self;
}

- (NSMutableDictionary *)channelGroup
{
    if(channelGroupIndex > -1)
        return [data channelGroupFromFilePath:[data channelGroupFilePathAtIndex:channelGroupIndex]];
    
    return nil;
}

- (void)updateContent
{
    if(channelGroupIndex > -1)
    {
        [descriptionTextField setEnabled:YES];
        
        [addChannelButton setEnabled:YES];
        
        [descriptionTextField setStringValue:[data descriptionForChannelGroup:[self channelGroup]]];
    }
    else
    {
        [descriptionTextField setEnabled:NO];
        
        [addChannelButton setEnabled:NO];
        [removeChannelButton setEnabled:NO];
        
        [descriptionTextField setStringValue:@""];
    }
    
    [channelsTableView reloadData];
}

- (void)addItemDataToControlBox:(NSNotification *)aNotification
{
    [controlBoxChannelSelectorPopover performClose:nil];
    NSDictionary *theDictionary = [aNotification object];
    int channelIndex = [[theDictionary objectForKey:@"ChannelIndex"] intValue];
    int controlBoxIndex = [[theDictionary objectForKey:@"ControlBoxIndex"] intValue];
    
    [data createItemDataAndReturnNewItemIndexForChannelGroup:[self channelGroup]];
    [data setChannelIndex:channelIndex forItemDataAtIndex:(int)([data itemsCountForChannelGroup:[self channelGroup]] - 1) whichIsPartOfChannelGroup:[self channelGroup]];
    [data setControlBoxFilePath:[data filePathForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:controlBoxIndex]]] forItemDataAtIndex:(int)([data itemsCountForChannelGroup:[self channelGroup]] - 1) whichIsPartOfChannelGroup:[self channelGroup]];
    
    [channelsTableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

#pragma mark - Button Actions

- (IBAction)addChannelButtonPress:(id)sender
{
    [controlBoxChannelSelectorPopover showRelativeToRect:[channelsTableView rectOfRow:[channelsTableView selectedRow]] ofView:channelsTableView preferredEdge:NSMaxYEdge];
    [controlBoxChannelSelectorViewController reload];
    if([channelsTableView selectedRow] > -1)
    {
        //[controlBoxChannelSelectorViewController setSelectedControlBoxFilePath:[data controlBoxFilePathAtIndex:(int)[controlBoxesTableView selectedRow] forSequence:sequence]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)removeChannelButtonPress:(id)sender
{
    [data removeItemData:[data itemDataAtIndex:(int)[channelsTableView selectedRow] forChannelGroup:[self channelGroup]] forChannelGroup:[self channelGroup]];
    [channelsTableView deselectAll:nil];
    [channelsTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [data itemsCountForChannelGroup:[self channelGroup]];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if([[aTableColumn identifier] isEqualToString:@"Number"])
    {;
        return [data numberForChannel:[data channelAtIndex:[data channelIndexForItemData:[data itemDataAtIndex:(int)rowIndex forChannelGroup:[self channelGroup]]] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:[data itemDataAtIndex:(int)rowIndex forChannelGroup:[self channelGroup]]]]]];
    }
    else if([[aTableColumn identifier] isEqualToString:@"Color"])
    {
        return [data colorForChannel:[data channelAtIndex:[data channelIndexForItemData:[data itemDataAtIndex:(int)rowIndex forChannelGroup:[self channelGroup]]] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:[data itemDataAtIndex:(int)rowIndex forChannelGroup:[self channelGroup]]]]]];
    }
    else if([[aTableColumn identifier] isEqualToString:@"Description"])
    {
        return [data descriptionForChannel:[data channelAtIndex:[data channelIndexForItemData:[data itemDataAtIndex:(int)rowIndex forChannelGroup:[self channelGroup]]] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:[data itemDataAtIndex:(int)rowIndex forChannelGroup:[self channelGroup]]]]]];
    }
    else if([[aTableColumn identifier] isEqualToString:@"Control Box"])
    {
        return [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:[data itemDataAtIndex:(int)rowIndex forChannelGroup:[self channelGroup]]]]];
    }
    
    return @"nil";
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if([channelsTableView selectedRow] > -1)
    {
        [removeChannelButton setEnabled:YES];
    }
    else
    {
        [removeChannelButton setEnabled:NO];
    }
}

#pragma mark - TextEditinig Notifications

- (void)textDidBeginEditing:(NSNotification *)aNotification
{
    
}

- (void)textDidChange:(NSNotification *)aNotification
{
    
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
    if([aNotification object] == descriptionTextField)
    {
        [data setDescription:[descriptionTextField stringValue] forChannelGroup:[self channelGroup]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibrariesViewController" object:nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

@end
