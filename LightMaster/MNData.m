//
//  MNData.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNData.h"

#define LARGEST_NUMBER 999999
#define LIBRARY_VERSION_NUMBER 1.0
#define DATA_VERSION_NUMBER 1.0
#define setBit(var, mask)   ((var) |= (uint16_t)(1 << mask))
#define clearBit(var, mask)   ((var) &= (uint16_t)~(1 << mask))

@interface MNData()

- (NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory inDomain:(NSSearchPathDomainMask)domainMask appendPathComponent:(NSString *)appendComponent error:(NSError **)errorOut;
- (NSString *)applicationSupportDirectory;
- (void)loadLibaries;
- (void)saveLibraries;
- (void)saveControlBoxLibrary;
- (void)saveSequenceLibrary;
- (void)saveCommandClusterLibrary;
- (void)saveChannelGroupLibrary;
- (void)saveEffectLibrary;
- (void)saveAudioClipLibrary;
- (void)saveDictionaryToItsFilePath:(NSMutableDictionary *)dictionary;
- (NSString *)nextAvailableNumberForFilePaths:(NSMutableArray *)filePaths;
- (float)versionNumberForDictionary:(NSMutableDictionary *)dictionary;
- (void)setVersionNumber:(float)someVersionNumber forDictionary:(NSMutableDictionary *)dictionary;
- (NSString *)filePathForDictionary:(NSMutableDictionary *)dictionary;
- (void)setFilePath:(NSString *)filePath forDictionary:(NSMutableDictionary *)dictionary;
- (NSMutableArray *)dictionaryBeingUsedInSequenceFilePaths:(NSMutableDictionary *)dictionary;
- (int)dictionaryBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)dictionary;
- (NSString *)dictionary:(NSMutableDictionary *)dictionary beingUsedInSequenceFilePathAtIndex:(int)index;
- (void)addBeingUsedInSequenceFilePath:(NSString *)sequenceFilePath forDictionary:(NSMutableDictionary *)dictionary;
- (void)removeBeingUsedInSequenceFilePath:(NSString *)sequenceFilePath forDictionary:(NSMutableDictionary *)dictionary;
- (NSMutableDictionary *)dictionaryFromFilePath:(NSString *)filePath;
- (void)disconnectFromSerialPort;
- (void)sendStringToSerialPort:(NSString *)text;

@end


@implementation MNData

@synthesize currentSequence, libraryFolder, timeAtLeftEdgeOfTimelineView, zoomLevel, currentSequenceIsPlaying, serialPort, serialPortManager;

#pragma mark - System

- (id)init
{
    if(self = [super init])
    {
        // Custom initialization here
        [self loadLibaries];
        zoomLevel = 3.0;
        [self setCurrentTime:1.0];
        self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
    }
    
    return self;
}

#pragma mark - Private Methods

- (NSString *)findOrCreateDirectory:(NSSearchPathDirectory)searchPathDirectory inDomain:(NSSearchPathDomainMask)domainMask appendPathComponent:(NSString *)appendComponent error:(NSError **)errorOut
{
    // Search for the path
    NSArray* paths = NSSearchPathForDirectoriesInDomains(searchPathDirectory, domainMask, YES);
    if ([paths count] == 0)
    {
        // *** creation and return of error object omitted for space
        return nil;
    }
    
    // Normally only need the first path
    NSString *resolvedPath = [paths objectAtIndex:0];
    
    if (appendComponent)
    {
        resolvedPath = [resolvedPath stringByAppendingPathComponent:appendComponent];
    }
    
    // Create the path if it doesn't exist
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:resolvedPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (!success)
    {
        if (errorOut)
        {
            *errorOut = error;
        }
        return nil;
    }
    
    // If we've made it this far, we have a success
    if (errorOut)
    {
        *errorOut = nil;
    }
    return resolvedPath;
}

- (NSString *)applicationSupportDirectory
{
    NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSError *error;
    NSString *result = [self findOrCreateDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appendPathComponent:executableName error:&error];
    if (error)
    {
        NSLog(@"Unable to find or create application support directory:\n%@", error);
    }
    return result;
}

- (void)loadLibaries
{
    libraryFolder = [self applicationSupportDirectory];
    //NSLog(@"libraryFolder:%@", libraryFolder);
    
    // Load the libraries from file
    NSString *filePath = [NSString stringWithFormat:@"%@/sequenceLibrary.lmlib", libraryFolder];
    BOOL isDirectory = NO;
    BOOL createdLibrary = NO;
    // SequenceLibrary
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory])
    {
        sequenceLibrary = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    }
    else
    {
        sequenceLibrary = [[NSMutableDictionary alloc] init];
        NSMutableArray *sequenceFilePaths = [[NSMutableArray alloc] init];
        [sequenceLibrary setObject:sequenceFilePaths forKey:@"sequenceFilePaths"];
        [self setVersionNumberForSequenceLibraryTo:LIBRARY_VERSION_NUMBER];
        // Create the folder
        NSError *error = nil;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingPathExtension] withIntermediateDirectories:YES attributes:nil error:&error])
        {
            [NSException raise:@"Failed creating directory" format:@"[%@], %@", filePath, error];
        }
        createdLibrary = YES;
    }
    
    // ControlBox Library
    filePath = [NSString stringWithFormat:@"%@/controlBoxLibrary.lmlib", libraryFolder];
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory])
    {
        controlBoxLibrary = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    }
    else
    {
        controlBoxLibrary = [[NSMutableDictionary alloc] init];
        NSMutableArray *controlBoxFilePaths = [[NSMutableArray alloc] init];
        [controlBoxLibrary setObject:controlBoxFilePaths forKey:@"controlBoxFilePaths"];
        [self setVersionNumberForControlBoxLibraryTo:LIBRARY_VERSION_NUMBER];
        // Create the folder
        NSError *error = nil;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingPathExtension] withIntermediateDirectories:YES attributes:nil error:&error])
        {
            [NSException raise:@"Failed creating directory" format:@"[%@], %@", filePath, error];
        }
        createdLibrary = YES;
    }
    
    // Command Cluster Library
    filePath = [NSString stringWithFormat:@"%@/commandClusterLibrary.lmlib", libraryFolder];
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory])
    {
        commandClusterLibrary = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    }
    else
    {
        commandClusterLibrary = [[NSMutableDictionary alloc] init];
        NSMutableArray *commandClusterFilePaths = [[NSMutableArray alloc] init];
        [commandClusterLibrary setObject:commandClusterFilePaths forKey:@"commandClusterFilePaths"];
        [self setVersionNumberForCommandClusterLibraryTo:LIBRARY_VERSION_NUMBER];
        // Create the folder
        NSError *error = nil;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingPathExtension] withIntermediateDirectories:YES attributes:nil error:&error])
        {
            [NSException raise:@"Failed creating directory" format:@"[%@], %@", filePath, error];
        }
        createdLibrary = YES;
    }
    
    // AudioClip Library
    filePath = [NSString stringWithFormat:@"%@/audioClipLibrary.lmlib", libraryFolder];
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory])
    {
        audioClipLibrary = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    }
    else
    {
        audioClipLibrary = [[NSMutableDictionary alloc] init];
        NSMutableArray *audioClipFilePaths = [[NSMutableArray alloc] init];
        [audioClipLibrary setObject:audioClipFilePaths forKey:@"audioClipFilePaths"];
        [self setVersionNumberForAudioClipLibraryTo:LIBRARY_VERSION_NUMBER];
        // Create the folder
        NSError *error = nil;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingPathExtension] withIntermediateDirectories:YES attributes:nil error:&error])
        {
            [NSException raise:@"Failed creating directory" format:@"[%@], %@", filePath, error];
        }
        createdLibrary = YES;
    }
    
    // ChannelGroup Library
    filePath = [NSString stringWithFormat:@"%@/channelGroupLibrary.lmlib", libraryFolder];
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory])
    {
        channelGroupLibrary = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    }
    else
    {
        channelGroupLibrary = [[NSMutableDictionary alloc] init];
        NSMutableArray *channelGroupFilePaths = [[NSMutableArray alloc] init];
        [channelGroupLibrary setObject:channelGroupFilePaths forKey:@"channelGroupFilePaths"];
        [self setVersionNumberForChannelGroupLibraryTo:LIBRARY_VERSION_NUMBER];
        // Create the folder
        NSError *error = nil;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingPathExtension] withIntermediateDirectories:YES attributes:nil error:&error])
        {
            [NSException raise:@"Failed creating directory" format:@"[%@], %@", filePath, error];
        }
        createdLibrary = YES;
    }
    
    // Effect Library
    filePath = [NSString stringWithFormat:@"%@/effectLibrary.lmlib", libraryFolder];
    if([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory])
    {
        effectLibrary = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    }
    else
    {
        effectLibrary = [[NSMutableDictionary alloc] init];
        NSMutableArray *effectFilePaths = [[NSMutableArray alloc] init];
        [effectLibrary setObject:effectFilePaths forKey:@"effectFilePaths"];
        [self setVersionNumberForEffectLibraryTo:LIBRARY_VERSION_NUMBER];
        // Create the folder
        NSError *error = nil;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingPathExtension] withIntermediateDirectories:YES attributes:nil error:&error])
        {
            [NSException raise:@"Failed creating directory" format:@"[%@], %@", filePath, error];
        }
        createdLibrary = YES;
    }
    
    if(createdLibrary)
    {
        [self saveLibraries];
    }
}

- (void)saveLibraries
{
    [self saveControlBoxLibrary];
    [self saveSequenceLibrary];
    [self saveCommandClusterLibrary];
    [self saveChannelGroupLibrary];
    [self saveEffectLibrary];
    [self saveAudioClipLibrary];
}

- (void)saveControlBoxLibrary
{
    NSString *filePath = [NSString stringWithFormat:@"%@/controlBoxLibrary.lmlib", libraryFolder];
    [controlBoxLibrary writeToFile:filePath atomically:YES];
}

- (void)saveSequenceLibrary
{
    NSString *filePath = [NSString stringWithFormat:@"%@/sequenceLibrary.lmlib", libraryFolder];
    [sequenceLibrary writeToFile:filePath atomically:YES];
}

- (void)saveCommandClusterLibrary
{
    NSString *filePath = [NSString stringWithFormat:@"%@/commandClusterLibrary.lmlib", libraryFolder];
    [commandClusterLibrary writeToFile:filePath atomically:YES];
}

- (void)saveChannelGroupLibrary
{
    NSString *filePath = [NSString stringWithFormat:@"%@/channelGroupLibrary.lmlib", libraryFolder];
    [channelGroupLibrary writeToFile:filePath atomically:YES];
}

