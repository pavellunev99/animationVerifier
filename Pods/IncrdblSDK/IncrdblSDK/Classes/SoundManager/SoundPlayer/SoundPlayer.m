//
//  SoundPlayer.m
//
//  Created by Anton on 21/05/14.
//  Copyright (c) 2014 biz.bdgroup. All rights reserved.
//

#import "SoundPlayer.h"

NSNotificationName const NSNotificationSoundPlayerFinished = @"NotificationSoundPlayerFinished";

#define kNumberPlaybackBuffers 3

static dispatch_queue_t _freeQueue = NULL;

typedef struct
{
    AudioQueueBufferRef qBuffer;
    Boolean             completed;
    Boolean             enqueued;
}PlayerBuffer;

@interface SoundPlayer ()
{
    int                             _bufferComplete;
    Boolean                         _playStrongRefLinkAdded;
    Boolean                         _disposed;
@public
    AudioFileID						playbackFile;
    SInt64                          packetPosition;
    UInt32                          numPacketsToRead;
    AudioStreamPacketDescription    *packetDescs;
    Boolean                         isDone;
    AudioQueueRef                   mQueue;
    PlayerBuffer                    buffers[kNumberPlaybackBuffers];
    UInt32                          bufferByteSize;
    AudioStreamBasicDescription     dataFormat;
}
@property (nonatomic,assign) Boolean isDone;

@property (nonatomic,assign) AudioStreamPacketDescription *packetDescs;
@property (nonatomic,assign) SInt64  packetPosition;
@property (nonatomic,assign) UInt64  packetsCount;
@property (nonatomic,assign) UInt32 numPacketsToRead;

-(void)audioBufferDidComplete:(AudioQueueBufferRef)qBuffer;

@end

void OutputCallback(void *					inUserData,
								AudioQueueRef			inAQ,
								AudioQueueBufferRef		inCompleteAQBuffer)
{
	SoundPlayer* player = (SoundPlayer*)inUserData;
    
    if (inCompleteAQBuffer == NULL) {
        return;
    }
    
    if (player.isDone) {
        [player audioBufferDidComplete:inCompleteAQBuffer];
        return;
    }
    
    UInt32 numBytes = player->bufferByteSize;
    UInt32 numPackets=player->numPacketsToRead;
    
    OSStatus status = AudioFileReadPacketData(player->playbackFile, NO, &numBytes, player.packetDescs, player.packetPosition,&numPackets, inCompleteAQBuffer->mAudioData);
    
    if (status != noErr)
    {
        NSLog(@"audio player read packet error %d",(int)status);
    }
    
    if (status != noErr && status != kAudioFileEndOfFileError) {
        
        return;
    }
    
    if (player.isInfinitePlayback && numPackets == 0) {

        player.packetPosition = 0;
        numBytes = player->bufferByteSize;
        numPackets = player->numPacketsToRead;
        
        OSStatus status = AudioFileReadPacketData(player->playbackFile, NO, &numBytes, player.packetDescs, player.packetPosition,&numPackets, inCompleteAQBuffer->mAudioData);
        
        if (status != noErr)
        {
            NSLog(@"audio player read packet error %d",(int)status);
        }
        
        if (status != noErr && status != kAudioFileEndOfFileError) {
            
            return;
        }
    }
    
    if (numPackets>0) {
        
        inCompleteAQBuffer->mAudioDataByteSize=numBytes;
        
        for (int i = 0; i < kNumberPlaybackBuffers; ++i) {
            if (player->buffers[i].qBuffer == inCompleteAQBuffer && !player->buffers[i].enqueued) {
                player->buffers[i].enqueued = true;
                break;
            }
        }
        
        status = AudioQueueEnqueueBuffer(inAQ, inCompleteAQBuffer, (player.packetDescs ? numPackets : 0 ), player.packetDescs);
        if (status != noErr) {
            NSLog(@"audio player *** Error *** AudioQueueEnqueueBuffer failed,status=%d", (int)status);
        }
        
        player.packetPosition += numPackets;
        
    }else
    {
        [player audioBufferDidComplete:inCompleteAQBuffer];
    }
}

