//
//  MNData.m
//  LightMaster
//
//  Created by James Adams on 10/3/12.
//  Copyright (c) 2012 James Adams. All rights reserved.
//

#import "MNData.h"
#import "ENAPI.h"
#import "NSData+MD5.h"

#define LARGEST_NUMBER 999999
#define LIBRARY_VERSION_NUMBER 1.0
#define DATA_VERSION_NUMBER 1.0

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
- (NSMutableArray *)dictionaryBeingUsedInSequenceFilePaths:(NSMutableDictionary *)dictionary;
- (int)dictionaryBeingUsedInSequenceFilePathsCount:(NSMutableDictionary *)dictionary;
- (NSString *)dictionary:(NSMutableDictionary *)dictionary beingUsedInSequenceFilePathAtIndex:(int)index;
- (void)addBeingUsedInSequenceFilePath:(NSString *)sequenceFilePath forDictionary:(NSMutableDictionary *)dictionary;
- (void)removeBeingUsedInSequenceFilePath:(NSString *)sequenceFilePath forDictionary:(NSMutableDictionary *)dictionary;
- (NSMutableDictionary *)dictionaryFromFilePath:(NSString *)filePath;
- (void)loopButtonPress:(NSNotification *)aNotification;
- (void)loadControlBoxesForCurrentSequence;
- (void)loadCommandClustersForCurrentSequence;
- (void)loadAudioClipsForCurrentSequence;
- (void)loadChannelGroupsForCurrentSequence;
- (void)updateCurrentSequenceControlBoxesWithControlBox:(NSMutableDictionary *)controlBox;
- (void)updateCurrentSequenceCommandClustersWithCommandCluster:(NSMutableDictionary *)commandCluster;
- (void)updateCurrentSequenceAudioClipsWithAudioClip:(NSMutableDictionary *)audioClip;
- (void)updateCurrentSequenceChannelGroupsWithChannelGroup:(NSMutableDictionary *)channelGroup;
- (void)removeControlBoxFromCurrentSequenceControlBoxes:(NSMutableDictionary *)controlBox;
- (void)removeCommandClusterFromCurrentSequenceCommandClusters:(NSMutableDictionary *)commandCluster;
- (void)removeAudioClipFromCurrentSequenceAudioClips:(NSMutableDictionary *)audioClip;
- (void)removeChannelGroupFromCurrentSequenceChannelGroups:(NSMutableDictionary *)channelGroup;
- (void)pollENPostForTrackStatus:(ENAPIPostRequest *)request;
- (void)pollENForTrackStatus:(ENAPIPostRequest *)request;

@end


@implementation MNData

@synthesize currentSequence, libraryFolder, timeAtLeftEdgeOfTimelineView, zoomLevel, currentSequenceIsPlaying, mostRecentlySelectedCommandClusterIndex, serialPort, serialPortManager, shouldDrawSections, shouldDrawBars, shouldDrawBeats, shouldDrawTatums, shouldDrawSegments, shouldDrawTime, autogenIntensity, autogenv2Intensity, playlistButtonClick, currentSequenceIndex;

#pragma mark - System

- (id)init
{
    if(self = [super init])
    {
        // Custom initialization here
        shouldAutosave = YES;
        [self loadLibaries];
        zoomLevel = 3.0;
        [self setCurrentTime:1.0];
        self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
        enRequests = [[NSMutableArray alloc] init];
        loop = YES;
        currentPlaylistIndex = -1;
        self.shouldDrawSections = NO;
        self.shouldDrawBars = NO;
        self.shouldDrawBeats = NO;
        self.shouldDrawTatums = NO;
        self.shouldDrawSegments = NO;
        self.shouldDrawTime = YES;
        self.autogenIntensity = 1.0;
        self.autogenv2Intensity = 1.0;
        [ENAPI initWithApiKey:@"9F52RBALOQTUGKOT5" ConsumerKey:@"470771f3b2787696050f2f4143cb5c33" AndSharedSecret:@"QMa4TZ+PRL+Nq0e3SAR/RQ"];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loopButtonPress:) name:@"LoopButtonPress" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(convertRBCFile) name:@"ConvertRBC" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(splitMostRecentlySelectedCommandClusterAtCurrentTime:) name:@"SplitCommandCluster" object:nil];
        
        NSString *pathForEmptySound = [[NSBundle mainBundle] pathForResource:@"Empty" ofType:@"m4a"];
        emptySound = [[NSSound alloc] initWithContentsOfFile:pathForEmptySound byReference:NO];
        [emptySound setLoops:YES];
        [emptySound play];
        
        receivedText = [[NSMutableString alloc] init];
        memset(channelsOnlinePerBox, -1, 100);
        
        webSocket = [[MBWebSocketServer alloc] initWithPort:21012 delegate:self];
        NSLog(@"Listening on port 21012");
    }
    
    return self;
}

#pragma mark - WebSocket Methods

- (void)webSocketServer:(MBWebSocketServer *)webSocketServer didAcceptConnection:(GCDAsyncSocket *)connection
{
    NSLog(@"Connected to a client %@, we accept multiple connections", connection);
    
    [self updateAllSocketsWithClientCount];
}

- (void)webSocketServer:(MBWebSocketServer *)webSocket didReceiveData:(NSData *)data fromConnection:(GCDAsyncSocket *)connection
{
    NSString *receivedData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"received:%@", receivedData);
    
    // The string is complete. Now do something with it.
    if([receivedData rangeOfString:@"\r\n"].location != NSNotFound)
    {
        receivedData = [receivedData stringByReplacingOccurrencesOfString:@"\r\n" withString:@""];
        
        if([receivedData isEqualToString:@"Info"])
        {
            receivedData = [receivedData stringByReplacingOccurrencesOfString:@"Info" withString:@""];
            
            [self sendInformationToSocket:connection];
        }
        else if([receivedData rangeOfString:@"IP"].location != NSNotFound)
        {
            receivedData = [receivedData stringByReplacingOccurrencesOfString:@"IP" withString:@""];
            
            NSString *theIP = receivedData;
            //NSLog(@"theIP:%@", theIP);
        }
        else if([receivedData rangeOfString:@"control"].location != NSNotFound)
        {
            receivedData = [receivedData stringByReplacingOccurrencesOfString:@"control" withString:@""];
            
            uint8_t command[64];
            int charCount = 0;
            int boxIndex = [receivedData intValue];
            
            if([receivedData rangeOfString:@"All"].location != NSNotFound)
            {
                receivedData = [receivedData stringByReplacingOccurrencesOfString:@"All" withString:@""];
                
                BOOL on = NO;
                
                if([receivedData rangeOfString:@"On"].location != NSNotFound)
                {
                    receivedData = [receivedData stringByReplacingOccurrencesOfString:@"On" withString:@""];
                    
                    on = YES;
                }
                else if([receivedData rangeOfString:@"Off"].location != NSNotFound)
                {
                    receivedData = [receivedData stringByReplacingOccurrencesOfString:@"Off" withString:@""];
                    
                    on = NO;
                }
                
                // Get the box information
                NSMutableDictionary *controlBox = [self controlBoxFromFilePath:[self controlBoxFilePathAtIndex:boxIndex]];
                int channels = [self channelsCountForControlBox:controlBox];
                char boardID = (char)[[self controlBoxIDForControlBox:controlBox] intValue];
                
                // Loop through each channel
                for(int i = 0; i < channels; i ++)
                {
                    memset(command, 0, 64);
                    charCount = 0;
                    
                    command[charCount] = boardID; // Set the boardID
                    charCount ++;
                    if(on)
                    {
                        command[charCount] = 0x01; // Turn a channel on command
                    }
                    else
                    {
                        command[charCount] = 0x02; // Turn a channel off command
                    }
                    charCount ++;
                    command[charCount] = (char)(i); // Set which channel
                    charCount ++;
                    command[charCount] = 0xFF; // End of command char
                    charCount ++;
                    [self sendPacketToSerialPort:command packetLength:charCount];
                }
            }
            else if([receivedData rangeOfString:@"Everything"].location != NSNotFound)
            {
                receivedData = [receivedData stringByReplacingOccurrencesOfString:@"Everything" withString:@""];
                
                BOOL on = NO;
                
                if([receivedData rangeOfString:@"On"].location != NSNotFound)
                {
                    receivedData = [receivedData stringByReplacingOccurrencesOfString:@"On" withString:@""];
                    
                    on = YES;
                }
                else if([receivedData rangeOfString:@"Off"].location != NSNotFound)
                {
                    receivedData = [receivedData stringByReplacingOccurrencesOfString:@"Off" withString:@""];
                    
                    on = NO;
                }
                
                for(int b = 0; b < [self controlBoxFilePathsCount]; b ++)
                {
                    // Get the box information
                    NSMutableDictionary *controlBox = [self controlBoxFromFilePath:[self controlBoxFilePathAtIndex:b]];
                    int channels = [self channelsCountForControlBox:controlBox];
                    char boardID = (char)[[self controlBoxIDForControlBox:controlBox] intValue];
                    
                    // Loop through each channel
                    for(int i = 0; i < channels; i ++)
                    {
                        memset(command, 0, 64);
                        charCount = 0;
                        
                        command[charCount] = boardID; // Set the boardID
                        charCount ++;
                        if(on)
                        {
                            command[charCount] = 0x01; // Turn a channel on command
                        }
                        else
                        {
                            command[charCount] = 0x02; // Turn a channel off command
                        }
                        charCount ++;
                        command[charCount] = (char)(i); // Set which channel
                        charCount ++;
                        command[charCount] = 0xFF; // End of command char
                        charCount ++;
                        [self sendPacketToSerialPort:command packetLength:charCount];
                    }
                }
            }
        }
        else if([receivedData rangeOfString:@"song"].location != NSNotFound)
        {
            NSString *bytes = [receivedData stringByReplacingOccurrencesOfString:@"song" withString:@""];
            //NSLog(@"bytes:%@", bytes);
            
            for(int i = 0; i < [bytes length]; i ++)
            {
                NSLog(@"c:%c d:%d h:%02x", [bytes characterAtIndex:i], [bytes characterAtIndex:i], [bytes characterAtIndex:i]);
            }
            
            int songID = [bytes intValue];
            NSUInteger playlist[sequencesWithAudioCount];
            int currentSongID = songID;
            int playlistIndex = 0;
            
            while(currentSongID < [self sequenceFilePathsCount])
            {
                playlist[playlistIndex] = currentSongID;
                currentSongID ++;
                playlistIndex ++;
            }
            
            NSLog(@"playing song:%d from web", songID);
            playlistFromWeb = YES;
            
            [self playWebPlaylistOfSequenceIndexes:playlist indexCount:playlistIndex];
        }
    }
    
    //[connection writeWebSocketFrame:@"Thanks for the data!"]; // you can write NSStrings or NSDatas
}

- (void)webSocketServer:(MBWebSocketServer *)webSocketServer clientDisconnected:(GCDAsyncSocket *)connection
{
    NSLog(@"Disconnected from client: %@", connection);
    
    [self updateAllSocketsWithClientCount];
}

- (void)webSocketServer:(MBWebSocketServer *)webSocketServer couldNotParseRawData:(NSData *)rawData fromConnection:(GCDAsyncSocket *)connection error:(NSError *)error
{
    NSLog(@"MBWebSocketServer error: %@", error);
}

- (void)sendInformationToSocket:(GCDAsyncSocket *)socket
{
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    
    // Channel/Box Information
    NSMutableArray *boxes = [[NSMutableArray alloc] init];
    NSMutableArray *boxesKeys = [[NSMutableArray alloc] init];
    
    //int boxesCount = 0;
    
    for(int i = 0; i < [self controlBoxFilePathsCount]; i ++)
    {
        //if(channelsOnlinePerBox[i + 1] > -1)
        //{
            NSMutableDictionary *controlBox = [self controlBoxFromFilePath:[self controlBoxFilePathAtIndex:i]];
            
            NSMutableArray *boxDetails = [[NSMutableArray alloc] init];
            NSMutableArray *boxDetailsKeys = [[NSMutableArray alloc] init];
            
            [boxDetailsKeys addObject:@"channels"];
            [boxDetails addObject:[NSString stringWithFormat:@"%d", [self channelsCountForControlBox:controlBox]]];
        //[boxDetails addObject:[NSString stringWithFormat:@"%d", channelsOnlinePerBox[i + 1]]];
            [boxDetailsKeys addObject:@"description"];
            [boxDetails addObject:[NSString stringWithFormat:@"%@", [self descriptionForControlBox:controlBox]]];
            [boxDetailsKeys addObject:@"boxID"];
            [boxDetails addObject:[NSString stringWithFormat:@"%d", i]];
            
            NSDictionary *boxesDetailsDict = [NSDictionary dictionaryWithObjects:boxDetails forKeys:boxDetailsKeys];
            [boxesKeys addObject:[NSString stringWithFormat:@"%d", i]];
        //[boxesKeys addObject:[NSString stringWithFormat:@"%d", boxesCount]];
            [boxes addObject:boxesDetailsDict];
            
        //boxesCount ++;
        //}
    }
    
    NSDictionary *boxesDict = [NSDictionary dictionaryWithObjects:boxes forKeys:boxesKeys];
    
    [keys addObject:@"boxesCount"];
    [objects addObject:[NSNumber numberWithInt:[self controlBoxFilePathsCount]]];
    //[objects addObject:[NSNumber numberWithInt:boxesCount]];
    
    [keys addObject:@"boxDetails"];
    [objects addObject:boxesDict];
    
    // Song Information
    NSMutableArray *songs = [[NSMutableArray alloc] init];
    NSMutableArray *songsKeys = [[NSMutableArray alloc] init];
    sequencesWithAudioCount = 0;
    
    for(int i = 0; i < [self sequenceFilePathsCount]; i ++)
    {
        NSMutableDictionary *sequence = [self sequenceFromFilePath:[self sequenceFilePathAtIndex:i]];
        
        if([self audioClipFilePathsCountForSequence:sequence] > 0)
        {
            NSMutableArray *songDetails = [[NSMutableArray alloc] init];
            NSMutableArray *songDetailsKeys = [[NSMutableArray alloc] init];
            
            [songDetailsKeys addObject:@"description"];
            [songDetails addObject:[NSString stringWithFormat:@"%@", [self descriptionForSequence:sequence]]];
            [songDetailsKeys addObject:@"songID"];
            [songDetails addObject:[NSString stringWithFormat:@"%d", i]];
            
            NSDictionary *songsDetailsDict = [NSDictionary dictionaryWithObjects:songDetails forKeys:songDetailsKeys];
            //[songsKeys addObject:[NSString stringWithFormat:@"%d", i]];
            [songsKeys addObject:[NSString stringWithFormat:@"%d", sequencesWithAudioCount]];
            [songs addObject:songsDetailsDict];
            
            sequencesWithAudioCount ++;
        }
    }
    
    [keys addObject:@"songsCount"];
    //[objects addObject:[NSNumber numberWithInt:[self sequenceFilePathsCount]]];
    [objects addObject:[NSNumber numberWithInt:sequencesWithAudioCount]];
    
    NSDictionary *songsDict = [NSDictionary dictionaryWithObjects:songs forKeys:songsKeys];
    [keys addObject:@"songDetails"];
    [objects addObject:songsDict];
    
    [keys addObject:@"currentSongID"];
    if(self.currentSequenceIsPlaying)
    {
        NSLog(@"csq:%d", currentSequenceIndex);
        [objects addObject:[NSNumber numberWithInt:currentSequenceIndex]];
    }
    else
    {
        [objects addObject:[NSNumber numberWithInt:-1]];
    }
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    //NSString* channelsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [socket writeWebSocketFrame:jsonData];
}