- (void)saveEffectLibrary
{
    NSString *filePath = [NSString stringWithFormat:@"%@/effectLibrary.lmlib", libraryFolder];
    [effectLibrary writeToFile:filePath atomically:YES];
}

- (void)saveAudioClipLibrary
{
    NSString *filePath = [NSString stringWithFormat:@"%@/audioClipLibrary.lmlib", libraryFolder];
    [audioClipLibrary writeToFile:filePath atomically:YES];
}

- (void)saveDictionaryToItsFilePath:(NSMutableDictionary *)dictionary
{
    NSString *filePath = [self filePathForDictionary:dictionary];
    [dictionary writeToFile:[NSString stringWithFormat:@"%@/%@", libraryFolder, filePath] atomically:YES];
}

- (NSString *)nextAvailableNumberForFilePaths:(NSMutableArray *)filePaths
{
    int currentNumber = -1;
    int previousNumbers[LARGEST_NUMBER] = {0};
    int largestNumber = -1;
    int smallestNumber = LARGEST_NUMBER;
    int availableNumber = -1;
    
    for(int i = 0; i < [filePaths count]; i ++)
    {
        // Gives just the number of the file name without the extension
        currentNumber = [[[[filePaths objectAtIndex:i] lastPathComponent] stringByDeletingPathExtension] intValue];
        //NSLog(@"filePath:%@", [[[filePaths objectAtIndex:i] lastPathComponent] stringByDeletingPathExtension]);
        previousNumbers[currentNumber] = 1;
        
        // Check for the smallestNumber
        if(currentNumber < smallestNumber)
        {
            smallestNumber = currentNumber;
        }
        // Check for the largest number
        if(currentNumber > largestNumber)
        {
            largestNumber = currentNumber;
        }
    }
    
    // Smallest numbers take priority
    if(smallestNumber < LARGEST_NUMBER && smallestNumber > 0)
    {
        availableNumber = smallestNumber - 1;
    }
    // Gap numbers take next priority
    if(availableNumber == -1)
    {
        for(int i = 0; i < largestNumber; i ++)
        {
            if(previousNumbers[i] == 0 && availableNumber == -1)
            {
                availableNumber = i;
                // End the loop
                i = largestNumber;
            }
        }
    }
    // And then finally the largest number
    if(availableNumber == -1)
    {
        availableNumber = largestNumber + 1;
    }
    
    return [NSString stringWithFormat:@"%d", availableNumber];
}

- (float)versionNumberForDictionary:(NSMutableDictionary *)dictionary
{
    return [(NSNumber *)[dictionary objectForKey:@"versionNumber"] floatValue];
}

- (void)setVersionNumber:(float)someVersionNumber forDictionary:(NSMutableDictionary *)dictionary
{
    [dictionary setObject:[NSNumber numberWithFloat:someVersionNumber] forKey:@"versionNumber"];
}

- (NSString *)filePathForDictionary:(NSMutableDictionary *)dictionary
{
    return [dictionary objectForKey:@"filePath"];
}

- (void)setFilePath:(NSString *)filePath forDictionary:(NSMutableDictionary *)dictionary
{
    [dictionary setObject:filePath forKey:@"filePath"];
}

- (NSMutableArray *)dictionaryBeingUsedInSequenceFilePaths:(NSMutableDictionary *)dictionary
{
    return [dictionary objectForKey:@"beingUsedInSequenceFilePaths"];
}

- (int)dictionaryBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)dictionary
{
    return (int)[[self dictionaryBeingUsedInSequenceFilePaths:dictionary] count];
}

- (NSString *)dictionary:(NSMutableDictionary *)dictionary beingUsedInSequenceFilePathAtIndex:(int)index
{
    return [[self dictionaryBeingUsedInSequenceFilePaths:dictionary] objectAtIndex:index];
}

- (void)addBeingUsedInSequenceFilePath:(NSString *)sequenceFilePath forDictionary:(NSMutableDictionary *)dictionary
{
    NSMutableArray *beingUsedInSequenceFilePaths = [self dictionaryBeingUsedInSequenceFilePaths:dictionary];
    [beingUsedInSequenceFilePaths addObject:sequenceFilePath];
    [dictionary setObject:beingUsedInSequenceFilePaths forKey:@"beingUsedInSequenceFilePaths"];
    [self saveDictionaryToItsFilePath:dictionary];
}

- (void)removeBeingUsedInSequenceFilePath:(NSString *)sequenceFilePath forDictionary:(NSMutableDictionary *)dictionary
{
    NSMutableArray *beingUsedInSequenceFilePaths = [self dictionaryBeingUsedInSequenceFilePaths:dictionary];
    [beingUsedInSequenceFilePaths removeObject:sequenceFilePath];
    [dictionary setObject:beingUsedInSequenceFilePaths forKey:@"beingUsedInSequenceFilePaths"];
    [self saveDictionaryToItsFilePath:dictionary];
}

- (NSMutableDictionary *)dictionaryFromFilePath:(NSString *)filePath
{
    NSString *sequencePath = [NSString stringWithFormat:@"%@/%@", libraryFolder, filePath];
    BOOL isDirectory = NO;
    if([[NSFileManager defaultManager] fileExistsAtPath:sequencePath isDirectory:&isDirectory])
    {
        NSMutableDictionary *sequence = [[NSMutableDictionary alloc] initWithContentsOfFile:sequencePath];
        return sequence;
    }
    else
    {
        return nil;
    }
}

#pragma mark - Other Methods

- (int)timeToX:(float)time
{
    int x = [self widthForTimeInterval:time];
    
	return x;
}

- (float)xToTime:(int)x
{
	//return  (x / zoomLevel / PIXEL_TO_ZOOM_RATIO);
    return  x / zoomLevel / PIXEL_TO_ZOOM_RATIO;
}

- (int)widthForTimeInterval:(float)timeInterval
{
	return (timeInterval * zoomLevel * PIXEL_TO_ZOOM_RATIO);
}

- (void)setCurrentSequence:(NSMutableDictionary *)newSequence
{
    currentSequence = newSequence;
    
    currentSequenceNSSounds = nil;
    currentSequenceNSSounds = [[NSMutableArray alloc] init];
    
    // Load the sounds
    for(int i = 0; i < [self audioClipFilePathsCountForSequence:currentSequence]; i ++)
    {
        NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@", self.libraryFolder, [self filePathToAudioFileForAudioClip:[self audioClipFromFilePath:[self audioClipFilePathAtIndex:i forSequence:currentSequence]]]];
        NSSound *newSound = [[NSSound alloc] initWithContentsOfFile:soundFilePath byReference:NO];
        [newSound setName:[self audioClipFilePathAtIndex:i forSequence:currentSequence]];
        [newSound play];
        [newSound stop];
        [currentSequenceNSSounds addObject:newSound];
    }
}

- (NSMutableDictionary *)currentSequence
{
    return currentSequence;
}

- (void)setCurrentTime:(float)newTime
{
    currentTime = newTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentTimeChange" object:nil];
    
    if(currentSequenceIsPlaying)
    {
        // Play/Pause the necessary NSSounds
        for(int i = 0; i < [currentSequenceNSSounds count]; i ++)
        {
            float startTime = [self startTimeForAudioClip:[self audioClipFromFilePath:[[currentSequenceNSSounds objectAtIndex:i] name]]];
            float endTime = [self endTimeForAudioClip:[self audioClipFromFilePath:[[currentSequenceNSSounds objectAtIndex:i] name]]];
            
            // Play the sound
            if(currentTime >= startTime && currentTime < endTime && [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] isPlaying] == NO)
            {
                float seekTime = [self seekTimeForAudioClip:[self audioClipFromFilePath:[[currentSequenceNSSounds objectAtIndex:i] name]]];
                
                // Seek to the appropriate time
                [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] setCurrentTime:seekTime + currentTime - startTime];
                [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] play];
            }
            // Pause the sound
            else if((currentTime < startTime || currentTime >= endTime) && [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] isPlaying] == YES)
            {
                [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] stop];
            }
        }
        
        // Determine the channel states
        NSMutableDictionary *currentCommandCluster;
        NSMutableDictionary *currentCommand;
        int currentControlBoxIndex = -1;
        BOOL isChannelGroupCommand = YES;
        int currentChannelIndex = -1;
        for(int i = 0; i < [self commandClusterFilePathsCountForSequence:currentSequence]; i ++)
        {
            currentCommandCluster = [self commandClusterFromFilePath:[self commandClusterFilePathAtIndex:i forSequence:currentSequence]];
            // See if this is a controlBox cluster
            if([[self controlBoxFilePathForCommandCluster:currentCommandCluster] length] > 0)
            {
                isChannelGroupCommand = NO;
                currentControlBoxIndex = (int)[[self controlBoxFilePathsForSequence:currentSequence] indexOfObject:[self controlBoxFilePathForCommandCluster:currentCommandCluster]];
            }
            
            // Check to see if the current time is withing the command cluster's range (plus a little extra at the so we can turn all channels off if they haven't been already)
            if(currentTime >= [self startTimeForCommandCluster:currentCommandCluster] && currentTime <= [self endTimeForCommandCluster:currentCommandCluster] + 0.25)
            {
                // Loop through this clusters commands and determine the chanel's state
                for(int i2 = 0; i2 < [self commandsCountForCommandCluster:currentCommandCluster]; i2 ++)
                {
                    currentCommand = [self commandAtIndex:i2 fromCommandCluster:currentCommandCluster];
                    currentChannelIndex = [self channelIndexForCommand:currentCommand];
                    
                    // Determine the controlBoxIndex for this command if it's a channelGroup command
                    if(currentControlBoxIndex == -1)
                    {
                        currentControlBoxIndex = (int)[[self controlBoxFilePathsForSequence:currentSequence] indexOfObject:[self controlBoxFilePathForItemData:[self itemDataAtIndex:currentChannelIndex forChannelGroup:[self channelGroupFromFilePath:[self channelGroupFilePathForCommandCluster:currentCommandCluster]]]]];
                    }
                    
                    // Check if this command should be played
                    if(currentTime >= [self startTimeForCommand:currentCommand] && currentTime <= [self endTimeForCommand:currentCommand])
                    {
                        channelState[currentControlBoxIndex][currentChannelIndex] = YES;
                    }
                    else
                    {
                        channelState[currentControlBoxIndex][currentChannelIndex] = NO;
                    }
                }
            }
            
            currentControlBoxIndex = -1;
            isChannelGroupCommand = YES;
            currentChannelIndex = -1;
        }
        
        // Send out the necessary commands over the serial port
        for(int i = 0; i < [self controlBoxFilePathsCountForSequence:currentSequence]; i ++)
        {
            uint8_t commandCharacters[128] = {0};
            NSMutableString *command = [NSMutableString stringWithFormat:@"%@", [self controlBoxIDForControlBox:[self controlBoxFromFilePath:[self controlBoxFilePathAtIndex:i forSequence:currentSequence]]]];
            
            // Loop through each channel to build the command
            int i2;
            for(i2 = 0; i2 < [self channelsCountForControlBox:[self controlBoxFromFilePath:[self controlBoxFilePathAtIndex:i]]]; i2 ++)
            {
                if(channelState[i][i2] == YES)
                {
                    setBit(commandCharacters[i2 / 8], i2 % 8);
                }
                else
                {
                    clearBit(commandCharacters[i2 / 8], i2 % 8);
                }
                
                // Add each command character to the command string as it is completed
                if(i2 % 8 == 7)
                {
                    [command appendFormat:@"%02x", commandCharacters[i2 / 8]];
                }
            }
            
            // Add the final command character if neccessary
            if(i2 % 8 != 0)
            {
                [command appendFormat:@"%02x", commandCharacters[i2 / 8]];
            }
            
            // Send the command!
            [self sendStringToSerialPort:[NSString stringWithFormat:@"%@`", command]];
        }
    }
}

