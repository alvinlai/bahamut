//
//  SDPlaylistViewController.m
//  Songs
//
//  Created by Steven on 8/19/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "SDSongListViewController.h"





#import "SDUserDataManager.h"
#import "SDSong.h"


#import "SDMusicPlayer.h"


#define SDSongDragType @"SDSongDragType"









@interface SDSongsTableHeaderCell : NSTableHeaderCell
@end
@implementation SDSongsTableHeaderCell

- (NSRect)drawingRectForBounds:(NSRect)theRect {
    theRect.origin.y += 7;
    return theRect;
}

- (void)drawWithFrame:(CGRect)cellFrame inView:(NSView *)view {
    [[NSColor colorWithDeviceWhite:0.97 alpha:1.0] setFill];
    [NSBezierPath fillRect:cellFrame];
    
    [self drawInteriorWithFrame:cellFrame inView:view];
}

@end









@interface SDSongListViewController ()

@property (weak) IBOutlet NSView* songsHousingView;

@property (weak) IBOutlet NSTableView* songsTable;
@property (weak) IBOutlet NSView* searchContainerView;
@property (weak) IBOutlet NSSearchField* searchField;
@property (weak) IBOutlet NSScrollView* songsScrollView;

@property (weak) IBOutlet NSTextField* playlistTitleField;
@property (weak) IBOutlet NSButton* repeatButton;
@property (weak) IBOutlet NSButton* shuffleButton;

@property NSString* filterString;

@end

@implementation SDSongListViewController

- (NSString*) nibName {
    return @"SongListView";
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) loadView {
    [super loadView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(allSongsDidChange:) name:SDAllSongsDidChangeNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistSongsDidChange:) name:SDPlaylistSongsDidChangeNotification object:self.playlist];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistRenamedNotification:) name:SDPlaylistRenamedNotification object:self.playlist];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistOptionsChangedNotification:) name:SDPlaylistOptionsChangedNotification object:self.playlist];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(currentSongDidChange:) name:SDCurrentSongDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerStatusDidChange:) name:SDPlayerStatusDidChangeNotification object:nil];
    
    for (NSTableColumn* column in [self.songsTable tableColumns]) {
        [column setHeaderCell:[[SDSongsTableHeaderCell alloc] initTextCell:[[column headerCell] stringValue]]];
    }
    
    NSRect headerViewFrame = self.songsTable.headerView.frame;
    headerViewFrame.size.height = 27;
    self.songsTable.headerView.frame = headerViewFrame;
    
    NSRect cornerViewFrame = self.songsTable.cornerView.frame;
    cornerViewFrame.size.height = 27;
    self.songsTable.cornerView.frame = cornerViewFrame;
    
    [self.songsTable setSortDescriptors:@[]];
    
    [self.songsTable setTarget:self];
    [self.songsTable setDoubleAction:@selector(startPlayingSong:)];
    
    [self toggleSearchBar:NO];
    
    [self.songsTable registerForDraggedTypes:@[SDSongDragType]];
    
    [self.playlistTitleField setEnabled: ![self.playlist isMasterPlaylist]];
    [self updatePlaylistOptionsViewStuff];
}





- (void) startPlayingSong:(id)sender {
    NSLog(@"ok, playing a song");
}



- (void) allSongsDidChange:(NSNotification*)note {
    [self.songsTable reloadData];
}












- (void) playerStatusDidChange:(NSNotification*)note {
    [self.songsTable reloadData];
}

- (void) currentSongDidChange:(NSNotification*)note {
    [self.songsTable reloadData];
}











- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[self visibleSongs] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    NSArray* songs = [self visibleSongs];
    SDSong* song = [songs objectAtIndex:rowIndex];
    
    if ([[aTableColumn identifier] isEqual:@"playing"]) {
        if (self.playlist == [[SDMusicPlayer sharedPlayer] currentPlaylist] && song == [[SDMusicPlayer sharedPlayer] currentSong])
            return [NSImage imageNamed:NSImageNameRightFacingTriangleTemplate];
        else
            return nil;
    }
    if ([[aTableColumn identifier] isEqual:@"title"]) {
        return [song title];
    }
    if ([[aTableColumn identifier] isEqual:@"artist"]) {
        return [song artist];
    }
    if ([[aTableColumn identifier] isEqual:@"album"]) {
        return [song album];
    }
    
    return nil;
}












#pragma mark - Songs table, Drag / Drop


- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    NSArray* songs = [[self visibleSongs] objectsAtIndexes:rowIndexes];
    NSArray* uuids = [songs valueForKey:@"uuid"];
    NSUInteger playlistIndex = [[SDSharedData() playlists] indexOfObject:self.playlist];
    
    [pboard setPropertyList:@{@"uuids": uuids, @"playlist": @(playlistIndex)}
                    forType:SDSongDragType];
    
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
    if (operation == NSTableViewDropAbove && ![self.playlist isMasterPlaylist])
        return NSDragOperationCopy;
    else
        return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    NSDictionary* data = [[info draggingPasteboard] propertyListForType:SDSongDragType];
    
    NSArray* uuids = [data objectForKey:@"uuids"];
    NSArray* draggingSongs = [SDUserDataManager songsForUUIDs:uuids];
    
    NSUInteger playlistIndex = [[data objectForKey:@"playlist"] unsignedIntegerValue];
    SDPlaylist* fromPlaylist = nil;
    
    if (playlistIndex != NSNotFound)
        fromPlaylist = [[SDSharedData() playlists] objectAtIndex:playlistIndex];
    
    if (fromPlaylist == self.playlist) {
        [self.playlist moveSongs:draggingSongs
                         toIndex:row];
    }
    else {
        [self.playlist addSongs:draggingSongs
                        atIndex:row];
    }
    
    return YES;
}

- (void)tableView:(NSTableView *)aTableView sortDescriptorsDidChange:(NSArray *)oldDescriptors {
    [aTableView reloadData];
}












#pragma mark - Deleting stuff

- (BOOL) respondsToSelector:(SEL)aSelector {
    if (aSelector == @selector(severelyDeleteSomething:)) {
        if ([[self.songsTable window] firstResponder] != self.songsTable)
            return NO;
        
        if ([self.playlist isMasterPlaylist])
            return NO;
        
        if ([[self.songsTable selectedRowIndexes] count] < 1)
            return NO;
        
        return YES;
    }
    
    return [super respondsToSelector:aSelector];
}

- (IBAction) severelyDeleteSomething:(id)sender {
    NSIndexSet* set = [self.songsTable selectedRowIndexes];
    NSArray* songs = [[self visibleSongs] objectsAtIndexes:set];
    [self.playlist removeSongs: songs];
}








- (NSArray*) visibleSongs {
    NSArray* theSongs = [self.playlist songs];
    
    if (self.filterString) {
        theSongs = [theSongs filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SDSong* song, NSDictionary *bindings) {
            return ([song.title rangeOfString:self.filterString options:NSCaseInsensitiveSearch].location != NSNotFound)
            || ([song.artist rangeOfString:self.filterString options:NSCaseInsensitiveSearch].location != NSNotFound)
            || ([song.album rangeOfString:self.filterString options:NSCaseInsensitiveSearch].location != NSNotFound);
        }]];
    }
    
    theSongs = [theSongs sortedArrayUsingDescriptors:[self.songsTable sortDescriptors]];
    
    return theSongs;
}








#pragma mark - Updating View Stuff



- (void) updatePlaylistOptionsViewStuff {
    [self.repeatButton setState: self.playlist.repeats ? NSOnState : NSOffState];
    [self.shuffleButton setState: self.playlist.shuffles ? NSOnState : NSOffState];
    [self.playlistTitleField setStringValue: self.playlist.title];
}







- (void) playlistRenamedNotification:(NSNotification*)note {
    [self updatePlaylistOptionsViewStuff];
}

- (void) playlistOptionsChangedNotification:(NSNotification*)note {
    [self updatePlaylistOptionsViewStuff];
}

- (void) playlistSongsDidChange:(NSNotification*)note {
    if ([note object] == self.playlist) {
        [self.songsTable reloadData];
        [self.songsTable deselectAll:nil];
    }
}










#pragma mark - Editing the current Playlist


- (IBAction) renamePlaylist:(NSTextField*)sender {
    self.playlist.title = [sender stringValue];
}

- (IBAction) setPlaylistShuffles:(NSButton*)sender {
    self.playlist.shuffles = ([sender state] == NSOnState);
}

- (IBAction) setPlaylistRepeats:(NSButton*)sender {
    self.playlist.repeats = ([sender state] == NSOnState);
}











- (IBAction) performFindPanelAction:(id)sender {
    [self toggleSearchBar:YES];
}

- (void) toggleSearchBar:(BOOL)shouldShow {
    BOOL isShowing = ![self.searchContainerView isHidden];
    
    if (shouldShow != isShowing) {
        NSRect songsTableFrame = [self.songsHousingView bounds];
        
        if (shouldShow) {
            NSRect searchSectionFrame = [self.searchContainerView frame];
            NSDivideRect(songsTableFrame, &searchSectionFrame, &songsTableFrame, searchSectionFrame.size.height, NSMaxYEdge);
        }
        
        [self.searchContainerView setHidden: !shouldShow];
        [self.songsScrollView setFrame:songsTableFrame];
    }
    
    if (shouldShow)
        [[self.searchField window] makeFirstResponder: self.searchField];
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
    if ([aNotification object] == self.searchField) {
        NSString* searchString = [self.searchField stringValue];
        
        if ([[searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] == 0)
            searchString = nil;
        
        self.filterString = searchString;
        [self.songsTable reloadData];
    }
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command {
    if (control == self.searchField && command == @selector(cancelOperation:)) {
        [self toggleSearchBar:NO];
        [self.searchField setStringValue:@""];
        
        self.filterString = nil;
        [self.songsTable reloadData];
        
        return YES;
    }
    
    return NO;
}


@end
