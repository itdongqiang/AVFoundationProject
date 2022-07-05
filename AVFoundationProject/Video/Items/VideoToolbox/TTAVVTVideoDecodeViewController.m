//
//  TTAVVTVideoDecodeViewController.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/7/4.
//

#import "TTAVVTVideoDecodeViewController.h"
#import "TTAVVideoFileReader.h"
#import "TTAVVideoDecoder.h"

@interface TTAVVTVideoDecodeViewController ()<TTAVVideoDecoderDelegate>
{
    TTAVVideoFileReader *_fileReader;
    TTAVVideoDecoder *_decoder;
    NSMutableArray<UIImage *> *_imgs;
    CADisplayLink *_dis;
    int _decodedFrameCount;
    int _playFrameIndex;
    CIContext *_ctx;
    int displaylink_times;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation TTAVVTVideoDecodeViewController

- (instancetype)init{
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TTAVVTVideoDecodeViewController"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _imgs = [NSMutableArray array];
    _decodedFrameCount = 0;
    _ctx = [CIContext context];
    
    NSString *file = [NSString stringWithFormat:@"%@/video.h264", [(NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES)) objectAtIndex:0]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:file]) {
        file = [[NSBundle mainBundle] pathForResource:@"video" ofType:@".h264"];
        NSLog(@"没有采集编码的文件，已使用本地文件进行解码");
    }
    // 构造 H264 文件读取器
    _fileReader = [[TTAVVideoFileReader alloc] initWithH264File: file];
    
    // 构造 H264 解码器
    _decoder = [TTAVVideoDecoder new];
    _decoder.delegate = self;
}

#pragma mark - TTAVVideoDecoderDelegate 解码回调

- (void)onBufferDecoded:(TTAVVideoDecoder *)decoder buffer:(CVPixelBufferRef)buffer {
    _decodedFrameCount++;
    NSLog(@"解码中... current count: %d", _decodedFrameCount);
    if (buffer) {
        CIImage *ciImage = [CIImage imageWithCVPixelBuffer: buffer];
        CGRect rect = CGRectMake(0, 0, CVPixelBufferGetWidth(buffer), CVPixelBufferGetHeight(buffer));
        CGImageRef cgImage = [_ctx createCGImage: ciImage fromRect: rect];
        UIImage *img = [UIImage imageWithCGImage: cgImage scale: 0 orientation: UIImageOrientationUp];
        [_imgs addObject: img];
    }
}

#pragma mark - 播放
- (void)play {
    displaylink_times++;
    if (_playFrameIndex >= _imgs.count) {
        [_dis invalidate];
        _dis = nil;
        return;
    }
    if (displaylink_times % 2 == 0) {
        _imageView.image = _imgs[_playFrameIndex];
        _playFrameIndex++;
    }
}

- (IBAction)decodeAndReder:(id)sender {
    if([self checkDeviceTypeInvalid]) {
        return;
    }
    // 子线程读取 & 解码
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        // 循环从 H264 文件中读取 packet（内部以 startCode 分割）
        TTAVPacket *currentPacket = [self->_fileReader nextPacket];
        while (currentPacket != nil) {
            [self->_decoder decode: currentPacket]; // 1. 解码
            currentPacket = [self->_fileReader nextPacket]; // 2. 读取下一个 packet
        }
        
        // 读取结束，返回主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            self->_playFrameIndex = 0;
            self->_dis = [CADisplayLink displayLinkWithTarget: self selector: @selector(play)];
            [self->_dis addToRunLoop: [NSRunLoop currentRunLoop] forMode: NSRunLoopCommonModes];
        });
    });
}

@end
