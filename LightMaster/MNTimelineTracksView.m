//
//  MNTimelineTracksView.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNTimelineTracksView.h"
#import "MNTimelineTrackHeadersView.h"

@interface MNTimelineTracksView()

// Helper Drawing methods
- (void)drawRect:(NSRect)aRect withCornerRadius:(float)radius fillColor:(NSColor *)color andStroke:(BOOL)yesOrNo;
- (void)drawBackgroundTrackAtTrackIndex:(int)trackIndex tracksTall:(int)tracksTall;
- (void)drawTimelineBar;
- (void)drawInvertedTriangleAndLineWithTipPoint:(NSPoint)point width:(int)width andHeight:(int)height;
- (void)drawChannelGuidlinesForParentIndex:(int)parentFilePathIndex parentIsControlBox:(BOOL)parentIsControlBox atTrackIndex:(int)trackIndex tracksTall:(int)tracksTall;

// Audio analysis drawing methods
- (void)drawSectionsForAudioAnalysis:(NSDictionary *)audioAnalysis;
- (void)drawBarsForAudioAnalysis:(NSDictionary *)audioAnalysis;
- (void)drawBeatsForAudioAnalysis:(NSDictionary *)audioAnalysis;
- (void)drawTatumsForAudioAnalysis:(NSDictionary *)audioAnalysis;
- (void)drawSegmentsForAudioAnalysis:(NSDictionary *)audioAnalysis;

// Data Drawing Methods
- (void)drawAudioClipsAtTrackIndex:(int)trackIndex tracksTall:(int)tracksTall;
- (void)drawCommandClustersAtTrackIndex:(int)trackIndex tracksTall:(int)tracksTall parentIndex:(int)parentIndex parentIsControlBox:(BOOL)isControlBox;
- (void)drawCommandsForCommandCluster:(NSMutableDictionary *)commandCluster atTrackIndex:(int)trackIndex tracksTall:(int)tracksTall forControlBoxOrChannelGroup:(int)boxOrChannelGroup;

// Math Methods
- (void)updateTimeAtLeftEdgeOfTimelineView:(NSTimer*)theTimer;
- (float)roundUpNumber:(float)numberToRound toNearestMultipleOfNumber:(float)multiple;
- (int)controlBoxIndexForTrackIndex:(int)trackIndex;

// Mouse Checking Methods
- (void)timelineBarMouseChecking;
- (void)handleEmptySpaceMouseAction;
- (void)checkCommandClusterForCommandMouseEvent:(NSMutableDictionary *)commandCluster atTrackIndex:(int)trackIndex tracksTall:(int)tracksTall forControlBoxOrChannelGroup:(int)boxOrChannelGroup;

@end


@implementation MNTimelineTracksView

#pragma mark - System methods

- (void)setSelectedCommandClusterIndex:(int)newSelectedCommandClusterIndex
{
    selectedCommandClusterIndex = newSelectedCommandClusterIndex;
    data.mostRecentlySelectedCommandClusterIndex = selectedCommandClusterIndex;
}

- (int)selectedCommandClusterIndex
{
    return selectedCommandClusterIndex;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if(self = [super initWithCoder:aDecoder])
    {
        // Custom initialization code here
        clusterBackgroundImage = [NSImage imageNamed:@"CommandClusterBackground.tiff"];
        topBarBackgroundImage = [NSImage imageNamed:@"Toolbar.tiff"];
        
        // Register for the notifications on the scrollView
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(synchronizedViewContentBoundsDidChange:) name:NSViewBoundsDidChangeNotification object:[self superview]];
        
        audioClipNSSounds = [[NSMutableArray alloc] init];
        
        mouseDraggingEventObjectIndex = -1;
        selectedCommandIndex = -1;
        commandClusterIndexForSelectedCommand = -1;
    }
    
    return self;
}

- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification
{
    NSClipView *changedScrollView = [notification object];
    
    scrollViewOrigin = [changedScrollView documentVisibleRect].origin;
    scrollViewVisibleSize = [changedScrollView documentVisibleRect].size;
    [data setTimeAtLeftEdgeOfTimelineView:(scrollViewOrigin.x / [data zoomLevel] / PIXEL_TO_ZOOM_RATIO)];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor colorWithPatternImage:[NSImage imageNamed:@"TimelineTrackBackgroundImage.png"]] set];
    NSRectFill(self.bounds);
    
    int trackItemsCount = [data trackItemsCount];
    int frameHeight = 0;
    int frameWidth = [data timeToX:[data endTimeForSequence:[data currentSequence]]];
    // Set the Frame
    if(trackItemsCount * TRACK_ITEM_HEIGHT + TOP_BAR_HEIGHT > [[self superview] frame].size.height)
    {
        frameHeight = trackItemsCount * TRACK_ITEM_HEIGHT + TOP_BAR_HEIGHT;
    }
    else
    {
        frameHeight = [[self superview] frame].size.height;
    }
    if(frameWidth <= [[self superview] frame].size.width)
    {
        frameWidth = [[self superview] frame].size.width;
    }
    [self setFrame:NSMakeRect(0.0, 0.0, frameWidth, frameHeight)];
    
    // Check for timelineBar mouse clicks
    [self timelineBarMouseChecking];
    
    highlightedACluster = NO;
    int trackIndex = 0;
    int tracksTall = 0;
    int i = 0;
    // Draw the audio track
    if([data audioClipFilePathsCountForSequence:[data currentSequence]] > 0)
    {
        tracksTall = [data audioClipFilePathsCountForSequence:[data currentSequence]];
        [self drawBackgroundTrackAtTrackIndex:trackIndex tracksTall:tracksTall];
        [self drawAudioClipsAtTrackIndex:trackIndex tracksTall:tracksTall];
        trackIndex += tracksTall;
    }
    // Draw the controlBox tracks
    for(i = 0; i < [data controlBoxFilePathsCountForSequence:[data currentSequence]]; i ++)
    {
        controlBoxTrackIndexes[i] = trackIndex;
        tracksTall = [data channelsCountForControlBox:[data controlBoxForCurrentSequenceAtIndex:i]];
        [self drawBackgroundTrackAtTrackIndex:trackIndex tracksTall:tracksTall];
        [self drawCommandClustersAtTrackIndex:trackIndex tracksTall:tracksTall parentIndex:i parentIsControlBox:YES];
        [self drawChannelGuidlinesForParentIndex:i parentIsControlBox:YES atTrackIndex:trackIndex tracksTall:tracksTall];
        trackIndex += tracksTall;
    }
    memset(controlBoxTrackIndexes + i, -1, 256);
    // Draw the channelGroup tracks
    for(i = 0; i < [data channelGroupFilePathsCountForSequence:[data currentSequence]]; i ++)
    {
        channelGroupTrackIndexes[i] = trackIndex;
        tracksTall = [data itemsCountForChannelGroup:[data channelGroupForCurrentSequenceAtIndex:i]];
        [self drawBackgroundTrackAtTrackIndex:trackIndex tracksTall:tracksTall];
        [self drawCommandClustersAtTrackIndex:trackIndex tracksTall:tracksTall parentIndex:i parentIsControlBox:NO];
        [self drawChannelGuidlinesForParentIndex:i parentIsControlBox:NO atTrackIndex:trackIndex tracksTall:tracksTall];
        trackIndex += tracksTall;
    }
    memset(channelGroupTrackIndexes + i, -1, 256);
    
    if(!highlightedACluster)
    {
        selectedCommandClusterIndex = -1;
    }
    
    // Draw the timeline on top of everything
    [self drawTimelineBar];
    
    // Draw the audio analysis data
    for(int i = 0; i < [data audioClipFilePathsCountForSequence:[data currentSequence]]; i ++)
    {
        NSDictionary *audioAnalysis = [data audioAnalysisForCurrentSequenceAtIndex:i];
        if(audioAnalysis != [NSNull null])
        {
            if(data.shouldDrawSegments)
            {
                [self drawSegmentsForAudioAnalysis:audioAnalysis];
            }
            if(data.shouldDrawTatums)
            {
                [self drawTatumsForAudioAnalysis:audioAnalysis];
            }
            if(data.shouldDrawBeats)
            {
                [self drawBeatsForAudioAnalysis:audioAnalysis];
            }
            if(data.shouldDrawBars)
            {
                [self drawBarsForAudioAnalysis:audioAnalysis];
            }
            if(data.shouldDrawSections)
            {
                [self drawSectionsForAudioAnalysis:audioAnalysis];
            }
        }
    }

    // Check for manual channel controls and new commandCluster/audioClip/channelGroup clicks
    if(mouseEvent != nil)
    {
        [self handleEmptySpaceMouseAction];
    }
}

