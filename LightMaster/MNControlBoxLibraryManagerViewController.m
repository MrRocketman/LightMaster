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

- (void)textDidEndEditing:(NSNotification *)aNotification;

@end


@implementation MNControlBoxLibraryManagerViewController

@synthesize controlBox;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Text Editing Notifications
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidBeginEditing:) name:@"NSControlTextDidBeginEditingNotification" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:@"NSControlTextDidEndEditingNotification" object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:@"NSControlTextDidChangeNotification" object:nil];
    }
    
    return self;
}

- (void)updateContent
{
    if(controlBox != nil)
    {
        [idTextField setEnabled:YES];
        [descriptionTextField setEnabled:YES];
        
        [addChannelButton setEnabled:YES];
        
        [idTextField setStringValue:[data controlBoxIDForControlBox:controlBox]];
        [descriptionTextField setStringValue:[data descriptionForControlBox:controlBox]];
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
    [data addChannelAndReturnNewChannelIndexForControlBox:controlBox];
    [channelsTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

- (IBAction)deleteChannelButtonPress:(id)sender
{
    [data removeChannel:[data channelAtIndex:(int)[channelsTableView selectedRow] forControlBox:controlBox] forControlBox:controlBox];
    [channelsTableView deselectAll:nil];
    [channelsTableView reloadData];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

#pragma mark - NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    NSLog(@"controlBox:%@", controlBox);
    return [data channelsCountForControlBox:controlBox];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if([[aTableColumn identifier] isEqualToString:@"Number"])
    {
        return [data numberForChannel:[data channelAtIndex:(int)rowIndex forControlBox:controlBox]];
    }
    else if([[aTableColumn identifier] isEqualToString:@"Color"])
    {
        //NSLog(@"channel:%@", [data channelAtIndex:(int)rowIndex forControlBox:controlBox]);
        return [data colorForChannel:[data channelAtIndex:(int)rowIndex forControlBox:controlBox]];
    }
    else if([[aTableColumn identifier] isEqualToString:@"Description"])
    {
        return [data descriptionForChannel:[data channelAtIndex:(int)rowIndex forControlBox:controlBox]];
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

/*- (void)textDidBeginEditing:(NSNotification *)aNotification
 {
 
 }
 
 - (void)textDidChange:(NSNotification *)aNotification
 {
 
 }*/

- (void)textDidEndEditing:(NSNotification *)aNotification
{
    if([aNotification object] == descriptionTextField)
    {
        [data setDescription:[descriptionTextField stringValue] forControlBox:controlBox];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibrariesViewController" object:nil];
    }
    else if([aNotification object] == idTextField)
    {
        [data setControlBoxID:[idTextField stringValue] forControlBox:controlBox];
    }
    else if([[aNotification userInfo] objectForKey:@"NSFieldEditor"])
    {
        NSLog(@"before row:%d column:%d controlBox:%@", (int)[channelsTableView editedRow], (int)[channelsTableView editedColumn], controlBox);
        NSString *textFieldString = [[[aNotification userInfo] objectForKey:@"NSFieldEditor"] string];
        if([channelsTableView editedColumn] == 0)
        {
            //NSLog(@"number:%d", (int)[textFieldString intValue]);
            [data setNumber:[textFieldString intValue] forChannelAtIndex:(int)[channelsTableView editedRow] whichIsPartOfControlBox:controlBox];
        }
        else if([channelsTableView editedColumn] == 1)
        {
            //NSLog(@"color:%@", textFieldString);
            [data setColor:textFieldString forChannelAtIndex:(int)[channelsTableView editedRow] whichIsPartOfControlBox:controlBox];
        }
        else if([channelsTableView editedColumn] == 2)
        {
            //NSLog(@"description:%@", textFieldString);
            [data setDescription:textFieldString forChannelAtIndex:(int)[channelsTableView editedRow] whichIsPartOfControlBox:controlBox];
        }
        NSLog(@"after row:%d column:%d controlBox:%@", (int)[channelsTableView editedRow], (int)[channelsTableView editedColumn], controlBox);
        
        [channelsTableView reloadData];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

@end
