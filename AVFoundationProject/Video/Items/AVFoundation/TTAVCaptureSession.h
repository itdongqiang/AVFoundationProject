//
//  TTAVCaptureSession.h
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/7/4.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol TTAVCaptureSessionDelegate <NSObject>

- (void)captureSession:(AVCaptureSession *)captureSession
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

@interface TTAVCaptureSession : NSObject
@property (nonatomic ,strong) id<TTAVCaptureSessionDelegate>delegate;
@property (nonatomic ,strong) AVCaptureSession *session; //管理对象

- (void)startRunning;

- (void)stopRunning;


@end

NS_ASSUME_NONNULL_END