- (float)currentTime
{
    return currentTime;
}

- (void)setCurrentSequenceIsPlaying:(BOOL)isPlaying
{
    currentSequenceIsPlaying = isPlaying;
    
    // If the user pauses, pause all sounds
    if(!currentSequenceIsPlaying)
    {
        for(int i = 0; i < [currentSequenceNSSounds count]; i ++)
        {
            if([(NSSound *)[currentSequenceNSSounds objectAtIndex:i] isPlaying] == YES)
            {
                [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] stop];
            }
        }
    }
}

- (BOOL)currentSequenceIsPlaying
{
    return currentSequenceIsPlaying;
}

- (int)trackItemsCount
{
    // Determine the number of trackItems
    int trackItemsCount = [self audioClipFilePathsCountForSequence:currentSequence];
    for(int i = 0; i < [self controlBoxFilePathsCountForSequence:currentSequence]; i ++)
    {
        trackItemsCount += [self channelsCountForControlBox:[self controlBoxFromFilePath:[self controlBoxFilePathAtIndex:i]]];
    }
    for(int i = 0; i < [self channelGroupFilePathsCountForSequence:currentSequence]; i ++)
    {
        trackItemsCount += [self itemsCountForChannelGroup:[self channelGroupFromFilePath:[self channelGroupFilePathAtIndex:i]]];
    }
    
    return trackItemsCount;
}

#pragma mark - SerialPort

- (void)sendStringToSerialPort:(NSString *)text
{
	if([self.serialPort isOpen])
	{
		//NSLog(@"Writing:%@:", text);
        [serialPort sendData:[text dataUsingEncoding:NSUTF8StringEncoding]];
	}
	else
    {
        NSLog(@"Can't send:%@", text);
    }
}

#pragma mark - ORSSerialPortDelegate

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
	//self.openCloseButton.title = @"Close";
}

- (void)serialPortWasClosed:(ORSSerialPort *)serialPort
{
	//self.openCloseButton.title = @"Open";
}

- (void)serialPort:(ORSSerialPort *)serialPort didReceiveData:(NSData *)data
{
    // This method is called if data arrives
	if ([data length] > 0)
    {
		NSString *receivedText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
		NSLog(@"Serial Port Data Received: %@",receivedText);
        
        // ToDo: Do something with received text
	}
    // Port closed
    else
    { 
		NSLog(@"Port was closed on a readData operation...not good!");
	}
}

- (void)serialPortWasRemovedFromSystem:(ORSSerialPort *)serialPort;
{
	// After a serial port is removed from the system, it is invalid and we must discard any references to it
	self.serialPort = nil;
}

- (void)serialPort:(ORSSerialPort *)theSerialPort didEncounterError:(NSError *)error
{
	NSLog(@"Serial port %@ encountered an error: %@", theSerialPort, error);
}

#pragma mark - Sequence Library Methods
// Sequence Management Methods

- (NSString *)createSequenceAndReturnFilePath
{
    NSMutableDictionary *newSequence = [[NSMutableDictionary alloc] init];
    NSMutableArray *audioClipFilePathsForSequence = [[NSMutableArray alloc] init];
    NSMutableArray *controlBoxFilePathsForSequence = [[NSMutableArray alloc] init];
    NSMutableArray *channelGroupFilePathsForSequence = [[NSMutableArray alloc] init];
    NSMutableArray *commandClusterFilePathsForSequence = [[NSMutableArray alloc] init];
    [newSequence setObject:audioClipFilePathsForSequence forKey:@"audioClipFilePaths"];
    [newSequence setObject:controlBoxFilePathsForSequence forKey:@"controlBoxFilePaths"];
    [newSequence setObject:channelGroupFilePathsForSequence forKey:@"channelGroupFilePaths"];
    [newSequence setObject:commandClusterFilePathsForSequence forKey:@"commandClusterFilePaths"];
    
    // New files get a file name chosen by availble numbers (detemined by @selector(nextAvailableNumberForFilePaths))
    NSString *filePath = [NSString stringWithFormat:@"sequenceLibrary/%@.lmsq", [self nextAvailableNumberForFilePaths:[self sequenceFilePaths]]];
    [self addSequenceFilePathToSequenceLibrary:filePath];
    [self setFilePath:filePath forDictionary:newSequence];
    
    [newSequence writeToFile:[NSString stringWithFormat:@"%@/%@", libraryFolder, filePath] atomically:YES];
    [self setVersionNumber:DATA_VERSION_NUMBER forSequence:newSequence];
    [self setDescription:@"New Sequence" forSequence:newSequence];
    
    return filePath;
}

- (NSString *)createCopyOfSequenceAndReturnFilePath:(NSMutableDictionary *)sequence
{
    NSString *newSequenceFilePath = [self createSequenceAndReturnFilePath];
    NSMutableDictionary *newSequence = [self dictionaryFromFilePath:newSequenceFilePath];
    [newSequence setObject:[self audioClipFilePathsForSequence:sequence] forKey:@"audioClipFilePaths"];
    [newSequence setObject:[self controlBoxFilePathsForSequence:sequence] forKey:@"controlBoxFilePaths"];
    [newSequence setObject:[self channelGroupFilePathsForSequence:sequence] forKey:@"channelGroupFilePaths"];
    [newSequence setObject:[self commandClusterFilePathsForSequence:sequence] forKey:@"commandClusterFilePaths"];
    [self setDescription:[NSString stringWithFormat:@"%@ Copy", [self descriptionForSequence:sequence]] forSequence:newSequence];
    [self setStartTime:[self startTimeForSequence:sequence] forSequence:newSequence];
    [self setEndTime:[self endTimeForSequence:sequence] forSequence:newSequence];
    
    return newSequenceFilePath;
}

- (void)removeSequenceFromLibrary:(NSMutableDictionary *)sequence
{
    // Remove any controlBoxes from this sequence
    NSMutableArray *controlBoxFilePaths = [self controlBoxFilePathsForSequence:sequence];
    for(int i = 0; i < [controlBoxFilePaths count]; i ++)
    {
        [self removeControlBoxFilePath:[controlBoxFilePaths objectAtIndex:i] forSequence:sequence];
    }
    // Remove any chanelGroups from this sequence
    NSMutableArray *channelGroupFilePaths = [self channelGroupFilePathsForSequence:sequence];
    for(int i = 0; i < [channelGroupFilePaths count]; i ++)
    {
        [self removeChannelGroupFilePath:[channelGroupFilePaths objectAtIndex:i] forSequence:sequence];
    }
    // Remove any commandClustesr from this sequence
    NSMutableArray *commandClusterFilePaths = [self commandClusterFilePathsForSequence:sequence];
    for(int i = 0; i < [commandClusterFilePaths count]; i ++)
    {
        [self removeCommandClusterFilePath:[commandClusterFilePaths objectAtIndex:i] forSequence:sequence];
    }
    // Remove any audioClips from this sequence
    NSMutableArray *audioClipFilePaths = [self audioClipFilePathsForSequence:sequence];
    for(int i = 0; i < [audioClipFilePaths count]; i ++)
    {
        [self removeAudioClipFilePath:[audioClipFilePaths objectAtIndex:i] forSequence:sequence];
    }
    
    // Remove the sequence
    NSMutableArray *filePaths = [self sequenceFilePaths];
    [filePaths removeObject:[self filePathForSequence:sequence]];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", libraryFolder, [self filePathForSequence:sequence]] error:NULL];
    [sequenceLibrary setObject:filePaths forKey:@"sequenceFilePaths"];
    [self saveSequenceLibrary];
}

// Getter Methods

- (float)versionNumberForSequenceLibrary
{
    return [self versionNumberForDictionary:sequenceLibrary];
}

- (NSMutableArray *)sequenceFilePaths
{
    return [sequenceLibrary objectForKey:@"sequenceFilePaths"];
}

- (NSString *)sequenceFilePathAtIndex:(int)index
{
    return [[self sequenceFilePaths] objectAtIndex:index];
}

- (int)sequenceFilePathsCount
{
    return (int)[[self sequenceFilePaths] count];
}

// Setter Methods

- (void)setVersionNumberForSequenceLibraryTo:(float)newVersionNumber
{
    [self setVersionNumber:newVersionNumber forDictionary:sequenceLibrary];
    [self saveSequenceLibrary];
}

- (void)addSequenceFilePathToSequenceLibrary:(NSString *)filePath
{
    NSMutableArray *filePaths = [self sequenceFilePaths];
    [filePaths addObject:filePath];
    [sequenceLibrary setObject:filePaths forKey:@"sequenceFilePaths"];
    [self saveSequenceLibrary];
}

#pragma mark - Sequence Methods
// Getter Methods

- (float)versionNumberForSequence:(NSMutableDictionary *)sequence
{
    return [self versionNumberForDictionary:sequence];
}

- (NSString *)filePathForSequence:(NSMutableDictionary *)sequence
{
    return [self filePathForDictionary:sequence];
}

- (NSMutableDictionary *)sequenceFromFilePath:(NSString *)filePath
{
    return [self dictionaryFromFilePath:filePath];
}

- (NSString *)descriptionForSequence:(NSMutableDictionary *)sequence
{
    return [sequence objectForKey:@"description"];
}

- (float)startTimeForSequence:(NSMutableDictionary *)sequence
{
    return [[sequence objectForKey:@"startTime"] floatValue];
}

- (float)endTimeForSequence:(NSMutableDictionary *)sequence
{
    return [[sequence objectForKey:@"endTime"] floatValue];
}