- (void)sendClientCountToSocket:(GCDAsyncSocket *)socket
{
    NSMutableArray *objects = [[NSMutableArray alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    
    [objects addObject:[NSString stringWithFormat:@"%lu", (unsigned long)[webSocket clientCount]]];
    [keys addObject:@"clientCount"];
    
    NSDictionary *dict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
    
    //NSString* channelsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    [socket writeWebSocketFrame:jsonData];
}

- (void)updateAllSockets
{
    for(int i = 0; i < [webSocket clientCount]; i ++)
    {
        [self sendInformationToSocket:[webSocket clientAtIndex:i]];
    }
}

- (void)updateAllSocketsWithClientCount
{
    for(int i = 0; i < [webSocket clientCount]; i ++)
    {
        [self sendClientCountToSocket:[webSocket clientAtIndex:i]];
    }
}

- (void)checkBoxIsOnline:(uint8_t)boxID
{
    // Send the command!
    uint8_t command[8];
    memset(command, 0, 8);
    int charCount = 0;
    command[charCount] = boxID; // Board ID
    charCount ++;
    command[charCount] = 0xF1; // Request board status
    charCount ++;
    command[charCount] = 0xFF;
    charCount ++;
    
    [self sendPacketToSerialPort:command packetLength:charCount];
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
    
    // Import Folder
    /*filePath = [NSString stringWithFormat:@"%@/import", libraryFolder];
    if(![[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory])
    {
        // Create the folder
        NSError *error = nil;
        if(![[NSFileManager defaultManager] createDirectoryAtPath:[filePath stringByDeletingPathExtension] withIntermediateDirectories:YES attributes:nil error:&error])
        {
            [NSException raise:@"Failed creating directory" format:@"[%@], %@", filePath, error];
        }
    }*/
    
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
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:dictionary];
}

- (void)removeBeingUsedInSequenceFilePath:(NSString *)sequenceFilePath forDictionary:(NSMutableDictionary *)dictionary
{
    NSMutableArray *beingUsedInSequenceFilePaths = [self dictionaryBeingUsedInSequenceFilePaths:dictionary];
    [beingUsedInSequenceFilePaths removeObject:sequenceFilePath];
    [dictionary setObject:beingUsedInSequenceFilePaths forKey:@"beingUsedInSequenceFilePaths"];
    if(shouldAutosave)
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

- (void)loopButtonPress:(NSNotification *)aNotification
{
    loop = !loop;
}

- (void)loadControlBoxesForCurrentSequence
{
    // Load the Control Boxes
    currentSequenceControlBoxes = nil;
    currentSequenceControlBoxes = [[NSMutableArray alloc] init];
    for(int i = 0; i < [self controlBoxFilePathsCountForSequence:currentSequence]; i ++)
    {
        NSMutableDictionary *controlBox = [self controlBoxFromFilePath:[self controlBoxFilePathAtIndex:i forSequence:currentSequence]];
        if(controlBox != nil)
        {
            [currentSequenceControlBoxes addObject:controlBox];
        }
        else
        {
            [self removeControlBoxFilePath:[self controlBoxFilePathAtIndex:i forSequence:currentSequence] forSequence:currentSequence];
        }
    }
}

- (void)loadCommandClustersForCurrentSequence
{
    // Load the Command Clusters
    currentSequenceCommandClusters = nil;
    currentSequenceCommandClusters = [[NSMutableArray alloc] init];
    for(int i = 0; i < [self commandClusterFilePathsCountForSequence:currentSequence]; i ++)
    {
        NSMutableDictionary *commandCluster = [self commandClusterFromFilePath:[self commandClusterFilePathAtIndex:i forSequence:currentSequence]];
        if(commandCluster != nil)
        {
            [currentSequenceCommandClusters addObject:commandCluster];
        }
        else
        {
            [self removeCommandClusterFilePath:[self commandClusterFilePathAtIndex:i forSequence:currentSequence] forSequence:currentSequence];
        }
    }
}

- (void)loadAudioClipsForCurrentSequence
{
    // Load the Audio Clips
    currentSequenceAudioClips = nil;
    currentSequenceAudioClips = [[NSMutableArray alloc] init];
    currentSequenceAudioAnalyses = nil;
    currentSequenceAudioAnalyses = [[NSMutableArray alloc] init];
    for(int i = 0; i < [self audioClipFilePathsCountForSequence:currentSequence]; i ++)
    {
        NSMutableDictionary *audioClip = [self audioClipFromFilePath:[self audioClipFilePathAtIndex:i forSequence:currentSequence]];
        NSDictionary *audioAnalysis;
        if(audioClip != nil)
        {
            [currentSequenceAudioClips addObject:audioClip];
            
            audioAnalysis = [self audioAnalysisForAudioClip:audioClip];
        }
        else
        {
            [self removeAudioClipFilePath:[self audioClipFilePathAtIndex:i forSequence:currentSequence] forSequence:currentSequence];
        }
        
        if(audioAnalysis != nil)
        {
            [currentSequenceAudioAnalyses addObject:audioAnalysis];
        }
        else
        {
            [currentSequenceAudioAnalyses addObject:[NSNull null]];
        }
    }
}

- (void)loadChannelGroupsForCurrentSequence
{
    // Load the Channel Groups
    currentSequenceChannelGroups = nil;
    currentSequenceChannelGroups = [[NSMutableArray alloc] init];
    for(int i = 0; i < [self channelGroupFilePathsCountForSequence:currentSequence]; i ++)
    {
        NSMutableDictionary *channelGroup = [self channelGroupFromFilePath:[self channelGroupFilePathAtIndex:i forSequence:currentSequence]];
        if(channelGroup != nil)
        {
            [currentSequenceChannelGroups addObject:channelGroup];
        }
        else
        {
            [self removeChannelGroupFilePath:[self channelGroupFilePathAtIndex:i forSequence:currentSequence] forSequence:currentSequence];
        }
    }
}

- (void)updateCurrentSequenceControlBoxesWithControlBox:(NSMutableDictionary *)controlBox
{
    // Reload this controlBox if neccessary
    NSUInteger filePathsIndex = [[self controlBoxFilePathsForSequence:currentSequence] indexOfObject:[self filePathForControlBox:controlBox]];
    if(filePathsIndex != NSNotFound)
    {
        if([currentSequenceControlBoxes count] == 0)
        {
            [currentSequenceControlBoxes addObject:controlBox];
        }
        else
        {[currentSequenceControlBoxes replaceObjectAtIndex:filePathsIndex withObject:controlBox];
            
        }
    }
}

- (void)updateCurrentSequenceCommandClustersWithCommandCluster:(NSMutableDictionary *)commandCluster
{
    // Reload this cluster if neccessary
    NSUInteger filePathsIndex = [[self commandClusterFilePathsForSequence:currentSequence] indexOfObject:[self filePathForCommandCluster:commandCluster]];
    if(filePathsIndex != NSNotFound)
    {
        if([currentSequenceCommandClusters count] == 0)
        {
            [currentSequenceCommandClusters addObject:commandCluster];
        }
        else
        {
            [currentSequenceCommandClusters replaceObjectAtIndex:filePathsIndex withObject:commandCluster];
        }
    }
}

- (void)updateCurrentSequenceAudioClipsWithAudioClip:(NSMutableDictionary *)audioClip
{
    // Reload this audioClip if neccessary
    NSUInteger filePathsIndex = [[self audioClipFilePathsForSequence:currentSequence] indexOfObject:[self filePathForAudioClip:audioClip]];
    if(filePathsIndex != NSNotFound)
    {
        NSDictionary *audioAnalysis = [self audioAnalysisForAudioClip:audioClip];
        
        if([currentSequenceAudioClips count] == 0)
        {
            [currentSequenceAudioClips addObject:audioClip];
            
            if(!audioAnalysis)
            {
                [currentSequenceAudioAnalyses addObject:[NSNull null]];
            }
            else
            {
                [currentSequenceAudioAnalyses addObject:audioAnalysis];
            }
            
        }
        else
        {
            [currentSequenceAudioClips replaceObjectAtIndex:filePathsIndex withObject:audioClip];
            
            if(!audioAnalysis)
            {
                [currentSequenceAudioAnalyses replaceObjectAtIndex:filePathsIndex withObject:[NSNull null]];
            }
            else
            {
                [currentSequenceAudioAnalyses replaceObjectAtIndex:filePathsIndex withObject:audioAnalysis];
            }
        }
    }
}

- (void)updateCurrentSequenceChannelGroupsWithChannelGroup:(NSMutableDictionary *)channelGroup
{
    // Reload this channelGroup if neccessary
    NSUInteger filePathsIndex = [[self channelGroupFilePathsForSequence:currentSequence] indexOfObject:[self filePathForChannelGroup:channelGroup]];
    if(filePathsIndex != NSNotFound)
    {
        if([currentSequenceChannelGroups count] == 0)
        {
            [currentSequenceChannelGroups addObject:channelGroup];
        }
        else
        {
            [currentSequenceChannelGroups replaceObjectAtIndex:filePathsIndex withObject:channelGroup];
        }
    }
}

- (void)removeControlBoxFromCurrentSequenceControlBoxes:(NSMutableDictionary *)controlBox
{
    // Reload this controlBox if neccessary
    if(currentSequence != nil)
    {
        NSUInteger filePathsIndex = [[self controlBoxFilePathsForSequence:currentSequence] indexOfObject:[self filePathForControlBox:controlBox]];
        if(filePathsIndex != NSNotFound)
        {
            [currentSequenceControlBoxes removeObjectAtIndex:filePathsIndex];
        }
    }
}

- (void)removeCommandClusterFromCurrentSequenceCommandClusters:(NSMutableDictionary *)commandCluster
{
    // Reload this cluster if neccessary
    if(currentSequence != nil)
    {
        NSUInteger filePathsIndex = [[self commandClusterFilePathsForSequence:currentSequence] indexOfObject:[self filePathForCommandCluster:commandCluster]];
        if(filePathsIndex != NSNotFound)
        {
            [currentSequenceCommandClusters removeObjectAtIndex:filePathsIndex];
        }
    }
}

- (void)removeAudioClipFromCurrentSequenceAudioClips:(NSMutableDictionary *)audioClip
{
    // Reload this audioClip if neccessary
    if(currentSequence != nil)
    {
        NSUInteger filePathsIndex = [[self audioClipFilePathsForSequence:currentSequence] indexOfObject:[self filePathForAudioClip:audioClip]];
        NSLog(@"filePathsIndex:%lu", filePathsIndex);
        if(filePathsIndex != NSNotFound)
        {
            [currentSequenceAudioClips removeObjectAtIndex:filePathsIndex];
            [currentSequenceAudioAnalyses removeObjectAtIndex:filePathsIndex];
        }
    }
}

- (void)removeChannelGroupFromCurrentSequenceChannelGroups:(NSMutableDictionary *)channelGroup
{
    // Reload this channelGroup if neccessary
    if(currentSequence != nil)
    {
        NSUInteger filePathsIndex = [[self channelGroupFilePathsForSequence:currentSequence] indexOfObject:[self filePathForChannelGroup:channelGroup]];
        if(filePathsIndex != NSNotFound)
        {
            [currentSequenceChannelGroups removeObjectAtIndex:filePathsIndex];
        }
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

- (void)convertRBCFile
{
    [self loadOpenPanel];
    
    if(previousOpenPanelDirectory == nil)
    {
        [openPanel setDirectoryURL:[NSURL URLWithString:@"~"]];
    }
    else
    {
        [openPanel setDirectoryURL:[NSURL URLWithString:previousOpenPanelDirectory]];
    }
    
    [openPanel beginWithCompletionHandler:^(NSInteger result)
     {
         if(result == NSFileHandlingPanelOKButton)
         {
             NSString *filePath = [[openPanel URL] path];
             NSMutableDictionary *rbcDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
             NSMutableArray *rbcCommandsArrayArray = [rbcDictionary objectForKey:@"Commands"];
             NSString *rbcSequenceName = [[filePath lastPathComponent] stringByDeletingPathExtension];
             NSString *rbcAudioClipFliePath = [rbcDictionary objectForKey:@"Music"];
             int rbcNumberOfBoards = [(NSNumber *)[rbcDictionary objectForKey:@"NumberOfBoards"] intValue];
             
             // Create 1 commandCluster for each board
             for(int i = 1; i <= rbcNumberOfBoards; i ++)
             {
                 NSString *newCommandClusterFilePath = [self createCommandClusterAndReturnFilePath];
                 NSMutableDictionary *newCommandCluster = [self commandClusterFromFilePath:newCommandClusterFilePath];
                 int maxCommandEndTimeForThisCommandCluster = 0.0;
                 [self setDescription:[NSString stringWithFormat:@"%@ Cluster %d", rbcSequenceName, i] forCommandCluster:newCommandCluster];
                 
                 NSMutableArray *rbcCommandsArray;
                 NSMutableDictionary *rbcCommand;
                 // Cycle through each of the command arrays
                 for(int i3 = 0; i3 < [rbcCommandsArrayArray count]; i3 ++)
                 {
                     // Read in a commands array
                     rbcCommandsArray = [rbcCommandsArrayArray objectAtIndex:i3];
                     
                     // Read in the commands and add them to the command cluster
                     for(int i2 = 0; i2 < [rbcCommandsArray count]; i2 ++)
                     {
                         // Get the next rbcCommand
                         rbcCommand = [rbcCommandsArray objectAtIndex:i2];
                         
                         // Is this command for this commandCluster
                         if([(NSNumber *)[rbcCommand objectForKey:@"BoardNumber"] intValue] == i)
                         {
                             // Create a new command
                             int newCommandIndex = [self createCommandAndReturnNewCommandIndexForCommandCluster:newCommandCluster];
                             
                             // Set the new command data
                             [self setChannelIndex:[(NSNumber *)[rbcCommand objectForKey:@"RelayNumber"] intValue] - 1 forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
                             [self setStartTime:[(NSNumber *)[rbcCommand objectForKey:@"Time"] floatValue] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
                             [self setEndTime:[(NSNumber *)[rbcCommand objectForKey:@"Time"] floatValue] + [(NSNumber *)[rbcCommand objectForKey:@"Duration"] floatValue] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
                             
                             // Compare maxCommandEndTime
                             if([self endTimeForCommand:[self commandAtIndex:newCommandIndex fromCommandCluster:newCommandCluster]] > maxCommandEndTimeForThisCommandCluster)
                             {
                                 maxCommandEndTimeForThisCommandCluster = [self endTimeForCommand:[self commandAtIndex:newCommandIndex fromCommandCluster:newCommandCluster]];
                             }
                         }
                     }
                 }
                 
                 // Set newCommandCluster end time
                 [self setEndTime:maxCommandEndTimeForThisCommandCluster forCommandcluster:newCommandCluster];
             }
             
             // Create the audio clip
             [[NSNotificationCenter defaultCenter] postNotificationName:@"CreateNewAudioClipFromFilePath" object:rbcAudioClipFliePath];
             
             [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
         }
     }
     ];
}

- (void)loadOpenPanel
{
    // Load the open panel if neccessary
    if(openPanel == nil)
    {
        openPanel = [NSOpenPanel openPanel];
        [openPanel setCanChooseDirectories:NO];
        [openPanel setCanChooseFiles:YES];
        [openPanel setResolvesAliases:YES];
        [openPanel setAllowsMultipleSelection:NO];
        [openPanel setAllowedFileTypes:[NSArray arrayWithObject:@"rbc"]];
    }
}

- (void)setCurrentSequence:(NSMutableDictionary *)newSequence
{
    // Stop all of the previous Sounds
    for(int i = 0; i < [currentSequenceNSSounds count]; i ++)
    {
        if([(NSSound *)[currentSequenceNSSounds objectAtIndex:i] isPlaying] == YES)
        {
            [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] stop];
        }
    }
    
    currentSequence = newSequence;
    
    [self loadControlBoxesForCurrentSequence];
    if(shouldAutosave)
            [self loadCommandClustersForCurrentSequence];
    [self loadAudioClipsForCurrentSequence];
    [self loadChannelGroupsForCurrentSequence];
    
    // Load the sounds
    currentSequenceNSSounds = nil;
    currentSequenceNSSounds = [[NSMutableArray alloc] init];
    for(int i = 0; i < [self audioClipFilePathsCountForSequence:currentSequence]; i ++)
    {
        NSString *soundFilePath = [NSString stringWithFormat:@"%@/%@", self.libraryFolder, [self filePathToAudioFileForAudioClip:[self audioClipForCurrentSequenceAtIndex:i]]];
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
        // Loop the currentSequence
        if(loop)
        {
            if(currentTime >= [self endTimeForSequence:currentSequence])
            {
                if(numberOfPlaylistSongs > 0)
                {
                    [self playNextPlaylistItem];
                }
                else
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"SkipBackButtonPress" object:nil];
                }
            }
        }
        
        // Play/Pause the necessary NSSounds
        BOOL isPlayingAudio = NO;
        for(int i = 0; i < [currentSequenceNSSounds count]; i ++)
        {
            float startTime = [self startTimeForAudioClip:[self audioClipForCurrentSequenceAtIndex:i]];
            float endTime = [self endTimeForAudioClip:[self audioClipForCurrentSequenceAtIndex:i]];
            float fadeTime = [self endFadeTimeForAudioClip:[self audioClipForCurrentSequenceAtIndex:i]];
            
            // Play the sound
            if(currentTime >= startTime && currentTime < endTime && [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] isPlaying] == NO)
            {
                float seekTime = [self seekTimeForAudioClip:[self audioClipForCurrentSequenceAtIndex:i]];
                
                // Seek to the appropriate time
                [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] setCurrentTime:seekTime + currentTime - startTime];
                [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] play];
                
                isPlayingAudio = YES;
            }
            // Pause the sound
            else if((currentTime < startTime || currentTime >= endTime) && [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] isPlaying] == YES)
            {
                [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] stop];
            }
            else if(currentTime >= startTime && currentTime < endTime && [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] isPlaying] == YES)
            {
                isPlayingAudio = YES;
            }
            
            // Fade if neccessary
            if(currentTime >= endTime - fadeTime)
            {
                [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] setVolume:(endTime - currentTime) / fadeTime];
            }
            else if(currentTime < endTime - fadeTime && [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] volume] < 1.0)
            {
                [(NSSound *)[currentSequenceNSSounds objectAtIndex:i] setVolume:1.0];
            }
        }
        
        // Help keep the audio hardware active on laptops
        if(isPlayingAudio && [emptySound isPlaying])
        {
            [emptySound stop];
        }
        else if(!isPlayingAudio && ![emptySound isPlaying])
        {
            [emptySound play];
        }
        
        // Determine the channel states
        NSMutableDictionary *currentCommandCluster;
        NSMutableDictionary *currentCommand;
        int currentControlBoxIndex = -1;
        int currentChannelIndex = -1;
        
        //NSLog(@"check");
        
        // Go through each commandCluster
        for(int i = 0; i < [self commandClusterFilePathsCountForSequence:currentSequence]; i ++)
        {
            //NSLog(@"cluster:%d", i);
            currentCommandCluster = [self commandClusterForCurrentSequenceAtIndex:i];
            // See if this is a controlBox cluster
            if([[self controlBoxFilePathForCommandCluster:currentCommandCluster] length] > 0)
            {
                currentControlBoxIndex = (int)[[self controlBoxFilePathsForSequence:currentSequence] indexOfObject:[self controlBoxFilePathForCommandCluster:currentCommandCluster]];
            }
            
            // Check to see if the current time is within the command cluster's range (plus a little extra at the so we can turn all channels off if they haven't been already)
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
                    //NSLog(@"[%d][%d]", currentChannelIndex, channelState[currentControlBoxIndex][currentChannelIndex]);
                }
            }
            
            currentControlBoxIndex = -1;
        }
        
        // Send out the necessary commands over the serial port
        for(int i = 0; i < [self controlBoxFilePathsCountForSequence:currentSequence]; i ++)
        {
            NSString *controlBoxID = [self controlBoxIDForControlBox:[self controlBoxForCurrentSequenceAtIndex:i]];
            char boardID = (char)[controlBoxID intValue];
            uint8_t command[64];
            int charCount = 0;
            BOOL shouldSendCommand = NO;
            
            // Loop through each channel to build the command
            int i2;
            int numberOfChannels = [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:i]];
            for(i2 = 0; i2 < numberOfChannels; i2 ++)
            {
                shouldSendCommand = NO;
                // If there was a change, we need to send out a command
                if(((channelState[i][i2] == YES && previousChannelState[i][i2] == NO) || (channelState[i][i2] == NO && previousChannelState[i][i2] == YES)))
                {
                    shouldSendCommand = YES;
                }
                
                if(shouldSendCommand)
                {
                    if(channelState[i][i2] == YES)
                    {
                        memset(command, 0, 64);
                        charCount = 0;
                        
                        command[charCount] = boardID; // Set the boardID
                        charCount ++;
                        command[charCount] = 0x01; // Turn a channel on command
                        charCount ++;
                        command[charCount] = (char)(i2); // Set which channel
                        charCount ++;
                        command[charCount] = 0xFF; // End of command char
                        charCount ++;
                        [self sendPacketToSerialPort:command packetLength:charCount];
                    }
                    else
                    {
                        memset(command, 0, 64);
                        charCount = 0;
                        
                        command[charCount] = boardID; // Set the boardID
                        charCount ++;
                        command[charCount] = 0x02; // Turn a channel off command
                        charCount ++;
                        command[charCount] = (char)(i2); // Set which channel
                        charCount ++;
                        command[charCount] = 0xFF; // End of command char
                        charCount ++;
                        [self sendPacketToSerialPort:command packetLength:charCount];
                    }
                }
            }
        }
        
        // Set all values to 0 for the previous state (this also turns off the channels)
        for(int i = 0; i < [self controlBoxFilePathsCount]; i ++)
        {
            memset(previousChannelState[i], 0, 256);
        }
        
        // Copy the current state to the previous state for the next iteration to work
        for(int i = 0; i < 256; i ++)
        {
            for(int i2 = 0; i2 < 256; i2 ++)
            {
                previousChannelState[i][i2] = channelState[i][i2];
            }
        }
        
        // Set all values to 0 for the current state (this also turns off the channels)
        for(int i = 0; i < [self controlBoxFilePathsCount]; i ++)
        {
            memset(channelState[i], 0, 256);
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
    int trackItemsCount = (int)[currentSequenceAudioClips count];
    for(int i = 0; i < [currentSequenceControlBoxes count]; i ++)
    {
        trackItemsCount += [self channelsCountForControlBox:[currentSequenceControlBoxes objectAtIndex:i]];
    }
    for(int i = 0; i < [self channelGroupFilePathsCountForSequence:currentSequence]; i ++)
    {
        trackItemsCount += [self itemsCountForChannelGroup:[currentSequenceChannelGroups objectAtIndex:i]];
    }
    
    return trackItemsCount;
}

