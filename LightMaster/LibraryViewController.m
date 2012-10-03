//
//  LibraryViewController.m
//  LightMaster
//
//  Created by James Adams on 12/4/11.
//  Copyright (c) 2011 Pencil Busters, Inc. All rights reserved.
//

#import "LibraryViewController.h"
#import "ControlBoxSelectorViewController.h"
#import "GroupSelectorViewController.h"
#import "ChannelAndControlBoxSelectorViewController.h"
#import "ChannelSelectorViewController.h"
#import "SequenceSoundSelectorViewController.h"
#import "SequenceControlBoxSelectorViewController.h"
#import "SequenceGroupSelectorViewController.h"
#import "SequenceCommandClusterSelectorViewController.h"

@interface LibraryViewController()

- (void)toggleButtonsOffBesides:(NSButton *)button;
- (void)viewWillLoad;
- (void)viewDidLoad;
- (void)textDidBeginEditing:(NSNotification *)aNotification;
- (void)textDidChange:(NSNotification *)aNotification;
- (void)textDidEndEditing:(NSNotification *)aNotification;
- (void)tableViewDoubleClicked:(id)sender;
- (void)selectChannelAndControlBoxForGroup:(NSNotification *)aNotification;
- (void)selectChannelIndexForCurrentCommand:(NSNotification *)aNotification;
- (NSMutableDictionary *)selectedControlBox;
- (NSMutableDictionary *)selectedChannel;
- (NSMutableDictionary *)editingChannel;
- (NSMutableDictionary *)selectedCommandCluster;
- (NSMutableDictionary *)selectedCommand;
- (NSMutableDictionary *)editingCommand;
- (NSMutableDictionary *)selectedEffect;
- (NSMutableDictionary *)selectedSound;
- (void)loadOpenPanel;
- (NSMutableDictionary *)selectedGroup;
- (NSMutableDictionary *)selectedItemData;
- (void)selectControlBoxFilePath:(NSNotification *)aNotification;
- (void)selectGroupFilePath:(NSNotification *)aNotification;
- (void)addSoundFilePathToSequence:(NSNotification *)aNotification;
- (void)addControlBoxFilePathToSequence:(NSNotification *)aNotification;
- (void)addGroupFilePathToSequence:(NSNotification *)aNotification;
- (void)addCommandClusterFilePathToSequence:(NSNotification *)aNotification;
- (NSMutableDictionary *)selectedSequence;
- (NSString *)selectedSoundFilePath;
- (NSString *)selectedControlBoxFilePath;
- (NSString *)selectedGroupFilePath;
- (NSString *)selectedCommandClusterFilePath;
- (void)reloadGraphicalDisplays;
- (void)selectCommandCluster:(NSNotification *)aNotification;
- (void)selectCommand:(NSNotification *)aNotification;
- (void)selectSound:(NSNotification *)aNotification;

@end

@implementation LibraryViewController

@synthesize data;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Init Code Here
        
    }
    
    return self;
}

- (void)prepareForDisplay
{
    NSLog(@"Load View");
    [self viewWillLoad];
    [super loadView];
    [self viewDidLoad];
}

- (void)viewWillLoad 
{
    
}

- (void)viewDidLoad 
{
    NSLog(@"View Did Load");
    
    // External Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectCommandCluster:) name:@"SelectCommandCluster" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectCommand:) name:@"SelectCommand" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectSound:) name:@"SelectSound" object:nil];
    
    // Menu Items
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newSequence:) name:@"NewSequence" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newControlBox:) name:@"NewControlBox" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newGroup:) name:@"NewGroup" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newSound:) name:@"NewSound" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newEffect:) name:@"NewEffect" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newCommandCluster:) name:@"NewCommandCluster" object:nil];
    [[controlBoxDetailScrollView documentView] setFrame:NSMakeRect(0.0, 0.0, 460, 460)];
    
    // Command Cluster Library
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidBeginEditing:) name:@"NSControlTextDidBeginEditingNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:@"NSControlTextDidEndEditingNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectChannelIndexForCurrentCommand:) name:@"SelectChannelIndexForCommand" object:nil];
    [[commandClusterDetailScrollView documentView] setFrame:NSMakeRect(0.0, 0.0, 400, 800)];
    
    // Control Box Libraary
    [controlBoxSelectorViewController setData:self.data];
    [groupSelectorViewController setData:self.data];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectControlBoxFilePath:) name:@"SelectControlBoxFilePath" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectGroupFilePath:) name:@"SelectGroupFilePath" object:nil];
    
    // Effect Library
    [[effectDetailScrollView documentView] setFrame:NSMakeRect(0.0, 0.0, 400, 550)];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:@"NSControlTextDidChangeNotification" object:effectScriptTextView];
    
    // Sound Library
    [[soundDetailsScrollView documentView] setFrame:NSMakeRect(0.0, 0.0, 460, 420)];
    //[self performSelectorInBackground:@selector(loadOpenPanel) withObject:nil];
    
    // Group Library
    [channelAndControlBoxSelectorViewController setData:self.data];
    [channelSelectorViewController setData:self.data];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectChannelAndControlBoxForGroup:) name:@"SelectChannelIndexAndControlBoxForCurrentGroup" object:nil];
    [[groupDetailScrollView documentView] setFrame:NSMakeRect(0.0, 0.0, 1000, 420)];
    [groupItemsTableView setIgnoresMultiClick:NO];
    [groupItemsTableView setTarget:self];
    [groupItemsTableView setDoubleAction:@selector(tableViewDoubleClicked:)];
    
    // Sequence Library
    [[sequenceDetailScrollView documentView] setFrame:NSMakeRect(0.0, 0.0, 400, 1500)];
    [sequenceSoundSelectorViewController setData:self.data];
    [sequenceControlBoxSelectorViewController setData:self.data];
    [sequenceGroupSelectorViewController setData:self.data];
    [sequenceCommandClusterSelectorViewController setData:self.data];
    [sequenceCommandClusterSelectorViewController setData:self.data];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addSoundFilePathToSequence:) name:@"AddSoundFilePathToSequence" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addControlBoxFilePathToSequence:) name:@"AddControlBoxFilePathToSequence" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addGroupFilePathToSequence:) name:@"AddGroupFilePathToSequence" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(addCommandClusterFilePathToSequence:) name:@"AddCommandClusterFilePathToSequence" object:nil];
    [sequenceSoundsTableView setIgnoresMultiClick:NO];
    [sequenceSoundsTableView setTarget:self];
    [sequenceSoundsTableView setDoubleAction:@selector(tableViewDoubleClicked:)];
    [sequenceControlBoxesTableView setIgnoresMultiClick:NO];
    [sequenceControlBoxesTableView setTarget:self];
    [sequenceControlBoxesTableView setDoubleAction:@selector(tableViewDoubleClicked:)];
    [sequenceGroupsTableView setIgnoresMultiClick:NO];
    [sequenceGroupsTableView setTarget:self];
    [sequenceGroupsTableView setDoubleAction:@selector(tableViewDoubleClicked:)];
    [sequenceCommandClusterTableView setIgnoresMultiClick:NO];
    [sequenceCommandClusterTableView setTarget:self];
    [sequenceCommandClusterTableView setDoubleAction:@selector(tableViewDoubleClicked:)];
    
    // Select the sequences tab in the library
    selectedLibrary = -1;
    [self toggleButtonPress:sequencesButton];
}

#pragma mark - Private Methods

- (void)toggleButtonsOffBesides:(NSButton *)button
{
    selectedLibrary = (int)[button tag];
    
    if(button != controlBoxesButton)
    {
        [controlBoxesButton setState:NSOffState];
    }
    if(button != commandClustersButton)
    {
        [commandClustersButton setState:NSOffState];
    }
    if(button != effectsButton)
    {
        [effectsButton setState:NSOffState];
    }
    if(button != soundsButton)
    {
        [soundsButton setState:NSOffState];
    }
    if(button != groupsButton)
    {
        [groupsButton setState:NSOffState];
    }
    if(button != sequencesButton)
    {
        [sequencesButton setState:NSOffState];
    }
    
    [tableView deselectAll:nil];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
}

