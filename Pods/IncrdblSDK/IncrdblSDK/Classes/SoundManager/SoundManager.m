//  SoundManager.m
//  Created by Anton on 6/20/13.
//  Copyright (c) 2013 Incrdbl Mobile Entertainment LLC. All rights reserved.
//

#import "SoundManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "SoundPlayer/SoundPlayer.h"

static SoundManager* instance = nil;

@interface AudioFile : NSObject

@property (nonatomic,assign) AudioFileID fileId;
@property (nonatomic,retain) NSURL* fileUrl;
@property (nonatomic,retain) NSString* alias;

@end

@implementation AudioFile

+(instancetype)audioFileForUrl:(NSURL*)fileUrl alias:(NSString*)alias
{
    AudioFile* audioFile = [[self new] autorelease];
    audioFile.fileUrl = fileUrl;
    audioFile.alias = alias;
    
    if (fileUrl != nil) {
        AudioFileID fileId = NULL;
        AudioFileOpenURL ((CFURLRef)fileUrl, kAudioFileReadPermission, 0, &fileId);
        audioFile.fileId = fileId;
    }
    return audioFile;
}

- (void)dealloc
{
    self.alias = nil;
    self.fileUrl = nil;
    if (_fileId) {
        AudioFileClose(_fileId);
        _fileId = NULL;
    }
    
    [super dealloc];
}

@end

@interface SoundManager ()
{
    NSThread*           playingThread;
    BOOL                _shouldThreadExit;
    NSMutableDictionary<NSString*,AudioFile*>* _audioFiles;
    NSMutableArray<SoundPlayer*>* _currentPlayers;
}
@property (assign) BOOL initialized;
@end

@implementation SoundManager

+(id)instance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SoundManager alloc] initInstance];
    });

    return instance;
}

- (void)dealloc
{
    [playingThread release];
    playingThread = nil;
    
    if (_audioFiles) {
        [_audioFiles release];
        _audioFiles = nil;
    }
    
    [_currentPlayers release];
    _currentPlayers = nil;

    [super dealloc];
}

- (id)initInstance
{
    self = [super init];
    if (self) {
        _audioFiles = [NSMutableDictionary new];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_playerDidFinishNotificationHandler:) name:NSNotificationSoundPlayerFinished object:nil];
    }
    return self;
}

-(void)initialize
{
    @synchronized (self)
    {
        _shouldThreadExit = NO;
    }
    
    if (playingThread) {
        [playingThread cancel];
        [playingThread release];
        playingThread = nil;
    }
    playingThread = [[NSThread alloc] initWithTarget:self selector:@selector(mainThreadBody) object:nil];
    [playingThread start];
    [self performSelector:@selector(playPlayer:) onThread:playingThread withObject:nil waitUntilDone:NO];
    _initialized = YES;
}

-(void)deinitialize
{
    @synchronized (self)
    {
        _shouldThreadExit = YES;
    }
    _initialized = NO;
}

-(void)_initializePlayers
{
    NSError *sessionError = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:&sessionError];
    [[AVAudioSession sharedInstance] setActive:YES error:&sessionError];
}

-(void)_deinitializePlayers
{
    [_audioFiles removeAllObjects];
}

+(void)addFile:(NSURL*)url alias:(NSString*)alias
{
    if (url != nil && alias != nil) {
        [[self instance] _performInnerSelector:@selector(_addFile:) withObject:@{@"url":url,@"alias":alias}];
    }
}

+(void)playSound:(NSString*)alias
{
    [[self instance] _performInnerSelector:@selector(_playSound:) withObject:alias];
}

+(void)playSound:(NSString*)alias infinitely:(BOOL)infinitely
{
    if (!infinitely) {
        [[self instance] _performInnerSelector:@selector(_playSound:) withObject:alias];
    }else
    {
        [[self instance] _performInnerSelector:@selector(_playSoundInfinitely:) withObject:alias];
    }
}

+(void)stopSound:(NSString*)alias
{
    [[self instance] _performInnerSelector:@selector(_stopSound:) withObject:alias];
}

+(void)pauseSound:(NSString*)alias
{
    [[self instance] _performInnerSelector:@selector(_pauseSound:) withObject:alias];
}

+(void)resumeSound:(NSString*)alias
{
    [[self instance] _performInnerSelector:@selector(_resumeSound:) withObject:alias];
}

