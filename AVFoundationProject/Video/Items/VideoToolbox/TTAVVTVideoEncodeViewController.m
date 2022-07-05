//
//  TTAVVTVideoEncodeViewController.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/7/4.
//

#import "TTAVVTVideoEncodeViewController.h"
#import "TTAVVideoEncode.h"

@interface TTAVVTVideoEncodeViewController ()<TTAVCaptureSessionDelegate>

@property (nonatomic, strong) TTAVCaptureSession *captureSession;
@property (nonatomic, strong) TTAVVideoEncode *videEncoder;
@property (weak, nonatomic) IBOutlet UIButton *recorderButton;
@property (nonatomic, assign) BOOL isRecording;

@end

@implementation TTAVVTVideoEncodeViewController

- (instancetype)init{
    return [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TTAVVTVideoEncodeViewController"];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 视频编码器
    _videEncoder = [[TTAVVideoEncode alloc] init];
    //创建音视频采集会话
    _captureSession = [[TTAVCaptureSession alloc] init];
    //采集代理
    _captureSession.delegate = self;
    
    AVCaptureVideoPreviewLayer *preViewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession.session];
    //创建视频展示layer
    preViewLayer.frame = CGRectMake(0.f, 0.f, self.view.bounds.size.width, self.view.bounds.size.height);
    // 设置layer展示视频的方向
    preViewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer insertSublayer:preViewLayer atIndex:0];
}

// 开始采集并编码
- (IBAction)startRecording:(UIButton *)sender {
    if ([self checkDeviceTypeInvalid]) {
        return;
    }
    if (self.isRecording) {
        [self.captureSession stopRunning];
        [_videEncoder closefile];
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [_videEncoder openfile];
        [self.captureSession startRunning];
        [sender setTitle:@"结束录制" forState:UIControlStateNormal];
    }
    self.isRecording = !self.isRecording;
}

// 采集回调
- (void)captureSession:(AVCaptureSession *)captureSession didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [_videEncoder encodeSmapleBuffer:sampleBuffer];
}

@end