- (IBAction)toggleButtonPress:(id)sender
{
    if([sender state] == NSOffState)
    {
        [sender setState:NSOnState];
    }
    
    // Remove the old view
    switch (selectedLibrary)
    {
        case kControlBoxLibrary:
            previouslySelectedRowsInMainTableView[kControlBoxLibrary] = (int)[tableView selectedRow];
            [controlBoxDetailScrollView removeFromSuperview];
            break;
        case kCommandClusterLibrary:
            previouslySelectedRowsInMainTableView[kCommandClusterLibrary] = (int)[tableView selectedRow];
            [commandClusterDetailScrollView removeFromSuperview];
            break; 
        case kEffectLibrary:
            previouslySelectedRowsInMainTableView[kEffectLibrary] = (int)[tableView selectedRow];
            [effectDetailScrollView removeFromSuperview];
            break;
        case kSoundLibrary:
            previouslySelectedRowsInMainTableView[kSoundLibrary] = (int)[tableView selectedRow];
            [soundDetailsScrollView removeFromSuperview];
            break;
        case kGroupLibrary:
            previouslySelectedRowsInMainTableView[kGroupLibrary] = (int)[tableView selectedRow];
            [groupDetailScrollView removeFromSuperview];
            break;
        case kSequenceLibrary:
            previouslySelectedRowsInMainTableView[kSequenceLibrary] = (int)[tableView selectedRow];
            [sequenceDetailScrollView removeFromSuperview];
            break;
        default:
            break;
    }
    
    // Toggle the buttons and set the new selcted library
    [self toggleButtonsOffBesides:sender];
    [tableView reloadData];
    
    // Add the new library
    NSRect newFrame = NSMakeRect(0, 0, detailViewWell.frame.size.width, detailViewWell.frame.size.height);
    switch (selectedLibrary)
    {
        case kControlBoxLibrary:
            [controlBoxDetailScrollView setFrame:newFrame];
            [detailViewWell addSubview:controlBoxDetailScrollView];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInMainTableView[kControlBoxLibrary]] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
            break;
        case kCommandClusterLibrary:
            [commandClusterDetailScrollView setFrame:newFrame];
            [detailViewWell addSubview:commandClusterDetailScrollView];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInMainTableView[kCommandClusterLibrary]] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
            break;
        case kEffectLibrary:
            [effectDetailScrollView setFrame:newFrame];
            [detailViewWell addSubview:effectDetailScrollView];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInMainTableView[kEffectLibrary]] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
            break;
        case kSoundLibrary:
            [soundDetailsScrollView setFrame:newFrame];
            [detailViewWell addSubview:soundDetailsScrollView];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInMainTableView[kSoundLibrary]] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
            break;
        case kGroupLibrary:
            [groupDetailScrollView setFrame:newFrame];
            [detailViewWell addSubview:groupDetailScrollView];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInMainTableView[kGroupLibrary]] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
            break;
        case kSequenceLibrary:
            [sequenceDetailScrollView setFrame:newFrame];
            [detailViewWell addSubview:sequenceDetailScrollView];
            [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:previouslySelectedRowsInMainTableView[kSequenceLibrary]] byExtendingSelection:NO];
            [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];
            break;
        default:
            break;
    }
}

- (void)textDidBeginEditing:(NSNotification *)aNotification
{
    
}