@implementation SoundPlayer
@synthesize isDone = isDone;
@synthesize playbackFile = playbackFile;
@synthesize packetDescs = packetDescs;
@synthesize packetPosition = packetPosition;
@synthesize numPacketsToRead = numPacketsToRead;

+(void)initialize
{
    _freeQueue = dispatch_queue_create("soundPlayer.free.queue", DISPATCH_QUEUE_SERIAL);
}

+(instancetype)playWithFileId:(AudioFileID)fileId
{
    SoundPlayer* player = [[SoundPlayer alloc] initWithFileId:fileId];
    if (player) {
        player.isNeedRelease = YES;
        [player play];
    }
    return player;
}

-(instancetype)initWithFileId:(AudioFileID)fileId
{
    self = [super init];
    if (self) {
        _isInfinitePlayback = false;
        _disposed = false;
        mQueue = NULL;
        playbackFile = fileId;
        if (![self _configure]) {
            [self release];
            return nil;
        }
    }
    return self;
}

-(BOOL)_configure
{
    UInt32 propSize = sizeof(dataFormat);
    OSStatus status = AudioFileGetProperty(playbackFile, kAudioFilePropertyDataFormat, &propSize, &dataFormat);
    
    if (status != noErr) {
        return NO;
    }
    
    UInt32 dataPacketCountPropSize = sizeof(_packetsCount);
    
    status = AudioFileGetProperty(playbackFile, kAudioFilePropertyAudioDataPacketCount, &dataPacketCountPropSize, &_packetsCount);
    
    AudioQueueRef queue;
    status = AudioQueueNewOutput(&dataFormat, OutputCallback, self,
                                 CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &queue);
    if (status != noErr) {
        
        return NO;
    }
    
    mQueue = queue;
    
    [self calculateBytesForTime:playbackFile
                           desc:dataFormat
                        seconds:0.5
                  outBufferSize:&bufferByteSize
                  outNumPackets:&numPacketsToRead];
    
    bool isFormatVBR = (dataFormat.mBytesPerPacket == 0 || dataFormat.mFramesPerPacket == 0);
    
    if (packetDescs != NULL) {
        free(packetDescs);
        packetDescs = NULL;
    }
    
    if (isFormatVBR) {
        packetDescs = (AudioStreamPacketDescription*)malloc(sizeof(AudioStreamPacketDescription)*numPacketsToRead);
    }else
    {
        packetDescs = NULL;
    }
    
    [self copyEncoderCookieToQueue:playbackFile queue:queue];
    
    isDone = true;
    packetPosition = 0;
    _isNeedRelease = NO;
    
    int i = 0;
    
    for (i = 0; i < kNumberPlaybackBuffers; ++i) {
        if (buffers[i].qBuffer == NULL) {
            OSStatus status = AudioQueueAllocateBuffer(queue,
                                                       bufferByteSize,
                                                       &buffers[i].qBuffer);
            if (status != noErr) {
                buffers[i].qBuffer = NULL;
            }
            buffers[i].completed = false;
        }
    }
    return YES;
}

-(instancetype)initWithURL:(NSURL*)url
{
    AudioFileOpenURL ((CFURLRef)url, kAudioFileReadPermission, 0, &playbackFile);
    return [self initWithFileId:playbackFile];
}

-(void)copyEncoderCookieToQueue:(AudioFileID)theFile queue:(AudioQueueRef)queue
{
    UInt32 propertySize;
    OSStatus result = AudioFileGetPropertyInfo(theFile,
                                               kAudioFilePropertyMagicCookieData,
                                               &propertySize,
                                               NULL);
    if (result == noErr && propertySize > 0) {
        Byte* magicCookie = (UInt8*)malloc(sizeof(UInt8)*propertySize);
        AudioFileGetProperty(theFile,
                             kAudioFilePropertyMagicCookieData,
                             &propertySize,
                             magicCookie);
        AudioQueueSetProperty(queue,
                              kAudioQueueProperty_MagicCookie,
                              magicCookie, propertySize);
        free(magicCookie);
    }
}

