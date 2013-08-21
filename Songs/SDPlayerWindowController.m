//
//  MUPlayerWindowController.m
//  Songs
//
//  Created by Steven Degutis on 3/25/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "SDPlayerWindowController.h"

#import "SDUserDataManager.h"
#import "SDPlaylist.h"
#import "SDMusicPlayer.h"
#import "SDTrackPositionView.h"

#import "SDSongListViewController.h"
#import "SDSourceListViewController.h"


@interface SDPlayerWindowController ()

@property (weak) IBOutlet NSView* playlistsViewHouser;
@property SDSourceListViewController* playlistsViewController;
@property SDPlaylist* selectedPlaylist;

@property (weak) IBOutlet NSView* songListViewHouser;
@property NSMutableArray* songListViewControllers;
@property (weak) SDSongListViewController* currentSongListViewController;

@property (weak) IBOutlet NSView* nowPlayingControlsView;
@property (weak) IBOutlet SDTrackPositionView* songPositionSlider;
@property (weak) IBOutlet NSButton* playButton;
@property (weak) IBOutlet NSButton* prevButton;
@property (weak) IBOutlet NSButton* nextButton;
@property (weak) IBOutlet NSTextField* currentSongInfoField;
@property (weak) IBOutlet NSTextField* timeElapsedField;
@property (weak) IBOutlet NSTextField* timeRemainingField;

@end

@implementation SDPlayerWindowController

- (NSString*) windowNibName {
    return @"PlayerWindow";
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistAddedNotification:) name:SDPlaylistAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistRemovedNotification:) name:SDPlaylistRemovedNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentSongTimeDidChange:) name:SDCurrentSongTimeDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentSongDidChange:) name:SDCurrentSongDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStatusDidChange:) name:SDPlayerStatusDidChangeNotification object:nil];
    
    self.songListViewControllers = [NSMutableArray array];
    
    for (SDPlaylist* playlist in [SDSharedData() playlists]) {
        SDSongListViewController* vc = [[SDSongListViewController alloc] init];
        vc.playlist = playlist;
        [self.songListViewControllers addObject:vc];
    }
    
    
    [[self window] setBackgroundColor:[NSColor colorWithDeviceWhite:0.92 alpha:1.0]];
    
    self.playlistsViewController = [[SDSourceListViewController alloc] init];
    self.playlistsViewController.playlistsViewDelegate = self;
    [[self.playlistsViewController view] setFrame:[self.playlistsViewHouser frame]];
    [self.playlistsViewHouser addSubview:[self.playlistsViewController view]];
    
    [self setNextResponder:self.playlistsViewController];
    
    self.selectedPlaylist = [[SDSharedData() playlists] objectAtIndex:0];
    [self.playlistsViewController selectPlaylist: self.selectedPlaylist];
    
    [self updatePlayerViews];
    
//    self.window.styleMask = NSBorderlessWindowMask;
//    [self.window setMovableByWindowBackground:YES];
}

- (void) windowWillClose:(NSNotification *)notification {
    [self.killedDelegate playerWindowKilled:self];
}

- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [SDSharedData() undoManager];
}






#pragma Playlists