- (NSMutableArray *)audioClipFilePathsForSequence:(NSMutableDictionary *)sequence
{
    return [sequence objectForKey:@"audioClipFilePaths"];
}

- (int)audioClipFilePathsCountForSequence:(NSMutableDictionary *)sequence
{
    return (int)[[self audioClipFilePathsForSequence:sequence] count];
}

- (NSString *)audioClipFilePathAtIndex:(int)index forSequence:(NSMutableDictionary *)sequence;
{
    return [[self audioClipFilePathsForSequence:sequence] objectAtIndex:index];
}

- (NSMutableArray *)controlBoxFilePathsForSequence:(NSMutableDictionary *)sequence
{
    return [sequence objectForKey:@"controlBoxFilePaths"];
}

- (int)controlBoxFilePathsCountForSequence:(NSMutableDictionary *)sequence
{
    return (int)[[self controlBoxFilePathsForSequence:sequence] count];
}

- (NSString *)controlBoxFilePathAtIndex:(int)index forSequence:(NSMutableDictionary *)sequence;
{
    return [[self controlBoxFilePathsForSequence:sequence] objectAtIndex:index];
}

- (NSMutableArray *)channelGroupFilePathsForSequence:(NSMutableDictionary *)sequence
{
    return [sequence objectForKey:@"channelGroupFilePaths"];
}

- (int)channelGroupFilePathsCountForSequence:(NSMutableDictionary *)sequence
{
    return (int)[[self channelGroupFilePathsForSequence:sequence] count];
}

- (NSString *)channelGroupFilePathAtIndex:(int)index forSequence:(NSMutableDictionary *)sequence;
{
    return [[self channelGroupFilePathsForSequence:sequence] objectAtIndex:index];
}

- (NSMutableArray *)commandClusterFilePathsForSequence:(NSMutableDictionary *)sequence
{
    return [sequence objectForKey:@"commandClusterFilePaths"];
}

- (int)commandClusterFilePathsCountForSequence:(NSMutableDictionary *)sequence
{
    return (int)[[self commandClusterFilePathsForSequence:sequence] count];
}

- (NSString *)commandClusterFilePathAtIndex:(int)index forSequence:(NSMutableDictionary *)sequence;
{
    return [[self commandClusterFilePathsForSequence:sequence] objectAtIndex:index];
}

// Setter Methods

- (void)setVersionNumber:(float)newVersionNumber forSequence:(NSMutableDictionary *)sequence
{
    [self setVersionNumber:newVersionNumber forDictionary:sequence];
    [self saveDictionaryToItsFilePath:sequence];
}

- (void)setDescription:(NSString *)description forSequence:(NSMutableDictionary *)sequence
{
    [sequence setObject:description forKey:@"description"];
    [self saveDictionaryToItsFilePath:sequence];
}

- (void)setStartTime:(float)startTIme forSequence:(NSMutableDictionary *)sequence
{
    [sequence setObject:[NSNumber numberWithFloat:startTIme] forKey:@"startTime"];
    [self saveDictionaryToItsFilePath:sequence];
}

- (void)setEndTime:(float)endTime forSequence:(NSMutableDictionary *)sequence
{
    [sequence setObject:[NSNumber numberWithFloat:endTime] forKey:@"endTime"];
    [self saveDictionaryToItsFilePath:sequence];
}

- (void)addAudioClipFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self audioClipFilePathsForSequence:sequence];
    [filePaths addObject:filePath];
    [sequence setObject:filePaths forKey:@"audioClipFilePaths"];
    [self saveDictionaryToItsFilePath:sequence];
    
    [self addBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
    
    // Load the NSSound
    if(sequence == currentSequence)
    {
        NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@", self.libraryFolder, [self filePathToAudioFileForAudioClip:[self audioClipFromFilePath:filePath]]];
        NSSound *newSound = [[NSSound alloc] initWithContentsOfFile:soundFilePath byReference:NO];
        [newSound setName:filePath];
        [newSound play];
        [newSound stop];
        [currentSequenceNSSounds addObject:newSound];
    }
}

- (void)removeAudioClipFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self audioClipFilePathsForSequence:sequence];
    [filePaths removeObject:filePath];
    [sequence setObject:filePaths forKey:@"audioClipFilePaths"];
    [self saveDictionaryToItsFilePath:sequence];
    
    [self removeBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
    
    // Unload the NSSound
    if(sequence == currentSequence)
    {
        for(int i = 0; i < [currentSequenceNSSounds count]; i ++)
        {
            if([[[currentSequenceNSSounds objectAtIndex:i] name] isEqualToString:filePath])
            {
                [currentSequenceNSSounds removeObjectAtIndex:i];
            }
        }
    }
}

- (void)addControlBoxFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self controlBoxFilePathsForSequence:sequence];
    [filePaths addObject:filePath];
    [sequence setObject:filePaths forKey:@"controlBoxFilePaths"];
    [self saveDictionaryToItsFilePath:sequence];
    
    [self addBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
}

- (void)removeControlBoxFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self controlBoxFilePathsForSequence:sequence];
    [filePaths removeObject:filePath];
    [sequence setObject:filePaths forKey:@"controlBoxFilePaths"];
    [self saveDictionaryToItsFilePath:sequence];
    
    [self removeBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
}

- (void)addChannelGroupFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self channelGroupFilePathsForSequence:sequence];
    [filePaths addObject:filePath];
    [sequence setObject:filePaths forKey:@"channelGroupFilePaths"];
    [self saveDictionaryToItsFilePath:sequence];
    
    [self addBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
}

- (void)removeChannelGroupFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self channelGroupFilePathsForSequence:sequence];
    [filePaths removeObject:filePath];
    [sequence setObject:filePaths forKey:@"channelGroupFilePaths"];
    [self saveDictionaryToItsFilePath:sequence];
    
    [self removeBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
}

- (void)addCommandClusterFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self commandClusterFilePathsForSequence:sequence];
    [filePaths addObject:filePath];
    [sequence setObject:filePaths forKey:@"commandClusterFilePaths"];
    [self saveDictionaryToItsFilePath:sequence];
    
    [self addBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
}

- (void)removeCommandClusterFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self commandClusterFilePathsForSequence:sequence];
    [filePaths removeObject:filePath];
    [sequence setObject:filePaths forKey:@"commandClusterFilePaths"];
    [self saveDictionaryToItsFilePath:sequence];
    
    [self removeBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
}

#pragma mark - ControlBox Library Methods
// Management Methods

- (NSString *)createControlBoxAndReturnFilePath
{
    NSMutableDictionary *newControlBox = [[NSMutableDictionary alloc] init];
    NSMutableArray *channelsForControlBox = [[NSMutableArray alloc] init];
    NSMutableArray *beingUsedInSequenceFilePaths = [[NSMutableArray alloc] init];
    [newControlBox setObject:beingUsedInSequenceFilePaths forKey:@"beingUsedInSequenceFilePaths"];
    [newControlBox setObject:channelsForControlBox forKey:@"channels"];
    
    // New files get a file name chosen by availble numbers (detemined by @selector(nextAvailableNumberForFilePaths))
    NSString *filePath = [NSString stringWithFormat:@"controlBoxLibrary/%@.lmcb", [self nextAvailableNumberForFilePaths:[self controlBoxFilePaths]]];
    [self addControlBoxFilePathToControlBoxLibrary:filePath];
    [self setFilePath:filePath forDictionary:newControlBox];
    
    [newControlBox writeToFile:[NSString stringWithFormat:@"%@/%@", libraryFolder, filePath] atomically:YES];
    [self setVersionNumber:DATA_VERSION_NUMBER forControlBox:newControlBox];
    [self setDescription:@"New Control Box" forControlBox:newControlBox];
    [self setControlBoxID:@"0" forControlBox:newControlBox];
    
    return filePath;
}

- (NSString *)createCopyOfControlBoxAndReturnFilePath:(NSMutableDictionary *)controlBox
{
    NSString *newControlBoxFilePath = [self createControlBoxAndReturnFilePath];
    NSMutableDictionary *newControlBox = [self dictionaryFromFilePath:newControlBoxFilePath];
    [newControlBox setObject:[self dictionaryBeingUsedInSequenceFilePaths:controlBox] forKey:@"beingUsedInSequenceFilePaths"];
    [newControlBox setObject:[self channelsForControlBox:controlBox] forKey:@"channels"];
    [self setDescription:[NSString stringWithFormat:@"%@ Copy", [self descriptionForControlBox:controlBox]] forControlBox:newControlBox];
    [self setControlBoxID:[self controlBoxIDForControlBox:controlBox] forControlBox:newControlBox];
    
    return newControlBoxFilePath;
}

- (void)removeControlBoxFromLibrary:(NSMutableDictionary *)controlBox
{
    // Remove the controlBox from any sequences
    NSMutableArray *sequenceFilePaths = [self controlBoxBeingUsedInSequenceFilePaths:controlBox];
    for(int i = 0; i < [sequenceFilePaths count]; i ++)
    {
        [self removeControlBoxFilePath:[self filePathForControlBox:controlBox] forSequence:[self sequenceFromFilePath:[sequenceFilePaths objectAtIndex:i]]];
    }
    
    // Remove the Control Box
    NSMutableArray *filePaths = [self controlBoxFilePaths];
    [filePaths removeObject:[self filePathForControlBox:controlBox]];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", libraryFolder, [self filePathForControlBox:controlBox]] error:NULL];
    [controlBoxLibrary setObject:filePaths forKey:@"controlBoxFilePaths"];
    [self saveControlBoxLibrary];
}

// Getter Methods

- (float)versionNumberForControlBoxLibrary
{
    return [self versionNumberForDictionary:controlBoxLibrary];
}

- (NSMutableArray *)controlBoxFilePaths
{
    return [controlBoxLibrary objectForKey:@"controlBoxFilePaths"];
}

- (NSString *)controlBoxFilePathAtIndex:(int)index
{
    return [[self controlBoxFilePaths] objectAtIndex:index];
}

- (int)controlBoxFilePathsCount
{
    return (int)[[self controlBoxFilePaths] count];
}

// Setter Methods
- (void)setVersionNumberForControlBoxLibraryTo:(float)newVersionNumber
{
    [self setVersionNumber:newVersionNumber forDictionary:controlBoxLibrary];
    [self saveControlBoxLibrary];
}

- (void)addControlBoxFilePathToControlBoxLibrary:(NSString *)filePath
{
    NSMutableArray *filePaths = [self controlBoxFilePaths];
    [filePaths addObject:filePath];
    [controlBoxLibrary setObject:filePaths forKey:@"controlBoxFilePaths"];
    [self saveControlBoxLibrary];
}