// Quick Access To Data

- (NSMutableDictionary *)controlBoxForCurrentSequenceAtIndex:(int)i
{
    if([currentSequenceControlBoxes count] - 1 >= i)
        return [currentSequenceControlBoxes objectAtIndex:i];
    
    return nil;
}

- (NSMutableDictionary *)commandClusterForCurrentSequenceAtIndex:(int)i
{
    if([currentSequenceCommandClusters count] - 1 >= i)
        return [currentSequenceCommandClusters objectAtIndex:i];
    
    return nil;
}

- (NSMutableDictionary *)audioClipForCurrentSequenceAtIndex:(int)i
{
    if([currentSequenceAudioClips count] - 1 >= i)
        return [currentSequenceAudioClips objectAtIndex:i];
    
    return nil;
}

- (NSDictionary *)audioAnalysisForCurrentSequenceAtIndex:(int)i
{
    if([currentSequenceAudioAnalyses count] - 1 >= i)
        return [currentSequenceAudioAnalyses objectAtIndex:i];
    
    return nil;
}

- (NSMutableDictionary *)channelGroupForCurrentSequenceAtIndex:(int)i
{
    if([currentSequenceChannelGroups count] - 1 >= i)
        return [currentSequenceChannelGroups objectAtIndex:i];
    
    return nil;
}

- (void)playWebPlaylistOfSequenceIndexes:(NSUInteger *)indexes indexCount:(int)count
{
    numberOfPlaylistSongs = count;
    currentPlaylistIndex = -1;
    memset(playlistIndexes, 0, 999);
    for(int i = 0; i < numberOfPlaylistSongs; i ++)
    {
        playlistIndexes[i] = (int)indexes[i];
    }
    
    [self playNextPlaylistItem];
    
    if(playlistButtonClick)
        NSLog(@"playing:%d", self.currentSequenceIsPlaying);
}

- (void)playPlaylistOfSequenceIndexes:(NSUInteger *)indexes indexCount:(int)count
{
    numberOfPlaylistSongs = count;
    currentPlaylistIndex = -1;
    memset(playlistIndexes, 0, 999);
    for(int i = 0; i < numberOfPlaylistSongs; i ++)
    {
        playlistIndexes[i] = (int)indexes[i];
    }
    
    [self playNextPlaylistItem];
}

- (void)playNextPlaylistItem
{
    currentPlaylistIndex ++;
    
    // Loop back to the start
    if(currentPlaylistIndex >= numberOfPlaylistSongs)
    {
        if(playlistFromWeb)
        {
            NSUInteger playlist[sequencesWithAudioCount];
            
            NSLog(@"Looping because of web playlist");
            int currentSongID = 0;
            int playlistIndex = 0;
            while(currentSongID < [self sequenceFilePathsCount])
            {
                playlist[playlistIndex] = currentSongID;
                currentSongID ++;
                playlistIndex ++;
            }
            
            playlistFromWeb = YES;
            
            [self playWebPlaylistOfSequenceIndexes:playlist indexCount:playlistIndex];
        }
        else
        {
            currentPlaylistIndex = 0;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayButtonPress" object:nil];
        }
    }
    
    // Pause the current sequence
    if(self.currentSequenceIsPlaying)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayButtonPress" object:nil];
    }
    // Load the new sequence and play it
    [self setCurrentSequence:[self sequenceFromFilePath:[self sequenceFilePathAtIndex:(int)playlistIndexes[currentPlaylistIndex]]]];
    self.currentSequenceIndex = (int)playlistIndexes[currentPlaylistIndex];
    [self setCurrentTime:0.0];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"SetSequence" object:currentSequence];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ResetScrollPoint" object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayButtonPress" object:nil];
    
    // So they know which song is playing
    [self updateAllSockets];
}

- (void)stopPlaylist
{
    memset(playlistIndexes, 0, 999);
    numberOfPlaylistSongs = -1;
    currentPlaylistIndex = -1;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"PlayButtonPress" object:nil];
}