- (void) selectPlaylist:(SDPlaylist*)playlist {
    self.selectedPlaylist = playlist;
    
    NSUInteger idx = [[SDSharedData() playlists] indexOfObject: self.selectedPlaylist];
    
    SDSongListViewController* vc = [self.songListViewControllers objectAtIndex: idx];
    self.currentSongListViewController = vc;
    
    [[self.songListViewHouser subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [[vc view] setFrame: [self.songListViewHouser bounds]];
    [self.songListViewHouser addSubview:[vc view]];
    [self.playlistsViewController setNextResponder: vc];
    
//    NSLog(@"%@", self.selectedPlaylist);
}

- (void) playPlaylist:(SDPlaylist*)playlist {
    [[SDMusicPlayer sharedPlayer] playPlaylist: playlist];
}







#pragma mark - Notifications

- (void) playlistAddedNotification:(NSNotification*)note {
    SDPlaylist* playlist = [note object];
    
    NSUInteger idx = [[SDSharedData() playlists] indexOfObject:playlist];
    
    SDSongListViewController* vc = [[SDSongListViewController alloc] init];
    vc.playlist = playlist;
    [self.songListViewControllers insertObject:vc atIndex:idx];
    
//    NSLog(@"its %@", playlist);
}

- (void) playlistRemovedNotification:(NSNotification*)note {
    SDPlaylist* playlist = [note object];
    
    NSUInteger idx = [self.songListViewControllers indexOfObjectPassingTest:^BOOL(SDSongListViewController* obj, NSUInteger idx, BOOL *stop) {
        return obj.playlist == playlist;
    }];
    
    [self.songListViewControllers removeObjectAtIndex:idx];
    
//    NSLog(@"its %@", playlist);
}





- (void) playerStatusDidChange:(NSNotification*)note {
    [self updatePlayerViews];
}

- (void) currentSongDidChange:(NSNotification*)note {
    [self updatePlayerViews];
}

NSString* timeForSeconds(CGFloat seconds) {
    CGFloat mins = seconds / 60.0;
    CGFloat secs = fmod(seconds, 60.0);
    return [NSString stringWithFormat:@"%d:%02d", (int)mins, (int)secs];
}

- (void) currentSongTimeDidChange:(NSNotification*)note {
    [self updatePlayerViews];
}





























- (void) updatePlayerViews {
    [self.nowPlayingControlsView setHidden: [[SDMusicPlayer sharedPlayer] stopped]];
    
    [self.prevButton setEnabled: ![[SDMusicPlayer sharedPlayer] stopped]];
    [self.nextButton setEnabled: ![[SDMusicPlayer sharedPlayer] stopped]];
    
    [self.playButton setTitle: [[SDMusicPlayer sharedPlayer] isPlaying] ? @"Pause" : @"Play"];
    
    SDSong* currentSong = [[SDMusicPlayer sharedPlayer] currentSong];
    
    if (currentSong) {
        NSString* trackInfo = [NSString stringWithFormat:@"%@  -  %@  -  %@", currentSong.title, currentSong.artist, currentSong.album];
        [self.currentSongInfoField setStringValue:trackInfo];
        
        CGFloat current = [SDMusicPlayer sharedPlayer].currentTime;
        CGFloat max = currentSong.duration;
        CGFloat left = max - current;
        
        [self.timeElapsedField setStringValue: timeForSeconds(current)];
        [self.timeRemainingField setStringValue: timeForSeconds(left)];
        
        self.songPositionSlider.maxValue = currentSong.duration;
        self.songPositionSlider.currentValue = current;
    }
}































#pragma mark - Creating a new Playlist



- (IBAction) makeNewPlaylist:(id)sender {
    NSMutableArray* playlists = [SDSharedData() playlists];
    
    SDPlaylist* newPlaylist = [[SDPlaylist alloc] init];
    [SDSharedData() insertPlaylist:newPlaylist atIndex:[playlists count]];
    
    [self.playlistsViewController selectPlaylist:newPlaylist];
    [self.playlistsViewController editPlaylistTitle];
}








#pragma mark - Playing music


- (IBAction) playPause:(id)sender {
    if ([SDMusicPlayer sharedPlayer].stopped) {
        NSArray* selectedSongs = [self.currentSongListViewController selectedSongs];
        
        if ([selectedSongs count] == 1) {
            [[SDMusicPlayer sharedPlayer] playSong:[selectedSongs lastObject]
                                        inPlaylist:self.selectedPlaylist];
        }
        else {
            [[SDMusicPlayer sharedPlayer] playPlaylist:self.selectedPlaylist];
        }
    }
    else {
        if ([[SDMusicPlayer sharedPlayer] isPlaying])
            [[SDMusicPlayer sharedPlayer] pause];
        else
            [[SDMusicPlayer sharedPlayer] resume];
    }
}

- (void) trackPositionMovedTo:(CGFloat)newValue {
    [[SDMusicPlayer sharedPlayer] seekToTime:newValue];
}

@end