#pragma mark - ControlBox Methods
// Getter Methods

- (float)versionNumberForControlBox:(NSMutableDictionary *)controlBox
{
    return [self versionNumberForDictionary:controlBox];
}

- (NSString *)filePathForControlBox:(NSMutableDictionary *)controlBox
{
    return [self filePathForDictionary:controlBox];
}

- (NSMutableDictionary *)controlBoxFromFilePath:(NSString *)filePath
{
    return [self dictionaryFromFilePath:filePath];
}

- (NSString *)controlBoxIDForControlBox:(NSMutableDictionary *)controlBox
{
    return [controlBox objectForKey:@"controlBoxID"];
}

- (NSString *)descriptionForControlBox:(NSMutableDictionary *)controlBox
{
    return [controlBox objectForKey:@"description"];
}

- (NSMutableArray *)controlBoxBeingUsedInSequenceFilePaths:(NSMutableDictionary *)controlBox
{
    return [self dictionaryBeingUsedInSequenceFilePaths:controlBox];
}

- (int)controlBoxBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)controlBox
{
    return [self dictionaryBeingUsedInSequenceFilePathsCount:controlBox];
}

- (NSString *)controlBox:(NSMutableDictionary *)controlBox beingUsedInSequenceFilePathAtIndex:(int)index
{
    return [self dictionary:controlBox beingUsedInSequenceFilePathAtIndex:index];
}

- (NSMutableArray *)channelsForControlBox:(NSMutableDictionary *)controlBox
{
    return [controlBox objectForKey:@"channels"];
}

- (int)channelsCountForControlBox:(NSMutableDictionary *)controlBox
{
    return (int)[[self channelsForControlBox:controlBox] count];
}

- (NSMutableDictionary *)channelAtIndex:(int)index forControlBox:(NSMutableDictionary *)controlBox
{
    return [[self channelsForControlBox:controlBox] objectAtIndex:index];
}

- (NSNumber *)numberForChannel:(NSMutableDictionary *)channel
{
    return [channel objectForKey:@"number"];
}

- (NSString *)colorForChannel:(NSMutableDictionary *)channel
{
    return [channel objectForKey:@"color"];
}

- (NSString *)descriptionForChannel:(NSMutableDictionary *)channel
{
    return [channel objectForKey:@"description"];
}

// Setter Methods

- (void)setVersionNumber:(float)newVersionNumber forControlBox:(NSMutableDictionary *)controlBox
{
    [self setVersionNumber:newVersionNumber forDictionary:controlBox];
    [self saveDictionaryToItsFilePath:controlBox];
}

- (void)setControlBoxID:(NSString *)ID forControlBox:(NSMutableDictionary *)controlBox
{
    [controlBox setObject:ID forKey:@"controlBoxID"];
    [self saveDictionaryToItsFilePath:controlBox];
}

- (void)setDescription:(NSString *)description forControlBox:(NSMutableDictionary *)controlBox
{
    [controlBox setObject:description forKey:@"description"];
    [self saveDictionaryToItsFilePath:controlBox];
}

- (int)addChannelAndReturnNewChannelIndexForControlBox:(NSMutableDictionary *)controlBox
{
    NSMutableDictionary *newChannel = [[NSMutableDictionary alloc] init];
    [newChannel setObject:[NSNumber numberWithFloat:DATA_VERSION_NUMBER] forKey:@"versionNumber"];
    [newChannel setObject:[NSNumber numberWithInt:[self channelsCountForControlBox:controlBox]] forKey:@"number"];
    [newChannel setObject:@"White" forKey:@"color"];
    [newChannel setObject:@"New Channel" forKey:@"description"];
    
    NSMutableArray *channels = [self channelsForControlBox:controlBox];
    [channels addObject:newChannel];
    [controlBox setObject:channels forKey:@"channels"];
    int index = (int)[channels count] - 1;
    
    [self saveDictionaryToItsFilePath:controlBox];
    
    return index;
}

- (void)removeChannel:(NSMutableDictionary *)channel forControlBox:(NSMutableDictionary *)controlBox
{
    NSMutableArray *channels = [self channelsForControlBox:controlBox];
    [channels removeObject:channel];
    [controlBox setObject:channels forKey:@"channels"];
    [self saveDictionaryToItsFilePath:controlBox];
}

- (void)setNumber:(int)number forChannelAtIndex:(int)index whichIsPartOfControlBox:(NSMutableDictionary *)controlBox
{
    NSMutableArray *channels = [self channelsForControlBox:controlBox];
    NSMutableDictionary *channel = [channels objectAtIndex:index];
    [channel setObject:[NSNumber numberWithInt:number] forKey:@"number"];
    [channels replaceObjectAtIndex:index withObject:channel];
    [controlBox setObject:channels forKey:@"channels"];
    [self saveDictionaryToItsFilePath:controlBox];
}

- (void)setColor:(NSString *)color forChannelAtIndex:(int)index whichIsPartOfControlBox:(NSMutableDictionary *)controlBox
{
    NSMutableArray *channels = [self channelsForControlBox:controlBox];
    NSMutableDictionary *channel = [channels objectAtIndex:index];
    [channel setObject:color forKey:@"color"];
    [channels replaceObjectAtIndex:index withObject:channel];
    [controlBox setObject:channels forKey:@"channels"];
    [self saveDictionaryToItsFilePath:controlBox];
}

- (void)setDescription:(NSString *)description forChannelAtIndex:(int)index whichIsPartOfControlBox:(NSMutableDictionary *)controlBox
{
    NSMutableArray *channels = [self channelsForControlBox:controlBox];
    NSMutableDictionary *channel = [channels objectAtIndex:index];
    [channel setObject:description forKey:@"description"];
    [channels replaceObjectAtIndex:index withObject:channel];
    [controlBox setObject:channels forKey:@"channels"];
    [self saveDictionaryToItsFilePath:controlBox];
}

#pragma mark - ChannelGroupLibrary Methods
// Management Methods
- (NSString *)createChannelGroupAndReturnFilePath
{
    NSMutableDictionary *newChannelGroup = [[NSMutableDictionary alloc] init];
    NSMutableArray *items = [[NSMutableArray alloc] init];
    NSMutableArray *beingUsedInSequenceFilePaths = [[NSMutableArray alloc] init];
    [newChannelGroup setObject:beingUsedInSequenceFilePaths forKey:@"beingUsedInSequenceFilePaths"];
    [newChannelGroup setObject:items forKey:@"items"];
    
    // New files get a file name chosen by availble numbers (detemined by @selector(nextAvailableNumberForFilePaths))
    NSString *filePath = [NSString stringWithFormat:@"channelGroupLibrary/%@.lmgp", [self nextAvailableNumberForFilePaths:[self channelGroupFilePaths]]];
    [self addChannelGroupFilePathToChannelGroupLibrary:filePath];
    [self setFilePath:filePath forDictionary:newChannelGroup];
    
    [newChannelGroup writeToFile:[NSString stringWithFormat:@"%@/%@", libraryFolder, filePath] atomically:YES];
    [self setVersionNumber:DATA_VERSION_NUMBER forChannelGroup:newChannelGroup];
    [self setDescription:@"New ChannelGroup" forChannelGroup:newChannelGroup];
    
    return filePath;
}

- (NSString *)createCopyOfChannelGroupAndReturnFilePath:(NSMutableDictionary *)channelGroup
{
    NSString *newChannelGroupFilePath = [self createChannelGroupAndReturnFilePath];
    NSMutableDictionary *newChannelGroup = [self dictionaryFromFilePath:newChannelGroupFilePath];
    [newChannelGroup setObject:[self dictionaryBeingUsedInSequenceFilePaths:channelGroup] forKey:@"beingUsedInSequenceFilePaths"];
    [newChannelGroup setObject:[self itemsForChannelGroup:channelGroup] forKey:@"items"];
    [self setDescription:[NSString stringWithFormat:@"%@ Copy", [self descriptionForChannelGroup:channelGroup]] forChannelGroup:newChannelGroup];
    
    return newChannelGroupFilePath;
}

- (void)removeChannelGroupFromLibrary:(NSMutableDictionary *)channelGroup
{
    // Remove the channelGroup from any sequences
    NSMutableArray *sequenceFilePaths = [self channelGroupBeingUsedInSequenceFilePaths:channelGroup];
    for(int i = 0; i < [sequenceFilePaths count]; i ++)
    {
        [self removeChannelGroupFilePath:[self filePathForChannelGroup:channelGroup] forSequence:[self sequenceFromFilePath:[sequenceFilePaths objectAtIndex:i]]];
    }
    
    NSMutableArray *filePaths = [self channelGroupFilePaths];
    [filePaths removeObject:[self filePathForChannelGroup:channelGroup]];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", libraryFolder, [self filePathForChannelGroup:channelGroup]] error:NULL];
    [channelGroupLibrary setObject:filePaths forKey:@"channelGroupFilePaths"];
    [self saveChannelGroupLibrary];
}

// Getter Methods

- (float)channelGroupLibraryVersionNumber
{
    return [self versionNumberForDictionary:channelGroupLibrary];
}

- (NSMutableArray *)channelGroupFilePaths
{
    return [channelGroupLibrary objectForKey:@"channelGroupFilePaths"];
}

- (NSString *)channelGroupFilePathAtIndex:(int)index
{
    return [[self channelGroupFilePaths] objectAtIndex:index];
}

- (int)channelGroupFilePathsCount
{
    return (int)[[self channelGroupFilePaths] count];
}

// Setter Methods
- (void)setVersionNumberForChannelGroupLibraryTo:(float)newVersionNumber
{
    [self setVersionNumber:newVersionNumber forDictionary:channelGroupLibrary];
    [self saveChannelGroupLibrary];
}

- (void)addChannelGroupFilePathToChannelGroupLibrary:(NSString *)filePath
{
    NSMutableArray *filePaths = [self channelGroupFilePaths];
    [filePaths addObject:filePath];
    [channelGroupLibrary setObject:filePaths forKey:@"channelGroupFilePaths"];
    [self saveChannelGroupLibrary];
}

#pragma mark - ChannelGroup Methods
// Getter Methods

- (float)versionNumberForChannelGroup:(NSMutableDictionary *)channelGroup
{
    return [self versionNumberForDictionary:channelGroup];
}

- (NSString *)filePathForChannelGroup:(NSMutableDictionary *)channelGroup
{
    return [self filePathForDictionary:channelGroup];
}

- (NSMutableDictionary *)channelGroupFromFilePath:(NSString *)filePath
{
    return [self dictionaryFromFilePath:filePath];
}

