//
//  SDPlaylistsViewController.m
//  Songs
//
//  Created by Steven on 8/19/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "SDPlaylistsViewController.h"

#import "SDUserDataManager.h"



@interface SDTableRowView : NSTableRowView
@end

@implementation SDTableRowView

- (void)drawSelectionInRect:(NSRect)dirtyRect {
    if ([[self window] firstResponder] == [self superview] && [[self window] isKeyWindow]) {
        [[NSColor colorWithDeviceHue:206.0/360.0 saturation:0.67 brightness:0.92 alpha:1.0] setFill];
        [[NSBezierPath bezierPathWithRect:self.bounds] fill];
    }
    else {
        [[NSColor colorWithDeviceHue:206.0/360.0 saturation:0.67 brightness:0.92 alpha:0.5] setFill];
        [[NSBezierPath bezierPathWithRect:self.bounds] fill];
    }
}

//- (void) resetCursorRects {
//    NSCursor* c = [NSCursor pointingHandCursor];
//    [self addCursorRect:[self bounds] cursor:c];
//    [c setOnMouseEntered:YES];
//}

@end





@interface SDPlaylistsViewController ()

@property (weak) IBOutlet NSTableView* playlistsTableView;

@end

@implementation SDPlaylistsViewController

- (NSString*) nibName {
    return @"PlaylistsView";
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) loadView {
    [super loadView];
    
    [self.playlistsTableView setTarget:self];
    [self.playlistsTableView setDoubleAction:@selector(doubleClickedThing:)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistAddedNotification:) name:SDPlaylistAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistRenamedNotification:) name:SDPlaylistRenamedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playlistRemovedNotification:) name:SDPlaylistRemovedNotification object:nil];
}

- (void) playlistAddedNotification:(NSNotification*)note {
    NSInteger row = [self.playlistsTableView selectedRow];
    [self.playlistsTableView reloadData];
    [self.playlistsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
}

- (void) playlistRenamedNotification:(NSNotification*)note {
    NSInteger row = [self.playlistsTableView selectedRow];
    [self.playlistsTableView reloadData];
    [self.playlistsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    
//    [self updatePlaylistOptionsViewStuff];
}

- (void) playlistRemovedNotification:(NSNotification*)note {
    [self.playlistsTableView reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView {
    return [[SDSharedData() playlists] count] + 1;
}

- (NSView *)tableView:(NSTableView *)tableView
   viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row {
    if (row == 0) {
        NSTableCellView *result = [tableView makeViewWithIdentifier:@"ExistingPlaylist" owner:self];
        [result textField].stringValue = @"All Songs";
        return result;
    }
    else {
        NSTableCellView *result = [tableView makeViewWithIdentifier:@"ExistingPlaylist" owner:self];
        [result textField].stringValue = [[[SDSharedData() playlists] objectAtIndex:row - 1] title];
        return result;
    }
}

- (NSTableRowView *)tableView:(NSTableView *)tableView rowViewForRow:(NSInteger)row {
    return [[SDTableRowView alloc] init];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification {
    NSInteger row = [self.playlistsTableView selectedRow];
    
    if (row > 0)
        [self.playlistsViewDelegate selectPlaylist: [[SDSharedData() playlists] objectAtIndex:row - 1]];
}


- (BOOL) respondsToSelector:(SEL)aSelector {
    if (aSelector == @selector(severelyDeleteSomething:)) {
        return ([self.playlistsTableView selectedRow] != -1);
    }
    
    return [super respondsToSelector:aSelector];
}

- (IBAction) severelyDeleteSomething:(id)sender {
    NSInteger row = [self.playlistsTableView selectedRow];
    [SDSharedData() deletePlaylist: [[SDSharedData() playlists] objectAtIndex:row]];
    [self.playlistsTableView reloadData];
}

- (void) selectPlaylist:(SDPlaylist*)playlist {
    NSUInteger idx = [[SDSharedData() playlists] indexOfObject:playlist];
    [self.playlistsTableView selectRowIndexes:[NSIndexSet indexSetWithIndex:idx]
                         byExtendingSelection:NO];
    
    [self.playlistsViewDelegate selectPlaylist:playlist];
}

- (void) doubleClickedThing:(id)sender {
    NSInteger row = [self.playlistsTableView clickedRow];
    
    if (row < 0 || row == [[SDSharedData() playlists] count])
        return;
    
    SDPlaylist* playlist = [[SDSharedData() playlists] objectAtIndex:row];
    [self.playlistsViewDelegate playPlaylist:playlist];
}

@end