- (void)textDidChange:(NSNotification *)aNotification
{
    if([aNotification object] == effectScriptTextView)
    {
        [data setScript:[effectScriptTextView string] forEffect:[self selectedEffect]];
    }
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
    switch (selectedLibrary)
    {
        case kControlBoxLibrary:
            if([aNotification object] == controlBoxIDTextField)
            {
                [data setControlBoxID:[controlBoxIDTextField stringValue] forControlBox:[self selectedControlBox]];
            }
            else if([aNotification object] == controlBoxDescriptionTextField)
            {
                [data setDescription:[controlBoxDescriptionTextField stringValue] forControlBox:[self selectedControlBox]];
                int selectedRow = (int)[tableView selectedRow];
                [tableView reloadData];
                [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
            }
            else
            {
                //NSLog(@"selectedColumn:%d", (int)[controlBoxChannelsTableView editedColumn]);
                NSString *textFieldString = [[[aNotification userInfo] objectForKey:@"NSFieldEditor"] string];
                if([controlBoxChannelsTableView editedColumn] == 0)
                {
                    //NSLog(@"number:%d", (int)[textFieldString intValue]);
                    [data setNumber:[textFieldString intValue] - 1 forChannelAtIndex:(int)[controlBoxChannelsTableView editedRow] whichIsPartOfControlBox:[self selectedControlBox]];
                }
                else if([controlBoxChannelsTableView editedColumn] == 1)
                {
                    //NSLog(@"color:%@", textFieldString);
                    [data setColor:textFieldString forChannelAtIndex:(int)[controlBoxChannelsTableView editedRow] whichIsPartOfControlBox:[self selectedControlBox]];
                }
                else if([controlBoxChannelsTableView editedColumn] == 2)
                {
                    //NSLog(@"description:%@", textFieldString);
                    [data setDescription:textFieldString forChannelAtIndex:(int)[controlBoxChannelsTableView editedRow] whichIsPartOfControlBox:[self selectedControlBox]];
                }
                
                [controlBoxChannelsTableView reloadData];
            }
            break;
        case kCommandClusterLibrary:
            if([aNotification object] == commandClusterDescriptionTextField)
            {
                [data setDescription:[commandClusterDescriptionTextField stringValue] forCommandCluster:[self selectedCommandCluster]];
                int selectedRow = (int)[tableView selectedRow];
                [tableView reloadData];
                [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
            }
            else if([aNotification object] == startTimeTextField)
            {
                [data setStartTime:[startTimeTextField floatValue] forCommandCluster:[self selectedCommandCluster]];
                [commandsTableView reloadData];
            }
            else if([aNotification object] == endTimeTextField)
            {
                [data setEndTime:[endTimeTextField floatValue] forCommandcluster:[self selectedCommandCluster]];
                [commandsTableView reloadData];
            }
            else if([aNotification object] == adjustCommandClusterByTextField)
            {
                [data moveCluster:[self selectedCommandCluster] byTime:[adjustCommandClusterByTextField floatValue]];
                [adjustCommandClusterByTextField setFloatValue:0.0];
                [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChangeNotification" object:tableView]];
                [commandsTableView reloadData];
            }
            else
            {
                //NSLog(@"selectedColumn:%d", (int)[commandsTableView editedColumn]);
                NSString *textFieldString = [[[aNotification userInfo] objectForKey:@"NSFieldEditor"] string];
                if([commandsTableView editedColumn] == 0)
                {
                    //NSLog(@"startTime:%@", textFieldString);
                    // Relative Start Time -- Messed up
                    //[data setStartTime:[textFieldString floatValue] - [data startTimeForCommandCluster:[self selectedCommandCluster]] forCommandAtIndex:(int)[commandsTableView editedRow] whichIsPartOfCommandCluster:[self selectedCommandCluster]];
                    [data setStartTime:[textFieldString floatValue] forCommandAtIndex:(int)[commandsTableView editedRow] whichIsPartOfCommandCluster:[self selectedCommandCluster]];
                }
                else if([commandsTableView editedColumn] == 1)
                {
                    //NSLog(@"endTime:%@", textFieldString);
                    // Relative End Time -- Messed up
                    //[data setEndTime:[textFieldString floatValue] - [data startTimeForCommandCluster:[self selectedCommandCluster]] forCommandAtIndex:(int)[commandsTableView editedRow] whichIsPartOfCommandCluster:[self selectedCommandCluster]];
                    [data setEndTime:[textFieldString floatValue] forCommandAtIndex:(int)[commandsTableView editedRow] whichIsPartOfCommandCluster:[self selectedCommandCluster]];
                }
                
                [commandsTableView reloadData];
            }
            break;
        case kEffectLibrary:
            if([aNotification object] == effectDescriptionTextField)
            {
                [data setDescription:[effectDescriptionTextField stringValue] forEffect:[self selectedEffect]];
                int selectedRow = (int)[tableView selectedRow];
                [tableView reloadData];
                [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
            }
            break;
        case kSoundLibrary:
            if([aNotification object] == soundDescriptionTextField)
            {
                [data setDescription:[soundDescriptionTextField stringValue] forSound:[self selectedSound]];
                int selectedRow = (int)[tableView selectedRow];
                [tableView reloadData];
                [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
            }
            else if([aNotification object] == soundStartTimeTextField)
            {
                //NSLog(@"sound startTime:%f", [soundStartTimeTextField floatValue]);
                [data setStartTime:[soundStartTimeTextField floatValue] forSound:[self selectedSound]];
            }
            else if([aNotification object] == soundEndTimeTextField)
            {
                //NSLog(@"sound endTime:%f", [soundEndTimeTextField floatValue]);
                [data setEndTime:[soundEndTimeTextField floatValue] forSound:[self selectedSound]];
            }
            break;
        case kGroupLibrary:
            if([aNotification object] == groupDescriptionTextField)
            {
                [data setDescription:[groupDescriptionTextField stringValue] forGroup:[self selectedGroup]];
                int selectedRow = (int)[tableView selectedRow];
                [tableView reloadData];
                [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
            }
            break;
        case kSequenceLibrary:
            if([aNotification object] == sequenceDescriptionTextField)
            {
                [data setDescription:[sequenceDescriptionTextField stringValue] forSequence:[self selectedSequence]];
                int selectedRow = (int)[tableView selectedRow];
                [tableView reloadData];
                [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
            }
            else if([aNotification object] == sequenceStartTimeTextField)
            {
                [data setStartTime:[sequenceStartTimeTextField floatValue] forSequence:[self selectedSequence]];
            }
            else if([aNotification object] == sequenceEndTimeTextField)
            {
                [data setEndTime:[sequenceEndTimeTextField floatValue] forSequence:[self selectedSequence]];
            }
            break;
        default:
            break;
    }
    
    [self reloadGraphicalDisplays];
}

- (void)tableViewDoubleClicked:(id)sender
{
    switch(selectedLibrary)
    {
        case kGroupLibrary:
            if([groupItemsTableView clickedColumn] == 0 || [groupItemsTableView clickedColumn] == 1)
            {
                if([groupItemsTableView selectedRow] > -1)
                {
                    [channelAndControlBoxSelectorViewController setItemData:[self selectedItemData]];
                    [channelAndControlBoxPopover showRelativeToRect:[groupItemsTableView rectOfRow:[groupItemsTableView selectedRow]] ofView:groupItemsTableView preferredEdge:NSMaxYEdge];
                    [channelAndControlBoxSelectorViewController reload];
                }
                else
                {
                    [channelAndControlBoxPopover performClose:nil];
                }
            }
            break;
        case kSequenceLibrary:
            if(sender == sequenceSoundsTableView)
            {
                if([sequenceSoundsTableView selectedRow] > -1)
                {
                    /*NSString *selectedSoundFilePath = [self selectedSoundFilePath];
                    int selectedSoundIndex = (int)[[data soundFilePaths] indexOfObject:selectedSoundFilePath];
                    [self toggleButtonPress:soundsButton];
                    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedSoundIndex] byExtendingSelection:NO];
                    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];*/
                    [sequenceSoundPopover showRelativeToRect:[sequenceSoundsTableView rectOfRow:[sequenceSoundsTableView selectedRow]] ofView:sequenceSoundsTableView preferredEdge:NSMaxYEdge];
                    [sequenceSoundSelectorViewController setSelectedSoundFilePath:[data soundFilePathAtIndex:(int)[sequenceSoundsTableView selectedRow] forSequence:[self selectedSequence]]];
                }
            }
            else if(sender == sequenceControlBoxesTableView)
            {
                if([sequenceControlBoxesTableView selectedRow] > -1)
                {
                    /*NSString *selectedControlBoxFilePath = [self selectedControlBoxFilePath];
                    int selectedControlBoxIndex = (int)[[data controlBoxFilePaths] indexOfObject:selectedControlBoxFilePath];
                    [self toggleButtonPress:controlBoxesButton];
                    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedControlBoxIndex] byExtendingSelection:NO];
                    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];*/
                    [sequenceControlBoxPopover showRelativeToRect:[sequenceControlBoxesTableView rectOfRow:[sequenceControlBoxesTableView selectedRow]] ofView:sequenceControlBoxesTableView preferredEdge:NSMaxYEdge];
                     [sequenceControlBoxSelectorViewController setSelectedControlBoxFilePath:[data controlBoxFilePathAtIndex:(int)[sequenceControlBoxesTableView selectedRow] forSequence:[self selectedSequence]]];
                }
            }
            else if(sender == sequenceGroupsTableView)
            {
                if([sequenceGroupsTableView selectedRow] > -1)
                {
                    /*NSString *selectedGroupFilePath = [self selectedGroupFilePath];
                    int selectedGroupIndex = (int)[[data groupFilePaths] indexOfObject:selectedGroupFilePath];
                    [self toggleButtonPress:groupsButton];
                    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedGroupIndex] byExtendingSelection:NO];
                    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];*/
                    [sequenceGroupPopover showRelativeToRect:[sequenceGroupsTableView rectOfRow:[sequenceGroupsTableView selectedRow]] ofView:sequenceGroupsTableView preferredEdge:NSMaxYEdge];
                    [sequenceGroupSelectorViewController setSelectedGroupFilePath:[data groupFilePathAtIndex:(int)[sequenceGroupsTableView selectedRow] forSequence:[self selectedSequence]]];
                }
            }
            else if(sender == sequenceCommandClusterTableView)
            {
                if([sequenceCommandClusterTableView selectedRow] > -1)
                {
                    /*NSString *selectedCommandClusterFilePath = [self selectedCommandClusterFilePath];
                    int selectedCommandClusterIndex = (int)[[data commandClusterFilePaths] indexOfObject:selectedCommandClusterFilePath];
                    [self toggleButtonPress:commandClustersButton];
                    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:selectedCommandClusterIndex] byExtendingSelection:NO];
                    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:tableView]];*/
                    [sequenceCommandClusterPopover showRelativeToRect:[sequenceCommandClusterTableView rectOfRow:[sequenceCommandClusterTableView selectedRow]] ofView:sequenceCommandClusterTableView preferredEdge:NSMaxYEdge];
                    [sequenceCommandClusterSelectorViewController setSelectedCommandClusterFilePath:[data commandClusterFilePathAtIndex:(int)[sequenceCommandClusterTableView selectedRow] forSequence:[self selectedSequence]]];
                }
            }
            break;
        default:
            break;
    }
}

- (void)selectChannelAndControlBoxForGroup:(NSNotification *)aNotification
{
    [channelAndControlBoxPopover performClose:nil];
    NSDictionary *userInfo = [aNotification userInfo];
    int channelIndex = [[userInfo objectForKey:@"channelIndex"] intValue];
    NSMutableDictionary *controlBox = [userInfo objectForKey:@"controlBox"];
    
    [data createItemDataAndReturnNewItemIndexForGroup:[self selectedGroup]];
    [data setChannelIndex:channelIndex forItemDataAtIndex:(int)([data itemsCountForGroup:[self selectedGroup]] - 1) whichIsPartOfGroup:[self selectedGroup]];
    [data setControlBoxFilePath:[data filePathForControlBox:controlBox] forItemDataAtIndex:(int)([data itemsCountForGroup:[self selectedGroup]] - 1) whichIsPartOfGroup:[self selectedGroup]];
    
    [groupItemsTableView reloadData];
    [self reloadGraphicalDisplays];
}

- (void)selectChannelIndexForCurrentCommand:(NSNotification *)aNotification
{
    [channelPopover performClose:nil];
    NSNumber *channelIndex = [aNotification object];
    
    // Command Cluster is a Control Box Cluster
    if([data controlBoxFilePathForCommandCluster:[self selectedCommandCluster]] != nil)
    {
        [data setChannelIndex:[channelIndex intValue] forCommandAtIndex:(int)[commandsTableView selectedRow] whichIsPartOfCommandCluster:[self selectedCommandCluster]];
    }
    // Command Cluster is a Group Cluster
    else if([data groupFilePathForCommandCluster:[self selectedCommandCluster]] != nil)
    {
        [data setChannelIndex:[channelIndex intValue] forCommandAtIndex:(int)[commandsTableView selectedRow] whichIsPartOfCommandCluster:[self selectedCommandCluster]];
    }
    
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:commandsTableView]];
    [self reloadGraphicalDisplays];
}

- (NSMutableDictionary *)selectedControlBox
{
    return [data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:(int)[tableView selectedRow]]];
}

- (NSMutableDictionary *)selectedChannel
{
    return [data channelAtIndex:(int)[controlBoxChannelsTableView selectedRow] forControlBox:[self selectedControlBox]];
}

- (NSMutableDictionary *)editingChannel
{
    return [data channelAtIndex:(int)[controlBoxChannelsTableView editedRow] forControlBox:[self selectedControlBox]];
}

- (NSMutableDictionary *)selectedCommandCluster
{
    //NSString *commandClusterFilePath = [data commandClusterFilePathAtIndex:(int)[tableView selectedRow]];
    //NSLog(@"selectedClusterFilePath:%@", commandClusterFilePath);
    //NSMutableDictionary *commandCluster = [data commandClusterFromFilePath:commandClusterFilePath];
    //NSLog(@"selectedClusterDict:%@", commandCluster);
    return [data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:(int)[tableView selectedRow]]];
}

- (NSMutableDictionary *)selectedCommand
{
    return [data commandAtIndex:(int)[commandsTableView selectedRow] fromCommandCluster:[self selectedCommandCluster]];
}

- (NSMutableDictionary *)editingCommand
{
    return [data commandAtIndex:(int)[commandsTableView editedRow] fromCommandCluster:[self selectedCommandCluster]];
}

- (NSMutableDictionary *)selectedEffect
{
    return [data effectFromFilePath:[data effectFilePathAtIndex:(int)[tableView selectedRow]]];
}

- (NSMutableDictionary *)selectedSound
{
    return [data soundFromFilePath:[data soundFilePathAtIndex:(int)[tableView selectedRow]]];
}

- (void)loadOpenPanel
{
    openPanel = [NSOpenPanel openPanel];
}

- (NSMutableDictionary *)selectedGroup
{
    return [data groupFromFilePath:[data groupFilePathAtIndex:(int)[tableView selectedRow]]];
}

- (NSMutableDictionary *)selectedItemData
{
    return [data itemDataAtIndex:(int)[groupItemsTableView selectedRow] forGroup:[self selectedGroup]];
}

- (void)selectControlBoxFilePath:(NSNotification *)aNotification
{
    [controlBoxPopover performClose:nil];
    [commandsTableView deselectAll:nil];
    [data setControlBoxFilePath:[aNotification object] forCommandCluster:[self selectedCommandCluster]];
    if([[aNotification object] length] > 0)
    {
        [controlBoxDescriptionForCommandCluster setStringValue:[data descriptionForControlBox:[data controlBoxFromFilePath:[aNotification object]]]];
        [self selectGroupFilePath:[NSNotification notificationWithName:@"SelectGroupFilePath" object:@""]];
        
        [addCommandButton setEnabled:YES];
    }
    else
    {
        [controlBoxDescriptionForCommandCluster setStringValue:@""];
    }
}

- (void)selectGroupFilePath:(NSNotification *)aNotification
{
    [groupPopover performClose:nil];
    [commandsTableView deselectAll:nil];
    [data setGroupFilePath:[aNotification object] forCommandCluster:[self selectedCommandCluster]];
    if([[aNotification object] length] > 0)
    {
        [groupDescriptionForCommandCluster setStringValue:[data descriptionForGroup:[data groupFromFilePath:[aNotification object]]]];
        [self selectControlBoxFilePath:[NSNotification notificationWithName:@"SelectControlBoxFilePath" object:@""]];
        
        [addCommandButton setEnabled:YES];
    }
    else
    {
        [groupDescriptionForCommandCluster setStringValue:@""];
    }
}

- (void)addSoundFilePathToSequence:(NSNotification *)aNotification
{
    [sequenceSoundPopover performClose:nil];
    [data addSoundFilePath:[aNotification object] forSequence:[self selectedSequence]];
    [sequenceSoundsTableView reloadData];
    [self reloadGraphicalDisplays];
}

- (void)addControlBoxFilePathToSequence:(NSNotification *)aNotification
{
    [sequenceControlBoxPopover performClose:nil];
    [data addControlBoxFilePath:[aNotification object] forSequence:[self selectedSequence]];
    [sequenceControlBoxesTableView reloadData];
    [self reloadGraphicalDisplays];
}

- (void)addGroupFilePathToSequence:(NSNotification *)aNotification
{
    [sequenceGroupPopover performClose:nil];
    [data addGroupFilePath:[aNotification object] forSequence:[self selectedSequence]];
    [sequenceGroupsTableView reloadData];
    [self reloadGraphicalDisplays];
}

- (void)addCommandClusterFilePathToSequence:(NSNotification *)aNotification
{
    [sequenceCommandClusterPopover performClose:nil];
    [data addCommandClusterFilePath:[aNotification object] forSequence:[self selectedSequence]];
    [sequenceCommandClusterTableView reloadData];
    [self reloadGraphicalDisplays];
}

- (NSMutableDictionary *)selectedSequence
{
    return [data sequenceFromFilePath:[data sequenceFilePathAtIndex:(int)[tableView selectedRow]]];
}

- (NSString *)selectedSoundFilePath
{
    return [data soundFilePathAtIndex:(int)[sequenceSoundsTableView selectedRow] forSequence:[self selectedSequence]];
}

- (NSString *)selectedControlBoxFilePath
{
    return [data controlBoxFilePathAtIndex:(int)[sequenceControlBoxesTableView selectedRow] forSequence:[self selectedSequence]];
}

- (NSString *)selectedGroupFilePath
{
    return [data groupFilePathAtIndex:(int)[sequenceGroupsTableView selectedRow] forSequence:[self selectedSequence]];
}

- (NSString *)selectedCommandClusterFilePath
{
    return [data commandClusterFilePathAtIndex:(int)[sequenceCommandClusterTableView selectedRow] forSequence:[self selectedSequence]];
}

- (void)reloadGraphicalDisplays
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"LoadSequence" object:nil];
}

- (void)selectCommandCluster:(NSNotification *)aNotification
{
    NSMutableDictionary *selectedCommandCluster = [aNotification object];
    [self toggleButtonPress:commandClustersButton];
    int commandClusterIndex = (int)[[data commandClusterFilePaths] indexOfObject:[data filePathForCommandCluster:selectedCommandCluster]];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:commandClusterIndex] byExtendingSelection:NO];
    [tableView reloadData];
}

