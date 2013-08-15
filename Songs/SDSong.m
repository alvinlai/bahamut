//
//  SOSong.m
//  Songs
//
//  Created by Steven Degutis on 3/24/13.
//  Copyright (c) 2013 Steven Degutis. All rights reserved.
//

#import "SDSong.h"

@interface SDSong ()

@property NSString* uuid;

@property AVURLAsset* cachedAsset;
//@property AVPlayerItem* cachedPlayerItem;

@end

@implementation SDSong

+ (BOOL)supportsSecureCoding {
    return YES;
}

- (id) initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init]) {
        self.uuid = [aDecoder decodeObjectOfClass:[NSString self] forKey:@"uuid"];
        self.url = [[aDecoder decodeObjectOfClass:[NSURL self] forKey:@"url"] fileReferenceURL];
    }
    return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uuid forKey:@"uuid"];
    [aCoder encodeObject:self.url forKey:@"url"];
}

- (id) init {
    if (self = [super init]) {
        self.uuid = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (BOOL) isEqual:(id)object {
    return [object isKindOfClass: [self class]] && [self.uuid isEqual: [object uuid]];
}

- (NSUInteger) hash {
    return [self.uuid hash];
}

- (AVURLAsset*) asset {
    if (self.cachedAsset == nil)
        self.cachedAsset = [AVURLAsset assetWithURL:self.url];
    
    return self.cachedAsset;
}

- (AVPlayerItem*) playerItem {
    return [AVPlayerItem playerItemWithAsset:[self asset]];
}

- (NSString*) metadataOfType:(NSString*)type {
    NSArray* metadataItems = [AVMetadataItem metadataItemsFromArray:[[self asset] commonMetadata]
                                                            withKey:type
                                                           keySpace:AVMetadataKeySpaceCommon];
    
    if ([metadataItems count] == 0) {
        if (type == AVMetadataCommonKeyTitle)
            return [[[self asset] URL] lastPathComponent];
        else
            return @"";
    }
    
    AVMetadataItem* firstMatchingMetadataItem = [metadataItems objectAtIndex:0];
    return (id)[firstMatchingMetadataItem value];
}

- (CGFloat) duration {
    CMTime dur = [[self asset] duration];
    return CMTimeGetSeconds(dur);
}

- (NSString*) title {
    return [self metadataOfType:AVMetadataCommonKeyTitle];
}

- (NSString*) album {
    return [self metadataOfType:AVMetadataCommonKeyAlbumName];
}

- (NSString*) artist {
    return [self metadataOfType:AVMetadataCommonKeyArtist];
}

@end
