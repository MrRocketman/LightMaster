//
//  LightMasterTests.m
//  LightMasterTests
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "LightMasterTests.h"

@implementation LightMasterTests

- (int)autogenCycleNumberOfChannelsOnForChannelsArray:(BOOL *)channelsInUseForBox channelsCount:(int)channelsCount
{
    int numberOfChannelsOn = 0;
    
    for(int i = 0; i < channelsCount; i ++)
    {
        if(channelsInUseForBox[i] == YES)
        {
            numberOfChannelsOn ++;
        }
    }
    
    return numberOfChannelsOn;
}

- (void)autogenCycleWithChannelsArray:(BOOL *)channelsInUseForBox channelsCount:(int)channelsCount
{
    BOOL firstIndexValue = channelsInUseForBox[0];
    
    // Turn on the next channels
    for(int i = 0; i < channelsCount - 1; i ++)
    {
        channelsInUseForBox[i] = channelsInUseForBox[i + 1];
    }
    
    channelsInUseForBox[channelsCount - 1] = firstIndexValue;
}

- (void)cylcePatternWithChannelsArray:(BOOL *)channelsInUseForBox channelsCount:(int)channelsCount numberOfChannelsToUseAtOnce:(int)numberOfChannelsToUseAtOnce
{
    if([self autogenCycleNumberOfChannelsOnForChannelsArray:channelsInUseForBox channelsCount:channelsCount] < numberOfChannelsToUseAtOnce)
    {
        [self initialChannelsForCyclePattern:channelsInUseForBox channelsCount:channelsCount numberOfChannelsToUseAtOnce:numberOfChannelsToUseAtOnce];
        for (int i = 0; i < channelsCount; i++) {
            printf("%i,", channelsInUseForBox[i]);
        }
        NSLog(@"");
    }
    
    [self autogenCycleWithChannelsArray:channelsInUseForBox channelsCount:channelsCount];
}

- (void)initialChannelsForCyclePattern:(BOOL *)channelsInUseForBox channelsCount:(int)channelsCount numberOfChannelsToUseAtOnce:(int)numberOfChannelsToUseAtOnce
{
    if(numberOfChannelsToUseAtOnce <= channelsCount / 2)
    {
        int channelsRatio = channelsCount / numberOfChannelsToUseAtOnce;
        int ratioCounter = 0;
        
        for(int i = 0; i < channelsCount; i ++)
        {
            if(ratioCounter == 0)
            {
                channelsInUseForBox[i] = YES;
            }
            
            ratioCounter ++;
            
            if(ratioCounter == channelsRatio)
            {
                ratioCounter = 0;
            }
        }
    }
    else
    {
        int channelsRatio = channelsCount / numberOfChannelsToUseAtOnce;
        int ratioCounter = 0;
        
        for(int i = 0; i < channelsCount; i ++)
        {
            if(ratioCounter != channelsRatio)
            {
                channelsInUseForBox[i] = YES;
            }
            
            ratioCounter ++;
            
            if(ratioCounter == channelsRatio)
            {
                ratioCounter = 0;
            }
        }
    }
}

- (void)daisyPatternWithChannelsArray:(BOOL *)channelsInUseForBox channelsCount:(int)channelsCount numberOfChannelsToUseAtOnce:(int)numberOfChannelsToUseAtOnce
{
    // Ramp up to the appropriate number of channels being used
    if([self autogenCycleNumberOfChannelsOnForChannelsArray:channelsInUseForBox channelsCount:channelsCount] < numberOfChannelsToUseAtOnce)
    {
        for(int i = 0; i < channelsCount; i ++)
        {
            if(channelsInUseForBox[i] == NO)
            {
                channelsInUseForBox[i] = YES;
                break;
            }
        }
    }
    
    [self autogenCycleWithChannelsArray:channelsInUseForBox channelsCount:channelsCount];
}

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testExample
{
    STFail(@"Unit tests are not implemented yet in LightMasterTests");
}

@end