- (void)selectCommand:(NSNotification *)aNotification
{
    NSMutableDictionary *selectedCommand = [aNotification object];
    [commandsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data channelIndexForCommand:selectedCommand]] byExtendingSelection:NO];
    [commandsTableView reloadData];
}

- (void)selectSound:(NSNotification *)aNotification
{
    NSMutableDictionary *selectedSound = [aNotification object];
    [self toggleButtonPress:soundsButton];
    int soundIndex = (int)[[data soundFilePaths] indexOfObject:[data filePathForSound:selectedSound]];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:soundIndex] byExtendingSelection:NO];
    [tableView reloadData];
}

#pragma mark - Menu Items

- (void)newSequence:(NSNotification *)notificaiton
{
    [data createSequenceAndReturnFilePath];
    [self toggleButtonPress:sequencesButton];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data sequenceFilePathsCount] - 1] byExtendingSelection:NO];
    [tableView reloadData];
}

- (void)newControlBox:(NSNotification *)notification
{
    [data createControlBoxAndReturnFilePath];
    [self toggleButtonPress:controlBoxesButton];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data controlBoxFilePathsCount] - 1] byExtendingSelection:NO];
    [tableView reloadData];
}

- (void)newGroup:(NSNotification *)notification
{
    [data createGroupAndReturnFilePath];
    [self toggleButtonPress:groupsButton];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data groupFilePathsCount] - 1] byExtendingSelection:NO];
    [tableView reloadData];
}

- (void)newSound:(NSNotification *)notification
{
    [data createSoundAndReturnFilePath];
    [self toggleButtonPress:soundsButton];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data soundFilePathsCount] - 1] byExtendingSelection:NO];
    [tableView reloadData];
}

- (void)newEffect:(NSNotification *)notification
{
    [data createEffectAndReturnFilePath];
    [self toggleButtonPress:effectsButton];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data effectFilePathsCount] - 1] byExtendingSelection:NO];
    [tableView reloadData];
}

