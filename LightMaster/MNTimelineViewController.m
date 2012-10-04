//
//  MNTimelineViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNTimelineViewController.h"

@interface MNTimelineViewController()

- (void)loadSequence:(NSNotification *)aNotification;

@end

@implementation MNTimelineViewController

//@synthesize timelineTracksView, timelineClustersView;
@synthesize data, zoomLevel;

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Init Code Here
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadSequence:) name:@"LoadSequence" object:nil];
        
        [timelineTracksView setData:self.data];
        [timelineTrackHeadersView setData:self.data];
        [timelineTracksView setNeedsDisplay:YES];
        [timelineTrackHeadersView setNeedsDisplay:YES];
    }
    
    return self;
}

- (IBAction)zoomLevelChange:(id)sender
{
    self.zoomLevel = [sender floatValue];
    [data setZoomLevel:self.zoomLevel];
    [timelineTrackHeadersView setNeedsDisplay:YES];
}

- (void)loadSequence:(NSNotification *)aNotification
{
    [timelineTracksView setNeedsDisplay:YES];
    [timelineTrackHeadersView setNeedsDisplay:YES];
}

@end
