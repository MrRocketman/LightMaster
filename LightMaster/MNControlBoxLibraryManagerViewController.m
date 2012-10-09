//
//  MNControlBoxLibraryManagerViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNControlBoxLibraryManagerViewController.h"
#import "MNData.h"


@interface MNControlBoxLibraryManagerViewController ()

- (void)textDidBeginEditing:(NSNotification *)aNotification;
- (void)textDidEndEditing:(NSNotification *)aNotification;
- (NSMutableDictionary *)controlBox;

@end


@implementation MNControlBoxLibraryManagerViewController

@synthesize controlBoxIndex;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Text Editing Notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidBeginEditing:) name:@"NSControlTextDidBeginEditingNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:@"NSControlTextDidEndEditingNotification" object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:@"NSControlTextDidChangeNotification" object:nil];
    }
    
    return self;
}

- (NSMutableDictionary *)controlBox
{
    if(controlBoxIndex > -1)
        return [data controlBoxFromFilePath:[data controlBoxFilePathAtIndex:controlBoxIndex]];
    
    return nil;
}

- (void)updateContent
{
    if(controlBoxIndex > -1)
    {
        [idTextField setEnabled:YES];
        [descriptionTextField setEnabled:YES];
        
        [addChannelButton setEnabled:YES];
        
        [idTextField setStringValue:[data controlBoxIDForControlBox:[self controlBox]]];
        [descriptionTextField setStringValue:[data descriptionForControlBox:[self controlBox]]];
    }
    else
    {
        [idTextField setEnabled:NO];
        [descriptionTextField setEnabled:NO];
        
        [addChannelButton setEnabled:NO];
        [deleteChannelButton setEnabled:NO];
        
        [idTextField setStringValue:@""];
        [descriptionTextField setStringValue:@""];
    }
    
    [channelsTableView reloadData];
}

#pragma mark - Button Actions

- (IBAction)addChannelButtonPress:(id)sender
{
    [data addChannelAndReturnNewChannelIndexForControlBox:[self controlBox]];
    [channelsTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)deleteChannelButtonPress:(id)sender
{
    [data removeChannel:[data channelAtIndex:(int)[channelsTableView selectedRow] forControlBox:[self controlBox]] forControlBox:[self controlBox]];
    [channelsTableView deselectAll:nil];
    [channelsTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [data channelsCountForControlBox:[self controlBox]];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if([[aTableColumn identifier] isEqualToString:@"Number"])
    {
        return [data numberForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self controlBox]]];
    }
    else if([[aTableColumn identifier] isEqualToString:@"Color"])
    {
        return [data colorForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self controlBox]]];
    }
    else if([[aTableColumn identifier] isEqualToString:@"Description"])
    {
        return [data descriptionForChannel:[data channelAtIndex:(int)rowIndex forControlBox:[self controlBox]]];
    }
    
    return @"nil";
}

#pragma mark - NSTableViewDelegate Methods

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if([channelsTableView selectedRow] > -1)
    {
        [deleteChannelButton setEnabled:YES];
    }
    else
    {
        [deleteChannelButton setEnabled:NO];
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
        [data setDescription:[descriptionTextField stringValue] forControlBox:[self controlBox]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibrariesViewController" object:nil];
    }
    else if([aNotification object] == idTextField)
    {
        [data setControlBoxID:[idTextField stringValue] forControlBox:[self controlBox]];
    }
    else if([[aNotification userInfo] objectForKey:@"NSFieldEditor"])
    {
        NSString *textFieldString = [[[aNotification userInfo] objectForKey:@"NSFieldEditor"] string];
        if([channelsTableView editedColumn] == 0)
        {
            //NSLog(@"number:%d", (int)[textFieldString intValue]);
            [data setNumber:[textFieldString intValue] forChannelAtIndex:(int)[channelsTableView editedRow] whichIsPartOfControlBox:[self controlBox]];
        }
        else if([channelsTableView editedColumn] == 1)
        {
            //NSLog(@"color:%@", textFieldString);
            [data setColor:textFieldString forChannelAtIndex:(int)[channelsTableView editedRow] whichIsPartOfControlBox:[self controlBox]];
        }
        else if([channelsTableView editedColumn] == 2)
        {
            //NSLog(@"description:%@", textFieldString);
            [data setDescription:textFieldString forChannelAtIndex:(int)[channelsTableView editedRow] whichIsPartOfControlBox:[self controlBox]];
        }
        
        [channelsTableView reloadData];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

@end