#pragma mark - Helper Drawing Methods

- (void)drawRect:(NSRect)aRect withCornerRadius:(float)radius fillColor:(NSColor *)color andStroke:(BOOL)yesOrNo
{
    NSBezierPath *thePath = [NSBezierPath bezierPathWithRoundedRect:aRect xRadius:radius yRadius:radius];
    
	[color setFill];
    [[NSColor whiteColor] setStroke];
	
	if(yesOrNo)
    {
        [thePath stroke];
    }
	[thePath fill];
}

- (void)drawBackgroundTrackAtTrackIndex:(int)trackIndex tracksTall:(int)tracksTall
{
    // Draw the track group background
    NSRect backgroundFrame = NSMakeRect(0, self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - tracksTall * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT, self.frame.size.width, TRACK_ITEM_HEIGHT * tracksTall);
    NSSize imageSize = [clusterBackgroundImage size];
    [clusterBackgroundImage drawInRect:backgroundFrame fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
}

- (void)drawTimelineBar
{
    // Draw the Top Bar
    NSRect superViewFrame = [[self superview] frame];
    NSRect topBarFrame = NSMakeRect(0, scrollViewOrigin.y + superViewFrame.size.height - TOP_BAR_HEIGHT, self.frame.size.width, TOP_BAR_HEIGHT);
    NSSize imageSize = [topBarBackgroundImage size];
    [topBarBackgroundImage drawInRect:topBarFrame fromRect:NSMakeRect(0.0, 0.0, imageSize.width, imageSize.height) operation:NSCompositeSourceOver fraction:1.0];
    
    // Determine the grid spacing
    NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
    NSFont *font = [NSFont fontWithName:@"Helvetica" size:10];
    [attributes setObject:font forKey:NSFontAttributeName];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeMarkerDifference = 0.0;
    if(timeSpan >= 60.0)
    {
        timeMarkerDifference = 6.0;
    }
    else if(timeSpan >= 50.0)
    {
        timeMarkerDifference = 5.0;
    }
    else if(timeSpan >= 40.0)
    {
        timeMarkerDifference = 4.0;
    }
    else if(timeSpan >= 30.0)
    {
        timeMarkerDifference = 3.0;
    }
    else if(timeSpan >= 20.0)
    {
        timeMarkerDifference = 2.0;
    }
    else if(timeSpan >= 15.0)
    {
        timeMarkerDifference = 1.5;
    }
    else if(timeSpan >= 10.0)
    {
        timeMarkerDifference = 1.0;
    }
    else if(timeSpan >= 5.0)
    {
        timeMarkerDifference = 0.5;
    }
    else if(timeSpan >= 2.5)
    {
        timeMarkerDifference = 0.25;
    }
    else if(timeSpan >= 1.25)
    {
        timeMarkerDifference = 0.125;
    }
    else
    {
        timeMarkerDifference = 0.0625;
    }
    
    // Draw the grid (+ 5 extras so the user doesn't see blank areas)
    float leftEdgeNearestTimeMaker = [self roundUpNumber:[data timeAtLeftEdgeOfTimelineView] toNearestMultipleOfNumber:timeMarkerDifference];
	for(int i = 0; i < timeSpan / timeMarkerDifference + 6; i ++)
	{
        float timeMarker = (leftEdgeNearestTimeMaker - (timeMarkerDifference * 3) + i * timeMarkerDifference);
        // Draw the times
        NSString *time = [NSString stringWithFormat:@"%.02f", timeMarker];
        NSRect textFrame = NSMakeRect([data timeToX:timeMarker], topBarFrame.origin.y, 40, topBarFrame.size.height);
        [time drawInRect:textFrame withAttributes:attributes];
        
        // Draw grid lines
        if(data.shouldDrawTime)
        {
            NSRect markerLineFrame = NSMakeRect(textFrame.origin.x, scrollViewOrigin.y, 1, superViewFrame.size.height - TOP_BAR_HEIGHT);
            [[NSColor blackColor] set];
            NSRectFill(markerLineFrame);
        }
	}
    
    // Draw the currentTime marker
    NSPoint trianglePoint = NSMakePoint((float)[data timeToX:[data currentTime]], topBarFrame.origin.y);
    [self drawInvertedTriangleAndLineWithTipPoint:trianglePoint width:20 andHeight:20];
}

- (void)drawInvertedTriangleAndLineWithTipPoint:(NSPoint)point width:(int)width andHeight:(int)height
{
    NSBezierPath *triangle = [NSBezierPath bezierPath];
	
    [triangle moveToPoint:point];
    [triangle lineToPoint:NSMakePoint(point.x - width / 2,  point.y + height)];
    [triangle lineToPoint:NSMakePoint(point.x + width / 2, point.y + height)];
    [triangle closePath];
	
    // Set the color according to whether it is clicked or not
	if(!currentTimeMarkerIsSelected)
    {
        [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.5] setFill];
    }
	else
    {
        [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.5] setFill];
    }
	[triangle fill];
	[[NSColor whiteColor] setStroke];
    [triangle stroke];
    
    NSRect markerLineFrame = NSMakeRect(point.x, scrollViewOrigin.y, 1, [[self superview] frame].size.height - TOP_BAR_HEIGHT);
    [[NSColor redColor] set];
    NSRectFill(markerLineFrame);
}