-(void)_addFile:(NSDictionary*)dct
{
    NSURL* url = [dct objectForKey:@"url"];
    NSString* alias = [dct objectForKey:@"alias"];
    AudioFile* audioFile = [AudioFile audioFileForUrl:url alias:alias];
    [_audioFiles setObject:audioFile forKey:alias];
}

-(void)_playSound:(NSString*)alias
{
    if (alias) {
        AudioFile* audioFile = [_audioFiles objectForKey:alias];
        if (audioFile.fileId != NULL) {
            [self playPlayer:audioFile.fileId];
        }
    }
}

-(void)_stopSound:(NSString*)alias
{
    if (alias) {
        AudioFile* audioFile = [_audioFiles objectForKey:alias];
        if (audioFile.fileId != NULL) {
            [self _stopPlayer:audioFile.fileId];
        }
    }
}

-(void)_pauseSound:(NSString*)alias
{
    if (alias) {
        AudioFile* audioFile = [_audioFiles objectForKey:alias];
        if (audioFile.fileId != NULL) {
            [self _pausePlayer:audioFile.fileId];
        }
    }
}

-(void)_resumeSound:(NSString*)alias
{
    if (alias) {
        AudioFile* audioFile = [_audioFiles objectForKey:alias];
        if (audioFile.fileId != NULL) {
            [self _continuePlayer:audioFile.fileId];
        }
    }
}

-(void)_playSoundInfinitely:(NSString*)alias
{
    if (alias) {
        AudioFile* audioFile = [_audioFiles objectForKey:alias];
        if (audioFile.fileId != NULL) {
            [self playPlayer:audioFile.fileId infinitely:YES];
        }
    }
}

-(void)_stopPlayer:(AudioFileID)fileId
{
    NSArray* players = [NSArray arrayWithArray:_currentPlayers ? _currentPlayers : @[]];
    for (SoundPlayer* player in players) {
        if (player.playbackFile == fileId) {
            [player stop];
        }
    }
}

-(void)_pausePlayer:(AudioFileID)fileId
{
    for (SoundPlayer* player in _currentPlayers) {
        if (player.playbackFile == fileId) {
            [player pause];
        }
    }
}

-(void)_continuePlayer:(AudioFileID)fileId
{
    for (SoundPlayer* player in _currentPlayers) {
        if (player.playbackFile == fileId) {
            [player unpause];
        }
    }
}

+(void)switchSounds:(BOOL)on
{
    if (on) {
        [[self instance] initialize];
    }else
    {
        [[self instance] deinitialize];
    }
}

-(void)playPlayer:(AudioFileID)fileId
{
    [self playPlayer:fileId infinitely:NO];
}

-(void)playPlayer:(AudioFileID)fileId infinitely:(BOOL)infinitely
{
    if (fileId) {
        @try {
            SoundPlayer* player = [[SoundPlayer alloc] initWithFileId:fileId];
            if (player) {
                if (_currentPlayers == nil) {
                    _currentPlayers = [NSMutableArray new];
                }
                [_currentPlayers addObject:player];
                player.isInfinitePlayback = infinitely;
                [player play];
            }
            
        } @catch (NSException *exception) {
            NSLog(@"%@",exception);
        } @finally {
            
        }
    }
}

-(void)_playerDidFinishNotificationHandler:(NSNotification*)notification
{
    SoundPlayer* player = (SoundPlayer*)notification.object;
    if ([player isKindOfClass:[SoundPlayer class]] && [_currentPlayers containsObject:player]) {
        [player dispose];
        [_currentPlayers removeObject:player];
    }
}

-(void)_performInnerSelector:(SEL)sel withObject:(nullable id)arg
{
    if ([self respondsToSelector:sel]) {
        [self performSelector:sel onThread:playingThread withObject:arg waitUntilDone:NO];
    }
    
}

-(void)mainThreadBody
{
    [self _initializePlayers];
    BOOL shouldExit = NO;
    while (!shouldExit) {
        @autoreleasepool {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
        }
        @synchronized (self)
        {
            shouldExit = _shouldThreadExit;
        }
    }
    [self _deinitializePlayers];
}

+(BOOL)isSoundSwitchedOn
{
    return instance != nil && instance.initialized;
}

@end
