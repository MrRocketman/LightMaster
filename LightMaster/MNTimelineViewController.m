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
@synthesize zoomLevel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Init Code Here
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadSequence:) name:@"LoadSequence" object:nil];
        
        // Update the zoom level
        [data setZoomLevel:self.zoomLevel];
    }
    
    return self;
}

- (IBAction)zoomLevelChange:(id)sender
{
    // This gives a much more linear feel to the zoom
    self.zoomLevel = pow([sender floatValue], 2) / 2;
    [data setZoomLevel:self.zoomLevel];
    
    // Scroll to the new left edge point by x (the left edge time has not change, the x has because of zoon)
    [timelineTracksView scrollPoint:NSMakePoint([data timeToX:[data timeAtLeftEdgeOfTimelineView]], 0)];
    [timelineTracksView setNeedsDisplay:YES];
}

- (void)loadSequence:(NSNotification *)aNotification
{
    [timelineTracksView setNeedsDisplay:YES];
    [timelineTrackHeadersView setNeedsDisplay:YES];
}

@end
