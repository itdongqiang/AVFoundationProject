//
//  TTAVPacket.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/7/4.
//

#import "TTAVPacket.h"

@implementation TTAVPacket

- (instancetype)initWithSize: (NSInteger)size
{
    self = [super init];
    if (self) {
        _size = size;
        _buffer = malloc(size);
    }
    return self;
}

- (void)dealloc
{
    free(self.buffer);
}

@end
