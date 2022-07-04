//
//  TTAVCaptureSession.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/7/4.
//

#import "TTAVCaptureSession.h"

@interface TTAVCaptureSession()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic ,strong) AVCaptureDevice *videoDevice; //设备
@property (nonatomic ,strong) AVCaptureDeviceInput *videoInput;//输入对象
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;//输出对象

@end
@implementation TTAVCaptureSession

- (instancetype)init{
    if ([super init]) {
        [self initAVcaptureSession];
    }
    return self;
}

- (void)initAVcaptureSession {
    
    //初始化AVCaptureSession
    _session = [[AVCaptureSession alloc] init];
    // 设置录像分辨率
    if ([self.session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        [self.session setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    
    //开始配置
    [_session beginConfiguration];
    
    AVCaptureDeviceDiscoverySession *captureDeviceDiscoverySession = [AVCaptureDeviceDiscoverySession  discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInWideAngleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionFront];
    self.videoDevice = captureDeviceDiscoverySession.devices.lastObject;
    //初始化视频捕获输入对象
    NSError *error;
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.videoDevice error:&error];
    if (error) {
        NSLog(@"摄像头错误");
        return;
    }
    //输入对象添加到Session
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    //输出对象
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    //是否卡顿时丢帧
    self.videoOutput.alwaysDiscardsLateVideoFrames = NO;
    // 设置像素格式
    [self.videoOutput setVideoSettings:@{
                                         (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
                                         }];
    //将输出对象添加到队列、并设置代理
    dispatch_queue_t captureQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    [self.videoOutput setSampleBufferDelegate:self queue:captureQueue];
    
    // 判断session 是否可添加视频输出对象
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
    }
    //创建连接  AVCaptureConnection输入对像和捕获输出对象之间建立连接。
    AVCaptureConnection *connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    //视频的方向
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    //设置稳定性，判断connection连接对象是否支持视频稳定
    if ([connection isVideoStabilizationSupported]) {
        //这个稳定模式最适合连接
        connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    //缩放裁剪系数
    connection.videoScaleAndCropFactor = connection.videoMaxScaleAndCropFactor;
    [self.session commitConfiguration];

}

- (void)startRunning {
    [self.session startRunning];
}
- (void)stopRunning {
    [self.session stopRunning];
}
- (void)captureOutput:(AVCaptureOutput *)captureOutput
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    if (captureOutput == self.videoOutput) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(captureSession:didOutputSampleBuffer:)]) {
            [self.delegate captureSession:self.session didOutputSampleBuffer:sampleBuffer];
        }
    }
}

@end