- (void)newCommandCluster:(NSNotification *)notification
{
    [data createCommandClusterAndReturnFilePath];
    [self toggleButtonPress:commandClustersButton];
    [tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:[data commandClusterFilePathsCount] - 1] byExtendingSelection:NO];
    [tableView reloadData];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if(aTableView == tableView)
    {
        switch (selectedLibrary)
        {
            case kControlBoxLibrary:
                return [data controlBoxFilePathsCount];
                break;
            case kCommandClusterLibrary:
                return [data commandClusterFilePathsCount];
                break;
            case kEffectLibrary:
                return [data effectFilePathsCount];
                break;
            case kSoundLibrary:
                return [data soundFilePathsCount];
                break;
            case kGroupLibrary:
                return [data groupFilePathsCount];
                break;
            case kSequenceLibrary:
                return [data sequenceFilePathsCount];
                break;
            default:
                break;
        }
    }
    
    if([tableView selectedRow] > -1)
    {
        if(aTableView == controlBoxChannelsTableView)
        {
            //NSLog(@"channels count:%d", [data channelsCountForControlBox:[self selectedControlBox]]);
            return [data channelsCountForControlBox:[self selectedControlBox]];
        }
        else if(aTableView == commandsTableView)
        {
            //NSLog(@"commands count:%d", [data commandsCountForCommandCluster:[self selectedCommandCluster]]);
            return [data commandsCountForCommandCluster:[self selectedCommandCluster]];
        }
        else if(aTableView == groupItemsTableView)
        {
            //NSLog(@"items count:%d", [data itemsCountForGroup:[self selectedGroup]]);
            return [data itemsCountForGroup:[self selectedGroup]];
        }
        else if(aTableView == sequenceSoundsTableView)
        {
            return [data soundFilePathsCountForSequence:[self selectedSequence]];
        }
        else if(aTableView == sequenceControlBoxesTableView)
        {
            return [data controlBoxFilePathsCountForSequence:[self selectedSequence]];
        }
        else if(aTableView == sequenceGroupsTableView)
        {
            return [data groupFilePathsCountForSequence:[self selectedSequence]];
        }
        else if(aTableView == sequenceCommandClusterTableView)
        {
            return [data commandClusterFilePathsCountForSequence:[self selectedSequence]];
        }
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if(aTableView == tableView)
    {
        switch (selectedLibrary)
        {
            case kControlBoxLibrary:
                return [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:(int)rowIndex]]];
                break;
            case kCommandClusterLibrary:
                return [data descriptionForCommandCluster:[data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:(int)rowIndex]]];
                break;
            case kEffectLibrary:
                return [data descriptionForEffect:[data effectFromFilePath:[data effectFilePathAtIndex:(int)rowIndex]]];
                break;
            case kSoundLibrary:
                return [data descriptionForSound:[data soundFromFilePath:[data soundFilePathAtIndex:(int)rowIndex]]];
                break;
            case kGroupLibrary:
                return [data descriptionForGroup:[data groupFromFilePath:[data groupFilePathAtIndex:(int)rowIndex]]];
                break;
            case kSequenceLibrary:
                return [data descriptionForSequence:[data sequenceFromFilePath:[data sequenceFilePathAtIndex:(int)rowIndex]]];
                break;
            default:
                break;
        }
    }
    
    if([tableView selectedRow] > -1)
    {
        if(aTableView == controlBoxChannelsTableView)
        {
            if([[aTableColumn identifier] isEqualToString:@"Number"])
            {
                //NSLog(@"table channel number:%d", [[data numberForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self selectedControlBox]]] intValue]);
                NSNumber *numberForChannel = [data numberForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self selectedControlBox]]];
                return [NSNumber numberWithInt:[numberForChannel intValue] + 1];
            }
            else if([[aTableColumn identifier] isEqualToString:@"Color"])
            {
                //NSLog(@"table channel color:%@", [data colorForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self selectedControlBox]]]);
                return [data colorForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self selectedControlBox]]];
            }
            else if([[aTableColumn identifier] isEqualToString:@"Description"])
            {
                //NSLog(@"table channel description:%@", [data descriptionForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self selectedControlBox]]]);
                return [data descriptionForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self selectedControlBox]]];
            }
        }
        else if(aTableView == commandsTableView)
        {
            if([[aTableColumn identifier] isEqualToString:@"Start Time"])
            {
                // Display the absolute timing
                return [NSNumber numberWithFloat:[data startTimeForCommand:[data commandAtIndex:(int)rowIndex fromCommandCluster:[self selectedCommandCluster]]]];
            }
            else if([[aTableColumn identifier] isEqualToString:@"End Time"])
            {
                // Display the absolute timing
                return [NSNumber numberWithFloat:[data endTimeForCommand:[data commandAtIndex:(int)rowIndex fromCommandCluster:[self selectedCommandCluster]]]];
            }
        }
        else  if(aTableView == groupItemsTableView)
        {
            if([[aTableColumn identifier] isEqualToString:@"Number"])
            {
                NSNumber *numberForChannel = [data numberForChannel:[data channelAtIndex:[data channelIndexForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:[self selectedGroup]]]  forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:[self selectedGroup]]]]]];
                return [NSNumber numberWithInt:[numberForChannel intValue] + 1];
            }
            else if([[aTableColumn identifier] isEqualToString:@"Color"])
            {
                return [data colorForChannel:[data channelAtIndex:[data channelIndexForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:[self selectedGroup]]]  forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:[self selectedGroup]]]]]];
            }
            else if([[aTableColumn identifier] isEqualToString:@"Description"])
            {
                return [data descriptionForChannel:[data channelAtIndex:[data channelIndexForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:[self selectedGroup]]]  forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:[self selectedGroup]]]]]];
            }
            else if([[aTableColumn identifier] isEqualToString:@"Control Box"])
            {
                return [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:[data itemDataAtIndex:(int)rowIndex forGroup:[self selectedGroup]]]]];
            }
        }
        else if(aTableView == sequenceSoundsTableView)
        {
            return [data descriptionForSound:[data soundFromFilePath:[data soundFilePathAtIndex:(int)rowIndex forSequence:[self selectedSequence]]]];
        }
        else if(aTableView == sequenceControlBoxesTableView)
        {
            return [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:(int)rowIndex forSequence:[self selectedSequence]]]];
        }
        else if(aTableView == sequenceGroupsTableView)
        {
            return [data descriptionForGroup:[data groupFromFilePath:[data groupFilePathAtIndex:(int)rowIndex forSequence:[self selectedSequence]]]];
        }
        else if(aTableView == sequenceCommandClusterTableView)
        {
            return [data descriptionForCommandCluster:[data commandClusterFromFilePath:[data commandClusterFilePathAtIndex:(int)rowIndex forSequence:[self selectedSequence]]]];
        }
    }
    
    return @"nil";
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //NSLog(@"tableView selected:%d", (int)[tableView selectedRow]);
    
    if([notification object] == tableView)
    {
        if([tableView selectedRow] > -1)
        {
            switch (selectedLibrary)
            {
                case kControlBoxLibrary:
                    [controlBoxDescriptionTextField setEnabled:YES];
                    [controlBoxIDTextField setEnabled:YES];
                    [deleteControlBoxButton setEnabled:YES];
                    [addControlBoxToSequenceButton setEnabled:YES];
                    [addChannelToControlBoxButton setEnabled:YES];
                    // Only allow deleting of the last index channel. Otherwise the indexes will get messed up and destroy the data model
                    if([controlBoxChannelsTableView selectedRow] == [data channelsCountForControlBox:[self selectedControlBox]] - 1)
                         [deleteChannelFromControlBoxButton setEnabled:YES];
                    
                    [controlBoxIDTextField setStringValue:[data controlBoxIDForControlBox:[self selectedControlBox]]];
                    [controlBoxDescriptionTextField setStringValue:[data descriptionForControlBox:[self selectedControlBox]]];
                    [controlBoxChannelsTableView reloadData];
                    break;
                case kCommandClusterLibrary:
                    [commandClusterDescriptionTextField setEnabled:YES];
                    [startTimeTextField setEnabled:YES];
                    [endTimeTextField setEnabled:YES];
                    [deleteCommandClusterButton setEnabled:YES];
                    [addCommandClusterToSequenceButton setEnabled:YES];
                    [selectControlBoxForCommandClusterButton setEnabled:YES];
                    [selectGroupForCommandClusterButton setEnabled:YES];
                    if([[data controlBoxFilePathForCommandCluster:[self selectedCommandCluster]] length] > 0)
                    {
                        [addCommandButton setEnabled:YES];
                    }
                    
                    [commandClusterDescriptionTextField setStringValue:[data descriptionForCommandCluster:[self selectedCommandCluster]]];
                    [startTimeTextField setFloatValue:[data startTimeForCommandCluster:[self selectedCommandCluster]]];
                    [endTimeTextField setFloatValue:[data endTimeForCommandCluster:[self selectedCommandCluster]]];
                    if([data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self selectedCommandCluster]]]] != nil)
                    {
                        [controlBoxDescriptionForCommandCluster setStringValue:[data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self selectedCommandCluster]]]]];
                    }
                    else
                    {
                        [controlBoxDescriptionForCommandCluster setStringValue:@""];
                    }
                    if([data descriptionForGroup:[data groupFromFilePath:[data groupFilePathForCommandCluster:[self selectedCommandCluster]]]] != nil)
                    {
                        [groupDescriptionForCommandCluster setStringValue:[data descriptionForGroup:[data groupFromFilePath:[data groupFilePathForCommandCluster:[self selectedCommandCluster]]]]];
                    }
                    else
                    {
                        [groupDescriptionForCommandCluster setStringValue:@""];
                    }
                    
                    [commandsTableView reloadData];
                    break;  
                case kEffectLibrary:
                    [deleteEffectButton setEnabled:YES];
                    [effectDescriptionTextField setStringValue:[data descriptionForEffect:[self selectedEffect]]];
                    [compileEffectButton setEnabled:YES];
                    [effectScriptTextView setEditable:YES];
                    if([[data scriptForEffect:[self selectedEffect]] length] > 0)
                    {
                        [effectScriptTextView setString:@""];
                        [effectScriptTextView insertText:[data scriptForEffect:[self selectedEffect]]];
                    }
                    break;
                case kSoundLibrary:
                    [soundDescriptionTextField setEnabled:YES];
                    [soundStartTimeTextField setEnabled:YES];
                    [soundEndTimeTextField setEnabled:YES];
                    [deleteSoundButton setEnabled:YES];
                    [addSoundToSequenceButton setEnabled:YES];
                    [selectExternalAudioFileButton setEnabled:YES];
                    [selectAudioFileFromLibraryButton setEnabled:YES];
                    
                    [soundDescriptionTextField setStringValue:[data descriptionForSound:[self selectedSound]]];
                    [soundStartTimeTextField setFloatValue:[data startTimeForSound:[self selectedSound]]];
                    [soundEndTimeTextField setFloatValue:[data endTimeForSound:[self selectedSound]]];
                    [audioFilePathTextField setStringValue:[[data filePathToAudioFileForSound:[self selectedSound]] lastPathComponent]];
                    break;
                case kGroupLibrary:
                    [deleteGroupButton setEnabled:YES];
                    [addGroupToSequenceButton setEnabled:YES];
                    [groupDescriptionTextField setEnabled:YES];
                    [deleteItemFromGroupButton setEnabled:YES];
                    [addItemToGroupButton setEnabled:YES];
                    
                    [groupDescriptionTextField setStringValue:[data descriptionForGroup:[self selectedGroup]]];
                    [groupItemsTableView reloadData];
                    break;
                case kSequenceLibrary:
                    [deleteSequenceButton setEnabled:YES];
                    [loadSequenceButton setEnabled:YES];
                    [sequenceDescriptionTextField setEnabled:YES];
                    [sequenceStartTimeTextField setEnabled:YES];
                    [sequenceEndTimeTextField setEnabled:YES];
                    [addSoundToSequenceButton setEnabled:YES];
                    [addControlBoxToSequenceButton setEnabled:YES];
                    [addGroupToSequenceButton setEnabled:YES];
                    [addCommandClusterToSequenceButton setEnabled:YES];
                    
                    [sequenceDescriptionTextField setStringValue:[data descriptionForSequence:[self selectedSequence]]];
                    [sequenceStartTimeTextField setFloatValue:[data startTimeForSequence:[self selectedSequence]]];
                    [sequenceEndTimeTextField setFloatValue:[data endTimeForSequence:[self selectedSequence]]];
                    [sequenceSoundsTableView reloadData];
                    [sequenceControlBoxesTableView reloadData];
                    [sequenceGroupsTableView reloadData];
                    [sequenceCommandClusterTableView reloadData];
                    break;
                default:
                    break;
            }
        }
        else
        {
            switch (selectedLibrary)
            {
                case kControlBoxLibrary:
                    [controlBoxDescriptionTextField setEnabled:NO];
                    [controlBoxIDTextField setEnabled:NO];
                    [deleteControlBoxButton setEnabled:NO];
                    [addControlBoxToSequenceButton setEnabled:NO];
                    [selectControlBoxForCommandClusterButton setEnabled:NO];
                    [selectGroupForCommandClusterButton setEnabled:NO];
                    [deleteChannelFromControlBoxButton setEnabled:NO];
                    [addChannelToControlBoxButton setEnabled:NO];
                    
                    [controlBoxIDTextField setStringValue:@""];
                    [controlBoxDescriptionTextField setStringValue:@""];
                    [controlBoxChannelsTableView reloadData];
                    break;
                case kCommandClusterLibrary:
                    [commandClusterDescriptionTextField setEnabled:NO];
                    [startTimeTextField setEnabled:NO];
                    [endTimeTextField setEnabled:NO];
                    [deleteCommandClusterButton setEnabled:NO];
                    [addCommandClusterToSequenceButton setEnabled:NO];
                    [addCommandButton setEnabled:NO];
                    
                    [commandClusterDescriptionTextField setStringValue:@""];
                    [startTimeTextField setStringValue:@""];
                    [endTimeTextField setStringValue:@""];
                    [controlBoxDescriptionForCommandCluster setStringValue:@""];
                    [groupDescriptionForCommandCluster setStringValue:@""];
                    [commandsTableView reloadData];
                    break;
                case kEffectLibrary:
                    [deleteEffectButton setEnabled:NO];
                    [effectDescriptionTextField setStringValue:@""];
                    [compileEffectButton setEnabled:NO];
                    [effectScriptTextView setEditable:NO];
                    [effectScriptTextView setString:@""];
                    break;
                case kSoundLibrary:
                    [soundDescriptionTextField setEnabled:NO];
                    [soundStartTimeTextField setEnabled:NO];
                    [soundEndTimeTextField setEnabled:NO];
                    [deleteSoundButton setEnabled:NO];
                    [addSoundToSequenceButton setEnabled:NO];
                    [selectExternalAudioFileButton setEnabled:NO];
                    [selectAudioFileFromLibraryButton setEnabled:NO];
                    
                    [soundDescriptionTextField setStringValue:@""];
                    [soundStartTimeTextField setStringValue:@""];
                    [soundEndTimeTextField setStringValue:@""];
                    [audioFilePathTextField setStringValue:@""];
                    break;  
                case kGroupLibrary:
                    [deleteGroupButton setEnabled:NO];
                    [addGroupToSequenceButton setEnabled:NO];
                    [groupDescriptionTextField setEnabled:NO];
                    [deleteItemFromGroupButton setEnabled:NO];
                    [addItemToGroupButton setEnabled:NO];
                    
                    [groupDescriptionTextField setStringValue:@""];
                    [groupItemsTableView reloadData];
                    break;
                case kSequenceLibrary:
                    [deleteSequenceButton setEnabled:NO];
                    [loadSequenceButton setEnabled:NO];
                    [sequenceDescriptionTextField setEnabled:NO];
                    [sequenceStartTimeTextField setEnabled:NO];
                    [sequenceEndTimeTextField setEnabled:NO];
                    [deleteSoundFromSequenceButton setEnabled:NO];
                    [addSoundToSequenceButton setEnabled:NO];
                    [deleteControlBoxFromSequenceButton setEnabled:NO];
                    [addControlBoxToSequenceButton setEnabled:NO];
                    [deleteGroupFromSequenceButton setEnabled:NO];
                    [addGroupToSequenceButton setEnabled:NO];
                    [deleteCommandClusterFromSequenceButton setEnabled:NO];
                    [addCommandClusterToSequenceButton setEnabled:NO];
                    
                    [sequenceDescriptionTextField setStringValue:@""];
                    [sequenceStartTimeTextField setStringValue:@""];
                    [sequenceEndTimeTextField setStringValue:@""];
                    [sequenceSoundsTableView reloadData];
                    [sequenceControlBoxesTableView reloadData];
                    [sequenceGroupsTableView reloadData];
                    [sequenceCommandClusterTableView reloadData];
                    break;
                default:
                    break;
            }
        }
    }
    else if([notification object] == controlBoxChannelsTableView)
    {
        if([controlBoxChannelsTableView selectedRow] == [data channelsCountForControlBox:[self selectedControlBox]] - 1)
        {
            [deleteChannelFromControlBoxButton setEnabled:YES];
        }
        else
        {
            [deleteChannelFromControlBoxButton setEnabled:NO];
        }
    }
    else if([notification object] == commandsTableView)
    {
        if([commandsTableView selectedRow] > -1)
        {         
            [selectChannelForCommandButton setEnabled:YES];
            [deleteCommandButton setEnabled:YES];
            
            int channelIndex = [data channelIndexForCommand:[self selectedCommand]];
            NSMutableDictionary *itemData = [data itemDataAtIndex:channelIndex forGroup:[data groupFromFilePath:[data groupFilePathForCommandCluster:[self selectedCommandCluster]]]];
            if([[data controlBoxFilePathForCommandCluster:[self selectedCommandCluster]] length] > 0)
            {
                NSNumber *numberForChannel = [data numberForChannel:[data channelAtIndex:[data channelIndexForCommand:[self selectedCommand]] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self selectedCommandCluster]]]]];
                int channelNumber = [numberForChannel intValue] + 1;
                NSString *colorForChannel = [data colorForChannel:[data channelAtIndex:[data channelIndexForCommand:[self selectedCommand]] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self selectedCommandCluster]]]]];
                NSString *descriptionForChannel = [data descriptionForChannel:[data channelAtIndex:[data channelIndexForCommand:[self selectedCommand]] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self selectedCommandCluster]]]]];
                NSString *descriptionForControlBox = [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self selectedCommandCluster]]]];
                
                [commandChannelInformationTextField setStringValue:[NSString stringWithFormat:@"%d %@ %@", channelNumber, colorForChannel, descriptionForChannel]];
                [commandControlBoxInformationTextField setStringValue:descriptionForControlBox];
            }
            else if([[data groupFilePathForCommandCluster:[self selectedCommandCluster]] length] > 0)
            {
                NSNumber *numberForChannel = [data numberForChannel:[data channelAtIndex:[data channelIndexForItemData:itemData] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:itemData]]]];
                int channelNumber = [numberForChannel intValue] + 1;
                NSString *colorForChannel = [data colorForChannel:[data channelAtIndex:[data channelIndexForItemData:itemData] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:itemData]]]];
                NSString *descriptionForChannel = [data colorForChannel:[data channelAtIndex:[data channelIndexForItemData:itemData] forControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:itemData]]]];
                NSString *descriptionForControlBox = [data descriptionForControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForItemData:itemData]]];
                
                [commandChannelInformationTextField setStringValue:[NSString stringWithFormat:@"%d %@ %@", channelNumber, colorForChannel, descriptionForChannel]];
                [commandControlBoxInformationTextField setStringValue:descriptionForControlBox];
            }
        }
        else
        {
            [selectChannelForCommandButton setEnabled:NO];
            [deleteCommandButton setEnabled:NO];
            
            [commandChannelInformationTextField setStringValue:@""];
            [commandControlBoxInformationTextField setStringValue:@""];
        }
    }
    else if([notification object] == sequenceSoundsTableView)
    {
        if([sequenceSoundsTableView selectedRow] > -1)
        {
            [deleteSoundFromSequenceButton setEnabled:YES];
        }
        else
        {
            [deleteSoundFromSequenceButton setEnabled:NO];
        }
    }
    else if([notification object] == sequenceControlBoxesTableView)
    {
        if([sequenceControlBoxesTableView selectedRow] > -1)
        {
            [deleteControlBoxFromSequenceButton setEnabled:YES];
        }
        else
        {
            [deleteControlBoxFromSequenceButton setEnabled:NO];
        }
    }
    else if([notification object] == sequenceGroupsTableView)
    {
        if([sequenceGroupsTableView selectedRow] > -1)
        {
            [deleteGroupFromSequenceButton setEnabled:YES];
        }
        else
        {
            [deleteGroupFromSequenceButton setEnabled:NO];
        }
    }
    else if([notification object] == sequenceCommandClusterTableView)
    {
        if([sequenceCommandClusterTableView selectedRow] > -1)
        {
            [deleteCommandClusterFromSequenceButton setEnabled:YES];
        }
        else
        {
            [deleteCommandClusterFromSequenceButton setEnabled:NO];
        }
    }
}

