//
//  MNCheckboxBackground5.m
//  LightMaster
//
//  Created by James Adams on 12/14/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNCheckboxBackground5.h"

@implementation MNCheckboxBackground5

- (void)drawRect:(NSRect)rect
{
    rect = [self bounds];
    [[NSColor colorWithCalibratedRed:1.0 green:0.0 blue:1.0 alpha:0.5] set];
    [NSBezierPath fillRect: rect];
}

@end