- (void)autogenCurrentSequence
{
    // Delete all previous data for the sequence
    int commandClusterFilePathsCountForSequence = [self commandClusterFilePathsCountForSequence:currentSequence];
    NSLog(@"ccCount:%d", commandClusterFilePathsCountForSequence);
    shouldAutosave = NO;
    for(int i = 0; i < commandClusterFilePathsCountForSequence; i ++)
    {
        NSLog(@"delete cluster:%d", i);
        NSMutableDictionary *commandCluster = [self commandClusterForCurrentSequenceAtIndex:0];
        [self removeCommandClusterFromLibrary:commandCluster];
        [currentSequenceCommandClusters removeObject:commandCluster];
    }
    shouldAutosave = YES;
    [self setCurrentSequence:currentSequence];
    
    // Get the first audioAnalysis for this sequence (autogen does not yet support multiple audioAnalysi)
    NSDictionary *audioAnalysis = nil;
    audioAnalysis = [self audioAnalysisForCurrentSequenceAtIndex:0];
    
    // If the sequence has an analysis, autogen commands
    if(audioAnalysis != nil)
    {
        //NSDictionary *metaData = [audioAnalysis objectForKey:@"track"];
        NSArray *beats = [audioAnalysis objectForKey:@"beats"];
        NSArray *tatums = [audioAnalysis objectForKey:@"tatums"];
        NSArray *segments = [audioAnalysis objectForKey:@"segments"];
        
        int controlBoxesCount = [self controlBoxFilePathsCountForSequence:currentSequence];
        // Create one commandCluster per controlBox (these will get split up into smaller clusters layer)
        for(int i = 0; i < controlBoxesCount; i ++)
        {
            NSString *newCommandClusterFilePath = [self createCommandClusterAndReturnFilePath];
            NSMutableDictionary *newCommandCluster = [self commandClusterFromFilePath:newCommandClusterFilePath];
            [self setEndTime:[self endTimeForSequence:currentSequence] forCommandcluster:newCommandCluster];
            [self setDescription:[NSString stringWithFormat:@"%@", [self descriptionForControlBox:[self controlBoxForCurrentSequenceAtIndex:i]]] forCommandCluster:newCommandCluster];
            [self setControlBoxFilePath:[self controlBoxFilePathAtIndex:i forSequence:currentSequence] forCommandCluster:newCommandCluster];
            [self addCommandClusterFilePath:newCommandClusterFilePath forSequence:currentSequence];
        }
        shouldAutosave = NO;
        // Assgin the boxes to a data type
        int *beatControlBoxIndexes = malloc(controlBoxesCount * sizeof(int));
        int beatControlBoxesCount = 0;
        int *tatumControlBoxIndexes = malloc(controlBoxesCount * sizeof(int));
        int tatumControlBoxesCount = 0;
        int *segmentControlBoxIndexes = malloc(controlBoxesCount * sizeof(int));
        int segmentControlBoxesCount = 0;
        for(int i = 0; i < controlBoxesCount; i ++)
        {
            int dataType = arc4random() % 3; // Either a 0, 1, or 2 (beat, tatum, or segment)
            NSLog(@"dataType:%d", dataType);
            if(dataType == MNBeat)
            {
                beatControlBoxIndexes[beatControlBoxesCount] = i;
                beatControlBoxesCount ++;
            }
            else if(dataType == MNTatum)
            {
                tatumControlBoxIndexes[tatumControlBoxesCount] = i;
                tatumControlBoxesCount ++;
            }
            else if(dataType == MNSegment)
            {
                segmentControlBoxIndexes[segmentControlBoxesCount] = i;
                segmentControlBoxesCount ++;
            }
        }
        
        // Get the numberOfAvailableChannels for beatControlBoxes
        int numberOfAvailableChannelsForBeats = 0;
        for(int i = 0; i < beatControlBoxesCount; i ++)
        {
            numberOfAvailableChannelsForBeats += [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:beatControlBoxIndexes[i]]];
        }
        // Get the numberOfAvailableChannels for tatumControlBoxes
        int numberOfAvailableChannelsForTatums = 0;
        for(int i = 0; i < tatumControlBoxesCount; i ++)
        {
            numberOfAvailableChannelsForTatums += [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:tatumControlBoxIndexes[i]]];
        }
        // Get the numberOfAvailableChannels for segmentControlBoxes
        int numberOfAvailableChannelsForSegments = 0;
        for(int i = 0; i < segmentControlBoxesCount; i ++)
        {
            numberOfAvailableChannelsForSegments += [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:segmentControlBoxIndexes[i]]];
        }
        
        int numberOfChannelsToUse = 0;
        float averageLoudness = [[[audioAnalysis objectForKey:@"track"] objectForKey:@"loudness"] floatValue];
        NSLog(@"averageLoudness:%f", averageLoudness);
        float minLoudness = INT32_MAX;
        float maxLoudness = -INT32_MAX;
        // Find the min and max loudness of the audioAnalysis
        for(int currentSegmentIndex = 0; currentSegmentIndex < [segments count]; currentSegmentIndex ++)
        {
            NSDictionary *segment = [segments objectAtIndex:currentSegmentIndex];
            float segmentLoudness = [[segment objectForKey:@"loudness_start"] floatValue];
            
            if(segmentLoudness > maxLoudness)
            {
                maxLoudness = segmentLoudness;
            }
            if(segmentLoudness < minLoudness && segmentLoudness >= -51.000)
            {
                minLoudness = segmentLoudness;
            }
        }
        float loudnessRange = maxLoudness - minLoudness;
        NSLog(@"loudnessMin:%f max:%f", minLoudness, maxLoudness);
        
        // Loop through the segments
        for(int currentSegmentIndex = 0, currentTatumIndex = 0, currentBeatIndex = 0; currentSegmentIndex < [segments count]; currentSegmentIndex ++)
        {
            // Determine how many channels we should use for this segment
            NSDictionary *segment = [segments objectAtIndex:currentSegmentIndex];
            float segmentLoudness = [[segment objectForKey:@"loudness_start"] floatValue];
            float currentSegmentStartTime = [[segment objectForKey:@"start"] floatValue];
            float currentSegmentEndTime;
            if(currentSegmentIndex < [segments count] - 1)
            {
                currentSegmentEndTime = [[[segments objectAtIndex:currentSegmentIndex + 1] objectForKey:@"start"] floatValue];
            }
            else
            {
                currentSegmentEndTime = [self endTimeForSequence:currentSequence];
            }
            //int numberOfChannelsVariation = arc4random() % (int)(numberOfAvailableChannelsForSegments * 0.10) - (int)(numberOfAvailableChannelsForSegments * 0.05); // Add/subtract a 10% variation to the numberOfChannels
            numberOfChannelsToUse = ((segmentLoudness - minLoudness) / loudnessRange) * autogenIntensity * numberOfAvailableChannelsForSegments;// + numberOfChannelsVariation;
            // Limit the numberOfChannelsToUse
            if(numberOfChannelsToUse > numberOfAvailableChannelsForSegments)
            {
                numberOfChannelsToUse = numberOfAvailableChannelsForSegments;
            }
            else if(numberOfChannelsToUse < 0)
            {
                numberOfChannelsToUse = 0;
            }
            // Make an array of the availble channels for segment commands for easy command insertion (controlBoxIndex at index 0, channelIndex at index 1)
            NSMutableArray *availbleSegmentChannelIndexPaths = [[NSMutableArray alloc] init];
            for(int i = 0; i < segmentControlBoxesCount; i ++)
            {
                for(int i2 = 0; i2 < [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:segmentControlBoxIndexes[i]]]; i2 ++)
                {
                    [availbleSegmentChannelIndexPaths addObject:[[NSIndexPath indexPathWithIndex:segmentControlBoxIndexes[i]] indexPathByAddingIndex:i2]];
                }
            }
            NSLog(@"segment:%d of %d\tloudness:%f\tloudnesssmax:%f\tchannels:%d", currentSegmentIndex, (int)[segments count], segmentLoudness, [[segment objectForKey:@"loudness_max"] floatValue],numberOfChannelsToUse);
            
            // Create the commands for this segment
            for(int i = 0; i < numberOfChannelsToUse; i ++)
            {
                // Randomly pick a channel/controlBox to use
                int segmentChannelIndexPathToUse = arc4random() % [availbleSegmentChannelIndexPaths count];
                NSMutableDictionary *commandClusterForNewCommand = [self commandClusterForCurrentSequenceAtIndex:(int)[[availbleSegmentChannelIndexPaths objectAtIndex:segmentChannelIndexPathToUse] indexAtPosition:0]];
                // Create the newCommand and set it's start/end time
                int newCommandIndex = [self createCommandAndReturnNewCommandIndexForCommandCluster:commandClusterForNewCommand];
                [self setChannelIndex:(int)[[availbleSegmentChannelIndexPaths objectAtIndex:segmentChannelIndexPathToUse] indexAtPosition:1] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                [self setStartTime:[[segment objectForKey:@"start"] floatValue] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                float newCommandEndTime = 0;
                if(currentSegmentIndex < [segments count] - 1)
                {
                    newCommandEndTime = [[[segments objectAtIndex:currentSegmentIndex + 1] objectForKey:@"start"] floatValue] - 0.1;
                }
                else
                {
                    newCommandEndTime = [self endTimeForSequence:currentSequence] - 0.1;
                }
                [self setEndTime:newCommandEndTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                
                // Remove this channel/controlBox from the availble channels to use
                [availbleSegmentChannelIndexPaths removeObjectAtIndex:segmentChannelIndexPathToUse];
            }
            
            // Now create the commands for the tatums within the doman of the current segment
            for( ; (currentTatumIndex < [tatums count] && tatumControlBoxesCount > 0); currentTatumIndex ++)
            {
                NSDictionary *tatum = [tatums objectAtIndex:currentTatumIndex];
                float tatumStartTime = [[tatum objectForKey:@"start"] floatValue];
                
                // This tatum should have commands added
                if(tatumStartTime >= currentSegmentStartTime && tatumStartTime < currentSegmentEndTime)
                {
                    int numberOfChannelsVariation = arc4random() % (int)(numberOfAvailableChannelsForTatums * 0.20) - (int)(numberOfAvailableChannelsForTatums * 0.10); // Add/subtract a 10% variation to the numberOfChannels
                    numberOfChannelsToUse = ((segmentLoudness - minLoudness) / loudnessRange) * autogenIntensity * numberOfAvailableChannelsForTatums + numberOfChannelsVariation;
                    // Limit the numberOfChannelsToUse
                    if(numberOfChannelsToUse > numberOfAvailableChannelsForTatums)
                    {
                        numberOfChannelsToUse = numberOfAvailableChannelsForTatums;
                    }
                    else if(numberOfChannelsToUse < 0)
                    {
                        numberOfChannelsToUse = 0;
                    }
                    // Make an array of the availble channels for tatum commands for easy command insertion (controlBoxIndex at index 0, channelIndex at index 1)
                    NSMutableArray *availbleTatumChannelIndexPaths = [[NSMutableArray alloc] init];
                    for(int i = 0; i < tatumControlBoxesCount; i ++)
                    {
                        for(int i2 = 0; i2 < [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:tatumControlBoxIndexes[i]]]; i2 ++)
                        {
                            [availbleTatumChannelIndexPaths addObject:[[NSIndexPath indexPathWithIndex:tatumControlBoxIndexes[i]] indexPathByAddingIndex:i2]];
                        }
                    }
                    
                    // Create the commands for this tatum
                    for(int i = 0; i < numberOfChannelsToUse; i ++)
                    {
                        // Randomly pick a channel/controlBox to use
                        int tatumChannelIndexPathToUse = arc4random() % [availbleTatumChannelIndexPaths count];
                        NSMutableDictionary *commandClusterForNewCommand = [self commandClusterForCurrentSequenceAtIndex:(int)[[availbleTatumChannelIndexPaths objectAtIndex:tatumChannelIndexPathToUse] indexAtPosition:0]];
                        // Create the newCommand and set it's start/end time
                        int newCommandIndex = [self createCommandAndReturnNewCommandIndexForCommandCluster:commandClusterForNewCommand];
                        [self setChannelIndex:(int)[[availbleTatumChannelIndexPaths objectAtIndex:tatumChannelIndexPathToUse] indexAtPosition:1] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                        [self setStartTime:[[tatum objectForKey:@"start"] floatValue] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                        float newCommandEndTime = 0;
                        if(currentTatumIndex < [tatums count] - 1)
                        {
                            newCommandEndTime = [[[tatums objectAtIndex:currentTatumIndex + 1] objectForKey:@"start"] floatValue] - 0.1;
                        }
                        else
                        {
                            newCommandEndTime = [self endTimeForSequence:currentSequence] - 0.1;
                        }
                        [self setEndTime:newCommandEndTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                        
                        // Remove this channel/controlBox from the availble channels to use
                        [availbleTatumChannelIndexPaths removeObjectAtIndex:tatumChannelIndexPathToUse];
                    }
                }
                // We are done looking if we get past the endTime of the current segment since the data is sorted
                else if(tatumStartTime >= currentSegmentEndTime)
                {
                    break;
                }
            }
            
            // Now create the commands for the beats within the doman of the current segment
            for( ; (currentBeatIndex < [beats count] && beatControlBoxesCount > 0); currentBeatIndex ++)
            {
                NSDictionary *beat = [beats objectAtIndex:currentBeatIndex];
                float beatStartTime = [[beat objectForKey:@"start"] floatValue];
                
                // This beat should have commands added
                if(beatStartTime >= currentSegmentStartTime && beatStartTime < currentSegmentEndTime)
                {
                    int numberOfChannelsVariation = arc4random() % (int)(numberOfAvailableChannelsForBeats * 0.20) - (int)(numberOfAvailableChannelsForBeats * 0.10); // Add/subtract a 10% variation to the numberOfChannels
                    numberOfChannelsToUse = ((segmentLoudness - minLoudness) / loudnessRange) * autogenIntensity * numberOfAvailableChannelsForBeats + numberOfChannelsVariation;
                    // Limit the numberOfChannelsToUse
                    if(numberOfChannelsToUse > numberOfAvailableChannelsForBeats)
                    {
                        numberOfChannelsToUse = numberOfAvailableChannelsForBeats;
                    }
                    else if(numberOfChannelsToUse < 0)
                    {
                        numberOfChannelsToUse = 0;
                    }
                    // Make an array of the availble channels for beat commands for easy command insertion (controlBoxIndex at index 0, channelIndex at index 1)
                    NSMutableArray *availbleBeatChannelIndexPaths = [[NSMutableArray alloc] init];
                    for(int i = 0; i < beatControlBoxesCount; i ++)
                    {
                        for(int i2 = 0; i2 < [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:beatControlBoxIndexes[i]]]; i2 ++)
                        {
                            [availbleBeatChannelIndexPaths addObject:[[NSIndexPath indexPathWithIndex:beatControlBoxIndexes[i]] indexPathByAddingIndex:i2]];
                        }
                    }
                    
                    // Create the commands for this beat
                    for(int i = 0; i < numberOfChannelsToUse; i ++)
                    {
                        // Randomly pick a channel/controlBox to use
                        int beatChannelIndexPathToUse = arc4random() % [availbleBeatChannelIndexPaths count];
                        NSMutableDictionary *commandClusterForNewCommand = [self commandClusterForCurrentSequenceAtIndex:(int)[[availbleBeatChannelIndexPaths objectAtIndex:beatChannelIndexPathToUse] indexAtPosition:0]];
                        // Create the newCommand and set it's start/end time
                        int newCommandIndex = [self createCommandAndReturnNewCommandIndexForCommandCluster:commandClusterForNewCommand];
                        [self setChannelIndex:(int)[[availbleBeatChannelIndexPaths objectAtIndex:beatChannelIndexPathToUse] indexAtPosition:1] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                        [self setStartTime:[[beat objectForKey:@"start"] floatValue] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                        float newCommandEndTime = 0;
                        if(currentBeatIndex < [beats count] - 1)
                        {
                            newCommandEndTime = [[[beats objectAtIndex:currentBeatIndex + 1] objectForKey:@"start"] floatValue] - 0.1;
                        }
                        else
                        {
                            newCommandEndTime = [self endTimeForSequence:currentSequence] - 0.1;
                        }
                        [self setEndTime:newCommandEndTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                        
                        // Remove this channel/controlBox from the availble channels to use
                        [availbleBeatChannelIndexPaths removeObjectAtIndex:beatChannelIndexPathToUse];
                    }
                }
                // We are done looking if we get past the endTime of the current segment since the data is sorted
                else if(beatStartTime >= currentSegmentEndTime)
                {
                    break;
                }
            }
        }
        
        // Split up the commandClusters every 5 seconds
        for(int i = 0; i < controlBoxesCount; i ++)
        {
            int commandClusterIndexToSplit = i;
            int newCommandClusterIndexToSplit = 0;
            for(float t = 5.0; t < [self endTimeForSequence:currentSequence]; t += 5.0)
            {
                NSLog(@"splitting commandClusterIndex:%d", commandClusterIndexToSplit);
                newCommandClusterIndexToSplit = [self splitCommandClusterForCurrentSequenceAtIndex:commandClusterIndexToSplit atTime:t];
                
                // Manually save each cluster now that we are done changing it
                [self saveDictionaryToItsFilePath:[self commandClusterForCurrentSequenceAtIndex:commandClusterIndexToSplit]];
                
                commandClusterIndexToSplit = newCommandClusterIndexToSplit;
            }
            
            // Manually save each cluster now that we are done changing it
            [self saveDictionaryToItsFilePath:[self commandClusterForCurrentSequenceAtIndex:commandClusterIndexToSplit]];
        }
        
        [self saveDictionaryToItsFilePath:currentSequence];
        
        // Manually save each cluster now that we are done changing it
        /*for(int i = 0; i < controlBoxesCount; i ++)
        {
            [self saveDictionaryToItsFilePath:[self commandClusterForCurrentSequenceAtIndex:i]];
        }*/
        
        shouldAutosave = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
    }
}

- (void)autogenv2ForCurrentSequence
{
    // Delete all previous data for the sequence
    int commandClusterFilePathsCountForSequence = [self commandClusterFilePathsCountForSequence:currentSequence];
    NSLog(@"ccCount:%d", commandClusterFilePathsCountForSequence);
    shouldAutosave = NO;
    for(int i = 0; i < commandClusterFilePathsCountForSequence; i ++)
    {
        NSLog(@"delete cluster:%d", i);
        NSMutableDictionary *commandCluster = [self commandClusterForCurrentSequenceAtIndex:0];
        [self removeCommandClusterFromLibrary:commandCluster];
        [currentSequenceCommandClusters removeObject:commandCluster];
    }
    shouldAutosave = YES;
    [self setCurrentSequence:currentSequence];
    
    // Get the first audioAnalysis for this sequence (autogen does not yet support multiple audioAnalysi)
    NSDictionary *audioAnalysis = nil;
    audioAnalysis = [self audioAnalysisForCurrentSequenceAtIndex:0];
    
    // If the sequence has an analysis, autogen commands
    if(audioAnalysis != nil)
    {
        // Variables
        //NSDictionary *metaData = [audioAnalysis objectForKey:@"track"];
        NSArray *beats = [audioAnalysis objectForKey:@"beats"];
        NSArray *tatums = [audioAnalysis objectForKey:@"tatums"];
        NSArray *segments = [audioAnalysis objectForKey:@"segments"];
        NSArray *sections = [audioAnalysis objectForKey:@"sections"];
        
        int controlBoxesCount = [self controlBoxFilePathsCountForSequence:currentSequence];
        
        int *beatControlBoxIndexes = malloc(controlBoxesCount * sizeof(int));
        int beatControlBoxesCount = 0;
        int *tatumControlBoxIndexes = malloc(controlBoxesCount * sizeof(int));
        int tatumControlBoxesCount = 0;
        int *segmentControlBoxIndexes = malloc(controlBoxesCount * sizeof(int));
        int segmentControlBoxesCount = 0;
        int *controlBoxesBeingUsed = malloc(controlBoxesCount * sizeof(int));
        memset(controlBoxesBeingUsed, 0, controlBoxesCount * sizeof(int));
        int controlBoxesAvailable = controlBoxesCount;
        int numberOfBoxesToUseForBeat = (controlBoxesAvailable > 3 ? arc4random() % 2 + 1 : 0); // 1 or 2
        int numberOfBoxesToUseForTatum = (controlBoxesAvailable > 3 ? 1 : 0); // just 1 for now
        
        int numberOfAvailableChannelsForBeats = 0;
        int numberOfAvailableChannelsForTatums = 0;
        int numberOfAvailableChannelsForSegments = 0;
        
        float minLoudness = 10000.0;
        float maxLoudness = -10000.0;
        
        int pitchesToUse[12];
        memset(pitchesToUse, -1, 12 * sizeof(int));
        float channelsPerPitch = 0;
        int pitchesToUseCount = 0;
        
        // Find the min and max loudness of the audioAnalysis
        for(int currentSegmentIndex = 0; currentSegmentIndex < [segments count]; currentSegmentIndex ++)
        {
            NSDictionary *segment = [segments objectAtIndex:currentSegmentIndex];
            float segmentLoudness = [[segment objectForKey:@"loudness_start"] floatValue];
            
            if(segmentLoudness > maxLoudness)
            {
                maxLoudness = segmentLoudness;
            }
            if(segmentLoudness < minLoudness && segmentLoudness >= -51.000)
            {
                minLoudness = segmentLoudness;
            }
        }
        float loudnessRange = maxLoudness - minLoudness;
        NSLog(@"loudness Min:%f max:%f range:%f", minLoudness, maxLoudness, loudnessRange);
        
        // Create one commandCluster per controlBox (these will get split up into smaller clusters layer)
        for(int i = 0; i < controlBoxesCount; i ++)
        {
            NSString *newCommandClusterFilePath = [self createCommandClusterAndReturnFilePath];
            NSMutableDictionary *newCommandCluster = [self commandClusterFromFilePath:newCommandClusterFilePath];
            [self setEndTime:[self endTimeForSequence:currentSequence] forCommandcluster:newCommandCluster];
            [self setDescription:[NSString stringWithFormat:@"%@", [self descriptionForControlBox:[self controlBoxForCurrentSequenceAtIndex:i]]] forCommandCluster:newCommandCluster];
            [self setControlBoxFilePath:[self controlBoxFilePathAtIndex:i forSequence:currentSequence] forCommandCluster:newCommandCluster];
            [self addCommandClusterFilePath:newCommandClusterFilePath forSequence:currentSequence];
        }
        shouldAutosave = NO;
        
        // Pick controlBox indexes for the beat
        if(numberOfBoxesToUseForBeat >= 1)
        {
            // Pick a random control box index
            int controlBoxIndexToUse = arc4random() % controlBoxesCount;
            NSLog(@"beat CB:%d", controlBoxIndexToUse);
            controlBoxesBeingUsed[controlBoxIndexToUse] = 1;
            controlBoxesAvailable --;
            
            // Store it in the beats controls boxes array
            beatControlBoxIndexes[beatControlBoxesCount] = controlBoxIndexToUse;
            beatControlBoxesCount ++;
        }
        if(numberOfBoxesToUseForBeat >= 2)
        {
            // Pick a random control box index
            int controlBoxIndexToUse = -1;
            do
            {
                controlBoxIndexToUse = arc4random() % controlBoxesCount;
            } while(controlBoxesBeingUsed[controlBoxIndexToUse] == 1);
            controlBoxesBeingUsed[controlBoxIndexToUse] = 1;
            controlBoxesAvailable --;
            
            // Store it in the beats controls boxes array
            beatControlBoxIndexes[beatControlBoxesCount] = controlBoxIndexToUse;
            beatControlBoxesCount ++;
        }
        // Get the numberOfAvailableChannels for beatControlBoxes
        for(int i = 0; i < beatControlBoxesCount; i ++)
        {
            numberOfAvailableChannelsForBeats += [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:beatControlBoxIndexes[i]]];
        }
        
        // Pick a controlBox index for the tatum
        if(numberOfBoxesToUseForTatum >= 1)
        {
            // Pick a random control box index
            int controlBoxIndexToUse = -1;
            do
            {
                controlBoxIndexToUse = arc4random() % controlBoxesCount;
            } while(controlBoxesBeingUsed[controlBoxIndexToUse] == 1);
            controlBoxesBeingUsed[controlBoxIndexToUse] = 1;
            controlBoxesAvailable --;
            
            // Store it in the beats controls boxes array
            tatumControlBoxIndexes[tatumControlBoxesCount] = controlBoxIndexToUse;
            tatumControlBoxesCount ++;
        }
        // Get the numberOfAvailableChannels for tatumControlBoxes
        for(int i = 0; i < tatumControlBoxesCount; i ++)
        {
            numberOfAvailableChannelsForTatums += [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:tatumControlBoxIndexes[i]]];
        }
        
        // Main loop (looping through the sections, then segments, then beats and tatums)
        for(int currentSectionIndex = 0; currentSectionIndex < [sections count]; currentSectionIndex ++)
        {
            float averageLoudnessForSection = 0.0;
            float numberOfSegmentsUsedForAverageLoudness = 0;
            NSDictionary *currentSection = [sections objectAtIndex:currentSectionIndex];
            float sectionStartTime = [[currentSection objectForKey:@"start"] floatValue];
            float sectionEndTime = sectionStartTime + [[currentSection objectForKey:@"duration"] floatValue];
            int numberOfControlBoxesToUseForSegments = 0;
            memset(segmentControlBoxIndexes, 0, controlBoxesCount * sizeof(int));
            segmentControlBoxesCount = 0;
            numberOfAvailableChannelsForSegments = 0;
            
            // Make a copy of the controlBoxes being used/available to assign to the segments
            int tempControlBoxesAvailable = controlBoxesAvailable;
            int tempControlBoxesBeingUsed[controlBoxesCount];
            for(int i = 0; i < controlBoxesCount; i ++)
            {
                tempControlBoxesBeingUsed[i] = controlBoxesBeingUsed[i];
            }
            
            // Determine the average loudness for this section as well as what pitches to use
            for(int currentSegmentIndex = 1; currentSegmentIndex < [segments count]; currentSegmentIndex ++)
            {
                NSDictionary *currentSegment = [segments objectAtIndex:currentSegmentIndex];
                float segmentStartTime = [[currentSegment objectForKey:@"start"] floatValue];
                float segmentEndTime = segmentStartTime + [[currentSegment objectForKey:@"duration"] floatValue];
                
                // Determine if this segment is within the bounds of the sections
                if(segmentStartTime >= sectionStartTime && segmentEndTime <= sectionEndTime)
                {
                    averageLoudnessForSection += [[currentSegment objectForKey:@"loudness_start"] floatValue];
                    numberOfSegmentsUsedForAverageLoudness ++;
                    
                    NSArray *pitches = [currentSegment objectForKey:@"pitches"];
                    for(int i = 0; i < 12; i ++)
                    {
                        if([[pitches objectAtIndex:i] floatValue] > 0.5)
                        {
                            BOOL pitchAlreadyInUse = NO;
                            for(int i2 = 0; i2 < 12; i2 ++)
                            {
                                if(pitchesToUse[i2] == i)
                                {
                                    pitchAlreadyInUse = YES;
                                    break;
                                }
                            }
                            
                            if(!pitchAlreadyInUse)
                            {
                                pitchesToUse[pitchesToUseCount] = i;
                                NSLog(@"pitchesToUse[%d]:%d", pitchesToUseCount, i);
                                pitchesToUseCount ++;
                            }
                        }
                    }
                }
                else if(segmentStartTime > sectionEndTime)
                {
                    break;
                }
            }
            averageLoudnessForSection /= numberOfSegmentsUsedForAverageLoudness;
            NSLog(@"averageLoudnessForSection[%d]:%f", currentSectionIndex, averageLoudnessForSection);
            NSLog(@"controlBoxesAvailable:%d", controlBoxesAvailable);
            
            // Determine how many controlBoxes to use
            numberOfControlBoxesToUseForSegments = (int)((averageLoudnessForSection - minLoudness) / loudnessRange * autogenv2Intensity * tempControlBoxesAvailable + 0.5);
            if(numberOfControlBoxesToUseForSegments == 0)
            {
                numberOfControlBoxesToUseForSegments = 1;
            }
            // If we are using 2 or fewer boxes, assign all boxes to segment data
            if(numberOfBoxesToUseForBeat == 0 && numberOfBoxesToUseForTatum == 0)
            {
                numberOfControlBoxesToUseForSegments = tempControlBoxesAvailable;
            }
            
            // Now randomly assign boxes to use for the segments
            for(int i = 0; i < numberOfControlBoxesToUseForSegments; i ++)
            {
                int controlBoxIndexToUse = -1;
                do
                {
                    controlBoxIndexToUse = arc4random() % controlBoxesCount;
                } while(tempControlBoxesBeingUsed[controlBoxIndexToUse] == 1);
                tempControlBoxesBeingUsed[controlBoxIndexToUse] = 1;
                tempControlBoxesAvailable --;
                
                NSLog(@"segmentCBI[%d] set:%d", segmentControlBoxesCount, controlBoxIndexToUse);
                segmentControlBoxIndexes[segmentControlBoxesCount] = controlBoxIndexToUse;
                segmentControlBoxesCount ++;
            }
            
            // Get the numberOfAvailableChannels for segmentControlBoxes
            for(int i = 0; i < segmentControlBoxesCount; i ++)
            {
                numberOfAvailableChannelsForSegments += [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:segmentControlBoxIndexes[i]]];
            }
            
            // Calculate the number of channels per pitch
            NSLog(@"availableChannels:%d", numberOfAvailableChannelsForSegments);
            NSLog(@"pitchesToUseCount:%d", pitchesToUseCount);
            channelsPerPitch = -1;
            
            // Make a 2D array of the availble channels for segment commands for easy command insertion (controlBoxIndex at index 0, channelIndex at index 1)
            NSMutableArray *segmentChannelIndexPathArrays = [[NSMutableArray alloc] init];
            for(int i = 0; i < 12; i ++)
            {
                NSMutableArray *availableSegmentChannelIndexPathsForPitch = [[NSMutableArray alloc] init];
                [segmentChannelIndexPathArrays addObject:availableSegmentChannelIndexPathsForPitch];
            }
            int currentPitchIndex = pitchesToUse[0];
            int pitchesAssigned = 0;
            int channelsAssignedTotal = 0;
            int channelsToUseCount = 0;
            for(int i = 0; i < segmentControlBoxesCount; i ++)
            {
                channelsToUseCount = [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:segmentControlBoxIndexes[i]]];
                channelsPerPitch = (float)channelsToUseCount / pitchesToUseCount * autogenv2Intensity; // Use this to assign all pitches to each box
                NSLog(@"channels:%d, pitchesToUse:%d, intensity:%f, channelsPerPitch:%f", channelsToUseCount, pitchesToUseCount, autogenv2Intensity, channelsPerPitch);
                currentPitchIndex = pitchesToUse[0]; // Also use these 3 lines to assign all pitches to each box
                pitchesAssigned = 0;
                channelsAssignedTotal = 0;
                for(int i2 = 0; i2 < [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:segmentControlBoxIndexes[i]]]; i2 ++)
                {
                    // If there are fewer picthes than channels, use this math to distribute the pitches throughout the channels rather than having them lumped into to first couple channels
                    if(channelsPerPitch < 1.0)
                    {
                        if(channelsPerPitch * (i2 + 1) > pitchesAssigned + 0.01)
                        {
                            [[segmentChannelIndexPathArrays objectAtIndex:currentPitchIndex] addObject:[[NSIndexPath indexPathWithIndex:segmentControlBoxIndexes[i]] indexPathByAddingIndex:i2]];
                            NSLog(@"channel:%d assigned to pitch:%d", i2, currentPitchIndex);
                            
                            channelsAssignedTotal ++;
                            NSLog(@"channelsAssignedTotal:%d RH:%d, pitchesAssigned:%d", channelsAssignedTotal, (int)(channelsPerPitch * (pitchesAssigned + 1)), pitchesAssigned);
                            
                            pitchesAssigned ++;
                            currentPitchIndex = pitchesToUse[pitchesAssigned];
                            //NSLog(@"currentPitchIndex:%d", currentPitchIndex);
                            
                            // If all of the pitches have been assigned, we are done
                            if(pitchesAssigned >= pitchesToUseCount)
                                break;
                        }
                    }
                    // Else use this math to assign 1 pitch to multiple channels
                    else
                    {
                        [[segmentChannelIndexPathArrays objectAtIndex:currentPitchIndex] addObject:[[NSIndexPath indexPathWithIndex:segmentControlBoxIndexes[i]] indexPathByAddingIndex:i2]];
                        NSLog(@"channel:%d assigned to pitch:%d", i2, currentPitchIndex);
                        
                        channelsAssignedTotal ++;
                        NSLog(@"channelsAssignedTotal:%d RH:%d, pitchesAssigned:%d", channelsAssignedTotal, (int)(channelsPerPitch * (pitchesAssigned + 1)), pitchesAssigned);
                        if(channelsAssignedTotal >= (int)(channelsPerPitch * (pitchesAssigned + 1)))
                        {
                            pitchesAssigned ++;
                            currentPitchIndex = pitchesToUse[pitchesAssigned];
                            //NSLog(@"currentPitchIndex:%d", currentPitchIndex);
                            
                            // If all of the pitches have been assigned, we are done
                            if(pitchesAssigned >= pitchesToUseCount)
                                break;
                        }
                    }
                }
            }
            
            // Now loop through each segment
            for(int currentSegmentIndex = 1, currentTatumIndex = 0, currentBeatIndex = 0; currentSegmentIndex < [segments count]; currentSegmentIndex ++)
            {
                NSDictionary *previousSegment;
                if(currentSegmentIndex >= 1)
                    previousSegment = [segments objectAtIndex:currentSegmentIndex - 1];
                NSArray *previousSegmentPitches = [previousSegment objectForKey:@"pitches"];
                NSDictionary *currentSegment = [segments objectAtIndex:currentSegmentIndex];
                NSArray *currentSegmentPitches = [currentSegment objectForKey:@"pitches"];
                NSDictionary *nextSegment;
                if(currentSegmentIndex < [segments count] - 1)
                    nextSegment = [segments objectAtIndex:currentSegmentIndex + 1];
                NSArray *nextSegmentPitches = [nextSegment objectForKey:@"pitches"];
                NSDictionary *nextNextSegment;
                if(currentSegmentIndex < [segments count] - 2)
                    nextNextSegment = [segments objectAtIndex:currentSegmentIndex + 2];
                NSArray *nextNextSegmentPitches = [nextNextSegment objectForKey:@"pitches"];
                float currentSegmentLoudness = [[currentSegment objectForKey:@"loudness_start"] floatValue];
                float currentSegmentStartTime = [[currentSegment objectForKey:@"start"] floatValue];
                float currentSegmentEndTime = currentSegmentStartTime + [[currentSegment objectForKey:@"duration"] floatValue];
                
                NSLog(@"currentSegmentIndex:%d", currentSegmentIndex);
                
                // Make sure this segment is within the current section
                if(currentSegmentStartTime >= sectionStartTime && currentSegmentEndTime <= sectionEndTime)
                {
                    // Create the commands for the segments
                    for(int pitchCounter = 0; pitchCounter < pitchesToUseCount; pitchCounter ++)
                    {
                        int currentPitchIndex = pitchesToUse[pitchCounter];
                        float previousPitchValue = [[previousSegmentPitches objectAtIndex:currentPitchIndex] floatValue];
                        float currentPitchValue = [[currentSegmentPitches objectAtIndex:currentPitchIndex] floatValue];
                        float nextPitchValue = [[nextSegmentPitches objectAtIndex:currentPitchIndex] floatValue];
                        float nextNextPitchValue = [[nextNextSegmentPitches objectAtIndex:currentPitchIndex] floatValue];
                        //NSLog(@"pitchIndex:%d currentPitch:%f previousPitch:%f", currentPitchIndex, currentPitchValue, previousPitchValue);
                        
                        // Create a new command (volume increased, therefore it has to be a new 'ding')
                        if(currentPitchValue >= previousPitchValue + 0.1 && currentPitchValue >= 0.3) // && currentPitch > 0.5???
                        {
                            NSLog(@"yes for pitch:%d", currentPitchIndex);
                            NSMutableArray *availbleSegmentChannelIndexPaths = [segmentChannelIndexPathArrays objectAtIndex:currentPitchIndex];
                            NSLog(@"availableChannels:%d", (int)[availbleSegmentChannelIndexPaths count]);
                            
                            for(int i = 0; i < [availbleSegmentChannelIndexPaths count]; i ++)
                            {
                                // Create the newCommand and set it's start/end time
                                NSMutableDictionary *commandClusterForNewCommand = [self commandClusterForCurrentSequenceAtIndex:(int)[[availbleSegmentChannelIndexPaths objectAtIndex:i] indexAtPosition:0]];
                                int newCommandIndex = [self createCommandAndReturnNewCommandIndexForCommandCluster:commandClusterForNewCommand];
                                [self setChannelIndex:(int)[[availbleSegmentChannelIndexPaths objectAtIndex:i] indexAtPosition:1] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                [self setStartTime:currentSegmentStartTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                float newCommandEndTime;
                                // Note lasts more than this segment
                                if(nextPitchValue <= currentPitchValue)
                                {
                                    // Note lasts at least 2 segments
                                    if((nextPitchValue <= currentPitchValue && nextPitchValue >= 0.3 && [[nextSegment objectForKey:@"confidence"] floatValue] >= 0.3) || (currentPitchValue - nextPitchValue <= 0.1 && currentPitchValue - nextPitchValue >= 0.0 && [[nextSegment objectForKey:@"confidence"] floatValue] < 0.3))
                                    {
                                        // Note lasts three segments
                                        if((nextNextPitchValue <= nextPitchValue && nextNextPitchValue >= 0.3 && [[nextNextSegment objectForKey:@"confidence"] floatValue] >= 0.3) || (nextPitchValue - nextNextPitchValue <= 0.1 && nextPitchValue - nextNextPitchValue >= 0.0 && [[nextNextSegment objectForKey:@"confidence"] floatValue] < 0.3))
                                        {
                                            NSLog(@"three segments");
                                            newCommandEndTime = currentSegmentStartTime + ([[nextNextSegment objectForKey:@"start"] floatValue] - currentSegmentStartTime) + [[nextNextSegment objectForKey:@"duration"] floatValue] - 0.1;
                                        }
                                        // Note lasts two segments but the third segment is a new note
                                        else if(nextNextPitchValue >= nextPitchValue + 0.1 && nextPitchValue >= 0.2)
                                        {
                                            NSLog(@"two segments, third is new note");
                                            newCommandEndTime = currentSegmentStartTime + ([[nextSegment objectForKey:@"start"] floatValue] - currentSegmentStartTime) + [[nextSegment objectForKey:@"duration"] floatValue] - 0.1;
                                        }
                                        // Note lasts two segments and the third segment is not a note
                                        else
                                        {
                                            NSLog(@"two segments");
                                            newCommandEndTime = currentSegmentStartTime + ([[nextSegment objectForKey:@"start"] floatValue] - currentSegmentStartTime) + [[nextSegment objectForKey:@"duration"] floatValue];
                                        }
                                    }
                                    // Note just lasts one segment
                                    else
                                    {
                                        NSLog(@"one segment fade out");
                                        newCommandEndTime = [[currentSegment objectForKey:@"start"] floatValue] + [[currentSegment objectForKey:@"duration"] floatValue];
                                    }
                                }
                                else
                                {
                                    NSLog(@"One segment");
                                    newCommandEndTime = [[currentSegment objectForKey:@"start"] floatValue] + [[currentSegment objectForKey:@"duration"] floatValue] - 0.1;
                                }
                                [self setEndTime:newCommandEndTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                NSLog(@"c start:%f end:%f", currentSegmentStartTime, newCommandEndTime);
                            }
                        }
                    }
                    
                    // Now create the commands for the tatums within the doman of the current segment
                    for( ; (currentTatumIndex < [tatums count] && tatumControlBoxesCount > 0); currentTatumIndex ++)
                    {
                        NSDictionary *tatum = [tatums objectAtIndex:currentTatumIndex];
                        float tatumStartTime = [[tatum objectForKey:@"start"] floatValue];
                        
                        // This tatum should have commands added
                        if(tatumStartTime >= currentSegmentStartTime && tatumStartTime < currentSegmentEndTime && [[tatum objectForKey:@"confidence"] floatValue] >= 0.10)
                        {
                            //int numberOfChannelsVariation = arc4random() % (int)(numberOfAvailableChannelsForTatums * 0.20) - (int)(numberOfAvailableChannelsForTatums * 0.10); // Add/subtract a 10% variation to the numberOfChannels
                            int numberOfChannelsToUse = ((currentSegmentLoudness - minLoudness) / loudnessRange) * autogenv2Intensity * numberOfAvailableChannelsForTatums / 2;// + numberOfChannelsVariation;
                            
                            // Limit the numberOfChannelsToUse
                            if(numberOfChannelsToUse > numberOfAvailableChannelsForTatums)
                            {
                                numberOfChannelsToUse = numberOfAvailableChannelsForTatums;
                            }
                            else if(numberOfChannelsToUse < 0)
                            {
                                numberOfChannelsToUse = 0;
                            }
                            else if(numberOfChannelsToUse == 0)
                            {
                                numberOfChannelsToUse ++;
                            }
                            // Make an array of the availble channels for tatum commands for easy command insertion (controlBoxIndex at index 0, channelIndex at index 1)
                            NSMutableArray *availbleTatumChannelIndexPaths = [[NSMutableArray alloc] init];
                            for(int i = 0; i < tatumControlBoxesCount; i ++)
                            {
                                for(int i2 = 0; i2 < [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:tatumControlBoxIndexes[i]]]; i2 ++)
                                {
                                    [availbleTatumChannelIndexPaths addObject:[[NSIndexPath indexPathWithIndex:tatumControlBoxIndexes[i]] indexPathByAddingIndex:i2]];
                                }
                            }
                            
                            // Create the commands for this tatum
                            for(int i = 0; i < numberOfChannelsToUse; i ++)
                            {
                                // Randomly pick a channel/controlBox to use
                                int tatumChannelIndexPathToUse = arc4random() % [availbleTatumChannelIndexPaths count];
                                NSMutableDictionary *commandClusterForNewCommand = [self commandClusterForCurrentSequenceAtIndex:(int)[[availbleTatumChannelIndexPaths objectAtIndex:tatumChannelIndexPathToUse] indexAtPosition:0]];
                                // Create the newCommand and set it's start/end time
                                int newCommandIndex = [self createCommandAndReturnNewCommandIndexForCommandCluster:commandClusterForNewCommand];
                                [self setChannelIndex:(int)[[availbleTatumChannelIndexPaths objectAtIndex:tatumChannelIndexPathToUse] indexAtPosition:1] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                [self setStartTime:[[tatum objectForKey:@"start"] floatValue] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                float newCommandEndTime = [[tatum objectForKey:@"start"] floatValue] + [[tatum objectForKey:@"duration"] floatValue] - 0.1;
                                [self setEndTime:newCommandEndTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                
                                // Remove this channel/controlBox from the availble channels to use
                                [availbleTatumChannelIndexPaths removeObjectAtIndex:tatumChannelIndexPathToUse];
                            }
                        }
                        // We are done looking if we get past the endTime of the current segment since the data is sorted
                        else if(tatumStartTime >= currentSegmentEndTime)
                        {
                            break;
                        }
                    }
                    
                    // Now create the commands for the beats within the doman of the current segment
                    for( ; (currentBeatIndex < [beats count] && beatControlBoxesCount > 0); currentBeatIndex ++)
                    {
                        NSDictionary *beat = [beats objectAtIndex:currentBeatIndex];
                        float beatStartTime = [[beat objectForKey:@"start"] floatValue];
                        
                        // This beat should have commands added
                        if(beatStartTime >= currentSegmentStartTime && beatStartTime < currentSegmentEndTime && [[beat objectForKey:@"confidence"] floatValue] >= 0.10)
                        {
                            //int numberOfChannelsVariation = arc4random() % (int)(numberOfAvailableChannelsForBeats * 0.20) - (int)(numberOfAvailableChannelsForBeats * 0.10); // Add/subtract a 10% variation to the numberOfChannels
                            int numberOfChannelsToUse = ((currentSegmentLoudness - minLoudness) / loudnessRange) * autogenv2Intensity * numberOfAvailableChannelsForBeats / 2;// + numberOfChannelsVariation;
                            
                            // Limit the numberOfChannelsToUse
                            if(numberOfChannelsToUse > numberOfAvailableChannelsForBeats)
                            {
                                numberOfChannelsToUse = numberOfAvailableChannelsForBeats;
                            }
                            else if(numberOfChannelsToUse < 0)
                            {
                                numberOfChannelsToUse = 0;
                            }
                            else if(numberOfChannelsToUse == 0)
                            {
                                numberOfChannelsToUse ++;
                            }
                            // Make an array of the availble channels for beat commands for easy command insertion (controlBoxIndex at index 0, channelIndex at index 1)
                            NSMutableArray *availbleBeatChannelIndexPaths = [[NSMutableArray alloc] init];
                            for(int i = 0; i < beatControlBoxesCount; i ++)
                            {
                                for(int i2 = 0; i2 < [self channelsCountForControlBox:[self controlBoxForCurrentSequenceAtIndex:beatControlBoxIndexes[i]]]; i2 ++)
                                {
                                    [availbleBeatChannelIndexPaths addObject:[[NSIndexPath indexPathWithIndex:beatControlBoxIndexes[i]] indexPathByAddingIndex:i2]];
                                }
                            }
                            
                            // Create the commands for this beat
                            for(int i = 0; i < numberOfChannelsToUse; i ++)
                            {
                                // Randomly pick a channel/controlBox to use
                                int beatChannelIndexPathToUse = arc4random() % [availbleBeatChannelIndexPaths count];
                                NSMutableDictionary *commandClusterForNewCommand = [self commandClusterForCurrentSequenceAtIndex:(int)[[availbleBeatChannelIndexPaths objectAtIndex:beatChannelIndexPathToUse] indexAtPosition:0]];
                                // Create the newCommand and set it's start/end time
                                int newCommandIndex = [self createCommandAndReturnNewCommandIndexForCommandCluster:commandClusterForNewCommand];
                                [self setChannelIndex:(int)[[availbleBeatChannelIndexPaths objectAtIndex:beatChannelIndexPathToUse] indexAtPosition:1] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                [self setStartTime:[[beat objectForKey:@"start"] floatValue] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                float newCommandEndTime = [[beat objectForKey:@"start"] floatValue] + [[beat objectForKey:@"duration"] floatValue] - 0.1;
                                [self setEndTime:newCommandEndTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:commandClusterForNewCommand];
                                
                                // Remove this channel/controlBox from the availble channels to use
                                [availbleBeatChannelIndexPaths removeObjectAtIndex:beatChannelIndexPathToUse];
                            }
                        }
                        // We are done looking if we get past the endTime of the current segment since the data is sorted
                        else if(beatStartTime >= currentSegmentEndTime)
                        {
                            break;
                        }
                    }
                }
            }
        }
        
        // Split up the commandClusters every 5 seconds
        for(int i = 0; i < controlBoxesCount; i ++)
        {
            int commandClusterIndexToSplit = i;
            int newCommandClusterIndexToSplit = 0;
            for(float t = 5.0; t < [self endTimeForSequence:currentSequence]; t += 5.0)
            {
                NSLog(@"splitting commandClusterIndex:%d", commandClusterIndexToSplit);
                newCommandClusterIndexToSplit = [self splitCommandClusterForCurrentSequenceAtIndex:commandClusterIndexToSplit atTime:t];
                
                // Manually save each cluster now that we are done changing it
                [self saveDictionaryToItsFilePath:[self commandClusterForCurrentSequenceAtIndex:commandClusterIndexToSplit]];
                
                commandClusterIndexToSplit = newCommandClusterIndexToSplit;
            }
            
            // Manually save each cluster now that we are done changing it
            [self saveDictionaryToItsFilePath:[self commandClusterForCurrentSequenceAtIndex:commandClusterIndexToSplit]];
        }
        
        [self saveDictionaryToItsFilePath:currentSequence];
        
        // Manually save each cluster now that we are done changing it
        /*for(int i = 0; i < controlBoxesCount; i ++)
         {
         [self saveDictionaryToItsFilePath:[self commandClusterForCurrentSequenceAtIndex:i]];
         }*/
        
        shouldAutosave = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateLibraryContent" object:nil];
    }
    
}

// File Name Methods
- (NSString *)nextAvailableSequenceFileName
{
    return [self nextAvailableNumberForFilePaths:[self sequenceFilePaths]];
}

- (NSString *)nextAvailableControlBoxFileName
{
    return [self nextAvailableNumberForFilePaths:[self controlBoxFilePaths]];
}

- (NSString *)nextAvailableCommandClusterFileName
{
    return [self nextAvailableNumberForFilePaths:[self commandClusterFilePaths]];
}

- (NSString *)nextAvailableAudioClipFileName
{
    return [self nextAvailableNumberForFilePaths:[self audioClipFilePaths]];
}

- (NSString *)nextAvailableChannelGroupFileName
{
    return [self nextAvailableNumberForFilePaths:[self channelGroupFilePaths]];
}

- (NSString *)nextAvailableEffectFileName
{
    return [self nextAvailableNumberForFilePaths:[self effectFilePaths]];
}

#pragma mark - SerialPort

- (void)sendPacketToSerialPort:(uint8_t *)packet packetLength:(int)length
{
    if([self.serialPort isOpen])
	{
		//NSLog(@"Writing:%@:", text);
        /*for(int i = 0; i < length; i ++)
        {
            NSLog(@"sending c:%c d:%d h:%02x", packet[i], packet[i], packet[i]);
        }*/
        [serialPort sendData:[NSData dataWithBytes:packet length:length]];
	}
	else
    {
        //NSLog(@"Can't send:%@", [NSString stringWithCString:packet encoding:NSStringEncodingConversionAllowLossy]);
        /*for(int i = 0; i < length; i ++)
        {
            NSLog(@"can't send c:%c d:%d h:%02x", packet[i], packet[i], packet[i]);
        }*/
        //NSLog(@"Couldn't send. Not connected");
    }
}

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
        for(int i = 0; i < [text length]; i ++)
        {
            NSLog(@"c:%c d:%d h:%x", [text characterAtIndex:i], [text characterAtIndex:i], [text characterAtIndex:i]);
        }
    }
}

#pragma mark - ORSSerialPortDelegate

- (void)serialPortWasOpened:(ORSSerialPort *)serialPort
{
	//self.openCloseButton.title = @"Close";
    
    checkingBoxIndex = 1;
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkBoxesTimerFired:) userInfo:nil repeats:YES];
}

- (void)checkBoxesTimerFired:(NSTimer *)timer
{
    if(checkingBoxIndex > [self controlBoxFilePathsCount])
    {
        [timer invalidate];
        
        [self updateAllSockets];
        
        checkingBoxIndex = 0;
        
    }
    else
    {
        [self checkBoxIsOnline:checkingBoxIndex];
    }
    
    checkingBoxIndex ++;
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
		NSString *newText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if(newText != nil)
        {
            [receivedText appendString:newText];
        }
        
		NSLog(@"Serial Port Data Received: %@",newText);
        
        // Print out the received data byte by byte
        for(int i = 0; i < [newText length]; i ++)
        {
            char character = [newText characterAtIndex:i];
            int characterValue = (int)character;
            NSLog(@"c:%c v:%i", character, characterValue);
        }
        
        // The string is complete. Now do something with it.
        if([receivedText rangeOfString:@"\r\n"].location != NSNotFound)
        {
            if([receivedText rangeOfString:@"Boards Connected:"].location != NSNotFound)
            {
                // set someting showing channels connected
                
                receivedText = (NSMutableString *)[receivedText stringByReplacingOccurrencesOfString:@"LD:" withString:@""];
                int boxID = [receivedText intValue];
                NSLog(@"boxID:%d", boxID);
                receivedText = (NSMutableString *)[receivedText stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
                receivedText = (NSMutableString *)[receivedText stringByReplacingOccurrencesOfString:@",Boards Connected:" withString:@""];
                int channelsOnline = [receivedText intValue] * 8;
                NSLog(@"channels:%d", channelsOnline);
                channelsOnlinePerBox[boxID] = channelsOnline;
                
                // If we receive data without polling for iti (board gets rebooted), update the sockets
                if(checkingBoxIndex == 0)
                {
                    [self updateAllSockets];
                }
            }
            
            [receivedText setString:@""];
        }
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
    NSString *filePath = [NSString stringWithFormat:@"sequenceLibrary/%@.lmsq", [self nextAvailableSequenceFileName]];
    [self addSequenceFilePathToSequenceLibrary:filePath];
    [self setFilePath:filePath forDictionary:newSequence];
    
    [newSequence writeToFile:[NSString stringWithFormat:@"%@/%@", libraryFolder, filePath] atomically:YES];
    [self setVersionNumber:DATA_VERSION_NUMBER forSequence:newSequence];
    [self setDescription:@"New Sequence" forSequence:newSequence];
    [self setEndTime:1.0 forSequence:newSequence];
    
    // Add all of the control boxes to the sequence
    for(int i = 0; i < [self controlBoxFilePathsCount]; i ++)
    {
        [self addControlBoxFilePath:[self controlBoxFilePathAtIndex:i] forSequence:newSequence];
    }
    
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
    shouldAutosave = NO;
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
    int count = (int)[commandClusterFilePaths count];
    for(int i = count - 1; i >= 0; i --)
    {
        [self removeCommandClusterFromLibrary:[self commandClusterFromFilePath:[commandClusterFilePaths objectAtIndex:i]]];
        [self removeCommandClusterFilePath:[commandClusterFilePaths objectAtIndex:i] forSequence:sequence];
    }
    // Remove any audioClips from this sequence
    NSMutableArray *audioClipFilePaths = [self audioClipFilePathsForSequence:sequence];
    count = (int)[audioClipFilePaths count];
    for(int i = count - 1; i >= 0; i --)
    {
        [self removeAudioClipFromLibrary:[self audioClipFromFilePath:[audioClipFilePaths objectAtIndex:i]]];
        [self removeAudioClipFilePath:[audioClipFilePaths objectAtIndex:i] forSequence:sequence];
    }
    
    shouldAutosave = YES;
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
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:sequence];
}

- (void)setDescription:(NSString *)description forSequence:(NSMutableDictionary *)sequence
{
    [sequence setObject:description forKey:@"description"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:sequence];
}

- (void)setStartTime:(float)startTIme forSequence:(NSMutableDictionary *)sequence
{
    [sequence setObject:[NSNumber numberWithFloat:startTIme] forKey:@"startTime"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:sequence];
}

- (void)setEndTime:(float)endTime forSequence:(NSMutableDictionary *)sequence
{
    [sequence setObject:[NSNumber numberWithFloat:endTime] forKey:@"endTime"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:sequence];
}

- (void)addAudioClipFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self audioClipFilePathsForSequence:sequence];
    [filePaths addObject:filePath];
    [sequence setObject:filePaths forKey:@"audioClipFilePaths"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:sequence];
    
    [self addBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
    
    // Set the sequence end time to the audio clip end time.
    NSMutableDictionary *audioClip = [self audioClipFromFilePath:filePath];
    [self setEndTime:[self endTimeForAudioClip:audioClip] forSequence:sequence];
    // Set the sequence description to the audio clip description
    [self setDescription:[self descriptionForAudioClip:audioClip] forSequence:sequence];
    
    // Load the NSSound
    if([[self filePathForSequence:sequence] isEqualToString:[self filePathForSequence:currentSequence]])
    {
        [self loadAudioClipsForCurrentSequence];
        
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
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:sequence];
    
    [self removeBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
    
    // Unload the NSSound
    if([[self filePathForSequence:sequence] isEqualToString:[self filePathForSequence:currentSequence]])
    {
        [self loadAudioClipsForCurrentSequence];
        
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
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:sequence];
    
    [self addBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
    
    if([[self filePathForSequence:sequence] isEqualToString:[self filePathForSequence:currentSequence]])
    {
        [self loadControlBoxesForCurrentSequence];
    }
}

- (void)removeControlBoxFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self controlBoxFilePathsForSequence:sequence];
    [filePaths removeObject:filePath];
    [sequence setObject:filePaths forKey:@"controlBoxFilePaths"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:sequence];
    
    [self removeBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
    
    if([[self filePathForSequence:sequence] isEqualToString:[self filePathForSequence:currentSequence]])
    {
        [self loadControlBoxesForCurrentSequence];
    }
}

- (void)addChannelGroupFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self channelGroupFilePathsForSequence:sequence];
    [filePaths addObject:filePath];
    [sequence setObject:filePaths forKey:@"channelGroupFilePaths"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:sequence];
    
    [self addBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
    
    if([[self filePathForSequence:sequence] isEqualToString:[self filePathForSequence:currentSequence]])
    {
        [self loadChannelGroupsForCurrentSequence];
    }
}

- (void)removeChannelGroupFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self channelGroupFilePathsForSequence:sequence];
    [filePaths removeObject:filePath];
    [sequence setObject:filePaths forKey:@"channelGroupFilePaths"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:sequence];
    
    [self removeBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
    
    if([[self filePathForSequence:sequence] isEqualToString:[self filePathForSequence:currentSequence]])
    {
        [self loadChannelGroupsForCurrentSequence];
    }
}