#pragma mark - Control Box Methods

- (IBAction)deleteControlBoxButtonPress:(id)sender
{
    [data removeControlBoxFromLibrary:[self selectedControlBox]];
    [tableView deselectAll:nil];
    //[self tableViewSelectionDidChange:[NSNotification notificationWithName:@"" object:tableView]];
    [tableView reloadData];
    [self reloadGraphicalDisplays];
}

- (IBAction)deleteChannelFromControlBoxButtonPress:(id)sender
{
    [data removeChannel:[self selectedChannel] forControlBox:[self selectedControlBox]];
    [controlBoxChannelsTableView deselectAll:nil];
    [controlBoxChannelsTableView reloadData];
    [self reloadGraphicalDisplays];
}

- (IBAction)addChannelToControlBoxButtonPress:(id)sender
{
    [data addChannelAndReturnNewChannelIndexForControlBox:[self selectedControlBox]];
    [controlBoxChannelsTableView reloadData];
    [self reloadGraphicalDisplays];
}

#pragma mark - Command Cluster Methods

- (IBAction)deleteCommandClusterButtonPress:(id)sender
{
    [data removeCommandClusterFromLibrary:[self selectedCommandCluster]];
    [tableView deselectAll:nil];
    //[self tableViewSelectionDidChange:[NSNotification notificationWithName:@"" object:tableView]];
    [tableView reloadData];
    [self reloadGraphicalDisplays];
}

