//
//  MNEffectClusterLibraryManagerViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNEffectClusterLibraryManagerViewController.h"
#import "MNData.h"

@interface MNEffectClusterLibraryManagerViewController ()

- (void)textDidBeginEditing:(NSNotification *)aNotification;
- (void)textDidEndEditing:(NSNotification *)aNotification;
- (void)textDidChange:(NSNotification *)aNotification;
- (NSMutableDictionary *)effectCluster;

@end


@implementation MNEffectClusterLibraryManagerViewController

@synthesize effectClusterIndex;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        
    }
    
    return self;
}

- (void)awakeFromNib
{
    // Text Editing Notifications
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidBeginEditing:) name:@"NSControlTextDidBeginEditingNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidEndEditing:) name:@"NSControlTextDidEndEditingNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChange:) name:@"NSTextDidChangeNotification" object:scriptTextView];
}

- (NSMutableDictionary *)effectCluster
{
    if(effectClusterIndex > -1)
        return [data effectClusterFromFilePath:[data effectClusterFilePathAtIndex:effectClusterIndex]];
    
    return nil;
}

#pragma mark - Public Methods

- (void)updateContent
{
    if(effectClusterIndex > -1)
    {
        [descriptionTextField setEnabled:YES];
        [scriptTextView setEditable:YES];
        [compileButton setEnabled:YES];
        
        [descriptionTextField setStringValue:[data descriptionForEffectCluster:[self effectCluster]]];
        if([[data scriptForEffectCluster:[self effectCluster]] length] > 0)
            [scriptTextView setString:[data scriptForEffectCluster:[self effectCluster]]];
        else
            [scriptTextView setString:@""];
    }
    else
    {
        [descriptionTextField setEnabled:NO];
        [scriptTextView setEditable:NO];
        [compileButton setEnabled:NO];
        
        [descriptionTextField setStringValue:@""];
        [scriptTextView setString:@""];
    }
}

- (IBAction)compileButtonPress:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

#pragma mark - TextEditinig Notifications

- (void)textDidBeginEditing:(NSNotification *)aNotification
{
    
}

- (void)textDidChange:(NSNotification *)aNotification
{
    if([aNotification object] == scriptTextView)
    {
        [data setScript:[scriptTextView string] forEffectCluster:[self effectCluster]];
    }
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
    if([aNotification object] == descriptionTextField)
    {
        [data setDescription:[descriptionTextField stringValue] forEffectCluster:[self effectCluster]];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibrariesViewController" object:nil];
    }
    
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
}

@end