- (void)addCommandClusterFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self commandClusterFilePathsForSequence:sequence];
    [filePaths addObject:filePath];
    [sequence setObject:filePaths forKey:@"commandClusterFilePaths"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:sequence];
    
    [self addBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
    
    if([[self filePathForSequence:sequence] isEqualToString:[self filePathForSequence:currentSequence]])
    {
        if(shouldAutosave)
            [self loadCommandClustersForCurrentSequence];
    }
}

- (void)removeCommandClusterFilePath:(NSString *)filePath forSequence:(NSMutableDictionary *)sequence
{
    NSMutableArray *filePaths = [self commandClusterFilePathsForSequence:sequence];
    [filePaths removeObject:filePath];
    [sequence setObject:filePaths forKey:@"commandClusterFilePaths"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:sequence];
    
    [self removeBeingUsedInSequenceFilePath:[self filePathForSequence:sequence] forDictionary:[self dictionaryFromFilePath:filePath]];
    
    if([[self filePathForSequence:sequence] isEqualToString:[self filePathForSequence:currentSequence]])
    {
        if(shouldAutosave)
            [self loadCommandClustersForCurrentSequence];
    }
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
    NSString *filePath = [NSString stringWithFormat:@"controlBoxLibrary/%@.lmcb", [self nextAvailableControlBoxFileName]];
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
    [self removeControlBoxFromCurrentSequenceControlBoxes:controlBox];
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
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:controlBox];
    [self updateCurrentSequenceControlBoxesWithControlBox:controlBox];
}