- (NSString *)descriptionForChannelGroup:(NSMutableDictionary *)channelGroup
{
    return [channelGroup objectForKey:@"description"];
}

- (NSMutableArray *)channelGroupBeingUsedInSequenceFilePaths:(NSMutableDictionary *)channelGroup
{
    return [self dictionaryBeingUsedInSequenceFilePaths:channelGroup];
}

- (int)channelGroupBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)channelGroup
{
    return [self dictionaryBeingUsedInSequenceFilePathsCount:channelGroup];
}

- (NSString *)channelGroup:(NSMutableDictionary *)channelGroup beingUsedInSequenceFilePathAtIndex:(int)index
{
    return [self dictionary:channelGroup beingUsedInSequenceFilePathAtIndex:index];
}

- (NSMutableArray *)itemsForChannelGroup:(NSMutableDictionary *)channelGroup
{
    return [channelGroup objectForKey:@"items"];
}

- (int)itemsCountForChannelGroup:(NSMutableDictionary *)channelGroup
{
    return (int)[[self itemsForChannelGroup:channelGroup] count];
}

- (NSMutableDictionary *)itemDataAtIndex:(int)index forChannelGroup:(NSMutableDictionary *)channelGroup
{
    return [[self itemsForChannelGroup:channelGroup] objectAtIndex:index];
}

- (NSString *)controlBoxFilePathForItemData:(NSMutableDictionary *)itemData
{
    return [itemData objectForKey:@"controlBoxFilePath"];
}

- (int)channelIndexForItemData:(NSMutableDictionary *)itemData
{
    return [[itemData objectForKey:@"channelIndex"] intValue];
}

// Setter Methods

- (void)setVersionNumber:(float)newVersionNumber forChannelGroup:(NSMutableDictionary *)channelGroup
{
    [self setVersionNumber:newVersionNumber forDictionary:channelGroup];
    [self saveDictionaryToItsFilePath:channelGroup];
}

- (void)setDescription:(NSString *)description forChannelGroup:(NSMutableDictionary *)channelGroup
{
    [channelGroup setObject:description forKey:@"description"];
    [self saveDictionaryToItsFilePath:channelGroup];
}

- (int)createItemDataAndReturnNewItemIndexForChannelGroup:(NSMutableDictionary *)channelGroup
{
    NSMutableDictionary *newItemData = [[NSMutableDictionary alloc] init];
    [self setVersionNumber:DATA_VERSION_NUMBER forDictionary:newItemData];
    
    NSMutableArray *items = [self itemsForChannelGroup:channelGroup];
    [items addObject:newItemData];
    [channelGroup setObject:items forKey:@"commands"];
    int index = (int)[items count] - 1;
    
    [self saveDictionaryToItsFilePath:channelGroup];
    [self setChannelIndex:0 forItemDataAtIndex:index whichIsPartOfChannelGroup:channelGroup];
    
    return index;
}

- (void)removeItemData:(NSMutableDictionary *)itemData forChannelGroup:(NSMutableDictionary *)channelGroup
{
    NSMutableArray *items = [self itemsForChannelGroup:channelGroup];
    [items removeObject:itemData];
    [channelGroup setObject:items forKey:@"items"];
    [self saveDictionaryToItsFilePath:channelGroup];
}

- (void)setControlBoxFilePath:(NSString *)filePath forItemDataAtIndex:(int)index whichIsPartOfChannelGroup:(NSMutableDictionary *)channelGroup
{
    NSMutableArray *items = [self itemsForChannelGroup:channelGroup];
    NSMutableDictionary *itemData = [items objectAtIndex:index];
    [itemData setObject:filePath forKey:@"controlBoxFilePath"];
    [items replaceObjectAtIndex:index withObject:itemData];
    [channelGroup setObject:items forKey:@"items"];
    [self saveDictionaryToItsFilePath:channelGroup];
}

- (void)setChannelIndex:(int)channelIndex forItemDataAtIndex:(int)index whichIsPartOfChannelGroup:(NSMutableDictionary *)channelGroup
{
    NSMutableArray *items = [self itemsForChannelGroup:channelGroup];
    NSMutableDictionary *itemData = [items objectAtIndex:index];
    [itemData setObject:[NSNumber numberWithInt:channelIndex] forKey:@"channelIndex"];
    [items replaceObjectAtIndex:index withObject:itemData];
    [channelGroup setObject:items forKey:@"items"];
    [self saveDictionaryToItsFilePath:channelGroup];
}

#pragma mark - CommandClusterLibrary Methods
// Management Methods

- (NSString *)createCommandClusterAndReturnFilePath
{
    NSMutableDictionary *newCommandCluster = [[NSMutableDictionary alloc] init];
    NSMutableArray *commands = [[NSMutableArray alloc] init];
    NSMutableArray *beingUsedInSequenceFilePaths = [[NSMutableArray alloc] init];
    [newCommandCluster setObject:beingUsedInSequenceFilePaths forKey:@"beingUsedInSequenceFilePaths"];
    [newCommandCluster setObject:commands forKey:@"commands"];
    [newCommandCluster setObject:@"" forKey:@"controlBoxFilePath"];
    [newCommandCluster setObject:@"" forKey:@"channelGroupFilePath"];
    
    // New files get a file name chosen by availble numbers (detemined by @selector(nextAvailableNumberForFilePaths))
    NSString *filePath = [NSString stringWithFormat:@"commandClusterLibrary/%@.lmcc", [self nextAvailableNumberForFilePaths:[self commandClusterFilePaths]]];
    [self addCommandClusterFilePathToCommandClusterLibrary:filePath];
    [self setFilePath:filePath forDictionary:newCommandCluster];
    
    [newCommandCluster writeToFile:[NSString stringWithFormat:@"%@/%@", libraryFolder, filePath] atomically:YES];
    [self setVersionNumber:DATA_VERSION_NUMBER forCommandCluster:newCommandCluster];
    [self setDescription:@"New Command Cluster" forCommandCluster:newCommandCluster];
    [self setEndTime:1.0 forCommandcluster:newCommandCluster];
    
    return filePath;
}

- (NSString *)createCopyOfCommandClusterAndReturnFilePath:(NSMutableDictionary *)commandCluster
{
    NSString *newCommandClusterFilePath = [self createCommandClusterAndReturnFilePath];
    NSMutableDictionary *newCommandCluster = [self dictionaryFromFilePath:newCommandClusterFilePath];
    [newCommandCluster setObject:[self dictionaryBeingUsedInSequenceFilePaths:commandCluster] forKey:@"beingUsedInSequenceFilePaths"];
    [newCommandCluster setObject:[self commandsFromCommandCluster:commandCluster] forKey:@"commands"];
    [self setDescription:[NSString stringWithFormat:@"%@ Copy", [self descriptionForCommandCluster:commandCluster]] forCommandCluster:newCommandCluster];
    [self setControlBoxFilePath:[self controlBoxFilePathForCommandCluster:commandCluster] forCommandCluster:newCommandCluster];
    [self setChannelGroupFilePath:[self channelGroupFilePathForCommandCluster:commandCluster] forCommandCluster:newCommandCluster];
    [self setStartTime:[self startTimeForCommandCluster:commandCluster] forCommandCluster:newCommandCluster];
    [self setEndTime:[self endTimeForCommandCluster:commandCluster] forCommandcluster:newCommandCluster];
    
    return newCommandClusterFilePath;
}

- (void)removeCommandClusterFromLibrary:(NSMutableDictionary *)commandCluster
{
    // Remove the commandCluster from any sequences
    NSMutableArray *sequenceFilePaths = [self commandClusterBeingUsedInSequenceFilePaths:commandCluster];
    for(int i = 0; i < [sequenceFilePaths count]; i ++)
    {
        [self removeCommandClusterFilePath:[self filePathForCommandCluster:commandCluster] forSequence:[self sequenceFromFilePath:[sequenceFilePaths objectAtIndex:i]]];
    }
    
    NSMutableArray *filePaths = [self commandClusterFilePaths];
    [filePaths removeObject:[self filePathForCommandCluster:commandCluster]];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", libraryFolder, [self filePathForCommandCluster:commandCluster]] error:NULL];
    [commandClusterLibrary setObject:filePaths forKey:@"commandClusterFilePaths"];
    [self saveCommandClusterLibrary];
}

// Getter Methods

- (float)versionNumberForCommandClusterLibrary
{
    return [self versionNumberForDictionary:commandClusterLibrary];
}

- (NSMutableArray *)commandClusterFilePaths
{
    return [commandClusterLibrary objectForKey:@"commandClusterFilePaths"];
}

- (NSString *)commandClusterFilePathAtIndex:(int)index
{
    return [[self commandClusterFilePaths] objectAtIndex:index];
}

- (int)commandClusterFilePathsCount
{
    return (int)[[self commandClusterFilePaths] count];
}

// Setter Methods
- (void)setVersionNumberForCommandClusterLibraryTo:(float)newVersionNumber
{
    [self setVersionNumber:newVersionNumber forDictionary:commandClusterLibrary];
    [self saveCommandClusterLibrary];
}

- (void)addCommandClusterFilePathToCommandClusterLibrary:(NSString *)filePath
{
    NSMutableArray *filePaths = [self commandClusterFilePaths];
    [filePaths addObject:filePath];
    [commandClusterLibrary setObject:filePaths forKey:@"commandClusterFilePaths"];
    [self saveCommandClusterLibrary];
}

#pragma mark - CommandCluster Methods
// Getter Methods

- (float)versionNumberForCommandCluster:(NSMutableDictionary *)commandCluster
{
    return [self versionNumberForDictionary:commandCluster];
}

- (NSString *)filePathForCommandCluster:(NSMutableDictionary *)commandCluster
{
    return [self filePathForDictionary:commandCluster];
}

- (NSMutableDictionary *)commandClusterFromFilePath:(NSString *)filePath
{
    return [self dictionaryFromFilePath:filePath];
}

- (NSString *)descriptionForCommandCluster:(NSMutableDictionary *)commandCluster
{
    return [commandCluster objectForKey:@"description"];
}

- (NSMutableArray *)commandClusterBeingUsedInSequenceFilePaths:(NSMutableDictionary *)commandCluster
{
    return [self dictionaryBeingUsedInSequenceFilePaths:commandCluster];
}

- (int)commandClusterBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)commandCluster
{
    return [self dictionaryBeingUsedInSequenceFilePathsCount:commandCluster];
}

- (NSString *)commandCluster:(NSMutableDictionary *)commandCluster beingUsedInSequenceFilePathAtIndex:(int)index
{
    return [self dictionary:commandCluster beingUsedInSequenceFilePathAtIndex:index];
}

