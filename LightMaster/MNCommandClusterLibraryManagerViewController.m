//
//  MNCommandClusterLibraryManagerViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNCommandClusterLibraryManagerViewController.h"
#import "MNData.h"
#import "MNCommandChannelSelectorViewController.h"
#import "MNCommandClusterChannelGroupSelectorViewController.h"
#import "MNCommandClusterControlBoxSelectorViewController.h"

@interface MNCommandClusterLibraryManagerViewController ()

- (void)textDidBeginEditing:(NSNotification *)aNotification;
- (void)textDidEndEditing:(NSNotification *)aNotification;
- (NSMutableDictionary *)commandCluster;
- (void)selectControlBoxForCommandCluster:(NSNotification *)aNotification;
- (void)selectChannelGroupForCommandcluster:(NSNotification *)aNotification;
- (void)selectChannelForCommand:(NSNotification *)aNotification;
- (void)addCommandForCommandCluster:(NSNotification *)aNotification;
- (void)addCommandAtChannelIndex:(int)index withStartTime:(float)startTime andDuration:(float)duration forCommandCluster:(NSMutableDictionary *)commandCluster;

@end


@implementation MNCommandClusterLibraryManagerViewController

@synthesize commandClusterIndex;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Text Editing Notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidBeginEditing:) name:@"NSControlTextDidBeginEditingNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:@"NSControlTextDidEndEditingNotification" object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:@"NSControlTextDidChangeNotification" object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectControlBoxForCommandCluster:) name:@"SelectControlBoxForCommandCluster" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectChannelGroupForCommandcluster:) name:@"SelectChannelGroupForCommandCluster" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectChannelForCommand:) name:@"SelectChannelForCommand" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addCommandForCommandCluster:) name:@"AddCommandAtChannelIndexAndTimeForCommandCluster" object:nil];
        
        commandClusterIndex = -1;
    }
    
    return self;
}

- (NSMutableDictionary *)commandCluster
{
    if(commandClusterIndex > -1)
        return [data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:commandClusterIndex]];
    
    return nil;
}

- (void)updateContent
{
    if(commandClusterIndex > -1)
    {
        [descriptionTextField setEnabled:YES];
        [startTimeTextField setEnabled:YES];
        [endTimeTextField setEnabled:YES];
        [moveClusterByTimeTextField setEnabled:YES];
        [moveClusterToTimeTextField setEnabled:YES];
        
        [chooseControlBoxForCommandClusterButton setEnabled:YES];
        [chooseChannelGroupForCommandClusterButton setEnabled:YES];
        
        if([[data controlBoxFilePathForCommandCluster:[self commandCluster]] length] > 0 || [[data channelGroupFilePathForCommandCluster:[self commandCluster]] length] > 0)
            [addCommandButton setEnabled:YES];
        else
            [addCommandButton setEnabled:NO];
        
        [descriptionTextField setStringValue:[data descriptionForCommandCluster:[self commandCluster]]];
        [startTimeTextField setStringValue:[NSString stringWithFormat:@"%.3f", [data startTimeForCommandCluster:[self commandCluster]]]];
        [endTimeTextField setStringValue:[NSString stringWithFormat:@"%.3f", [data endTimeForCommandCluster:[self commandCluster]]]];
        
        NSString *controlBoxDescription = [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self commandCluster]]]];
        if(controlBoxDescription)
            [commandClusterControlBoxLabel setStringValue:controlBoxDescription];
        else
            [commandClusterControlBoxLabel setStringValue:@""];
        NSString *channelGroupDescription = [data descriptionForChannelGroup:[data channelGroupFromFilePath:[data channelGroupFilePathForCommandCluster:[self commandCluster]]]];
        if(channelGroupDescription)
            [commandClusterChannelGroupLabel setStringValue:channelGroupDescription];
        else
            [commandClusterChannelGroupLabel setStringValue:@""];
    }
    else
    {
        [descriptionTextField setEnabled:NO];
        [startTimeTextField setEnabled:NO];
        [endTimeTextField setEnabled:NO];
        [moveClusterByTimeTextField setEnabled:NO];
        [moveClusterToTimeTextField setEnabled:NO];
        
        [chooseControlBoxForCommandClusterButton setEnabled:NO];
        [chooseChannelGroupForCommandClusterButton setEnabled:NO];
        
        [chooseChannelForCommandButton setEnabled:NO];
        [addCommandButton setEnabled:NO];
        [deleteCommandButton setEnabled:NO];
        
        [descriptionTextField setStringValue:@""];
        [startTimeTextField setStringValue:@""];
        [endTimeTextField setStringValue:@""];
        
        [commandClusterControlBoxLabel setStringValue:@""];
        [commandClusterChannelGroupLabel setStringValue:@""];
    }
    
    [commandsTableView reloadData];
}