- (void)setControlBoxID:(NSString *)ID forControlBox:(NSMutableDictionary *)controlBox
{
    [controlBox setObject:ID forKey:@"controlBoxID"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:controlBox];
    [self updateCurrentSequenceControlBoxesWithControlBox:controlBox];
}

- (void)setDescription:(NSString *)description forControlBox:(NSMutableDictionary *)controlBox
{
    [controlBox setObject:description forKey:@"description"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:controlBox];
    [self updateCurrentSequenceControlBoxesWithControlBox:controlBox];
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
    
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:controlBox];
    [self updateCurrentSequenceControlBoxesWithControlBox:controlBox];
    
    return index;
}

- (void)removeChannel:(NSMutableDictionary *)channel forControlBox:(NSMutableDictionary *)controlBox
{
    NSMutableArray *channels = [self channelsForControlBox:controlBox];
    [channels removeObject:channel];
    [controlBox setObject:channels forKey:@"channels"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:controlBox];
    [self updateCurrentSequenceControlBoxesWithControlBox:controlBox];
}

- (void)setNumber:(int)number forChannelAtIndex:(int)index whichIsPartOfControlBox:(NSMutableDictionary *)controlBox
{
    NSMutableArray *channels = [self channelsForControlBox:controlBox];
    NSMutableDictionary *channel = [channels objectAtIndex:index];
    [channel setObject:[NSNumber numberWithInt:number] forKey:@"number"];
    [channels replaceObjectAtIndex:index withObject:channel];
    [controlBox setObject:channels forKey:@"channels"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:controlBox];
    [self updateCurrentSequenceControlBoxesWithControlBox:controlBox];
}

- (void)setColor:(NSString *)color forChannelAtIndex:(int)index whichIsPartOfControlBox:(NSMutableDictionary *)controlBox
{
    NSMutableArray *channels = [self channelsForControlBox:controlBox];
    NSMutableDictionary *channel = [channels objectAtIndex:index];
    [channel setObject:color forKey:@"color"];
    [channels replaceObjectAtIndex:index withObject:channel];
    [controlBox setObject:channels forKey:@"channels"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:controlBox];
    [self updateCurrentSequenceControlBoxesWithControlBox:controlBox];
}