- (IBAction)selectControlBoxForCommandClusterButtonPress:(id)sender
{
    [controlBoxPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
    [controlBoxSelectorViewController reload];
    [self reloadGraphicalDisplays];
}

- (IBAction)selectGroupForCommandClusterButtonPress:(id)sender
{
    [groupPopover showRelativeToRect:[sender bounds] ofView:sender preferredEdge:NSMaxYEdge];
    [groupSelectorViewController reload];
    [self reloadGraphicalDisplays];
}

- (IBAction)selectChannelForCommandButtonPress:(id)sender
{
    if([commandsTableView selectedRow] > -1)
    {
        // Command Cluster is a Control Box Cluster
        if([[data controlBoxFilePathForCommandCluster:[self selectedCommandCluster]] length] > 0)
        {
            [channelSelectorViewController setControlBox:[data controlBoxFromFilePath:[data controlBoxFilePathForCommandCluster:[self selectedCommandCluster]]]];
            [channelSelectorViewController setChannelIndex:[data channelIndexForCommand:[self selectedCommand]]];
            [channelPopover showRelativeToRect:[commandsTableView rectOfRow:[commandsTableView selectedRow]] ofView:commandsTableView preferredEdge:NSMaxYEdge];
            [channelSelectorViewController reload];
        }
        // Command Cluster is a Group Cluster
        else if([[data groupFilePathForCommandCluster:[self selectedCommandCluster]] length] > 0)
        {
            [channelSelectorViewController setGroup:[data groupFromFilePath:[data groupFilePathForCommandCluster:[self selectedCommandCluster]]]];
            [channelSelectorViewController setChannelIndex:[data channelIndexForCommand:[self selectedCommand]]];
            [channelPopover showRelativeToRect:[commandsTableView rectOfRow:[commandsTableView selectedRow]] ofView:commandsTableView preferredEdge:NSMaxYEdge];
            [channelSelectorViewController reload];
        }
        
    }
    else
    {
        [channelPopover performClose:nil];
    }
}

- (IBAction)deleteCommandButtonPress:(id)sender
{
    [data removeCommand:[self selectedCommand] fromCommandCluster:[self selectedCommandCluster]];
    [commandsTableView deselectAll:nil];
    [commandsTableView reloadData];
    [self reloadGraphicalDisplays];
}

- (IBAction)addCommandButtonPress:(id)sender
{
    [data createCommandAndReturnNewCommandIndexForCommandCluster:[self selectedCommandCluster]];
    [commandsTableView reloadData];
    [commandsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:(int)([data commandsCountForCommandCluster:[self selectedCommandCluster]] - 1)] byExtendingSelection:NO];
    [self tableViewSelectionDidChange:[NSNotification notificationWithName:@"NSTableViewSelectionDidChange" object:commandsTableView]];
    [self selectChannelForCommandButtonPress:selectChannelForCommandButton];
    [self reloadGraphicalDisplays];
}

#pragma mark - Effect Methods

