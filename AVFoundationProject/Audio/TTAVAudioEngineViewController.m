//
//  TTAVAudioEngineViewController.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/3/3.
//

#import "TTAVAudioEngineViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface TTAVAudioEngineViewController ()

@property(strong, nonatomic) AVAudioEngine *audioEngine;
@property(strong, nonatomic) AVAudioEngine *audioPlayEngine;
@property(nonatomic, strong) AVAudioFile *file;
@property(nonatomic, strong) dispatch_queue_t audioQueue;
@property(nonatomic, strong)AVAudioPlayerNode* player;

@end

@implementation TTAVAudioEngineViewController
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupEngine];
}
- (IBAction)play:(id)sender {
    _audioPlayEngine = [[AVAudioEngine alloc]init];
    _audioPlayEngine.autoShutdownEnabled = YES;
    _player = [[AVAudioPlayerNode alloc]init];
    [self.audioPlayEngine attachNode:self.player];
    [self.audioPlayEngine connect:self.player to:self.audioPlayEngine.outputNode format:[self.player outputFormatForBus:0]];
    NSError* error;
    BOOL isSuccess = [self.audioPlayEngine startAndReturnError:&error];
    if (error) {
        NSLog(@"error = %@",error.localizedDescription);
        return;
    }
    if (!isSuccess) {
        return;
    }
    [self.player scheduleFile:self.file atTime:nil completionHandler:^{
        NSLog(@"播放完成");
    }];
    [self.player play];
}

- (void)viewWillDisappear:(BOOL)animated{
    [self.audioPlayEngine stop];
}

- (void)setupEngine
{
    self.audioEngine = [[AVAudioEngine alloc] init];
    self.audioQueue = dispatch_queue_create("com.resample.test", 0);
    double sampleRate = 48000;
    float ioBufferDuration = 0.1;
    int bit = 16;
    
    AVAudioSession *audiosession = [AVAudioSession sharedInstance];
    [audiosession setPreferredSampleRate:sampleRate error:nil];
    [audiosession setPreferredIOBufferDuration:ioBufferDuration error:nil];
    [audiosession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    
    AVAudioInputNode *inputNode = _audioEngine.inputNode;
    NSDictionary *settingTmp =[_audioEngine.inputNode inputFormatForBus:0].settings;
    NSMutableDictionary *setting = [NSMutableDictionary dictionaryWithDictionary:settingTmp];
    [setting setObject:[NSNumber numberWithInt:bit] forKey:AVLinearPCMBitDepthKey];
    [setting setObject:[NSNumber numberWithDouble:sampleRate] forKey:AVSampleRateKey];
    [setting setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    
    // 录音信息
    AVAudioFormat *newFormat = [[AVAudioFormat alloc] initWithSettings:setting];
    
    // 重采样信息
    AVAudioFormat *resampleFormat = [[AVAudioFormat alloc] initWithCommonFormat:AVAudioPCMFormatInt16 sampleRate:16000 channels:1 interleaved:false];
    AVAudioConverter *formatConverter = [[AVAudioConverter alloc] initFromFormat:newFormat toFormat:resampleFormat];
    
    [inputNode installTapOnBus:0 bufferSize:(AVAudioFrameCount)0.1*sampleRate format:newFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        dispatch_async(self.audioQueue, ^{
            AVAudioPCMBuffer *pcmBuffer = [[AVAudioPCMBuffer alloc] initWithPCMFormat:resampleFormat frameCapacity:(AVAudioFrameCount)1600];
            NSError *conversionError = nil;
            AVAudioConverterOutputStatus conversionStatus = [formatConverter convertToBuffer:pcmBuffer error:&conversionError withInputFromBlock:^AVAudioBuffer * _Nullable(AVAudioPacketCount inNumberOfPackets, AVAudioConverterInputStatus * _Nonnull outStatus) {
                *outStatus = AVAudioConverterInputStatus_HaveData;
                return buffer;
            }];
            if (conversionStatus == AVAudioConverterOutputStatus_HaveData) {
                if (!self.file) {
                    [self initAVAudioFileWithPCMBuffer:pcmBuffer];
                }
                NSError *error;
                [self.file writeFromBuffer:pcmBuffer error:&error];
                if (error){
                    NSLog(@"writebuffererror =%@",error);
                }
                NSLog(@"打印输出PCMBuffer:%@",pcmBuffer);
            }
        });
        
    }];
    
}

- (IBAction)btnStartAction:(id)sender
{
    NSError* error;
    BOOL isSuccess = [self.audioEngine startAndReturnError:&error];
    if (error) {
        NSLog(@"error = %@",error.localizedDescription);
        return;
    }
    if (!isSuccess) {
        return;
    }
}

- (IBAction)btnStopAction:(id)sender
{
    [self.audioEngine stop];
    [self.audioEngine.inputNode removeTapOnBus:0];
    NSLog(@"filePath == %@", _file.url);
}

- (void)initAVAudioFileWithPCMBuffer:(AVAudioPCMBuffer *)pcmBuffer {
    
    NSString* filePath = [self createFilePath];
    
    NSMutableDictionary *setting = [NSMutableDictionary dictionaryWithDictionary:pcmBuffer.format.settings];
    [setting setObject:[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsNonInterleaved];

    NSLog(@"打印参数设置:%@",pcmBuffer.format.settings);
    _file = [[AVAudioFile alloc] initForWriting:[NSURL fileURLWithPath:filePath] settings:setting commonFormat:AVAudioPCMFormatInt16 interleaved:false error:nil];
    NSLog(@"fileFormat = %@",_file.fileFormat);
    NSLog(@"length = %lld",_file.length);
}

- (NSString *)createFilePath {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy_MM_dd__HH_mm_ss";
    NSString *date = [dateFormatter stringFromDate:[NSDate date]];
    
    NSArray *searchPaths    = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                  NSUserDomainMask,
                                                                  YES);
    
    NSString *documentPath  = [[searchPaths objectAtIndex:0] stringByAppendingPathComponent:@"Audio"];
    
    // 先创建子目录. 注意,若果直接调用AudioFileCreateWithURL创建一个不存在的目录创建文件会失败
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:documentPath]) {
        [fileManager createDirectoryAtPath:documentPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSString *fullFileName  = [NSString stringWithFormat:@"%@.caf",date];
    NSString *filePath      = [documentPath stringByAppendingPathComponent:fullFileName];
    return filePath;
}
@end