- (NSString *)controlBoxFilePathForCommandCluster:(NSMutableDictionary *)commandCluster
{
    return [commandCluster objectForKey:@"controlBoxFilePath"];
}

- (NSString *)channelGroupFilePathForCommandCluster:(NSMutableDictionary *)commandCluster
{
    return [commandCluster objectForKey:@"channelGroupFilePath"];
}

- (float)startTimeForCommandCluster:(NSMutableDictionary *)commandCluster
{
    return [[commandCluster objectForKey:@"startTime"] floatValue];
}

- (float)endTimeForCommandCluster:(NSMutableDictionary *)commandCluster
{
    return [[commandCluster objectForKey:@"endTime"] floatValue];
}

- (NSString *)audioClipFilePathForCommandCluster:(NSMutableDictionary *)commandCluster
{
    return [commandCluster objectForKey:@"audioClipFilePath"];
}

- (NSMutableArray *)commandsFromCommandCluster:(NSMutableDictionary *)commandCluster
{
    return [commandCluster objectForKey:@"commands"];
}

- (int)commandsCountForCommandCluster:(NSMutableDictionary *)commandCluster
{
    return (int)[[self commandsFromCommandCluster:commandCluster] count];
}

- (NSMutableDictionary *)commandAtIndex:(int)index fromCommandCluster:(NSMutableDictionary *)commandCluster
{
    return [[self commandsFromCommandCluster:commandCluster] objectAtIndex:index];
}

- (float)startTimeForCommand:(NSMutableDictionary *)command
{
    return [[command objectForKey:@"startTime"] floatValue];
}

- (float)endTimeForCommand:(NSMutableDictionary *)command
{
    return [[command objectForKey:@"endTime"] floatValue];
}

- (int)channelIndexForCommand:(NSMutableDictionary *)command
{
    return [[command objectForKey:@"channelIndex"] intValue];
}

- (int)brightnessForCommand:(NSMutableDictionary *)command
{
    return [[command objectForKey:@"brightness"] intValue];
}

- (float)fadeInDurationForCommand:(NSMutableDictionary *)command
{
    return [[command objectForKey:@"fadeInDuration"] floatValue];
}

- (float)fadeOutDurationForCommand:(NSMutableDictionary *)command
{
    return [[command objectForKey:@"fadeOutDuration"] floatValue];
}

// Setter Methods

