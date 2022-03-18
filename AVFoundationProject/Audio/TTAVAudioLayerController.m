//
//  TTAVAudioLayerController.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/3/3.
//

#import "TTAVAudioLayerController.h"
#import <AVFoundation/AVFoundation.h>

@interface TTAVAudioLayerController ()<AVAudioPlayerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UIButton *btnStop;
@property (weak, nonatomic) IBOutlet UIButton *btnPause;
@property (weak, nonatomic) IBOutlet UIProgressView *musicProgress;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;

@property(nonatomic,strong) AVAudioPlayer *player;
@property(nonatomic,strong) NSTimer *timer;
@end

@implementation TTAVAudioLayerController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self test];
    [self createAVAudioPlayer];
}

- (void)test{
    NSString *pathStr = [[NSBundle mainBundle] pathForResource:@"hdr" ofType:@"MOV"];
    NSURL *url = [NSURL fileURLWithPath:pathStr];
    AVAsset *asset = [AVAsset assetWithURL:url];
    [asset loadValuesAsynchronouslyForKeys:@[@"duration", @"tracks"] completionHandler:^{
        NSError *error;
        AVKeyValueStatus status_duration = [asset statusOfValueForKey:@"duration" error:&error];
        if (status_duration == AVKeyValueStatusLoaded) {
            CMTimeShow(asset.duration);
        }
        
        AVKeyValueStatus status_tracks = [asset statusOfValueForKey:@"tracks" error:&error];
        if (status_tracks == AVKeyValueStatusLoaded) {
            NSLog(@"%@", asset.tracks);
            AVAssetTrack *video_track = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
            CMVideoFormatDescriptionRef kaka = CFBridgingRetain(video_track.formatDescriptions.firstObject);
            NSLog(@"%@", kaka); // CVImageBufferTransferFunction = \"ITU_R_2100_HLG\"
            NSLog(@"%lld", video_track.totalSampleDataLength);
            NSLog(@"%d", [video_track hasMediaCharacteristic: AVMediaCharacteristicContainsHDRVideo]);
            for (AVAssetTrackSegment *seg in video_track.segments) {
                NSLog(@"%@", seg);
            }
        }
    }];
    
    
}

-(void)createAVAudioPlayer{
    NSString *pathStr = [[NSBundle mainBundle] pathForResource:@"夜空中最亮的星" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:pathStr];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [_player prepareToPlay];
    _player.volume = 0.5;
    _player.numberOfLoops = 0;
    _player.delegate = self;
    if (_player.enableRate) {
        _player.rate = 2.0;
    }
    [_player setRate:2.0];
    _player.pan = 0; /* set panning. -1.0 is left, 0.0 is center, 1.0 is right. */
}

- (IBAction)play:(id)sender {
    _timer =[NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(updateProgress) userInfo:nil repeats:YES];
    //开始播放
    [_player play];
    _musicProgress.progress = _player.currentTime / _player.duration;
    _volumeSlider.value = _player.volume;
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error{
    NSLog(@"audioPlayerDecodeErrorDidOccur %@", error.localizedDescription);
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag{
    [self stop:nil];
}

-(void)updateProgress{
    _musicProgress.progress = _player.currentTime / _player.duration;
}

- (IBAction)pause:(id)sender {
    [_player pause];
}
- (IBAction)stop:(id)sender {
    [_player stop];
    _player.currentTime = 0;
    _musicProgress.progress = 0;
    [_timer invalidate];
}
- (IBAction)volumeChange:(UISlider *)slider {
    _player.volume = slider.value;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
