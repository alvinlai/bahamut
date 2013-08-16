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
#import "SDPlayer.h"
#import "SDTrackPositionView.h"


#define SDPlaylistSongsDidChange @"SDPlaylistSongsDidChange"


static NSString* SDMasterPlaylistItem = @"master";
static NSString* SDUserPlaylistsItem = @"playlists";


static NSString* SDSongDragType = @"SDSongDragType";



@interface SDPlayerWindowController ()

@property (weak) IBOutlet NSSearchField* searchField;

@property (weak) IBOutlet NSView* songsTableContainerView;
@property (weak) IBOutlet NSView* searchContainerView;
@property (weak) IBOutlet NSView* songsScrollView;
@property (weak) IBOutlet NSView* playlistOptionsContainerView;

@property (weak) IBOutlet NSTextField* playlistTitleField;
@property (weak) IBOutlet NSButton* repeatButton;
@property (weak) IBOutlet NSButton* shuffleButton;

@property (weak) IBOutlet NSTableView* songsTable;
@property (weak) IBOutlet NSOutlineView* playlistsOutlineView;
@property (weak) IBOutlet SDTrackPositionView* songPositionSlider;

@property SDPlaylist* selectedPlaylist;

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(allSongsDidChange:) name:SDAllSongsDidChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistSongsDidChange:) name:SDPlaylistSongsDidChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistsDidVisiblyChange:) name:SDPlaylistsDidVisiblyChange object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingCurrentTimeDidChange:) name:SDNowPlayingCurrentTimeDidChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nowPlayingDidChange:) name:SDNowPlayingDidChange object:nil];
    
    [self.songsTable setTarget:self];
    [self.songsTable setDoubleAction:@selector(startPlayingSong:)];
    
    [self.playlistsOutlineView setTarget:self];
    [self.playlistsOutlineView setDoubleAction:@selector(startPlayingPlaylist:)];
    
    [self toggleSearchBar:NO];
    
    [self.songsTable registerForDraggedTypes:@[SDSongDragType]];
    [self.playlistsOutlineView registerForDraggedTypes:@[SDSongDragType]];
    
    [self.playlistsOutlineView expandItem:nil expandChildren:YES];
    [self.playlistsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
}

- (void) windowWillClose:(NSNotification *)notification {
    [self.killedDelegate playerWindowKilled:self];
}


- (void) playlistsDidVisiblyChange:(NSNotification*)note {
    NSIndexSet* sel = [self.playlistsOutlineView selectedRowIndexes];
    [self.playlistsOutlineView reloadItem:SDUserPlaylistsItem reloadChildren:YES];
    [self.playlistsOutlineView selectRowIndexes:sel byExtendingSelection:NO];
}

- (void) allSongsDidChange:(NSNotification*)note {
    if (self.selectedPlaylist == nil)
        [self.songsTable reloadData];
}

- (void) playlistSongsDidChange:(NSNotification*)note {
    if ([note object] == self.selectedPlaylist)
        [self.songsTable reloadData];
}



- (void) nowPlayingDidChange:(NSNotification*)note {
    self.songPositionSlider.maxValue = [[SDPlayer sharedPlayer] nowPlaying].duration;
}

- (void) nowPlayingCurrentTimeDidChange:(NSNotification*)note {
    self.songPositionSlider.currentValue = [SDPlayer sharedPlayer].currentTime;
}





- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard {
    NSArray* songs = [[self visibleSongs] objectsAtIndexes:rowIndexes];
    NSArray* uuids = [songs valueForKey:@"uuid"];
    [pboard setPropertyList:uuids forType:SDSongDragType];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation {
    if (operation == NSTableViewDropAbove)
        return NSDragOperationCopy;
    else
        return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation {
    return YES;
}

- (NSDragOperation)outlineView:(NSOutlineView *)outlineView validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    if ([item isKindOfClass: [SDPlaylist self]])
        return NSDragOperationCopy;
    else
        return NSDragOperationNone;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView acceptDrop:(id < NSDraggingInfo >)info item:(SDPlaylist*)playlist childIndex:(NSInteger)index {
    NSArray* uuids = [[info draggingPasteboard] propertyListForType:SDSongDragType];
    NSArray* songs = [SDUserDataManager songsForUUIDs:uuids];
    [playlist addSongs:songs];
    
    [SDUserDataManager saveUserData];
    [[NSNotificationCenter defaultCenter] postNotificationName:SDPlaylistSongsDidChange object:playlist];
    
    return YES;
}





- (void) startPlayingPlaylist:(id)sender {
    if ([self.playlistsOutlineView clickedRow] < 2)
        return;
    
    [[SDPlayer sharedPlayer] playPlaylist:self.selectedPlaylist];
}






- (NSArray*) visibleSongs {
    if (self.selectedPlaylist) {
        return [self.selectedPlaylist songs];
    }
    else {
        return [[SDUserDataManager sharedMusicManager] allSongs];
    }
}



- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[self visibleSongs] count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    NSArray* songs = [self visibleSongs];
    SDSong* song = [songs objectAtIndex:rowIndex];
    
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



- (void)controlTextDidChange:(NSNotification *)aNotification {
    if ([aNotification object] == self.searchField) {
        NSString* searchString = [self.searchField stringValue];
        NSLog(@"[%@]", searchString);
    }
}


- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command {
    if (control == self.searchField && command == @selector(cancelOperation:)) {
        [self toggleSearchBar:NO];
        [self.searchField setStringValue:@""];
        return YES;
    }
    
    return NO;
}





- (IBAction) performFindPanelAction:(id)sender {
    [self toggleSearchBar:YES];
}

- (void) toggleSearchBar:(BOOL)shouldShow {
    BOOL isShowing = ![self.searchContainerView isHidden];
    
    if (shouldShow != isShowing) {
        NSRect songsTableContainerFrame = [self.songsTableContainerView bounds];
        NSRect playlistOptionsFrame = [self.playlistOptionsContainerView frame];
        
        NSRect songsTableFrame;
        NSDivideRect(songsTableContainerFrame, &playlistOptionsFrame, &songsTableFrame, playlistOptionsFrame.size.height, NSMinYEdge);
        
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







- (BOOL) showingAllSongs {
    return (self.selectedPlaylist == nil);
}







- (void) outlineViewSelectionDidChange:(NSNotification*)note {
    NSInteger row = [self.playlistsOutlineView selectedRow];
    
    if (row == -1)
        return;
    
    if (row == 0) {
        self.selectedPlaylist = nil;
    }
    else {
        NSMutableArray* playlists = [[SDUserDataManager sharedMusicManager] playlists];
        self.selectedPlaylist = [playlists objectAtIndex:row - 2];
    }
    
    [self.repeatButton setEnabled: ![self showingAllSongs]];
    [self.shuffleButton setEnabled: ![self showingAllSongs]];
    [self.playlistTitleField setEnabled: ![self showingAllSongs]];
    
    [self.repeatButton setAllowsMixedState: [self showingAllSongs]];
    [self.shuffleButton setAllowsMixedState: [self showingAllSongs]];
    
    if ([self showingAllSongs]) {
        [self.repeatButton setState: NSMixedState];
        [self.shuffleButton setState: NSMixedState];
        [self.playlistTitleField setStringValue: @""];
    }
    else {
        [self.repeatButton setState: self.selectedPlaylist.repeats ? NSOnState : NSOffState];
        [self.shuffleButton setState: self.selectedPlaylist.shuffles ? NSOnState : NSOffState];
        [self.playlistTitleField setStringValue: self.selectedPlaylist.title];
    }
    
    [self.songsTable deselectAll:nil];
    [self.songsTable reloadData];
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item {
    NSTableCellView *result;
    if (item == SDUserPlaylistsItem) {
        result = [outlineView makeViewWithIdentifier:@"HeaderCell" owner:self];
        [[result textField] setStringValue:@"Playlists"];
    }
    else {
        result = [outlineView makeViewWithIdentifier:@"DataCell" owner:self];
        
        if (item == SDMasterPlaylistItem) {
            [[result textField] setStringValue:@"All Songs"];
        }
        else {
            SDPlaylist* playlist = item;
            [[result textField] setStringValue:playlist.title];
        }
    }
    return result;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    if (item == nil)
        return 2;
    else if (item == SDMasterPlaylistItem)
        return 0;
    else if (item == SDUserPlaylistsItem)
        return [[[SDUserDataManager sharedMusicManager] playlists] count];
    else
        return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
    if (item == SDUserPlaylistsItem)
        return YES;
    else
        return NO;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
    if (item == nil) {
        if (index == 0)
            return SDMasterPlaylistItem;
        else if (index == 1)
            return SDUserPlaylistsItem;
    }
    else if (item == SDUserPlaylistsItem) {
        return [[[SDUserDataManager sharedMusicManager] playlists] objectAtIndex:index];
    }
    return nil;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item {
    return (item == SDUserPlaylistsItem);
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldShowOutlineCellForItem:(id)item {
    return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item {
    return (item != SDUserPlaylistsItem);
}




















- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)dividerIndex {
    return MAX(proposedMin, 150.0);
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex {
    return MIN(proposedMax, [splitView frame].size.width - 150.0);
}

- (void)splitView:(NSSplitView*)sender resizeSubviewsWithOldSize:(NSSize)oldSize {
    CGFloat w = [[[sender subviews] objectAtIndex:0] frame].size.width;
    [sender adjustSubviews];
    [sender setPosition:w ofDividerAtIndex:0];
}














- (IBAction) renamePlaylist:(NSTextField*)sender {
    self.selectedPlaylist.title = [sender stringValue];
    
    [SDUserDataManager saveUserData];
    [[NSNotificationCenter defaultCenter] postNotificationName:SDPlaylistsDidVisiblyChange object:nil];
}





- (IBAction) makeNewPlaylist:(id)sender {
    NSMutableArray* playlists = [[SDUserDataManager sharedMusicManager] playlists];
    
    SDPlaylist* newlist = [[SDPlaylist alloc] init];
    [playlists addObject:newlist];
    
    [SDUserDataManager saveUserData];
    [[NSNotificationCenter defaultCenter] postNotificationName:SDPlaylistsDidVisiblyChange object:nil];
    
    NSIndexSet* indices = [NSIndexSet indexSetWithIndex:[playlists count] - 1 + 2];
    [self.playlistsOutlineView selectRowIndexes:indices byExtendingSelection:NO];
    
    [[self.playlistTitleField window] makeFirstResponder: self.playlistTitleField];
}







- (IBAction) nextSong:(id)sender {
    [[SDPlayer sharedPlayer] nextSong];
}

- (IBAction) prevSong:(id)sender {
    [[SDPlayer sharedPlayer] previousSong];
}

- (IBAction) startPlayingSong:(id)sender {
    if ([[self.songsTable selectedRowIndexes] count] != 1)
        return;
    
    if ([self showingAllSongs])
        return;
    
    NSInteger row = [self.songsTable selectedRow];
    if (row == -1)
        return;
    
    SDSong* song = [[self.selectedPlaylist songs] objectAtIndex:row];
    
    [[SDPlayer sharedPlayer] playSong:song inPlaylist:self.selectedPlaylist];
}

- (IBAction) playPause:(id)sender {
    // ...
}

- (void) trackPositionMovedTo:(CGFloat)newValue {
    [[SDPlayer sharedPlayer] seekToTime:newValue];
}

@end
