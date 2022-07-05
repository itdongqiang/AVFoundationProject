//
//  TTAVVideoFileReader.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/7/4.
//

#import "TTAVVideoFileReader.h"

#define MAX_BUFFER_LEN 1024 * 1024

const uint8_t KStartCode[4] = {0, 0, 0, 1};

@implementation TTAVVideoFileReader
{
    uint8_t *_tmpBuffer;
    NSInputStream *_fileStream;
    // 文件流的当前偏移值
    NSInteger _currentOffset;
}

- (instancetype)initWithH264File: (NSString *)file
{
    self = [super init];
    if (self) {
        _tmpBuffer = malloc(MAX_BUFFER_LEN);
        _fileStream = [NSInputStream inputStreamWithFileAtPath: file];
        [_fileStream open];
        _currentOffset = 0;
    }
    return self;
}

- (TTAVPacket*)nextPacket
{
    if(_currentOffset < MAX_BUFFER_LEN && _fileStream.hasBytesAvailable) {
        NSInteger readBytes = [_fileStream read: _tmpBuffer + _currentOffset maxLength: MAX_BUFFER_LEN - _currentOffset];
        _currentOffset += readBytes;
    }
    
    if(memcmp(_tmpBuffer, KStartCode, 4) != 0) {
        return nil;
    }
    
    if(_currentOffset >= 5) {
        uint8_t *bufferBegin = _tmpBuffer + 4;
        uint8_t *bufferEnd = _tmpBuffer + _currentOffset;
        while(bufferBegin != bufferEnd) {
            if(*bufferBegin == 0x01) {
                if(memcmp(bufferBegin - 3, KStartCode, 4) == 0) {
                    NSInteger packetSize = bufferBegin - _tmpBuffer - 3;
                    TTAVPacket *vp = [[TTAVPacket alloc] initWithSize:packetSize];
                    memcpy(vp.buffer, _tmpBuffer, packetSize);
                    
                    memmove(_tmpBuffer, _tmpBuffer + packetSize, _currentOffset - packetSize);
                    _currentOffset -= packetSize;
                    return vp;
                }
            }
            ++bufferBegin;
        }
    }

    return nil;
}

@end