- (void)selectCommandAtIndex:(int)index
{
    [commandsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
    [commandsTableView scrollRowToVisible:index];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:commandsTableView]];
}

- (void)addCommandAtChannelIndex:(int)index withStartTime:(float)startTime andDuration:(float)duration forCommandCluster:(NSMutableDictionary *)commandCluster
{
    int newCommandIndex = [data createCommandAndReturnNewCommandIndexForCommandCluster:commandCluster];
    [data setStartTime:startTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
    [data setEndTime:startTime + duration forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
    if(index >= 0)
    {
        [data setChannelIndex:index forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
    }
    
    [commandsTableView reloadData];
    [commandsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newCommandIndex] byExtendingSelection:NO];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:commandsTableView]];
    [commandsTableView scrollRowToVisible:newCommandIndex];
    if(index == -1)
    {
        [self chooseChannelForCommandButtonPress:nil];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

#pragma mark - NSNotifications

- (void)selectControlBoxForCommandCluster:(NSNotification *)aNotification
{
    [commandClusterControlBoxSelectorPopover performClose:nil];
    [commandsTableView deselectAll:nil];
    [data setControlBoxFilePath:[aNotification object] forCommandCluster:[self commandCluster]];
    if([[aNotification object] length] > 0)
    {
        [commandClusterControlBoxLabel setStringValue:[data descriptionForControlBox:[data controlBoxFromFilePath:[aNotification object]]]];
        [self selectChannelGroupForCommandcluster:[NSNotification notificationWithName:@"SelectChannelGroupForCommandCluster" object:@""]];
        
        [addCommandButton setEnabled:YES];
    }
    else
    {
        [commandClusterControlBoxLabel setStringValue:@""];
    }
    
    [self updateContent];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (void)selectChannelGroupForCommandcluster:(NSNotification *)aNotification
{
    [commandClusterChannelGroupSelectorPopover performClose:nil];
    [commandsTableView deselectAll:nil];
    [data setChannelGroupFilePath:[aNotification object] forCommandCluster:[self commandCluster]];
    if([[aNotification object] length] > 0)
    {
        [commandClusterChannelGroupLabel setStringValue:[data descriptionForChannelGroup:[data channelGroupFromFilePath:[aNotification object]]]];
        [self selectControlBoxForCommandCluster:[NSNotification notificationWithName:@"SelectControlBoxForCommandCluster" object:@""]];
        
        [addCommandButton setEnabled:YES];
    }
    else
    {
        [commandClusterControlBoxLabel setStringValue:@""];
    }
    
    [self updateContent];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (void)selectChannelForCommand:(NSNotification *)aNotification
{
    [commandChannelSelectorPopover performClose:nil];
    [data setChannelIndex:[[aNotification object] intValue] forCommandAtIndex:(int)[commandsTableView selectedRow] whichIsPartOfCommandCluster:[self commandCluster]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
    [commandsTableView reloadData];
}

- (void)addCommandForCommandCluster:(NSNotification *)aNotification
{
    [self addCommandAtChannelIndex:[[[aNotification userInfo] objectForKey:@"channelIndex"] intValue] withStartTime:[[[aNotification userInfo] objectForKey:@"startTime"] floatValue] andDuration:0.1 / [data zoomLevel] forCommandCluster:[[aNotification userInfo] objectForKey:@"commandCluster"]];
}

#pragma mark - Button Actions

- (IBAction)chooseControlBoxForCommandClusterButtonPress:(id)sender
{
    [commandClusterControlBoxSelectorPopover showRelativeToRect:[commandClusterControlBoxLabel frame] ofView:self.view preferredEdge:NSMaxYEdge];
    [commandClusterControlBoxSelectorViewController setControlBoxIndex:(int)[[data controlBoxFilePaths] indexOfObject:[data controlBoxFilePathForCommandCluster:[self commandCluster]]]];
    [commandClusterControlBoxSelectorViewController reload];
}

- (IBAction)chooseChannelGroupForCommandClusterButtonPress:(id)sender
{
    [commandClusterChannelGroupSelectorPopover showRelativeToRect:[commandClusterChannelGroupLabel frame] ofView:self.view preferredEdge:NSMaxYEdge];
    [commandClusterChannelGroupSelectorViewController setChannelGroupIndex:(int)[[data channelGroupFilePaths] indexOfObject:[data channelGroupFilePathForCommandCluster:[self commandCluster]]]];
    [commandClusterChannelGroupSelectorViewController reload];
}

- (IBAction)chooseChannelForCommandButtonPress:(id)sender
{
    [commandChannelSelectorPopover showRelativeToRect:[commandsTableView rectOfRow:[commandsTableView selectedRow]] ofView:commandsTableView preferredEdge:NSMaxYEdge];
    
    if([commandsTableView selectedRow] > -1)
    {
        int rowIndex = (int)[commandsTableView selectedRow];
        
        NSString *controlBox = [data controlBoxFilePathForCommandCluster:[self commandCluster]];
        
        int channelIndex = [data channelIndexForCommand:[data commandAtIndex:rowIndex fromCommandCluster:[self commandCluster]]];
        
        [commandChannelSelectorViewController setSelectedControlBoxIndex:(int)[[data controlBoxFilePaths] indexOfObject:controlBox] andChannelIndex:channelIndex];
    }
    
    [commandChannelSelectorViewController reload];
}

- (IBAction)addCommandButtonPress:(id)sender
{
    [self addCommandAtChannelIndex:-1 withStartTime:0.0 andDuration:1.0 forCommandCluster:[self commandCluster]];
}

- (IBAction)deleteCommandButtonPress:(id)sender
{
    int tableViewIndex = (int)[commandsTableView selectedRow];
    [data removeCommand:[data commandAtIndex:tableViewIndex fromCommandCluster:[self commandCluster]] fromCommandCluster:[self commandCluster]];
    [commandsTableView deselectAll:nil];
    [commandsTableView reloadData];
    [commandsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:tableViewIndex - 1] byExtendingSelection:NO];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:commandsTableView]];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [data commandsCountForCommandCluster:[self commandCluster]];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if([[aTableColumn identifier] isEqualToString:@"Start Time"])
    {
        return [NSString stringWithFormat:@"%.3f", [data startTimeForCommand:[data commandAtIndex:(int)rowIndex fromCommandCluster:[self commandCluster]]]];
    }
    else if([[aTableColumn identifier] isEqualToString:@"End Time"])
    {
        return [NSString stringWithFormat:@"%.3f", [data endTimeForCommand:[data commandAtIndex:(int)rowIndex fromCommandCluster:[self commandCluster]]]];
    }
    else if([[aTableColumn identifier] isEqualToString:@"Channel Number"])
    {
        return [NSNumber numberWithInt:(int)[data channelIndexForCommand:[data commandAtIndex:(int)rowIndex fromCommandCluster:[self commandCluster]]]];
    }
    else if([[aTableColumn identifier] isEqualToString:@"Channel Color"])
    {
        // This is a controlBoxCluster
        if([[data controlBoxFilePathForCommandCluster:[self commandCluster]] length] > 0)
        {
            return [data colorForChannel:[data channelAtIndex:[data channelIndexForCommand:[data commandAtIndex:(int)rowIndex fromCommandCluster:[self commandCluster]]] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self commandCluster]]]]];
        }
        // This is a channelGroupCluster
        else
        {
            NSMutableDictionary *itemData = [data itemDataAtIndex:[data channelIndexForCommand:[data commandAtIndex:(int)rowIndex fromCommandCluster:[self commandCluster]]] forChannelGroup:[data channelGroupFromFilePath:[data channelGroupFilePathForCommandCluster:[self commandCluster]]]];
            
            return [data colorForChannel:[data channelAtIndex:[data channelIndexForItemData:itemData] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:itemData]]]];
        }
    }
    else if([[aTableColumn identifier] isEqualToString:@"Channel Description"])
    {
        // This is a controlBoxCluster
        if([[data controlBoxFilePathForCommandCluster:[self commandCluster]] length] > 0)
        {
            return [data descriptionForChannel:[data channelAtIndex:[data channelIndexForCommand:[data commandAtIndex:(int)rowIndex fromCommandCluster:[self commandCluster]]] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self commandCluster]]]]];
        }
        // This is a channelGroupCluster
        else
        {
            NSMutableDictionary *itemData = [data itemDataAtIndex:[data channelIndexForCommand:[data commandAtIndex:(int)rowIndex fromCommandCluster:[self commandCluster]]] forChannelGroup:[data channelGroupFromFilePath:[data channelGroupFilePathForCommandCluster:[self commandCluster]]]];
            
            return [data colorForChannel:[data channelAtIndex:[data channelIndexForItemData:itemData] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:itemData]]]];
        }
    }
    else if([[aTableColumn identifier] isEqualToString:@"Control Box"])
    {
        return [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self commandCluster]]]];
    }
    
    return @"nil";
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if([commandsTableView selectedRow] > -1)
    {
        [deleteCommandButton setEnabled:YES];
        [chooseChannelForCommandButton setEnabled:YES];
        [moveCommandByTimeTextField setEnabled:YES];
        [moveCommandToTimeTextField setEnabled:YES];
    }
    else
    {
        [deleteCommandButton setEnabled:NO];
        [chooseChannelForCommandButton setEnabled:NO];
        [moveCommandByTimeTextField setEnabled:NO];
        [moveCommandToTimeTextField setEnabled:NO];
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
        [data setDescription:[descriptionTextField stringValue] forCommandCluster:[self commandCluster]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibrariesViewController" object:nil];
    }
    else if([aNotification object] == startTimeTextField)
    {
        [data setStartTime:[startTimeTextField floatValue] forCommandCluster:[self commandCluster]];
    }
    else if([aNotification object] == endTimeTextField)
    {
        [data setEndTime:[endTimeTextField floatValue] forCommandcluster:[self commandCluster]];
    }
    else if([aNotification object] == moveClusterByTimeTextField)
    {
        [data moveCommandCluster:[self commandCluster] byTime:[moveClusterByTimeTextField floatValue]];
        //[moveClusterByTimeTextField setStringValue:@""];
    }
    else if([aNotification object] == moveClusterToTimeTextField)
    {
        [data moveCommandCluster:[self commandCluster] toStartTime:[moveClusterToTimeTextField floatValue]];
        //[moveClusterToTimeTextField setStringValue:@""];
    }
    else if([aNotification object] == moveCommandByTimeTextField)
    {
        [data moveCommandAtIndex:(int)[commandsTableView selectedRow] byTime:[moveCommandByTimeTextField floatValue] whichIsPartOfCommandCluster:[self commandCluster]];
        //[moveCommandByTimeTextField setStringValue:@""];
    }
    else if([aNotification object] == moveCommandToTimeTextField)
    {
        [data moveCommandAtIndex:(int)[commandsTableView selectedRow] toStartTime:[moveCommandToTimeTextField floatValue] whichIsPartOfCommandCluster:[self commandCluster]];
        //[moveCommandToTimeTextField setStringValue:@""];
    }
    else if([[aNotification userInfo] objectForKey:@"NSFieldEditor"])
    {
        NSString *textFieldString = [[[aNotification userInfo] objectForKey:@"NSFieldEditor"] string];
        if([commandsTableView editedColumn] == 0)
        {
            [data setStartTime:[textFieldString floatValue] forCommandAtIndex:(int)[commandsTableView editedRow] whichIsPartOfCommandCluster:[self commandCluster]];
        }
        else if([commandsTableView editedColumn] == 1)
        {
            [data setEndTime:[textFieldString floatValue] forCommandAtIndex:(int)[commandsTableView editedRow] whichIsPartOfCommandCluster:[self commandCluster]];
        }
        
    }
    
    [self updateContent];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

@end