- (void)drawChannelGuidlinesForParentIndex:(int)parentFilePathIndex parentIsControlBox:(BOOL)parentIsControlBox atTrackIndex:(int)trackIndex tracksTall:(int)tracksTall;
{
    for(int i = 0; i < tracksTall; i ++)
    {
        NSRect bottomOfChannelLine = NSMakeRect(0, self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - i * TRACK_ITEM_HEIGHT - TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT, self.frame.size.width, 1);
        
        NSColor *guidelineColor = [NSColor colorWithCalibratedRed:1.0 green:1.0 blue:1.0 alpha:1.0];
        [guidelineColor setFill];
        NSRectFill(bottomOfChannelLine);
        
        // Draw the channel index
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        NSFont *font = [NSFont fontWithName:@"Helvetica Bold" size:12];
        NSRect textFrame = NSMakeRect([data timeToX:[data timeAtLeftEdgeOfTimelineView]] + 3, bottomOfChannelLine.origin.y - 2, 20, TRACK_ITEM_HEIGHT);
        [attributes setObject:font forKey:NSFontAttributeName];
        [attributes setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
        
        if(parentIsControlBox)
        {
            [[NSString stringWithFormat:@"%d", [[data numberForChannel:[data channelAtIndex:i forControlBox:[data controlBoxForCurrentSequenceAtIndex:parentFilePathIndex]]] intValue]] drawInRect:textFrame withAttributes:attributes];
        }
        else
        {
            [[NSString stringWithFormat:@"%d", [data channelIndexForItemData:[data itemDataAtIndex:i forChannelGroup:[data channelGroupForCurrentSequenceAtIndex:parentFilePathIndex]]]] drawInRect:textFrame withAttributes:attributes];
        }
    }
}

#pragma mark - Audio analysis drawing methods

- (void)drawSectionsForAudioAnalysis:(NSDictionary *)audioAnalysis
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *sections = [audioAnalysis objectForKey:@"sections"];
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [sections count] && (timeAtLeftEdge - 1 >= [[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] || timeAtRightEdge + 1 <= [[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        visibleSectionIndex ++;
    }
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [sections count] && (timeAtLeftEdge - 1 < [[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] && timeAtRightEdge + 1 > [[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        // Draw grid lines
        NSRect markerLineFrame = NSMakeRect([data timeToX:[[[sections objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]], scrollViewOrigin.y, 3, superViewFrame.size.height - TOP_BAR_HEIGHT);
        [[NSColor yellowColor] set];
        NSRectFill(markerLineFrame);
        
        visibleSectionIndex ++;
    }
}

- (void)drawBarsForAudioAnalysis:(NSDictionary *)audioAnalysis
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *bars = [audioAnalysis objectForKey:@"bars"];
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [bars count] && (timeAtLeftEdge - 1 >= [[[bars objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] || timeAtRightEdge + 1 <= [[[bars objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        visibleSectionIndex ++;
    }
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [bars count] && (timeAtLeftEdge - 1 < [[[bars objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] && timeAtRightEdge + 1 > [[[bars objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        // Draw grid lines
        NSRect markerLineFrame = NSMakeRect([data timeToX:[[[bars objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]], scrollViewOrigin.y, 2, superViewFrame.size.height - TOP_BAR_HEIGHT);
        [[NSColor orangeColor] set];
        NSRectFill(markerLineFrame);
        
        visibleSectionIndex ++;
    }
}

- (void)drawBeatsForAudioAnalysis:(NSDictionary *)audioAnalysis
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *beats = [audioAnalysis objectForKey:@"beats"];
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [beats count] && (timeAtLeftEdge - 1 >= [[[beats objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] || timeAtRightEdge + 1 <= [[[beats objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        visibleSectionIndex ++;
    }
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [beats count] && (timeAtLeftEdge - 1 < [[[beats objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] && timeAtRightEdge + 1 > [[[beats objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        // Draw grid lines
        NSRect markerLineFrame = NSMakeRect([data timeToX:[[[beats objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]], scrollViewOrigin.y, 1, superViewFrame.size.height - TOP_BAR_HEIGHT);
        [[NSColor whiteColor] set];
        NSRectFill(markerLineFrame);
        
        visibleSectionIndex ++;
    }
}

- (void)drawTatumsForAudioAnalysis:(NSDictionary *)audioAnalysis
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *tatums = [audioAnalysis objectForKey:@"tatums"];
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [tatums count] && (timeAtLeftEdge - 1 >= [[[tatums objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] || timeAtRightEdge + 1 <= [[[tatums objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        visibleSectionIndex ++;
    }
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [tatums count] && (timeAtLeftEdge - 1 < [[[tatums objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] && timeAtRightEdge + 1 > [[[tatums objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        // Draw grid lines
        NSRect markerLineFrame = NSMakeRect([data timeToX:[[[tatums objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]], scrollViewOrigin.y, 1, superViewFrame.size.height - TOP_BAR_HEIGHT);
        [[NSColor cyanColor] set];
        NSRectFill(markerLineFrame);
        
        visibleSectionIndex ++;
    }
}

- (void)drawSegmentsForAudioAnalysis:(NSDictionary *)audioAnalysis
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    int visibleSectionIndex = 0;
    NSArray *segments = [audioAnalysis objectForKey:@"segments"];
    // Find the first visible section (since the data is sorted)
    while(visibleSectionIndex < [segments count] && (timeAtLeftEdge - 1 >= [[[segments objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] || timeAtRightEdge + 1 <= [[[segments objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        visibleSectionIndex ++;
    }
    
    // Now draw the visible sections (since the data is sorted)
    while(visibleSectionIndex < [segments count] && (timeAtLeftEdge - 1 < [[[segments objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue] && timeAtRightEdge + 1 > [[[segments objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]))
    {
        // Draw grid lines
        NSRect markerLineFrame = NSMakeRect([data timeToX:[[[segments objectAtIndex:visibleSectionIndex] objectForKey:@"start"] floatValue]], scrollViewOrigin.y, 1, superViewFrame.size.height - TOP_BAR_HEIGHT);
        [[NSColor magentaColor] set];
        NSRectFill(markerLineFrame);
        
        visibleSectionIndex ++;
    }
}

#pragma mark - Data Drawing Methods

- (void)drawAudioClipsAtTrackIndex:(int)trackIndex tracksTall:(int)tracksTall
{
    tracksTall = 1;
    
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    for(int i = 0; i < [data audioClipFilePathsCountForSequence:[data currentSequence]]; i ++)
    {
        NSMutableDictionary *currentAudioClip = [data audioClipForCurrentSequenceAtIndex:i];
        
        // Check to see if this audioClip is in the visible range
        if(([data startTimeForAudioClip:currentAudioClip] > timeAtLeftEdge && [data startTimeForAudioClip:currentAudioClip] < timeAtRightEdge) || ([data endTimeForAudioClip:currentAudioClip] > timeAtLeftEdge && [data endTimeForAudioClip:currentAudioClip] < timeAtRightEdge) || ([data startTimeForAudioClip:currentAudioClip] <= timeAtLeftEdge && [data endTimeForAudioClip:currentAudioClip] >= timeAtRightEdge))
        {
            NSRect audioClipRect = NSMakeRect([data timeToX:[data startTimeForAudioClip:currentAudioClip]], self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - tracksTall * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1, [data widthForTimeInterval:[data endTimeForAudioClip:currentAudioClip] - [data startTimeForAudioClip:currentAudioClip]], TRACK_ITEM_HEIGHT - 2);
            
            // AudioClip Mouse Checking here
            if(mouseEvent != nil && ((mouseAction == MNMouseDown && [[NSBezierPath bezierPathWithRect:audioClipRect] containsPoint:currentMousePoint]) || (mouseAction == MNMouseDragged && ((mouseDraggingEvent == MNMouseDragNotInUse && [[NSBezierPath bezierPathWithRect:audioClipRect] containsPoint:currentMousePoint]) || mouseDraggingEvent == MNAudioClipMouseDrag) && (mouseDraggingEventObjectIndex == -1 || mouseDraggingEventObjectIndex == i))))
            {
                [self drawRect:audioClipRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
                
                if(mouseAction == MNMouseDown)
                {
                    selectedAudioClip = currentAudioClip;
                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:[data startTimeForAudioClip:currentAudioClip]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectAudioClip" object:selectedAudioClip];
                }
                else if(mouseAction == MNMouseDragged)
                {
                    mouseDraggingEvent = MNAudioClipMouseDrag;
                    mouseDraggingEventObjectIndex = i;
                    [data moveAudioClip:currentAudioClip toStartTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x]];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
                }
                
                mouseEvent = nil;
            }
            else
            {
                [self drawRect:audioClipRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.7] andStroke:YES];
                selectedAudioClip = nil;
            }
        }
        
        trackIndex++;
    }
}

- (void)drawCommandClustersAtTrackIndex:(int)trackIndex tracksTall:(int)tracksTall parentIndex:(int)parentIndex parentIsControlBox:(BOOL)isControlBox
{
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    for(int i = 0; i < [data commandClusterFilePathsCountForSequence:[data currentSequence]]; i ++)
    {
        NSMutableDictionary *currentCommandCluster = [data commandClusterForCurrentSequenceAtIndex:i];
        float startTime = [data startTimeForCommandCluster:currentCommandCluster];
        float endTime = [data endTimeForCommandCluster:currentCommandCluster];
        
        // Command Cluster is for this controlBox/channelGroup
        if((isControlBox ? [[data controlBoxFilePathForCommandCluster:currentCommandCluster] isEqualToString:[data controlBoxFilePathAtIndex:parentIndex forSequence:[data currentSequence]]] : [[data channelGroupFilePathForCommandCluster:currentCommandCluster] isEqualToString:[data channelGroupFilePathAtIndex:parentIndex forSequence:[data currentSequence]]]))
        {
            // Check to see if this commandCluster is in the visible range
            if((startTime > timeAtLeftEdge && startTime < timeAtRightEdge) || (endTime > timeAtLeftEdge && endTime < timeAtRightEdge) || (startTime <= timeAtLeftEdge && endTime >= timeAtRightEdge))
            {
                NSRect commandClusterRect = NSMakeRect([data timeToX:startTime], self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - tracksTall * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1, [data widthForTimeInterval:endTime - startTime], TRACK_ITEM_HEIGHT * tracksTall - 2);
                
                // There is a mouse event within the bounds of the commandCluster
                if(mouseEvent != nil && ([[NSBezierPath bezierPathWithRect:commandClusterRect] containsPoint:currentMousePoint] || ((mouseDraggingEvent == MNControlBoxCommandClusterMouseDrag || mouseDraggingEvent == MNControlBoxCommandClusterMouseDragStartTime || mouseDraggingEvent == MNControlBoxCommandClusterMouseDragEndTime || mouseDraggingEvent == MNControlBoxCommandClusterMouseDragBetweenChannels) && (mouseDraggingEventObjectIndex == -1 || mouseDraggingEventObjectIndex == i))))
                {
                    // Check the commands for mouse down clicks
                    [self checkCommandClusterForCommandMouseEvent:currentCommandCluster atTrackIndex:trackIndex tracksTall:tracksTall forControlBoxOrChannelGroup:MNChannelGroup];
                    
                    // Check for new command clicks
                    if(mouseEvent != nil && mouseAction == MNMouseDown && mouseEvent.modifierFlags & NSCommandKeyMask)
                    {
                        int channelIndex = (self.frame.size.height - currentMousePoint.y - (trackIndex * TRACK_ITEM_HEIGHT + TOP_BAR_HEIGHT + 1)) / TRACK_ITEM_HEIGHT;
                        float time = [data xToTime:currentMousePoint.x];
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"AddCommandAtChannelIndexAndTimeForCommandCluster" object:nil userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:channelIndex], [NSNumber numberWithFloat:time], currentCommandCluster, nil] forKeys:[NSArray arrayWithObjects:@"channelIndex", @"startTime", @"commandCluster", nil]]];
                        int newCommandIndex = [data commandsCountForCommandCluster:currentCommandCluster] - 1;
                        
                        mouseDraggingEvent = MNCommandMouseDragEndTime;
                        mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:[data endTimeForCommand:[data commandAtIndex:newCommandIndex fromCommandCluster:currentCommandCluster]]];
                        
                        selectedCommandIndex = newCommandIndex;
                        commandClusterIndexForSelectedCommand = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:currentCommandCluster]];
                        
                        mouseEvent = nil;
                    }
                    
                    // If a command didn't capture the mouse event, the commandCluster uses it
                    if(mouseEvent != nil)
                    {
                        // Cluster Mouse Checking Here
                        if(mouseAction == MNMouseDown)
                        {
                            // Duplicate a cluster if it's 'option clicked'
                            if(mouseEvent.modifierFlags & NSAlternateKeyMask)
                            {
                                NSString *newCommandClusterFilePath = [data createCopyOfCommandClusterAndReturnFilePath:currentCommandCluster];
                                [data addCommandClusterFilePath:newCommandClusterFilePath forSequence:[data currentSequence]];
                                
                                if(mouseEvent.modifierFlags & NSControlKeyMask)
                                {
                                    mouseDraggingEvent = MNControlBoxCommandClusterMouseDragBetweenChannels;
                                }
                                else
                                {
                                    mouseDraggingEvent = MNControlBoxCommandClusterMouseDrag;
                                }
                                mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                                self.selectedCommandClusterIndex = (int)[data commandClusterFilePathsCountForSequence:[data currentSequence]] - 1;
                                highlightedACluster = YES; // Trick the system
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibrariesViewController" object:nil];
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommandCluster" object:[data commandClusterFromFilePath:newCommandClusterFilePath]];
                            }
                            else if(mouseEvent.modifierFlags & NSControlKeyMask)
                            {
                                mouseDraggingEvent = MNControlBoxCommandClusterMouseDragBetweenChannels;
                                mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                                
                                self.selectedCommandClusterIndex = i;
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommandCluster" object:currentCommandCluster];
                            }
                            // Select a cluster
                            else
                            {
                                // Adjust start time
                                if(currentMousePoint.x <= commandClusterRect.origin.x + TIME_ADJUST_PIXEL_BUFFER)
                                {
                                    mouseDraggingEvent = MNControlBoxCommandClusterMouseDragStartTime;
                                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                                }
                                // Adjust the end time
                                else if(currentMousePoint.x >= commandClusterRect.origin.x + commandClusterRect.size.width - TIME_ADJUST_PIXEL_BUFFER)
                                {
                                    mouseDraggingEvent = MNControlBoxCommandClusterMouseDragEndTime;
                                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:endTime];
                                }
                                // Just select the cluster
                                else
                                {
                                    mouseDraggingEvent = MNControlBoxCommandClusterMouseDrag;
                                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                                }
                                
                                self.selectedCommandClusterIndex = i;
                                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommandCluster" object:currentCommandCluster];
                            }
                            
                            mouseEvent = nil;
                        }
                        // Dragging of clusters
                        else if(mouseAction == MNMouseDragged && i == selectedCommandClusterIndex)
                        {
                            // Drag the start Time
                            if(mouseDraggingEvent == MNControlBoxCommandClusterMouseDragStartTime)
                            {
                                [data setStartTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x] forCommandCluster:currentCommandCluster];
                            }
                            // Drag the end time
                            else if(mouseDraggingEvent == MNControlBoxCommandClusterMouseDragEndTime)
                            {
                                [data setEndTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x] forCommandcluster:currentCommandCluster];
                            }
                            // Drag the entire cluster
                            else if(mouseDraggingEvent == MNControlBoxCommandClusterMouseDrag)
                            {
                                // Drag the cluster
                                [data moveCommandCluster:currentCommandCluster toStartTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x]];
                                
                                // Mouse drag is moving the cluster to a different controlBox
                                if(currentMousePoint.y > commandClusterRect.origin.y + commandClusterRect.size.height || currentMousePoint.y < commandClusterRect.origin.y)
                                {
                                    int newTrackIndex = (self.frame.size.height - currentMousePoint.y - TOP_BAR_HEIGHT) / TRACK_ITEM_HEIGHT;
                                    int newIndex = [self controlBoxIndexForTrackIndex:newTrackIndex];
                                    //NSLog(@"newI:%d mouseY:%f newTrackIndex:%d trackIndex:%d", newIndex, self.frame.size.height - currentMousePoint.y - TOP_BAR_HEIGHT, newTrackIndex, trackIndex);
                                    [data setControlBoxFilePath:[data controlBoxFilePathAtIndex:newIndex forSequence:[data currentSequence]] forCommandCluster:currentCommandCluster];
                                }
                            }
                            else if(mouseDraggingEvent == MNControlBoxCommandClusterMouseDragBetweenChannels)
                            {
                                // Mouse drag is moving the cluster to a different controlBox
                                if(currentMousePoint.y > commandClusterRect.origin.y + commandClusterRect.size.height || currentMousePoint.y < commandClusterRect.origin.y)
                                {
                                    int newTrackIndex = (self.frame.size.height - currentMousePoint.y - TOP_BAR_HEIGHT) / TRACK_ITEM_HEIGHT;
                                    int newIndex = [self controlBoxIndexForTrackIndex:newTrackIndex];
                                    [data setControlBoxFilePath:[data controlBoxFilePathAtIndex:newIndex forSequence:[data currentSequence]] forCommandCluster:currentCommandCluster];
                                }
                            }
                            
                            mouseDraggingEventObjectIndex = i;
                            self.selectedCommandClusterIndex = i;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
                            
                            mouseEvent = nil;
                        }
                        // Mouse up
                        else if(i == selectedCommandClusterIndex)
                        {
                            selectedCommandClusterIndex = -1;
                            
                            mouseEvent = nil;
                        }
                        
                        // Draw this cluster as selected
                        if(i == selectedCommandClusterIndex)
                        {
                            [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
                            highlightedACluster = YES;
                        }
                        // Else just draw normally
                        else
                        {
                            [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.2 green:0.4 blue:0.2 alpha:0.7] andStroke:YES];
                        }
                    }
                    // Else just draw normally
                    else
                    {
                        [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.2 green:0.4 blue:0.2 alpha:0.7] andStroke:YES];
                    }
                }
                // No mouse events within the bounds of this cluster. Just draw everything normally
                else
                {
                    // Check the commands for mouse down clicks
                    [self checkCommandClusterForCommandMouseEvent:currentCommandCluster atTrackIndex:trackIndex tracksTall:tracksTall forControlBoxOrChannelGroup:MNChannelGroup];
                    
                    // Draw this cluster
                    [self drawRect:commandClusterRect withCornerRadius:CLUSTER_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.2 green:0.4 blue:0.2 alpha:0.7] andStroke:YES];
                }
                
                // Draw the commands for this cluster
                [self drawCommandsForCommandCluster:currentCommandCluster atTrackIndex:trackIndex tracksTall:tracksTall forControlBoxOrChannelGroup:MNControlBox];
            }
        }
    }
}

- (void)drawCommandsForCommandCluster:(NSMutableDictionary *)commandCluster atTrackIndex:(int)trackIndex tracksTall:(int)tracksTall forControlBoxOrChannelGroup:(int)boxOrChannelGroup
{
    tracksTall = 1;
    int startingTrackIndex = trackIndex;
    int commandClusterIndex = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]];
    
    NSRect superViewFrame = [[self superview] frame];
    float timeSpan = [data xToTime:[data timeToX:[data timeAtLeftEdgeOfTimelineView]] + superViewFrame.size.width] - [data timeAtLeftEdgeOfTimelineView];
    float timeAtLeftEdge = [data timeAtLeftEdgeOfTimelineView];
    float timeAtRightEdge = timeAtLeftEdge + timeSpan;
    
    for(int i = 0; i < [data commandsCountForCommandCluster:commandCluster]; i ++)
    {
        NSMutableDictionary *currentCommand = [data commandAtIndex:i fromCommandCluster:commandCluster];
        trackIndex = [data channelIndexForCommand:currentCommand] + startingTrackIndex;
        float startTime = [data startTimeForCommand:currentCommand];
        float endTime = [data endTimeForCommand:currentCommand];
        
        // Check to see if this commandCluster is in the visible range
        if((startTime > timeAtLeftEdge && startTime < timeAtRightEdge) || (endTime > timeAtLeftEdge && endTime < timeAtRightEdge) || (startTime <= timeAtLeftEdge && endTime >= timeAtRightEdge))
        {
            NSRect commandRect;
            float x, y, width , height;
            x  = [data timeToX:startTime];
            y = self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - tracksTall * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1;
            width = [data widthForTimeInterval:endTime - startTime];
            height = TRACK_ITEM_HEIGHT - 2;
            
            // Command extends over the end of it's parent cluster, bind it to the end of the parent cluster
            if(endTime > [data endTimeForCommandCluster:commandCluster])
            {
                width = [data widthForTimeInterval:[data endTimeForCommandCluster:commandCluster] - startTime];
            }
            // Command extends over the beggining of it's parent cluster, bind it to the beginning of the parent cluster
            else if(startTime < [data startTimeForCommandCluster:commandCluster])
            {
                x = [data timeToX:[data startTimeForCommandCluster:commandCluster]];
                width = [data widthForTimeInterval:endTime - [data xToTime:x]];
            }
            commandRect = NSMakeRect(x, y, width, height);
            
            // Draw the command
            if(selectedCommandIndex == i && commandClusterIndexForSelectedCommand == commandClusterIndex)
            {
                [self drawRect:commandRect withCornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.7] andStroke:YES];
            }
            else
            {
                [self drawRect:commandRect withCornerRadius:COMMAND_CORNER_RADIUS fillColor:[NSColor colorWithDeviceRed:0.3 green:1.0 blue:0.3 alpha:0.7] andStroke:YES];
            }
        }
    }
}

#pragma mark - Math Methods

- (void)updateTimeAtLeftEdgeOfTimelineView:(NSTimer *)theTimer;
{
    if(mouseEvent)
    {
        BOOL didAutoscroll = [[self superview] autoscroll:mouseEvent];
        if(didAutoscroll)
        {
            [data setCurrentTime:[data xToTime:[data currentTime] + mouseEvent.deltaX]];
            [self setNeedsDisplay:YES];
        }
    }
}

- (float)roundUpNumber:(float)numberToRound toNearestMultipleOfNumber:(float)multiple
{
    // Only works to the nearest thousandth
    int intNumberToRound = (int)(numberToRound * 1000000);
    int intMultiple = (int)(multiple * 1000000);
    
    if(multiple == 0)
    {
        return intNumberToRound / 1000000;
    }
    
    int remainder = intNumberToRound % intMultiple;
    if(remainder == 0)
    {
        return intNumberToRound / 1000000;
    }
    
    return (intNumberToRound + intMultiple - remainder) / 1000000.0;
}

- (int)controlBoxIndexForTrackIndex:(int)trackIndex
{
    int controlBoxIndex = -1;
    int i = 0;
    
    while(controlBoxIndex == -1 && controlBoxTrackIndexes[i] >= 0)
    {
        if(trackIndex >= controlBoxTrackIndexes[i] && (trackIndex < controlBoxTrackIndexes[i + 1] || controlBoxTrackIndexes[i + 1] == -1))
        {
            controlBoxIndex = i;
        }
        
        i ++;
    }
    
    return controlBoxIndex;
}

#pragma mark - Mouse Checking Methods

- (void)timelineBarMouseChecking
{
    // Draw the Top Bar
    NSRect superViewFrame = [[self superview] frame];
    NSRect topBarFrame = NSMakeRect(0, scrollViewOrigin.y + superViewFrame.size.height - TOP_BAR_HEIGHT, self.frame.size.width, TOP_BAR_HEIGHT);
    
    NSPoint trianglePoint = NSMakePoint((float)[data timeToX:[data currentTime]], topBarFrame.origin.y);
    float width = 20;
    float height = 20;
    
    NSBezierPath *triangle = [NSBezierPath bezierPath];
	
    [triangle moveToPoint:trianglePoint];
    [triangle lineToPoint:NSMakePoint(trianglePoint.x - width / 2,  trianglePoint.y + height)];
    [triangle lineToPoint:NSMakePoint(trianglePoint.x + width / 2, trianglePoint.y + height)];
    [triangle closePath];
    
    // CurrentTime Marker Mouse checking
    if([triangle containsPoint:currentMousePoint] && mouseAction == MNMouseDown && mouseEvent != nil)
    {
        currentTimeMarkerIsSelected = YES;
        mouseEvent = nil;
    }
    else if(currentTimeMarkerIsSelected && mouseAction == MNMouseUp && mouseEvent != nil)
    {
        currentTimeMarkerIsSelected = NO;
        mouseEvent = nil;
    }
    
    // Mouse Checking
    if(mouseAction == MNMouseDragged && (mouseDraggingEvent == MNMouseDragNotInUse || mouseDraggingEvent == MNTimeMarkerMouseDrag) && currentTimeMarkerIsSelected && mouseEvent != nil)
    {
        mouseDraggingEvent = MNTimeMarkerMouseDrag;
        mouseDraggingEventObjectIndex = -1;
        float newCurrentTime = [data xToTime:currentMousePoint.x];
        
        // Bind the minimum time to 0
        if(newCurrentTime < 0.0)
        {
            newCurrentTime = 0.0;
        }
        
        // Move the cursor to the new position
        [data setCurrentTime:newCurrentTime];
    }
    
    // TopBar Mouse Checking
    if([[NSBezierPath bezierPathWithRect:topBarFrame] containsPoint:currentMousePoint] && mouseAction == MNMouseDown && mouseEvent != nil && !currentTimeMarkerIsSelected)
    {
        [data setCurrentTime:[data xToTime:currentMousePoint.x]];
        mouseEvent = nil;
    }
}

- (void)handleEmptySpaceMouseAction
{
    // Check for new command clicks
    if(mouseEvent != nil && mouseAction == MNMouseDown && mouseEvent.modifierFlags & NSCommandKeyMask)
    {
        BOOL clusterWasCreated = NO;
        int trackIndex = 0;
        int tracksTall = 0;
        // Calculate the audio track
        if([data audioClipFilePathsCountForSequence:[data currentSequence]] > 0)
        {
            tracksTall = [data audioClipFilePathsCountForSequence:[data currentSequence]];
            trackIndex += tracksTall;
        }
        // Calculate the controlBox tracks
        for(int i = 0; (i < [data controlBoxFilePathsCountForSequence:[data currentSequence]] && clusterWasCreated == NO); i ++)
        {
            tracksTall = [data channelsCountForControlBox:[data controlBoxForCurrentSequenceAtIndex:i]];
            
            // Detemine the rect
            NSRect trackGroupRect = NSMakeRect(0, self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - tracksTall * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT, self.frame.size.width, TRACK_ITEM_HEIGHT * tracksTall);
            
            // Check for the mouse point within the trackGroupRect
            if([[NSBezierPath bezierPathWithRect:trackGroupRect] containsPoint:currentMousePoint])
            {
                clusterWasCreated = YES;
                
                // Create the new cluster
                float time = [data xToTime:currentMousePoint.x];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AddCommandClusterForControlBoxFilePathAndStartTime" object:nil userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[data controlBoxFilePathAtIndex:i forSequence:[data currentSequence]], [NSNumber numberWithFloat:time], nil] forKeys:[NSArray arrayWithObjects:@"controlBoxFilePath", @"startTime", nil]]];
                
                // Select it for end time dragging
                mouseDraggingEvent = MNControlBoxCommandClusterMouseDragEndTime;
                mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:time];
                self.selectedCommandClusterIndex = [data commandClusterFilePathsCountForSequence:[data currentSequence]] - 1;

                mouseEvent = nil;
            }
        
            trackIndex += tracksTall;
        }
        // Calculate the channelGroup tracks
        for(int i = 0; (i < [data channelGroupFilePathsCountForSequence:[data currentSequence]] && clusterWasCreated == NO); i ++)
        {
            tracksTall = [data itemsCountForChannelGroup:[data channelGroupForCurrentSequenceAtIndex:i]];
            
            // Detemine the rect
            NSRect trackGroupRect = NSMakeRect(0, self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - tracksTall * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT, self.frame.size.width, TRACK_ITEM_HEIGHT * tracksTall);
            
            // Check for the mouse point within the trackGroupRect
            if([[NSBezierPath bezierPathWithRect:trackGroupRect] containsPoint:currentMousePoint])
            {
                clusterWasCreated = YES;
                
                // Create the new cluster
                float time = [data xToTime:currentMousePoint.x];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"AddCommandClusterForChannelGroupFilePathAndStartTime" object:nil userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[data channelGroupFilePathAtIndex:i forSequence:[data currentSequence]], [NSNumber numberWithFloat:time], nil] forKeys:[NSArray arrayWithObjects:@"channelGroupFilePath", @"startTime", nil]]];
                
                // Select it for end time dragging
                mouseDraggingEvent = MNControlBoxCommandClusterMouseDragEndTime;
                mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:time];
                self.selectedCommandClusterIndex = [data commandClusterFilePathsCountForSequence:[data currentSequence]] - 1;
                mouseEvent = nil;
            }
            
            trackIndex += tracksTall;
        }
    }
}

- (void)checkCommandClusterForCommandMouseEvent:(NSMutableDictionary *)commandCluster atTrackIndex:(int)trackIndex tracksTall:(int)tracksTall forControlBoxOrChannelGroup:(int)boxOrChannelGroup
{
    tracksTall = 1;
    int startingTrackIndex = trackIndex;
    
    for(int i = 0; i < [data commandsCountForCommandCluster:commandCluster]; i ++)
    {
        NSMutableDictionary *currentCommand = [data commandAtIndex:i fromCommandCluster:commandCluster];
        trackIndex = [data channelIndexForCommand:currentCommand] + startingTrackIndex;
        float startTime = [data startTimeForCommand:currentCommand];
        float endTime = [data endTimeForCommand:currentCommand];
        
        NSRect commandRect;
        float x, y, width , height;
        x  = [data timeToX:startTime];
        y = self.frame.size.height - trackIndex * TRACK_ITEM_HEIGHT - tracksTall * TRACK_ITEM_HEIGHT - TOP_BAR_HEIGHT + 1;
        width = [data widthForTimeInterval:endTime - startTime];
        height = TRACK_ITEM_HEIGHT - 2;
        
        // Command extends over the end of it's parent cluster, bind it to the end of the parent cluster
        if(endTime > [data endTimeForCommandCluster:commandCluster])
        {
            width = [data widthForTimeInterval:[data endTimeForCommandCluster:commandCluster] - startTime];
        }
        // Command extends over the beggining of it's parent cluster, bind it to the beginning of the parent cluster
        else if(startTime < [data startTimeForCommandCluster:commandCluster])
        {
            x = [data timeToX:[data startTimeForCommandCluster:commandCluster]];
        }
        commandRect = NSMakeRect(x, y, width, height);
        
        // Command Mouse Checking Here
        if(mouseEvent != nil && (mouseAction == MNMouseDown && [[NSBezierPath bezierPathWithRect:commandRect] containsPoint:currentMousePoint]))
        {
            // Delete a command if it's 'command clicked'
            if(mouseEvent.modifierFlags & NSCommandKeyMask)
            {
                [data removeCommand:currentCommand fromCommandCluster:commandCluster];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
            }
            // Duplicate a command if it's 'option clicked'
            else if(mouseEvent.modifierFlags & NSAlternateKeyMask)
            {
                int newCommandIndex = [data createCommandAndReturnNewCommandIndexForCommandCluster:commandCluster];
                [data setStartTime:startTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
                [data setEndTime:endTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
                [data setChannelIndex:[data channelIndexForCommand:currentCommand] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
                [data setBrightness:[data brightnessForCommand:currentCommand] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
                
                if(mouseEvent.modifierFlags & NSControlKeyMask)
                {
                    mouseDraggingEvent = MNCommandMouseDragBetweenChannels;
                }
                else
                {
                    mouseDraggingEvent = MNCommandMouseDrag;
                }
                mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:[data startTimeForCommand:[data commandAtIndex:newCommandIndex fromCommandCluster:commandCluster]]];
                
                selectedCommandIndex = newCommandIndex;
                commandClusterIndexForSelectedCommand = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommand" object:[NSArray arrayWithObjects:[NSNumber numberWithInt:selectedCommandIndex], [data filePathForCommandCluster:commandCluster], nil]];
            }
            // Select a command and lock the start/end times
            else if(mouseEvent.modifierFlags & NSControlKeyMask)
            {
                mouseDraggingEvent = MNCommandMouseDragBetweenChannels;
                mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                
                selectedCommandIndex = i;
                commandClusterIndexForSelectedCommand = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommand" object:[NSArray arrayWithObjects:[NSNumber numberWithInt:selectedCommandIndex], [data filePathForCommandCluster:commandCluster], nil]];
            }
            // Select a command
            else
            {
                // Adjust start time
                if(currentMousePoint.x <= x + TIME_ADJUST_PIXEL_BUFFER)
                {
                    mouseDraggingEvent = MNCommandMouseDragStartTime;
                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                }
                // Adjust the end time
                else if(currentMousePoint.x >= x + width - TIME_ADJUST_PIXEL_BUFFER)
                {
                    mouseDraggingEvent = MNCommandMouseDragEndTime;
                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:endTime];
                }
                else
                {
                    mouseDraggingEvent = MNCommandMouseDrag;
                    mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:startTime];
                }
                
                selectedCommandIndex = i;
                commandClusterIndexForSelectedCommand = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"SelectCommand" object:[NSArray arrayWithObjects:[NSNumber numberWithInt:selectedCommandIndex], [data filePathForCommandCluster:commandCluster], nil]];
            }
            
            mouseEvent = nil;
        }
        // Dragging of commands
        else if(mouseEvent != nil && mouseAction == MNMouseDragged && i == selectedCommandIndex && commandClusterIndexForSelectedCommand == (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]])
        {
            if(mouseDraggingEvent == MNCommandMouseDragStartTime)
            {
                [data setStartTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x] forCommandAtIndex:i whichIsPartOfCommandCluster:commandCluster];
            }
            else if(mouseDraggingEvent == MNCommandMouseDragEndTime)
            {
                [data setEndTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x] forCommandAtIndex:i whichIsPartOfCommandCluster:commandCluster];
            }
            else if(mouseDraggingEvent == MNCommandMouseDrag)
            {
                mouseDraggingEvent = MNCommandMouseDrag;
                // Drag the command
                [data moveCommandAtIndex:i toStartTime:[data xToTime:currentMousePoint.x - mouseClickDownPoint.x] whichIsPartOfCommandCluster:commandCluster];
                
                // Mouse drag is changing the channel index
                if(currentMousePoint.y > y + height || currentMousePoint.y < y)
                {
                    int newIndex = (self.frame.size.height - currentMousePoint.y - TOP_BAR_HEIGHT) / TRACK_ITEM_HEIGHT - startingTrackIndex;
                    [data setChannelIndex:newIndex forCommandAtIndex:i whichIsPartOfCommandCluster:commandCluster];
                }
            }
            else if(mouseDraggingEvent == MNCommandMouseDragBetweenChannels)
            {
                // Mouse drag is changing the channel index
                if(currentMousePoint.y > y + height || currentMousePoint.y < y)
                {
                    int newIndex = (self.frame.size.height - currentMousePoint.y - TOP_BAR_HEIGHT) / TRACK_ITEM_HEIGHT - startingTrackIndex;
                    [data setChannelIndex:newIndex forCommandAtIndex:i whichIsPartOfCommandCluster:commandCluster];
                }
            }
            
            mouseDraggingEventObjectIndex = i;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
            
            mouseEvent = nil;
        }
        else if(mouseEvent != nil && i == selectedCommandIndex && commandClusterIndexForSelectedCommand == (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]])
        {
            selectedCommandIndex = -1;
            commandClusterIndexForSelectedCommand = -1;
            
            mouseEvent = nil;
        }
    }
}

#pragma mark Mouse Methods

- (void)mouseDown:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseClickDownPoint = currentMousePoint;
    mouseAction = MNMouseDown;
    mouseEvent = theEvent;
    
    [autoScrollTimer invalidate];
    autoScrollTimer = nil;
    autoScrollTimer = [NSTimer scheduledTimerWithTimeInterval:AUTO_SCROLL_REFRESH_RATE target:self selector:@selector(updateTimeAtLeftEdgeOfTimelineView:) userInfo:nil repeats:YES];
    autoscrollTimerIsRunning = YES;
    
    [self setNeedsDisplay:YES];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseAction = MNMouseDragged;
    mouseEvent = theEvent;
    [self setNeedsDisplay:YES];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	NSPoint eventLocation = [theEvent locationInWindow];
	currentMousePoint = [self convertPoint:eventLocation fromView:nil];
    mouseAction = MNMouseUp;
    mouseEvent = theEvent;
    mouseDraggingEvent = MNMouseDragNotInUse;
    mouseDraggingEventObjectIndex = -1;
    
    [autoScrollTimer invalidate];
    autoScrollTimer = nil;
    autoscrollTimerIsRunning = NO;
    
    [self setNeedsDisplay:YES];
}

#pragma mark - Keyboard Methods

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)keyDown:(NSEvent *)keyboardEvent
{
    NSLog(@"keyDown");
    // Check for new command clicks
    if(keyboardEvent.keyCode == 40 && ![keyboardEvent isARepeat])
    {
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
            int channelIndex = 0;
            NSMutableDictionary *commandCluster = [data commandClusterForCurrentSequenceAtIndex:data.mostRecentlySelectedCommandClusterIndex];
            float time = [data currentTime];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"AddCommandAtChannelIndexAndTimeForCommandCluster" object:nil userInfo:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSNumber numberWithInt:channelIndex], [NSNumber numberWithFloat:time], commandCluster, nil] forKeys:[NSArray arrayWithObjects:@"channelIndex", @"startTime", @"commandCluster", nil]]];
        //});
            
        /*int newCommandIndex = [data commandsCountForCommandCluster:commandCluster] - 1;
        
        mouseDraggingEvent = MNCommandMouseDragEndTime;
        mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:[data endTimeForCommand:[data commandAtIndex:newCommandIndex fromCommandCluster:commandCluster]]];
        
        selectedCommandIndex = newCommandIndex;
        commandClusterIndexForSelectedCommand = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]];
        
        mouseEvent = nil;*/
    }
    else if(keyboardEvent.keyCode != 40)
    {
        [super keyDown:keyboardEvent];
    }
}

- (void)keyUp:(NSEvent *)keyboardEvent
{
    // Check for new command clicks
    if(keyboardEvent.keyCode == 40 && ![keyboardEvent isARepeat])
    {
        //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(){
            NSMutableDictionary *commandCluster = [data commandClusterForCurrentSequenceAtIndex:data.mostRecentlySelectedCommandClusterIndex];
            float time = [data currentTime];
            int newCommandIndex = [data commandsCountForCommandCluster:commandCluster] - 1;
            [data setEndTime:time forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandCluster];
        //});
        
        /*
         
         mouseDraggingEvent = MNCommandMouseDragEndTime;
         mouseClickDownPoint.x = mouseClickDownPoint.x - [data timeToX:[data endTimeForCommand:[data commandAtIndex:newCommandIndex fromCommandCluster:commandCluster]]];
         
         selectedCommandIndex = newCommandIndex;
         commandClusterIndexForSelectedCommand = (int)[[data commandClusterFilePathsForSequence:[data currentSequence]] indexOfObject:[data filePathForCommandCluster:commandCluster]];
         
         mouseEvent = nil;*/
    }
}

@end
