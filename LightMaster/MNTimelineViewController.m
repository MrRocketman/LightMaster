//
//  MNTimelineViewController.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNTimelineViewController.h"

@interface MNTimelineViewController()

- (void)updateGraphics:(NSNotification *)aNotification;
- (void)rewindButtonPress:(NSNotification *)aNotification;
- (void)fastForwardButtonPress:(NSNotification *)aNotification;
- (void)skipBackButtonPress:(NSNotification *)aNotification;
- (void)playButtonPress:(NSNotification *)aNotification;
- (void)currentTimeChange:(NSNotification *)aNotification;

- (void)playTimerFire:(NSTimer *)theTimer;

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateGraphics:) name:@"UpdateGraphics" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rewindButtonPress:) name:@"RewindButtonPress" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fastForwardButtonPress:) name:@"FastForwardButtonPress" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(skipBackButtonPress:) name:@"SkipBackButtonPress" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playButtonPress:) name:@"PlayButtonPress" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentTimeChange:) name:@"CurrentTimeChange" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetScrollPoint:) name:@"ResetScrollPoint" object:nil];
        
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
    [timelineTracksView scrollPoint:NSMakePoint([data timeToX:[data timeAtLeftEdgeOfTimelineView]], timelineTracksScrollView.documentVisibleRect.origin.y)];
    [timelineTracksView setNeedsDisplay:YES];
}

#pragma mark - Private Methods

- (void)updateGraphics:(NSNotification *)aNotification
{
    [timelineTracksView setNeedsDisplay:YES];
    [timelineTrackHeadersView setNeedsDisplay:YES];
}

- (void)rewindButtonPress:(NSNotification *)aNotification
{
    
}

- (void)fastForwardButtonPress:(NSNotification *)aNotification
{
    
}

- (void)skipBackButtonPress:(NSNotification *)aNotification
{
    [data setCurrentTime:0.0];
    [timelineTracksView scrollPoint:NSMakePoint([data timeToX:0.0], timelineTracksScrollView.documentVisibleRect.origin.y)];
    [timelineTracksView setNeedsDisplay:YES];
}

- (void)playButtonPress:(NSNotification *)aNotification
{
    if(playTimer)
    {
        [playTimer invalidate];
        playTimer = nil;
        [data setCurrentSequenceIsPlaying:NO];
        [timelineTracksView setNeedsDisplay:YES];
    }
    else
    {
        playTimer = [NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(playTimerFire:) userInfo:nil repeats:YES];
        playButtonStartDate = [NSDate date];
        playButtonStartTime = [data currentTime];
        [data setCurrentSequenceIsPlaying:YES];
    }
}

- (void)currentTimeChange:(NSNotification *)aNotification
{
    // Current time changed externally while where sending time updates based on the timer. We need to change some things to continue functioning
    if(playTimer && (int)([data currentTime] * 1000) != (int)(newTimeForPlayTimer * 1000))
    {
        playButtonStartDate = [NSDate date];
        playButtonStartTime = [data currentTime];
        [data setCurrentSequenceIsPlaying:NO];
        [data setCurrentSequenceIsPlaying:YES];
    }
}

- (void)resetScrollPoint:(NSNotification *)aNotification
{
    [self performSelector:@selector(scrollToZero) withObject:nil afterDelay:0.25];
}

- (void)scrollToZero
{
    [timelineTracksView scrollPoint:NSMakePoint(0, 9999)];
}

- (void)playTimerFire:(NSTimer *)theTimer
{
    float timeDifference = [[NSDate date] timeIntervalSinceDate:playButtonStartDate];
    newTimeForPlayTimer = playButtonStartTime + timeDifference;
    [data setCurrentTime:newTimeForPlayTimer];
    [timelineTracksView scrollPoint:NSMakePoint([data timeToX:newTimeForPlayTimer] - timelineTracksView.superview.frame.size.width / 2, timelineTracksScrollView.documentVisibleRect.origin.y)];
    [timelineTracksView setNeedsDisplay:YES];
}

@end