- (void)setDescription:(NSString *)description forChannelAtIndex:(int)index whichIsPartOfControlBox:(NSMutableDictionary *)controlBox
{
    NSMutableArray *channels = [self channelsForControlBox:controlBox];
    NSMutableDictionary *channel = [channels objectAtIndex:index];
    [channel setObject:description forKey:@"description"];
    [channels replaceObjectAtIndex:index withObject:channel];
    [controlBox setObject:channels forKey:@"channels"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:controlBox];
    [self updateCurrentSequenceControlBoxesWithControlBox:controlBox];
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
    NSString *filePath = [NSString stringWithFormat:@"channelGroupLibrary/%@.lmgp", [self nextAvailableChannelGroupFileName]];
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
    [self removeChannelGroupFromCurrentSequenceChannelGroups:channelGroup];
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
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:channelGroup];
    [self updateCurrentSequenceChannelGroupsWithChannelGroup:channelGroup];
}

- (void)setDescription:(NSString *)description forChannelGroup:(NSMutableDictionary *)channelGroup
{
    [channelGroup setObject:description forKey:@"description"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:channelGroup];
    [self updateCurrentSequenceChannelGroupsWithChannelGroup:channelGroup];
}

- (int)createItemDataAndReturnNewItemIndexForChannelGroup:(NSMutableDictionary *)channelGroup
{
    NSMutableDictionary *newItemData = [[NSMutableDictionary alloc] init];
    [self setVersionNumber:DATA_VERSION_NUMBER forDictionary:newItemData];
    
    NSMutableArray *items = [self itemsForChannelGroup:channelGroup];
    [items addObject:newItemData];
    [channelGroup setObject:items forKey:@"commands"];
    int index = (int)[items count] - 1;
    
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:channelGroup];
    [self setChannelIndex:0 forItemDataAtIndex:index whichIsPartOfChannelGroup:channelGroup];
    [self updateCurrentSequenceChannelGroupsWithChannelGroup:channelGroup];
    
    return index;
}

- (void)removeItemData:(NSMutableDictionary *)itemData forChannelGroup:(NSMutableDictionary *)channelGroup
{
    NSMutableArray *items = [self itemsForChannelGroup:channelGroup];
    [items removeObject:itemData];
    [channelGroup setObject:items forKey:@"items"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:channelGroup];
    [self updateCurrentSequenceChannelGroupsWithChannelGroup:channelGroup];
}

- (void)setControlBoxFilePath:(NSString *)filePath forItemDataAtIndex:(int)index whichIsPartOfChannelGroup:(NSMutableDictionary *)channelGroup
{
    NSMutableArray *items = [self itemsForChannelGroup:channelGroup];
    NSMutableDictionary *itemData = [items objectAtIndex:index];
    [itemData setObject:filePath forKey:@"controlBoxFilePath"];
    [items replaceObjectAtIndex:index withObject:itemData];
    [channelGroup setObject:items forKey:@"items"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:channelGroup];
    [self updateCurrentSequenceChannelGroupsWithChannelGroup:channelGroup];
}

- (void)setChannelIndex:(int)channelIndex forItemDataAtIndex:(int)index whichIsPartOfChannelGroup:(NSMutableDictionary *)channelGroup
{
    NSMutableArray *items = [self itemsForChannelGroup:channelGroup];
    NSMutableDictionary *itemData = [items objectAtIndex:index];
    [itemData setObject:[NSNumber numberWithInt:channelIndex] forKey:@"channelIndex"];
    [items replaceObjectAtIndex:index withObject:itemData];
    [channelGroup setObject:items forKey:@"items"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:channelGroup];
    [self updateCurrentSequenceChannelGroupsWithChannelGroup:channelGroup];
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
    NSString *filePath = [NSString stringWithFormat:@"commandClusterLibrary/%@.lmcc", [self nextAvailableCommandClusterFileName]];
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
    
    if(shouldAutosave)
            [self loadCommandClustersForCurrentSequence];
    //[self removeCommandClusterFromCurrentSequenceCommandClusters:commandCluster];
}

