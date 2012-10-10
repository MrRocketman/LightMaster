//
//  MNCommandClusterLibraryManagerViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNCommandClusterLibraryManagerViewController.h"
#import "MNData.h"

@interface MNCommandClusterLibraryManagerViewController ()

- (void)textDidBeginEditing:(NSNotification *)aNotification;
- (void)textDidEndEditing:(NSNotification *)aNotification;
- (NSMutableDictionary *)commandCluster;
//- (void)addItemDataToControlBox:(NSNotification *)aNotification

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
        
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addItemDataToControlBox:) name:@"AddItemDataToSelectedCommandCluster" object:nil];
        
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
        
        [addCommandButton setEnabled:YES];
        
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

/*- (void)addItemDataToControlBox:(NSNotification *)aNotification
{
    [controlBoxChannelSelectorPopover performClose:nil];
    NSDictionary *theDictionary = [aNotification object];
    int channelIndex = [[theDictionary objectForKey:@"ChannelIndex"] intValue];
    int controlBoxIndex = [[theDictionary objectForKey:@"ControlBoxIndex"] intValue];
    
    [data createItemDataAndReturnNewItemIndexForCommandCluster:[self commandCluster]];
    [data setChannelIndex:channelIndex forItemDataAtIndex:(int)([data itemsCountForCommandCluster:[self commandCluster]] - 1) whichIsPartOfCommandCluster:[self commandCluster]];
    [data setControlBoxFilePath:[data filePathForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:controlBoxIndex]]] forItemDataAtIndex:(int)([data itemsCountForCommandCluster:[self commandCluster]] - 1) whichIsPartOfCommandCluster:[self commandCluster]];
    
    [channelsTableView reloadData];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}*/

#pragma mark - Button Actions

- (IBAction)chooseControlBoxForCommandClusterButtonPress:(id)sender
{
    
}

- (IBAction)chooseChannelGroupForCommandClusterButtonPress:(id)sender
{
    
}

- (IBAction)chooseChannelForCommandButtonPress:(id)sender
{
    
}

- (IBAction)addCommandButtonPress:(id)sender
{
    
}

- (IBAction)deleteCommandButtonPress:(id)sender
{
    
}

/*- (IBAction)addChannelButtonPress:(id)sender
{
    [controlBoxChannelSelectorPopover showRelativeToRect:[channelsTableView rectOfRow:[channelsTableView selectedRow]] ofView:channelsTableView preferredEdge:NSMaxYEdge];
    if([channelsTableView selectedRow] > -1)
    {
        //[controlBoxChannelSelectorViewController setSelectedControlBoxFilePath:[data controlBoxFilePathAtIndex:(int)[controlBoxesTableView selectedRow] forSequence:sequence]];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)removeChannelButtonPress:(id)sender
{
    [data removeItemData:[data itemDataAtIndex:(int)[channelsTableView selectedRow] forCommandCluster:[self commandCluster]] forCommandCluster:[self commandCluster]];
    [channelsTableView deselectAll:nil];
    [channelsTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}*/

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