- (IBAction)deleteEffectButtonPress:(id)sender;
{
    [data removeEffectFromLibrary:[data effectFromFilePath:[data effectFilePathAtIndex:(int)[tableView selectedRow]]]];
    [tableView reloadData];
    [self reloadGraphicalDisplays];
}

- (IBAction)compileEffectButtonPress:(id)sender
{
    
}

#pragma mark - Sound Methods

- (IBAction)deleteSoundButtonPress:(id)sender
{
    [data removeSoundFromLibrary:[self selectedSound]];
    [tableView deselectAll:nil];
    //[self tableViewSelectionDidChange:[NSNotification notificationWithName:@"" object:tableView]];
    [tableView reloadData];
    [self reloadGraphicalDisplays];
}

- (IBAction)selectExternalAudioFileButtonPress:(id)sender
{
    if(openPanel == nil)
    {
        [self loadOpenPanel];
    }
    
    [openPanel beginSheetForDirectory:@"~" file:nil types:[NSArray arrayWithObjects:@"aac", @"aif", @"aiff", @"alac", @"mp3", @"m4a", @"wav", nil] modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (IBAction)selectAudioFileFromLibrary:(id)sender
{
    if(openPanel == nil)
    {
        [self loadOpenPanel];
    }
    NSString *soundLibraryDirectory = [NSString stringWithFormat:@"%@/soundLibrary", [data libraryFolder]];
    NSLog(@"soundLibraryDirectory:%@", soundLibraryDirectory);
    
    [openPanel beginSheetForDirectory:soundLibraryDirectory file:nil types:[NSArray arrayWithObjects:@"aac", @"aif", @"aiff", @"alac", @"mp3", @"m4a", @"wav", nil] modalForWindow:self.view.window modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode contextInfo:(void  *)contextInfo
{
    if(returnCode == NSOKButton)
    {
        NSString *filePath = [panel filename];
        //NSLog(@"filePath:%@", filePath);
        NSString *soundLibraryDirectory = [NSString stringWithFormat:@"/Library/Application Support/LightMaster/soundLibrary"];
        NSRange textRange = [[filePath lowercaseString] rangeOfString:[soundLibraryDirectory lowercaseString]];
        
        // Library Sound
        if(textRange.location != NSNotFound)
        {
            //NSLog(@"library sound");
            [data setFilePathToAudioFile:[NSString stringWithFormat:@"soundLibrary/%@", [filePath lastPathComponent]] forSound:[self selectedSound]];
            [audioFilePathTextField setStringValue:[filePath lastPathComponent]];
        }
        // External Sound
        else
        {
            //NSLog(@"external sound");
            // Make a copy of the sound file in the library
            NSString *newFilePath = [NSString stringWithFormat:@"%@/soundLibrary/%@", [data libraryFolder], [filePath lastPathComponent]];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager copyItemAtPath:filePath toPath:newFilePath error:NULL];
            
            [data setFilePathToAudioFile:[NSString stringWithFormat:@"soundLibrary/%@", [filePath lastPathComponent]] forSound:[self selectedSound]];
            [audioFilePathTextField setStringValue:[filePath lastPathComponent]];
        }
        
        [self reloadGraphicalDisplays];
    }
}

#pragma mark - Group Methods

- (IBAction)deleteGroupButtonPress:(id)sender
{
    [data removeGroupFromLibrary:[self selectedGroup]];
    [tableView deselectAll:nil];
    //[self tableViewSelectionDidChange:[NSNotification notificationWithName:@"" object:tableView]];
    [tableView reloadData];
    [self reloadGraphicalDisplays];
}

- (IBAction)deleteItemFromGroupButtonPress:(id)sender
{
    [data removeItemData:[self selectedItemData] forGroup:[self selectedGroup]];
    [groupItemsTableView deselectAll:nil];
    [groupItemsTableView reloadData];
    [self reloadGraphicalDisplays];
}

- (IBAction)addItemToGroupButtonPress:(id)sender
{
    [channelAndControlBoxPopover showRelativeToRect:[groupItemsTableView rectOfRow:[groupItemsTableView selectedRow]] ofView:groupItemsTableView preferredEdge:NSMaxYEdge];
    [channelAndControlBoxSelectorViewController reload];
    [self reloadGraphicalDisplays];
}

#pragma mark - Sequence Methods

- (IBAction)deleteSequenceButtonPress:(id)sender
{
    [data removeSequenceFromLibrary:[self selectedSequence]];
    [tableView reloadData];
    [self reloadGraphicalDisplays];
}

- (IBAction)loadSequenceButtonPress:(id)sender
{
    [data setCurrentSequence:[self selectedSequence]];
    [self reloadGraphicalDisplays];
}

- (IBAction)deleteSoundFromSequenceButtonPress:(id)sender
{
    [data removeSoundFilePath:[self selectedSoundFilePath] forSequence:[self selectedSequence]];
    [sequenceSoundsTableView reloadData];
    [self reloadGraphicalDisplays];
}

- (IBAction)addSoundToSequenceButtonPress:(id)sender
{
    [sequenceSoundPopover showRelativeToRect:[sequenceSoundsTableView rectOfRow:[sequenceSoundsTableView selectedRow]] ofView:sequenceSoundsTableView preferredEdge:NSMaxYEdge];
    if([sequenceSoundsTableView selectedRow] > -1)
    {
        [sequenceSoundSelectorViewController setSelectedSoundFilePath:[data soundFilePathAtIndex:(int)[sequenceSoundsTableView selectedRow] forSequence:[self selectedSequence]]];
    }
    [self reloadGraphicalDisplays];
}

- (IBAction)deleteControlBoxFromSequenceButtonPress:(id)sender
{
    [data removeControlBoxFilePath:[self selectedControlBoxFilePath] forSequence:[self selectedSequence]];
    [sequenceControlBoxesTableView reloadData];
    [self reloadGraphicalDisplays];
}

- (IBAction)addControlBoxToSequenceButtonPress:(id)sender
{
    [sequenceControlBoxPopover showRelativeToRect:[sequenceControlBoxesTableView rectOfRow:[sequenceControlBoxesTableView selectedRow]] ofView:sequenceControlBoxesTableView preferredEdge:NSMaxYEdge];
    if([sequenceControlBoxesTableView selectedRow] > -1)
    {
        [sequenceControlBoxSelectorViewController setSelectedControlBoxFilePath:[data controlBoxFilePathAtIndex:(int)[sequenceControlBoxesTableView selectedRow] forSequence:[self selectedSequence]]];
    }
    [self reloadGraphicalDisplays];
}

- (IBAction)deleteGroupFromSequenceButtonPress:(id)sender
{
    [data removeGroupFilePath:[self selectedGroupFilePath] forSequence:[self selectedSequence]];
    [sequenceGroupsTableView reloadData];
    [self reloadGraphicalDisplays];
}

- (IBAction)addGroupToSequenceButtonPress:(id)sender
{
    [sequenceGroupPopover showRelativeToRect:[sequenceGroupsTableView rectOfRow:[sequenceGroupsTableView selectedRow]] ofView:sequenceGroupsTableView preferredEdge:NSMaxYEdge];
    if([sequenceGroupsTableView selectedRow] > -1)
    {
        [sequenceGroupSelectorViewController setSelectedGroupFilePath:[data groupFilePathAtIndex:(int)[sequenceGroupsTableView selectedRow] forSequence:[self selectedSequence]]];
    }
    [self reloadGraphicalDisplays];
}

- (IBAction)deleteCommandClusterFromSequenceButtonPress:(id)sender
{
    [data removeCommandClusterFilePath:[self selectedCommandClusterFilePath] forSequence:[self selectedSequence]];
    [sequenceCommandClusterTableView reloadData];
    [self reloadGraphicalDisplays];
}

- (IBAction)addCommandClustertoSequenceButtonPress:(id)sender
{
    [sequenceCommandClusterPopover showRelativeToRect:[sequenceCommandClusterTableView rectOfRow:[sequenceCommandClusterTableView selectedRow]] ofView:sequenceCommandClusterTableView preferredEdge:NSMaxYEdge];
    if([sequenceCommandClusterTableView selectedRow] > -1)
    {
        [sequenceCommandClusterSelectorViewController setSelectedCommandClusterFilePath:[data commandClusterFilePathAtIndex:(int)[sequenceCommandClusterTableView selectedRow] forSequence:[self selectedSequence]]];
    }
    [self reloadGraphicalDisplays];
}

@end