-(void)calculateBytesForTime:(AudioFileID)inAudioFile
                        desc:(AudioStreamBasicDescription)inDesc
                     seconds:(Float64)inSeconds
               outBufferSize:(UInt32*)outBufferSize
               outNumPackets:(UInt32*)outNumPackets
{
    UInt32 maxPacketSize;
    UInt32 propSize = sizeof(maxPacketSize);
    AudioFileGetProperty(inAudioFile,
                         kAudioFilePropertyPacketSizeUpperBound,
                         &propSize,
                         &maxPacketSize);
    
    static const int maxBufferSize = 0x50000;
    static const int minBufferSize = 0x4000;
    
    if (inDesc.mFramesPerPacket) {
        Float64 numPacketsForTime = inDesc.mSampleRate / inDesc.mFramesPerPacket * inSeconds;
        *outBufferSize = numPacketsForTime * maxPacketSize;
    }else
    {
        *outBufferSize = maxBufferSize > maxPacketSize ? maxPacketSize : maxPacketSize;
    }
    
    if (*outBufferSize > maxBufferSize &&
        *outBufferSize > maxPacketSize) {
        *outBufferSize = maxBufferSize;
    }else
    {
        if (*outBufferSize < minBufferSize) {
            *outBufferSize = minBufferSize;
        }
    }
    *outNumPackets = *outBufferSize / maxPacketSize;
}

-(void)setVolume:(float)volume
{
    AudioQueueSetParameter (mQueue, kAudioQueueParam_Volume, volume);
}

-(void)play
{
    isDone = false;
    packetPosition = 0;
    int i = 0;
    
    for (i = 0; i < kNumberPlaybackBuffers; ++i) {;
        OutputCallback(self, mQueue, buffers[i].qBuffer);
        if (isDone) {
            break;
        }
    }
    OSStatus status = AudioQueueStart(mQueue, NULL);
    if (status != noErr) {
        NSLog(@"audio player start error %d",(int)status);
    }else
    {
        [self _addPlayStrongRefLink];
    }
}

-(void)audioBufferDidComplete:(AudioQueueBufferRef)qBuffer
{
    self.isDone = true;
    
    int i = 0;
    Boolean allBuffersCompleted = true;
    
    for (i = 0; i < kNumberPlaybackBuffers; ++i) {
        if (buffers[i].qBuffer == qBuffer) {
            buffers[i].completed = true;
        }
        allBuffersCompleted &= buffers[i].completed ||
        !buffers[i].enqueued ||
        buffers[i].qBuffer->mAudioDataByteSize == 0;
    }
    
    if (allBuffersCompleted) {
        
        [[NSNotificationCenter defaultCenter] postNotificationName:NSNotificationSoundPlayerFinished object:self];
        if (self.isNeedRelease) {
            [self dispose];
        }
        [self _removePlayStrongRefLink];
    }
}

-(void)_addPlayStrongRefLink
{
    if (!_playStrongRefLinkAdded) {
        _playStrongRefLinkAdded = true;
        [self retain];
    }
}

-(void)_removePlayStrongRefLink
{
    if (_playStrongRefLinkAdded) {
        _playStrongRefLinkAdded = false;
        [self release];
    }
}

-(void)unpause
{
    if (!isDone) {
        OSStatus status = AudioQueueStart(mQueue, NULL);
        if (status != noErr) {
            NSLog(@"audio player unpause error %d",(int)status);
        }
    }
}

-(void)pause
{
    if (!isDone) {
        OSStatus status = AudioQueuePause(mQueue);
        if (status != noErr) {
            NSLog(@"audio player pause error %d",(int)status);
        }
    }
}

-(void)stop
{
    if (!isDone) {
        self.isDone = true;
        self.isInfinitePlayback = false;
        OSStatus status = AudioQueueStop(mQueue, true);
        if (status != noErr) {
            NSLog(@"audio player stop error %d",(int)status);
        }
    }
}

-(void)dispose
{
    if (!_disposed) {
        _disposed = true;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), _freeQueue, ^{
            [self autorelease];
        });
    }
}

- (void)dealloc
{
    if (mQueue != NULL) {
        AudioQueueStop(mQueue, true);
        AudioQueueDispose(mQueue, true);
        mQueue = NULL;
    }
    
    if (packetDescs != NULL) {
        free(packetDescs);
        packetDescs = NULL;
    }
    [super dealloc];
}

@end
