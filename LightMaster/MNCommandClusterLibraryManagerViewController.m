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
        [adjustByTimeTextTextField setEnabled:YES];
        
        [chooseControlBoxForCommandClusterButton setEnabled:YES];
        [chooseChannelGroupForCommandClusterButton setEnabled:YES];
        
        //[addCommandButton setEnabled:YES];
        
        [descriptionTextField setStringValue:[data descriptionForCommandCluster:[self commandCluster]]];
        [startTimeTextField setFloatValue:[data startTimeForCommandCluster:[self commandCluster]]];
        [endTimeTextField setFloatValue:[data endTimeForCommandCluster:[self commandCluster]]];
        
        [commandClusterControlBoxLabel setStringValue:[data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self commandCluster]]]]];
        [commandClusterChannelGroupLabel setStringValue:[data descriptionForChannelGroup:[data channelGroupFromFilePath:[data channelGroupFilePathForCommandCluster:[self commandCluster]]]]];
    }
    else
    {
        [descriptionTextField setEnabled:NO];
        [startTimeTextField setEnabled:NO];
        [endTimeTextField setEnabled:NO];
        [adjustByTimeTextTextField setEnabled:NO];
        
        [chooseControlBoxForCommandClusterButton setEnabled:NO];
        [chooseChannelGroupForCommandClusterButton setEnabled:NO];
        
        [chooseChannelForCommandButton setEnabled:NO];
        [addCommandButton setEnabled:NO];
        [deleteCommandButton setEnabled:NO];
        
        [descriptionTextField setStringValue:@""];
        [startTimeTextField setFloatValue:0.0];
        [endTimeTextField setFloatValue:0.0];
        
        [commandClusterControlBoxLabel setStringValue:@""];
        [commandClusterChannelGroupLabel setStringValue:@""];
    }
    
    [commandsTableView reloadData];
}

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
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (void)selectChannelForCommand:(NSNotification *)aNotification
{
    [commandChannelSelectorPopover performClose:nil];
    [data setChannelIndex:[[aNotification object] intValue] forCommandAtIndex:(int)[commandsTableView selectedRow] whichIsPartOfCommandCluster:[self commandCluster]];
    
    // Update the labels
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:commandsTableView]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

#pragma mark - Button Actions

- (IBAction)chooseControlBoxForCommandClusterButtonPress:(id)sender
{
    [commandClusterControlBoxSelectorPopover showRelativeToRect:[commandClusterControlBoxLabel frame] ofView:self.view preferredEdge:NSMaxYEdge];
}

- (IBAction)chooseChannelGroupForCommandClusterButtonPress:(id)sender
{
    [commandClusterChannelGroupSelectorPopover showRelativeToRect:[commandClusterChannelGroupLabel frame] ofView:self.view preferredEdge:NSMaxYEdge];
}

- (IBAction)chooseChannelForCommandButtonPress:(id)sender
{
    [commandChannelSelectorPopover showRelativeToRect:[commandsTableView rectOfRow:[commandsTableView selectedRow]] ofView:commandsTableView preferredEdge:NSMaxYEdge];
}

- (IBAction)addCommandButtonPress:(id)sender
{
    [data createCommandAndReturnNewCommandIndexForCommandCluster:[self commandCluster]];
    [commandsTableView reloadData];
    [commandsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(int)([data commandsCountForCommandCluster:[self commandCluster]] - 1)] byExtendingSelection:NO];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:commandsTableView]];
    [self chooseChannelForCommandButtonPress:nil];
}

- (IBAction)deleteCommandButtonPress:(id)sender
{
    [data removeCommand:[data commandAtIndex:(int)[commandsTableView selectedRow] fromCommandCluster:[self commandCluster]] fromCommandCluster:[self commandCluster]];
    [commandsTableView deselectAll:nil];
    [commandsTableView reloadData];
    
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
        return [NSNumber numberWithFloat:[data startTimeForCommand:[data commandAtIndex:(int)rowIndex fromCommandCluster:[self commandCluster]]]];
    }
    else if([[aTableColumn identifier] isEqualToString:@"End Time"])
    {
        return [NSNumber numberWithFloat:[data endTimeForCommand:[data commandAtIndex:(int)rowIndex fromCommandCluster:[self commandCluster]]]];
    }
    
    return @"nil";
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if([commandsTableView selectedRow] > -1)
    {
        [deleteCommandButton setEnabled:YES];
        [chooseControlBoxForCommandClusterButton setEnabled:YES];
        
        NSString *controlBoxLabelString = [NSString stringWithFormat:@"%d %@ %@", [data channelIndexForCommand:[data commandAtIndex:(int)[commandsTableView selectedRow] fromCommandCluster:[self commandCluster]]], [data colorForChannel:[data channelAtIndex:(int)[commandsTableView selectedRow] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self commandCluster]]]]], [data descriptionForChannel:[data channelAtIndex:(int)[commandsTableView selectedRow] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self commandCluster]]]]]];
        [commandChannelLabel setStringValue:controlBoxLabelString];
        [commandControlBoxLabel setStringValue:[data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self commandCluster]]]]];
    }
    else
    {
        [deleteCommandButton setEnabled:NO];
        [chooseControlBoxForCommandClusterButton setEnabled:NO];
        
        [commandChannelLabel setStringValue:@""];
        [commandControlBoxLabel setStringValue:@""];
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
        [commandsTableView reloadData];
    }
    else if([aNotification object] == endTimeTextField)
    {
        [data setStartTime:[endTimeTextField floatValue] forCommandCluster:[self commandCluster]];
        [commandsTableView reloadData];
    }
    else if([aNotification object] == adjustByTimeTextTextField)
    {
        [data moveCluster:[self commandCluster] byTime:[adjustByTimeTextTextField floatValue]];
        [adjustByTimeTextTextField setFloatValue:0.0];
        [commandsTableView reloadData];
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
        
        [commandsTableView reloadData];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

@end