- (void)setVersionNumber:(float)newVersionNumber forCommandCluster:(NSMutableDictionary *)commandCluster
{
    [self setVersionNumber:newVersionNumber forDictionary:commandCluster];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (void)setDescription:(NSString *)description forCommandCluster:(NSMutableDictionary *)commandCluster
{
    [commandCluster setObject:description forKey:@"description"];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (void)setControlBoxFilePath:(NSString *)filePath forCommandCluster:(NSMutableDictionary *)commandCluster
{
    [commandCluster setObject:filePath forKey:@"controlBoxFilePath"];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (void)setChannelGroupFilePath:(NSString *)filePath forCommandCluster:(NSMutableDictionary *)commandCluster
{
    [commandCluster setObject:filePath forKey:@"channelGroupFilePath"];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (void)setStartTime:(float)time forCommandCluster:(NSMutableDictionary *)commandCluster
{
    [commandCluster setObject:[NSNumber numberWithFloat:time] forKey:@"startTime"];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (void)setEndTime:(float)time forCommandcluster:(NSMutableDictionary *)commandCluster
{
    
    [commandCluster setObject:[NSNumber numberWithFloat:time] forKey:@"endTime"];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (void)moveCommandCluster:(NSMutableDictionary *)commandCluster byTime:(float)time
{
    // Adjust all of the times for the commands
    for(int i = 0; i < [self commandsCountForCommandCluster:commandCluster]; i ++)
    {
        [self setStartTime:([self startTimeForCommand:[self commandAtIndex:i fromCommandCluster:commandCluster]] + time) forCommandAtIndex:i whichIsPartOfCommandCluster:commandCluster];
        [self setEndTime:([self endTimeForCommand:[self commandAtIndex:i fromCommandCluster:commandCluster]] + time) forCommandAtIndex:i whichIsPartOfCommandCluster:commandCluster];
    }
    
    [self setStartTime:[self startTimeForCommandCluster:commandCluster] + time forCommandCluster:commandCluster];
    [self setEndTime:[self endTimeForCommandCluster:commandCluster] + time forCommandcluster:commandCluster];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (void)moveCommandCluster:(NSMutableDictionary *)commandCluster toStartTime:(float)startTime
{
    float startTimeOffset = startTime - [self startTimeForCommandCluster:commandCluster];
    
    [self moveCommandCluster:commandCluster byTime:startTimeOffset];
}

- (void)setAudioClipFilePath:(NSString *)filePath forCommandCluster:(NSMutableDictionary *)commandCluster
{
    [commandCluster setObject:filePath forKey:@"audioClipFilePath"];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (int)createCommandAndReturnNewCommandIndexForCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableDictionary *newCommand = [[NSMutableDictionary alloc] init];
    [self setVersionNumber:DATA_VERSION_NUMBER forDictionary:newCommand];
    
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    [commands addObject:newCommand];
    [commandCluster setObject:commands forKey:@"commands"];
    int index = (int)[commands count] - 1;
    
    [self saveDictionaryToItsFilePath:commandCluster];
    [self setChannelIndex:0 forCommandAtIndex:index whichIsPartOfCommandCluster:commandCluster];
    [self setEndTime:1.0 forCommandAtIndex:index whichIsPartOfCommandCluster:commandCluster];
    [self setBrightness:100 forCommandAtIndex:index whichIsPartOfCommandCluster:commandCluster];
    
    return index;
}

- (void)removeCommand:(NSMutableDictionary *)command fromCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    [commands removeObject:command];
    [commandCluster setObject:commands forKey:@"commands"];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (void)setStartTime:(float)time forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    NSMutableDictionary *command = [commands objectAtIndex:index];
    [command setObject:[NSNumber numberWithFloat:time] forKey:@"startTime"];
    [commands replaceObjectAtIndex:index withObject:command];
    [commandCluster setObject:commands forKey:@"commands"];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (void)setEndTime:(float)time forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    NSMutableDictionary *command = [commands objectAtIndex:index];
    [command setObject:[NSNumber numberWithFloat:time] forKey:@"endTime"];
    [commands replaceObjectAtIndex:index withObject:command];
    [commandCluster setObject:commands forKey:@"commands"];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (void)moveCommandAtIndex:(int)index byTime:(float)time whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster
{
    [self setStartTime:[self startTimeForCommand:[self commandAtIndex:index fromCommandCluster:commandCluster]] + time forCommandAtIndex:index whichIsPartOfCommandCluster:commandCluster];
    [self setEndTime:[self endTimeForCommand:[self commandAtIndex:index fromCommandCluster:commandCluster]] + time forCommandAtIndex:index whichIsPartOfCommandCluster:commandCluster];
}

- (void)moveCommandAtIndex:(int)index toStartTime:(float)startTime whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster
{
    float startTimeOffset = startTime - [self startTimeForCommand:[self commandAtIndex:index fromCommandCluster:commandCluster]];
    
    [self moveCommandAtIndex:index byTime:startTimeOffset whichIsPartOfCommandCluster:commandCluster];
}

- (void)setChannelIndex:(int)channelIndex forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    NSMutableDictionary *command = [commands objectAtIndex:index];
    [command setObject:[NSNumber numberWithInt:channelIndex] forKey:@"channelIndex"];
    [commands replaceObjectAtIndex:index withObject:command];
    [commandCluster setObject:commands forKey:@"commands"];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (void)setBrightness:(int)brightness forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    NSMutableDictionary *command = [commands objectAtIndex:index];
    [command setObject:[NSNumber numberWithInt:brightness] forKey:@"brightness"];
    [commands replaceObjectAtIndex:index withObject:command];
    [commandCluster setObject:commands forKey:@"commands"];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (void)setFadeInDuration:(int)fadeInDuration forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    NSMutableDictionary *command = [commands objectAtIndex:index];
    [command setObject:[NSNumber numberWithFloat:fadeInDuration] forKey:@"fadeInDuration"];
    [commands replaceObjectAtIndex:index withObject:command];
    [commandCluster setObject:commands forKey:@"commands"];
    [self saveDictionaryToItsFilePath:commandCluster];
}

- (void)setFadeOutDuration:(int)fadeOutDuration forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    NSMutableDictionary *command = [commands objectAtIndex:index];
    [command setObject:[NSNumber numberWithFloat:fadeOutDuration] forKey:@"fadeOutDuration"];
    [commands replaceObjectAtIndex:index withObject:command];
    [commandCluster setObject:commands forKey:@"commands"];
    [self saveDictionaryToItsFilePath:commandCluster];
}

#pragma mark - EffectLibrary Methods
// Management Methods

- (NSString *)createEffectAndReturnFilePath
{
    NSMutableDictionary *newEffect = [[NSMutableDictionary alloc] init];
    
    // New files get a file name chosen by availble numbers (detemined by @selector(nextAvailableNumberForFilePaths))
    NSString *filePath = [NSString stringWithFormat:@"effectLibrary/%@.lmef", [self nextAvailableNumberForFilePaths:[self effectFilePaths]]];
    [self addEffectFilePathToEffectLibrary:filePath];
    [self setFilePath:filePath forDictionary:newEffect];
    
    [newEffect writeToFile:[NSString stringWithFormat:@"%@/%@", libraryFolder, filePath] atomically:YES];
    [self setVersionNumber:DATA_VERSION_NUMBER forEffect:newEffect];
    [self setDescription:@"New Effect" forEffect:newEffect];
    [self setScript:@"// This is a new effect script\n" forEffect:newEffect];
    
    return filePath;
}

- (NSString *)createCopyOfEffectAndReturnFilePath:(NSMutableDictionary *)effect
{
    NSString *newEffectFilePath = [self createEffectAndReturnFilePath];
    NSMutableDictionary *newEffect = [self dictionaryFromFilePath:newEffectFilePath];
    [self setDescription:[NSString stringWithFormat:@"%@ Copy", [self descriptionForEffect:effect]] forEffect:newEffect];
    [self setScript:[self scriptForEffect:effect] forEffect:newEffect];
    
    return newEffectFilePath;
}

- (void)removeEffectFromLibrary:(NSMutableDictionary *)effect
{
    NSMutableArray *filePaths = [self effectFilePaths];
    [filePaths removeObject:[self filePathForEffect:effect]];
    [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@", libraryFolder, [self filePathForEffect:effect]] error:NULL];
    [effectLibrary setObject:filePaths forKey:@"effectFilePaths"];
    [self saveEffectLibrary];
}

// Getter Methods

- (float)versionNumberForEffectLibrary
{
    return [self versionNumberForDictionary:effectLibrary];
}

- (NSMutableArray *)effectFilePaths
{
    return [effectLibrary objectForKey:@"effectFilePaths"];
}

- (NSString *)effectFilePathAtIndex:(int)index
{
    return [[self effectFilePaths] objectAtIndex:index];
}

- (int)effectFilePathsCount
{
    return (int)[[self effectFilePaths] count];
}

// Setter Methods
- (void)setVersionNumberForEffectLibraryTo:(float)newVersionNumber
{
    [self setVersionNumber:newVersionNumber forDictionary:effectLibrary];
    [self saveEffectLibrary];
}

- (void)addEffectFilePathToEffectLibrary:(NSString *)filePath
{
    NSMutableArray *filePaths = [self effectFilePaths];
    [filePaths addObject:filePath];
    [effectLibrary setObject:filePaths forKey:@"effectFilePaths"];
    [self saveEffectLibrary];
}

#pragma mark - Effect Methods
// Getter Methods

- (float)versionNumberforEffect:(NSMutableDictionary *)effect
{
    return [self versionNumberForDictionary:effect];
}

- (NSString *)filePathForEffect:(NSMutableDictionary *)effect
{
    return [self filePathForDictionary:effect];
}

- (NSMutableDictionary *)effectFromFilePath:(NSString *)filePath
{
    return [self dictionaryFromFilePath:filePath];
}

- (NSString *)descriptionForEffect:(NSMutableDictionary *)effect
{
    return [effect objectForKey:@"description"];
}

- (NSString *)parametersForEffect:(NSMutableDictionary *)effect
{
    return [effect objectForKey:@"parameters"];
}

- (NSString *)scriptForEffect:(NSMutableDictionary *)effect
{
    return [effect objectForKey:@"script"];
}

// Setter Methods

- (void)setVersionNumber:(float)newVersionNumber forEffect:(NSMutableDictionary *)effect
{
    [self setVersionNumber:newVersionNumber forDictionary:effect];
    [self saveDictionaryToItsFilePath:effect];
}

- (void)setDescription:(NSString *)description forEffect:(NSMutableDictionary *)effect
{
    [effect setObject:description forKey:@"description"];
    [self saveDictionaryToItsFilePath:effect];
}

- (void)setParameters:(NSString *)parameters forEffect:(NSMutableDictionary *)effect
{
    [effect setObject:parameters forKey:@"parameters"];
    [self saveDictionaryToItsFilePath:effect];
}

- (void)setScript:(NSString *)script forEffect:(NSMutableDictionary *)effect
{
    [effect setObject:script forKey:@"script"];
    [self saveDictionaryToItsFilePath:effect];
}

#pragma mark - AudioClipLibrary Methods
// Management Methods

- (NSString *)createAudioClipAndReturnFilePath
{
    NSMutableDictionary *newAudioClip = [[NSMutableDictionary alloc] init];
    NSMutableArray *beingUsedInSequenceFilePaths = [[NSMutableArray alloc] init];
    [newAudioClip setObject:beingUsedInSequenceFilePaths forKey:@"beingUsedInSequenceFilePaths"];
    
    // New files get a file name chosen by availble numbers (detemined by @selector(nextAvailableNumberForFilePaths))
    NSString *filePath = [NSString stringWithFormat:@"audioClipLibrary/%@.lmsd", [self nextAvailableNumberForFilePaths:[self audioClipFilePaths]]];
    [self addAudioClipFilePathToAudioClipLibrary:filePath];
    [self setFilePath:filePath forDictionary:newAudioClip];
    
    [newAudioClip writeToFile:[NSString stringWithFormat:@"%@/%@", libraryFolder, filePath] atomically:YES];
    [self setVersionNumber:DATA_VERSION_NUMBER forAudioClip:newAudioClip];
    [self setDescription:@"New AudioClip" forAudioClip:newAudioClip];
    [self setFilePathToAudioFile:@"" forAudioClip:newAudioClip];
    
    return filePath;
}

- (NSString *)createCopyOfAudioClipAndReturnFilePath:(NSMutableDictionary *)audioClip
{
    NSString *newAudioClipFilePath = [self createAudioClipAndReturnFilePath];
    NSMutableDictionary *newAudioClip = [self dictionaryFromFilePath:newAudioClipFilePath];
    [newAudioClip setObject:[self dictionaryBeingUsedInSequenceFilePaths:audioClip] forKey:@"beingUsedInSequenceFilePaths"];
    [self setDescription:[NSString stringWithFormat:@"%@ Copy", [self descriptionForAudioClip:audioClip]] forAudioClip:newAudioClip];
    [self setFilePathToAudioFile:[self filePathToAudioFileForAudioClip:audioClip] forAudioClip:newAudioClip];
    [self setStartTime:[self startTimeForAudioClip:audioClip] forAudioClip:newAudioClip];
    [self setEndTime:[self endTimeForAudioClip:audioClip] forAudioClip:newAudioClip];
    
    return newAudioClipFilePath;
}

- (void)removeAudioClipFromLibrary:(NSMutableDictionary *)audioClip
{
    // Remove the audioClip from any sequences
    NSMutableArray *sequenceFilePaths = [self audioClipBeingUsedInSequenceFilePaths:audioClip];
    for(int i = 0; i < [sequenceFilePaths count]; i ++)
    {
        [self removeAudioClipFilePath:[self filePathForAudioClip:audioClip] forSequence:[self sequenceFromFilePath:[sequenceFilePaths objectAtIndex:i]]];
    }
    
    NSMutableArray *filePaths = [self audioClipFilePaths];
    [filePaths removeObject:[self filePathForAudioClip:audioClip]];
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", [self libraryFolder], [self filePathToAudioFileForAudioClip:audioClip]];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
    [audioClipLibrary setObject:filePaths forKey:@"audioClipFilePaths"];
    [self saveAudioClipLibrary];
}

// Getter Methods

- (float)audioClipLibraryVersionNumber
{
    return [self versionNumberForDictionary:audioClipLibrary];
}

- (NSMutableArray *)audioClipFilePaths
{
    return [audioClipLibrary objectForKey:@"audioClipFilePaths"];
}

- (NSString *)audioClipFilePathAtIndex:(int)index
{
    return [[self audioClipFilePaths] objectAtIndex:index];
}

- (int)audioClipFilePathsCount
{
    return (int)[[self audioClipFilePaths] count];
}

// Setter Methods
- (void)setVersionNumberForAudioClipLibraryTo:(float)newVersionNumber
{
    [self setVersionNumber:newVersionNumber forDictionary:audioClipLibrary];
    [self saveAudioClipLibrary];
}

- (void)addAudioClipFilePathToAudioClipLibrary:(NSString *)filePath
{
    NSMutableArray *filePaths = [self audioClipFilePaths];
    [filePaths addObject:filePath];
    [audioClipLibrary setObject:filePaths forKey:@"audioClipFilePaths"];
    [self saveAudioClipLibrary];
}

#pragma mark - AudioClip Methods
// Getter Methods
- (float)versionNumberForAudioClip:(NSMutableDictionary *)audioClip
{
    return [[audioClip objectForKey:@"versionNumber"] floatValue];
}

- (NSString *)filePathForAudioClip:(NSMutableDictionary *)audioClip
{
    return [audioClip objectForKey:@"filePath"];
}

- (NSString *)descriptionForAudioClip:(NSMutableDictionary *)audioClip
{
    return [audioClip objectForKey:@"description"];
}

- (NSMutableArray *)audioClipBeingUsedInSequenceFilePaths:(NSMutableDictionary *)audioClip
{
    return [self dictionaryBeingUsedInSequenceFilePaths:audioClip];
}

- (int)audioClipBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)audioClip
{
    return [self dictionaryBeingUsedInSequenceFilePathsCount:audioClip];
}

- (NSString *)audioClip:(NSMutableDictionary *)audioClip beingUsedInSequenceFilePathAtIndex:(int)index
{
    return [self dictionary:audioClip beingUsedInSequenceFilePathAtIndex:index];
}

- (NSMutableDictionary *)audioClipFromFilePath:(NSString *)filePath
{
    return [self dictionaryFromFilePath:filePath];
}

- (NSString *)filePathToAudioFileForAudioClip:(NSMutableDictionary *)audioClip
{
    return [audioClip objectForKey:@"filePathToAudioFile"];
}

- (float)startTimeForAudioClip:(NSMutableDictionary *)audioClip
{
    return [[audioClip objectForKey:@"startTime"] floatValue];
}

- (float)endTimeForAudioClip:(NSMutableDictionary *)audioClip
{
    return [[audioClip objectForKey:@"endTime"] floatValue];
}

- (float)seekTimeForAudioClip:(NSMutableDictionary *)audioClip
{
    return [[audioClip objectForKey:@"seekTime"] floatValue];
}

// Setter Methods
- (void)setVersionNumber:(float)newVersionNumber forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:[NSNumber numberWithFloat:newVersionNumber] forKey:@"versionNumber"];
    [self saveDictionaryToItsFilePath:audioClip];
}

- (void)setDescription:(NSString *)description forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:description forKey:@"description"];
    [self saveDictionaryToItsFilePath:audioClip];
}

- (void)setFilePathToAudioFile:(NSString *)filePath forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:filePath forKey:@"filePathToAudioFile"];
    [self saveDictionaryToItsFilePath:audioClip];
}

- (void)setStartTime:(float)time forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:[NSNumber numberWithFloat:time] forKey:@"startTime"];
    [self saveDictionaryToItsFilePath:audioClip];
}

- (void)setEndTime:(float)time forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:[NSNumber numberWithFloat:time] forKey:@"endTime"];
    [self saveDictionaryToItsFilePath:audioClip];
}

- (void)moveAudioClip:(NSMutableDictionary *)audioClip byTime:(float)time
{
    [audioClip setObject:[NSNumber numberWithFloat:[self startTimeForAudioClip:audioClip] + time] forKey:@"startTime"];
    [audioClip setObject:[NSNumber numberWithFloat:[self endTimeForAudioClip:audioClip] + time] forKey:@"endTime"];
    [self saveDictionaryToItsFilePath:audioClip];
}

- (void)moveAudioClip:(NSMutableDictionary *)audioClip toStartTime:(float)startTime
{
    float startTimeOffset = startTime - [self startTimeForAudioClip:audioClip];
    
    [self moveAudioClip:audioClip byTime:startTimeOffset];
}

- (void)setSeekTime:(float)time forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:[NSNumber numberWithFloat:time] forKey:@"seekTime"];
    [self saveDictionaryToItsFilePath:audioClip];
}

@end
