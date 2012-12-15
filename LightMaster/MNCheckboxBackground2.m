//
//  MNCheckboxBackground2.m
//  LightMaster
//
//  Created by James Adams on 12/14/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNCheckboxBackground2.h"

@implementation MNCheckboxBackground2

- (void)drawRect:(NSRect)rect
{
    rect = [self bounds];
    [[NSColor colorWithCalibratedRed:1.0 green:0.5 blue:0.0 alpha:0.5] set];
    [NSBezierPath fillRect: rect];
}

@end