- (void)splitMostRecentlySelectedCommandClusterAtCurrentTime:(NSNotification *)aNotifcation
{
    NSMutableDictionary *mostRecentlySelectedCommandCluster = [self commandClusterForCurrentSequenceAtIndex:mostRecentlySelectedCommandClusterIndex];
    
    if(mostRecentlySelectedCommandClusterIndex)
    {
        // Make a new cluster and set it's controlBox/channelGroup to the mostRecentlySelectedCommandCluster's controlBox/channelGroup
        NSString *newCommandClusterFilePath = [self createCommandClusterAndReturnFilePath];
        NSMutableDictionary *newCommandCluster = [self commandClusterFromFilePath:newCommandClusterFilePath];
        if([[self controlBoxFilePathForCommandCluster:mostRecentlySelectedCommandCluster] length] > 0)
        {
            [self setControlBoxFilePath:[self controlBoxFilePathForCommandCluster:mostRecentlySelectedCommandCluster] forCommandCluster:newCommandCluster];
        }
        else if([[self channelGroupFilePathForCommandCluster:mostRecentlySelectedCommandCluster] length] > 0)
        {
            [self setChannelGroupFilePath:[self channelGroupFilePathForCommandCluster:mostRecentlySelectedCommandCluster] forCommandCluster:newCommandCluster];
        }
        [self setDescription:[self descriptionForCommandCluster:mostRecentlySelectedCommandCluster] forCommandCluster:newCommandCluster];
        [self setEndTime:[self endTimeForCommandCluster:mostRecentlySelectedCommandCluster] forCommandcluster:newCommandCluster];
        [self setStartTime:currentTime forCommandCluster:newCommandCluster];
        [self setEndTime:currentTime forCommandcluster:mostRecentlySelectedCommandCluster];
        
        NSMutableArray *commandsToRemoveFromMostRecentlySelectedCommandCluster = [[NSMutableArray alloc] init];
        for(int i = 0; i < [self commandsCountForCommandCluster:mostRecentlySelectedCommandCluster]; i ++)
        {
            NSMutableDictionary *command = [self commandAtIndex:i fromCommandCluster:mostRecentlySelectedCommandCluster];
            
            // Move commands past the currentTime to the new cluster
            if([self startTimeForCommand:command] >= currentTime)
            {
                NSMutableArray *commands = [self commandsFromCommandCluster:newCommandCluster];
                [commands addObject:command];
                [newCommandCluster setObject:commands forKey:@"commands"];
                
                // Keep track of this command so it can be removed after we are done processing this cluster
                [commandsToRemoveFromMostRecentlySelectedCommandCluster addObject:command];
            }
            // Commands that are in the middle of the currentTime get split in half.
            else if([self startTimeForCommand:command] < currentTime && [self endTimeForCommand:command] >= currentTime)
            {
                // Set the end time for the first command
                float oldEndTime = [self endTimeForCommand:command];
                [self setEndTime:currentTime forCommandAtIndex:i whichIsPartOfCommandCluster:mostRecentlySelectedCommandCluster];
                
                // Now make a new command for the new cluster and set it's end time to the old ent time
                int newCommandIndex = [self createCommandAndReturnNewCommandIndexForCommandCluster:newCommandCluster];
                [self setStartTime:currentTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
                [self setEndTime:oldEndTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
                [self setChannelIndex:[self channelIndexForCommand:command] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
                [self setBrightness:[self brightnessForCommand:command] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
                [self setFadeInDuration:[self fadeInDurationForCommand:command] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
                [self setFadeOutDuration:[self fadeOutDurationForCommand:command] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
            }
        }
        
        // Remove any commands from the mostRecentlySelectedCommandCluster
        for(int i = 0; i < [commandsToRemoveFromMostRecentlySelectedCommandCluster count]; i ++)
        {
            [self removeCommand:[commandsToRemoveFromMostRecentlySelectedCommandCluster objectAtIndex:i] fromCommandCluster:mostRecentlySelectedCommandCluster];
        }
        
        if(shouldAutosave)
        [self saveDictionaryToItsFilePath:mostRecentlySelectedCommandCluster];
        //[self updateCurrentSequenceCommandClustersWithCommandCluster:mostRecentlySelectedCommandCluster];
        
        [self addCommandClusterFilePath:newCommandClusterFilePath forSequence:currentSequence];
        if(shouldAutosave)
        [self saveDictionaryToItsFilePath:newCommandCluster];
        //[self updateCurrentSequenceCommandClustersWithCommandCluster:newCommandCluster];
        if(shouldAutosave)
            [self loadCommandClustersForCurrentSequence];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"UpdateGraphics" object:nil];
    }
}

// Returns the index of the newCommandCluster
- (int)splitCommandClusterForCurrentSequenceAtIndex:(int)commandClusterIndex atTime:(float)time
{
    NSMutableDictionary *mostRecentlySelectedCommandCluster = [self commandClusterForCurrentSequenceAtIndex:commandClusterIndex];
    
    // Make a new cluster and set it's controlBox/channelGroup to the mostRecentlySelectedCommandCluster's controlBox/channelGroup
    NSString *newCommandClusterFilePath = [self createCommandClusterAndReturnFilePath];
    NSMutableDictionary *newCommandCluster = [self commandClusterFromFilePath:newCommandClusterFilePath];
    if([[self controlBoxFilePathForCommandCluster:mostRecentlySelectedCommandCluster] length] > 0)
    {
        [self setControlBoxFilePath:[self controlBoxFilePathForCommandCluster:mostRecentlySelectedCommandCluster] forCommandCluster:newCommandCluster];
    }
    else if([[self channelGroupFilePathForCommandCluster:mostRecentlySelectedCommandCluster] length] > 0)
    {
        [self setChannelGroupFilePath:[self channelGroupFilePathForCommandCluster:mostRecentlySelectedCommandCluster] forCommandCluster:newCommandCluster];
    }
    [self setDescription:[self descriptionForCommandCluster:mostRecentlySelectedCommandCluster] forCommandCluster:newCommandCluster];
    [self setEndTime:[self endTimeForCommandCluster:mostRecentlySelectedCommandCluster] forCommandcluster:newCommandCluster];
    [self setStartTime:time forCommandCluster:newCommandCluster];
    [self setEndTime:time forCommandcluster:mostRecentlySelectedCommandCluster];
    
    NSMutableArray *commandsToRemoveFromMostRecentlySelectedCommandCluster = [[NSMutableArray alloc] init];
    for(int i = 0; i < [self commandsCountForCommandCluster:mostRecentlySelectedCommandCluster]; i ++)
    {
        NSMutableDictionary *command = [self commandAtIndex:i fromCommandCluster:mostRecentlySelectedCommandCluster];
        
        // Move commands past the time to the new cluster
        if([self startTimeForCommand:command] >= time)
        {
            NSMutableArray *commands = [self commandsFromCommandCluster:newCommandCluster];
            [commands addObject:command];
            [newCommandCluster setObject:commands forKey:@"commands"];
            
            // Keep track of this command so it can be removed after we are done processing this cluster
            [commandsToRemoveFromMostRecentlySelectedCommandCluster addObject:[NSNumber numberWithInt:i]];
        }
        // Commands that are in the middle of the time get split in half.
        else if([self startTimeForCommand:command] < time && [self endTimeForCommand:command] >= time)
        {
            // Set the end time for the first command
            float oldEndTime = [self endTimeForCommand:command];
            [self setEndTime:time forCommandAtIndex:i whichIsPartOfCommandCluster:mostRecentlySelectedCommandCluster];
            
            // Now make a new command for the new cluster and set it's end time to the old ent time
            int newCommandIndex = [self createCommandAndReturnNewCommandIndexForCommandCluster:newCommandCluster];
            [self setStartTime:time forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
            [self setEndTime:oldEndTime forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
            [self setChannelIndex:[self channelIndexForCommand:command] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
            [self setBrightness:[self brightnessForCommand:command] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
            [self setFadeInDuration:[self fadeInDurationForCommand:command] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
            [self setFadeOutDuration:[self fadeOutDurationForCommand:command] forCommandAtIndex:newCommandIndex whichIsPartOfCommandCluster:newCommandCluster];
        }
    }
    
    // Remove any commands from the mostRecentlySelectedCommandCluster
    for(int i = (int)[commandsToRemoveFromMostRecentlySelectedCommandCluster count] - 1; i >= 0; i --)
    {
        //[self removeCommand:[commandsToRemoveFromMostRecentlySelectedCommandCluster objectAtIndex:i] fromCommandCluster:mostRecentlySelectedCommandCluster];
        
        NSMutableArray *commands = [self commandsFromCommandCluster:mostRecentlySelectedCommandCluster];
        [commands removeObjectAtIndex:[[commandsToRemoveFromMostRecentlySelectedCommandCluster objectAtIndex:i] intValue]];
        //[commands removeObject:command];
        [mostRecentlySelectedCommandCluster setObject:commands forKey:@"commands"];
        if(shouldAutosave)
            [self saveDictionaryToItsFilePath:mostRecentlySelectedCommandCluster];
        //[self updateCurrentSequenceCommandClustersWithCommandCluster:mostRecentlySelectedCommandCluster];
    }
    
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:mostRecentlySelectedCommandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:mostRecentlySelectedCommandCluster];
    //NSLog(@"new original cluster:%@", mostRecentlySelectedCommandCluster);
    
    [self addCommandClusterFilePath:newCommandClusterFilePath forSequence:currentSequence];
    [currentSequenceCommandClusters addObject:newCommandCluster];
    
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:newCommandCluster];
    //[self updateCurrentSequenceCommandClustersWithCommandCluster:newCommandCluster];
    //[self loadCommandClustersForCurrentSequence];
    
    return [self commandClusterFilePathsCountForSequence:currentSequence] - 1;
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
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (void)setDescription:(NSString *)description forCommandCluster:(NSMutableDictionary *)commandCluster
{
    [commandCluster setObject:description forKey:@"description"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (void)setControlBoxFilePath:(NSString *)filePath forCommandCluster:(NSMutableDictionary *)commandCluster
{
    [commandCluster setObject:filePath forKey:@"controlBoxFilePath"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (void)setChannelGroupFilePath:(NSString *)filePath forCommandCluster:(NSMutableDictionary *)commandCluster
{
    [commandCluster setObject:filePath forKey:@"channelGroupFilePath"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (void)setStartTime:(float)time forCommandCluster:(NSMutableDictionary *)commandCluster
{
    [commandCluster setObject:[NSNumber numberWithFloat:time] forKey:@"startTime"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (void)setEndTime:(float)time forCommandcluster:(NSMutableDictionary *)commandCluster
{
    
    [commandCluster setObject:[NSNumber numberWithFloat:time] forKey:@"endTime"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (void)moveCommandCluster:(NSMutableDictionary *)commandCluster byTime:(float)time
{
    // Adjust all of the times for the commands
    for(int i = 0; i < [self commandsCountForCommandCluster:commandCluster]; i ++)
    {
        //[self setStartTime:([self startTimeForCommand:[self commandAtIndex:i fromCommandCluster:commandCluster]] + time) forCommandAtIndex:i whichIsPartOfCommandCluster:commandCluster];
        //[self setEndTime:([self endTimeForCommand:[self commandAtIndex:i fromCommandCluster:commandCluster]] + time) forCommandAtIndex:i whichIsPartOfCommandCluster:commandCluster];
        
        // Set the time ourselves since the regular method saves everything and this move gets called a ton when the user is dragging a cluster
        // Start Time
        NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
        NSMutableDictionary *command = [commands objectAtIndex:i];
        [command setObject:[NSNumber numberWithFloat:[self startTimeForCommand:[self commandAtIndex:i fromCommandCluster:commandCluster]] + time] forKey:@"startTime"];
        [commands replaceObjectAtIndex:i withObject:command];
        [commandCluster setObject:commands forKey:@"commands"];
        // Start Time
        commands = [self commandsFromCommandCluster:commandCluster];
        command = [commands objectAtIndex:i];
        [command setObject:[NSNumber numberWithFloat:[self endTimeForCommand:[self commandAtIndex:i fromCommandCluster:commandCluster]] + time] forKey:@"endTime"];
        [commands replaceObjectAtIndex:i withObject:command];
        [commandCluster setObject:commands forKey:@"commands"];
    }
    
    [self setStartTime:[self startTimeForCommandCluster:commandCluster] + time forCommandCluster:commandCluster];
    [self setEndTime:[self endTimeForCommandCluster:commandCluster] + time forCommandcluster:commandCluster];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (void)moveCommandCluster:(NSMutableDictionary *)commandCluster toStartTime:(float)startTime
{
    float startTimeOffset = startTime - [self startTimeForCommandCluster:commandCluster];
    
    [self moveCommandCluster:commandCluster byTime:startTimeOffset];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (void)setAudioClipFilePath:(NSString *)filePath forCommandCluster:(NSMutableDictionary *)commandCluster
{
    [commandCluster setObject:filePath forKey:@"audioClipFilePath"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (int)createCommandAndReturnNewCommandIndexForCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableDictionary *newCommand = [[NSMutableDictionary alloc] init];
    [self setVersionNumber:DATA_VERSION_NUMBER forDictionary:newCommand];
    
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    [commands addObject:newCommand];
    [commandCluster setObject:commands forKey:@"commands"];
    int index = (int)[commands count] - 1;
    
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self setChannelIndex:0 forCommandAtIndex:index whichIsPartOfCommandCluster:commandCluster];
    [self setEndTime:1.0 forCommandAtIndex:index whichIsPartOfCommandCluster:commandCluster];
    [self setBrightness:100 forCommandAtIndex:index whichIsPartOfCommandCluster:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
    
    return index;
}

- (void)removeCommand:(NSMutableDictionary *)command fromCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    [commands removeObject:command];
    [commandCluster setObject:commands forKey:@"commands"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (void)setStartTime:(float)time forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    NSMutableDictionary *command = [commands objectAtIndex:index];
    [command setObject:[NSNumber numberWithFloat:time] forKey:@"startTime"];
    [commands replaceObjectAtIndex:index withObject:command];
    [commandCluster setObject:commands forKey:@"commands"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (void)setEndTime:(float)time forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    NSMutableDictionary *command = [commands objectAtIndex:index];
    [command setObject:[NSNumber numberWithFloat:time] forKey:@"endTime"];
    [commands replaceObjectAtIndex:index withObject:command];
    [commandCluster setObject:commands forKey:@"commands"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
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
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (void)setBrightness:(int)brightness forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    NSMutableDictionary *command = [commands objectAtIndex:index];
    [command setObject:[NSNumber numberWithInt:brightness] forKey:@"brightness"];
    [commands replaceObjectAtIndex:index withObject:command];
    [commandCluster setObject:commands forKey:@"commands"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (void)setFadeInDuration:(int)fadeInDuration forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    NSMutableDictionary *command = [commands objectAtIndex:index];
    [command setObject:[NSNumber numberWithFloat:fadeInDuration] forKey:@"fadeInDuration"];
    [commands replaceObjectAtIndex:index withObject:command];
    [commandCluster setObject:commands forKey:@"commands"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

- (void)setFadeOutDuration:(int)fadeOutDuration forCommandAtIndex:(int)index whichIsPartOfCommandCluster:(NSMutableDictionary *)commandCluster
{
    NSMutableArray *commands = [self commandsFromCommandCluster:commandCluster];
    NSMutableDictionary *command = [commands objectAtIndex:index];
    [command setObject:[NSNumber numberWithFloat:fadeOutDuration] forKey:@"fadeOutDuration"];
    [commands replaceObjectAtIndex:index withObject:command];
    [commandCluster setObject:commands forKey:@"commands"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:commandCluster];
    [self updateCurrentSequenceCommandClustersWithCommandCluster:commandCluster];
}

#pragma mark - EffectLibrary Methods
// Management Methods

- (NSString *)createEffectAndReturnFilePath
{
    NSMutableDictionary *newEffect = [[NSMutableDictionary alloc] init];
    
    // New files get a file name chosen by availble numbers (detemined by @selector(nextAvailableNumberForFilePaths))
    NSString *filePath = [NSString stringWithFormat:@"effectLibrary/%@.lmef", [self nextAvailableEffectFileName]];
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
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:effect];
}

- (void)setDescription:(NSString *)description forEffect:(NSMutableDictionary *)effect
{
    [effect setObject:description forKey:@"description"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:effect];
}

- (void)setParameters:(NSString *)parameters forEffect:(NSMutableDictionary *)effect
{
    [effect setObject:parameters forKey:@"parameters"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:effect];
}

- (void)setScript:(NSString *)script forEffect:(NSMutableDictionary *)effect
{
    [effect setObject:script forKey:@"script"];
    if(shouldAutosave)
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
    NSString *filePath = [NSString stringWithFormat:@"audioClipLibrary/%@.lmsd", [self nextAvailableAudioClipFileName]];
    [self addAudioClipFilePathToAudioClipLibrary:filePath];
    [self setFilePath:filePath forDictionary:newAudioClip];
    
    [newAudioClip writeToFile:[NSString stringWithFormat:@"%@/%@", libraryFolder, filePath] atomically:YES];
    [self setVersionNumber:DATA_VERSION_NUMBER forAudioClip:newAudioClip];
    [self setUploadProgress:0 ForAudioClip:newAudioClip];
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
    [self setEndFadeTime:[self endFadeTimeForAudioClip:audioClip] forAudioClip:newAudioClip];
    // Copy the audioAnalysis
    [[NSFileManager defaultManager] copyItemAtPath:[NSString stringWithFormat:@"%@/%@.lmaa", libraryFolder, [[self filePathForAudioClip:audioClip] stringByDeletingPathExtension]] toPath:[NSString stringWithFormat:@"%@/%@.lmaa", libraryFolder, [newAudioClipFilePath stringByDeletingPathExtension]] error:NULL];
    
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
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", [self libraryFolder], [self filePathForAudioClip:audioClip]];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:NULL];
    NSString *audioFileFilePath = [NSString stringWithFormat:@"%@/%@", [self libraryFolder], [self filePathToAudioFileForAudioClip:audioClip]];
    [[NSFileManager defaultManager] removeItemAtPath:audioFileFilePath error:NULL];
    NSString *audioAnalysisFilePath = [NSString stringWithFormat:@"%@/%@.lmaa", [self libraryFolder], [[self filePathForAudioClip:audioClip] stringByDeletingPathExtension]];
    [[NSFileManager defaultManager] removeItemAtPath:audioAnalysisFilePath error:NULL];
    [audioClipLibrary setObject:filePaths forKey:@"audioClipFilePaths"];
    [self saveAudioClipLibrary];
    [self removeAudioClipFromCurrentSequenceAudioClips:audioClip];
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

- (float)endFadeTimeForAudioClip:(NSMutableDictionary *)audioClip
{
    return [[audioClip objectForKey:@"endFadeTime"] floatValue];
}

- (float)seekTimeForAudioClip:(NSMutableDictionary *)audioClip
{
    return [[audioClip objectForKey:@"seekTime"] floatValue];
}

- (float)uploadProgressForAudioClip:(NSMutableDictionary *)audioClip
{
    return [[audioClip objectForKey:@"uploadProgress"] floatValue];
}

- (NSDictionary *)audioSummaryForAudioClip:(NSMutableDictionary *)audioClip
{
    return [audioClip objectForKey:@"audioSummary"];
}

- (NSDictionary *)audioAnalysisForAudioClip:(NSMutableDictionary *)audioClip
{
    return [self dictionaryFromFilePath:[NSString stringWithFormat:@"%@.lmaa", [[self filePathForAudioClip:audioClip] stringByDeletingPathExtension]]];
}

// Setter Methods
- (void)setVersionNumber:(float)newVersionNumber forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:[NSNumber numberWithFloat:newVersionNumber] forKey:@"versionNumber"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:audioClip];
    [self updateCurrentSequenceAudioClipsWithAudioClip:audioClip];
}

- (void)setDescription:(NSString *)description forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:description forKey:@"description"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:audioClip];
    [self updateCurrentSequenceAudioClipsWithAudioClip:audioClip];
}

- (void)setFilePathToAudioFile:(NSString *)filePath forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:filePath forKey:@"filePathToAudioFile"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:audioClip];
    [self updateCurrentSequenceAudioClipsWithAudioClip:audioClip];
    
    [self updateAudioAnalysisForAudioClip:audioClip];
}

- (void)setStartTime:(float)time forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:[NSNumber numberWithFloat:time] forKey:@"startTime"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:audioClip];
    [self updateCurrentSequenceAudioClipsWithAudioClip:audioClip];
}

- (void)setEndTime:(float)time forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:[NSNumber numberWithFloat:time] forKey:@"endTime"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:audioClip];
    [self updateCurrentSequenceAudioClipsWithAudioClip:audioClip];
}

- (void)setEndFadeTime:(float)time forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:[NSNumber numberWithFloat:time] forKey:@"endFadeTime"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:audioClip];
    [self updateCurrentSequenceAudioClipsWithAudioClip:audioClip];
}

- (void)moveAudioClip:(NSMutableDictionary *)audioClip byTime:(float)time
{
    [audioClip setObject:[NSNumber numberWithFloat:[self startTimeForAudioClip:audioClip] + time] forKey:@"startTime"];
    [audioClip setObject:[NSNumber numberWithFloat:[self endTimeForAudioClip:audioClip] + time] forKey:@"endTime"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:audioClip];
    [self updateCurrentSequenceAudioClipsWithAudioClip:audioClip];
}

- (void)moveAudioClip:(NSMutableDictionary *)audioClip toStartTime:(float)startTime
{
    float startTimeOffset = startTime - [self startTimeForAudioClip:audioClip];
    
    [self moveAudioClip:audioClip byTime:startTimeOffset];
    [self updateCurrentSequenceAudioClipsWithAudioClip:audioClip];
}

- (void)setSeekTime:(float)time forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:[NSNumber numberWithFloat:time] forKey:@"seekTime"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:audioClip];
    [self updateCurrentSequenceAudioClipsWithAudioClip:audioClip];
}

- (void)updateAudioAnalysisForAudioClip:(NSMutableDictionary *)audioClip
{
    NSString *filePath = [self filePathToAudioFileForAudioClip:audioClip];
    
    // Search EchoNest for analysis
    if([filePath length] > 1)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioClipUploadProgressUpdate" object:audioClip];
        if([self uploadProgressForAudioClip:audioClip] < 0.99)
        {
            ENAPIRequest *enRequest = [ENAPIRequest requestWithEndpoint:@"track/profile"];
            NSData *fileData = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", [self libraryFolder], filePath]];
            NSString *md5 = [fileData enapi_MD5];
            [enRequest setValue:md5 forParameter:@"md5"];
            [enRequest setValue:@"audio_summary" forParameter:@"bucket"];
            [enRequest setUserInfo:@{@"filePath" : filePath, @"audioClip" : audioClip}];
            [enRequest setDelegate:self];
            [enRequests addObject:enRequest];
            [enRequest startAsynchronous];
        }
    }
}

- (void)setUploadProgress:(float)uploadProgress ForAudioClip:(NSMutableDictionary *)audioClip;
{
    [audioClip setObject:[NSNumber numberWithFloat:uploadProgress] forKey:@"uploadProgress"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:audioClip];
    [self updateCurrentSequenceAudioClipsWithAudioClip:audioClip];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"AudioClipUploadProgressUpdate" object:audioClip];
}

- (void)setAudioSummary:(NSDictionary *)audioSummary forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioClip setObject:audioSummary forKey:@"audioSummary"];
    if(shouldAutosave)
        [self saveDictionaryToItsFilePath:audioClip];
    [self updateCurrentSequenceAudioClipsWithAudioClip:audioClip];
}

- (void)setAudioAnalysis:(NSDictionary *)audioAnalysis forAudioClip:(NSMutableDictionary *)audioClip
{
    [audioAnalysis writeToFile:[NSString stringWithFormat:@"%@/%@.lmaa", libraryFolder, [[self filePathForAudioClip:audioClip] stringByDeletingPathExtension]] atomically:YES];
    
    // Reload this audioAnalysis into RAM
    NSUInteger filePathsIndex = [[self audioClipFilePathsForSequence:currentSequence] indexOfObject:[self filePathForAudioClip:audioClip]];
    if(filePathsIndex != NSNotFound)
    {
        [currentSequenceAudioAnalyses replaceObjectAtIndex:filePathsIndex withObject:audioAnalysis];
    }
}

#pragma mark - ENAPIPostRequestDelegate Methods

- (void)postRequestFinished:(ENAPIPostRequest *)request
{
    NSDictionary *response = [request response];
    NSLog(@"post finished. response:%@", response);
    
    [enRequests removeObject:request];
    
    // Track is already uploaded, just waiting for the analysis to complete
    if([[[[response objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"status"] isEqualToString:@"pending"])
    {
        NSLog(@"waiting for analyze post");
        [self performSelector:@selector(pollENPostForTrackStatus:) withObject:request afterDelay:3.0];
        //[self performSelectorInBackground:@selector(pollENPostForTrackStatus:) withObject:request];
    }
    // Bad news
    else if([[[[response objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"status"] isEqualToString:@"error"])
    {
        NSLog(@"EN error post");
    }
}

- (void)postRequestFailed:(ENAPIPostRequest *)request
{
    NSDictionary *response = [request response];
    
    NSLog(@"EN postRequestFailed");
    NSLog(@"response:%@", response);
    NSLog(@"responseStatusCode:%lu", request.responseStatusCode);
    NSLog(@"echonestStatusCode:%lu", request.echonestStatusCode);
    NSLog(@"echonestStatusMessage:%@", request.echonestStatusMessage);
    NSLog(@"error:%@", request.error);
}

- (void)postRequest:(ENAPIPostRequest *)request didSendBytes:(long long)nBytes
{
    NSLog(@"bytes:%llu", nBytes);
}

- (void)postRequest:(ENAPIPostRequest *)request uploadProgress:(float)progress
{
    NSLog(@"upload:%f", progress);
    [self setUploadProgress:progress ForAudioClip:[[request userInfo] objectForKey:@"audioClip"]];
}

#pragma mark - ENAPIRequestDelegate Methods

- (void)requestFinished:(ENAPIRequest *)request
{
    NSDictionary *response = [request response];
    NSLog(@"finished. Response:%@", response);
    
    [enRequests removeObject:request];
    
    // This is for fetching/uploading the track profile
    if([[request userInfo] objectForKey:@"filePath"])
    {
        // This audioClip needs to be uploaded
        if([[[[response objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"status"] isEqualToString:@"unknown"] || [[[[response objectForKey:@"response"] objectForKey:@"status"] objectForKey:@"message"] rangeOfString:@"does not exist"].location != NSNotFound)
        {
            NSLog(@"uploading");
            ENAPIPostRequest *enPostRequest = [ENAPIPostRequest trackUploadRequestWithFile:[NSString stringWithFormat:@"%@/%@", [self libraryFolder], [[request userInfo] objectForKey:@"filePath"]]];
            [enPostRequest setDelegate:self];
            [enPostRequest setUserInfo:[request userInfo]];
            [enRequests addObject:enPostRequest];
            [enPostRequest startAsynchronous];
        }
        // Track is already uploaded, just waiting for the analysis to complete
        else if([[[[response objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"status"] isEqualToString:@"pending"])
        {
            NSLog(@"waiting for analyze");
            [self performSelector:@selector(pollENForTrackStatus:) withObject:request afterDelay:3.0];
            //[self performSelectorInBackground:@selector(pollENForTrackStatus:) withObject:request];
        }
        // The audioSummary was fetched from EN
        else if([[[[response objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"status"] isEqualToString:@"complete"])
        {
            NSLog(@"complete");
            // Only set the summary if we don't already have one
            if(![self audioSummaryForAudioClip:[[request userInfo] objectForKey:@"audioClip"]])
            {
                // Validate the Audio Summary
                if([[[[response objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"audio_summary"] objectForKey:@"acousticness"] == [NSNull null])
                {
                    [[[[response objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"audio_summary"] setObject:@-1 forKey:@"acousticness"];
                }
                //if([[[[[response objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"audio_summary"] objectForKey:@"valence"] isEqualToString:@"<null>"])
                if([[[[response objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"audio_summary"] objectForKey:@"valence"] == [NSNull null])
                {
                    [[[[response objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"audio_summary"] setObject:@-1 forKey:@"valence"];
                }
                
                // Store the audioSummary
                [self setAudioSummary:response forAudioClip:[[request userInfo] objectForKey:@"audioClip"]];
            }
            
            // Only fetch the analysis if we don't already have one
            if(![self audioAnalysisForAudioClip:[[request userInfo] objectForKey:@"audioClip"]])
            {
                // Now get the full analysis
                ENAPIRequest *enRequest = [ENAPIRequest requestWithAnalysisURL:[[[[response objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"audio_summary"] objectForKey:@"analysis_url"]];
                [enRequest setUserInfo:@{@"audioClip" : [[request userInfo] objectForKey:@"audioClip"]}];
                [enRequest setDelegate:self];
                [enRequests addObject:enRequest];
                [enRequest startAsynchronous];
            }
            else
            {
                [self setUploadProgress:1.0 ForAudioClip:[[request userInfo] objectForKey:@"audioClip"]];
            }
        }
    }
    // This is for fetching the full analysis
    else
    {
        NSLog(@"full analysis");
        [self setAudioAnalysis:response forAudioClip:[[request userInfo] objectForKey:@"audioClip"]];
        
        [self setUploadProgress:1.0 ForAudioClip:[[request userInfo] objectForKey:@"audioClip"]];
    }
}

- (void)requestFailed:(ENAPIRequest *)request
{
    NSDictionary *response = [request response];
    
    NSLog(@"response:%@", response);
    NSLog(@"responseStatusCode:%lu", request.responseStatusCode);
    NSLog(@"echonestStatusCode:%lu", request.echonestStatusCode);
    NSLog(@"echonestStatusMessage:%@", request.echonestStatusMessage);
    NSLog(@"error:%@", request.error);
}

#pragma mark - Private EN use Methods

- (void)pollENPostForTrackStatus:(ENAPIPostRequest *)request
{
    ENAPIRequest *enRequest = [ENAPIRequest requestWithEndpoint:@"track/profile"];
    [enRequest setValue:[[[[request response] objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"id"] forParameter:@"id"];
    [enRequest setValue:@"audio_summary" forParameter:@"bucket"];
    [enRequest setUserInfo:[request userInfo]];
    [enRequest setDelegate:self];
    [enRequests addObject:enRequest];
    [enRequest startAsynchronous];
}

- (void)pollENForTrackStatus:(ENAPIRequest *)request
{
    ENAPIRequest *enRequest = [ENAPIRequest requestWithEndpoint:@"track/profile"];
    [enRequest setValue:[[[[request response] objectForKey:@"response"] objectForKey:@"track"] objectForKey:@"id"] forParameter:@"id"];
    [enRequest setValue:@"audio_summary" forParameter:@"bucket"];
    [enRequest setUserInfo:[request userInfo]];
    [enRequest setDelegate:self];
    [enRequests addObject:enRequest];
    [enRequest startAsynchronous];
}

@end
