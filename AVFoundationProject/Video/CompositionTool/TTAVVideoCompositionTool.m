//
//  TTAVVideoCompositionTool.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/3/5.
//

#import "TTAVVideoCompositionTool.h"

@implementation TTAVVideoCompositionTool
// 视频尺寸
#define TTAVVideoSize (CGSizeMake(1080, 1920))
#pragma mark - 合成视频
+ (void)compositeVideoWithAssetArray:(NSArray <AVAsset *>*)assetArray transitionAnimation:(TransitionAnimationType)transitionAnimationType bgAudioAsset:(nullable AVAsset *)bgAudioAsset filter:(BOOL)addFilter complete:(CompositeVideoCompleteBlock)complete{
    AVMutableComposition *composition = [AVMutableComposition composition];
    NSError *error;
    NSMutableArray<AVMutableCompositionTrack*>* videoCompositionTracks = [NSMutableArray array];
    NSMutableArray<AVAssetTrack*>* videoTracks = [NSMutableArray array];
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    NSMutableArray *audioMixArray = [NSMutableArray array];

    CMTime startTime = kCMTimeZero;
    CMTime duration = kCMTimeZero;
    
    // 滤镜暂时只处理第一个视频
    if (addFilter) {
        assetArray = @[assetArray.firstObject];
    }
    
    CMTime transTime = kCMTimeZero;
    if (transitionAnimationType != TransitionAnimationNone) {
        transTime = CMTimeMake(1, 2);
    }
    
    for (int i = 0; i < assetArray.count; i++) {
        // 插入音视频轨道
        AVAsset* asset = assetArray[i];
        CMTimeShow(asset.duration); // tdq
        
        AVAssetTrack* videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        AVAssetTrack* audioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        // 轨道插入音视频
        AVMutableCompositionTrack* videoCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        AVMutableCompositionTrack* audioCompositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        [videoCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:startTime error:nil];
        [audioCompositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:audioTrack atTime:startTime error:nil];
        [videoTracks addObject:videoTrack];
        
        // 音频mix配置
        AVMutableAudioMixInputParameters *audioTrackParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
        [audioTrackParameters setVolume:0.5 atTime:startTime];
        [audioMixArray addObject:audioTrackParameters];
        
        [videoCompositionTracks addObject:videoCompositionTrack];
        
        startTime = CMTimeAdd(startTime, asset.duration);
        startTime = CMTimeSubtract(startTime, transTime);
        
        duration = CMTimeAdd(duration, asset.duration);
        if (i != 0) {
            duration = CMTimeSubtract(duration, transTime);
        }
    };
    
    // bgm
    if (bgAudioAsset != nil) {
        AVMutableCompositionTrack *bgAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        AVAssetTrack *assetAudioTrack = [[bgAudioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        [bgAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, duration) ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];
        AVMutableAudioMixInputParameters *bgAudioTrackParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:bgAudioTrack];
        [bgAudioTrackParameters setVolume:0.03 atTime:kCMTimeZero];
        [audioMixArray addObject:bgAudioTrackParameters];
    }
    audioMix.inputParameters = audioMixArray;
    
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    if (addFilter) {
        AVAsset *asset = assetArray.firstObject;
        CGAffineTransform rotation = [self changeVideoSizeWithAsset:asset passThroughLayer:nil];

        videoComposition = [AVMutableVideoComposition videoCompositionWithAsset:asset applyingCIFiltersWithHandler:^(AVAsynchronousCIImageFilteringRequest * _Nonnull request) {
            CIImage *sourceImage = request.sourceImage;
            
            // 修正frame
            CIFilter *transformFilter = [CIFilter filterWithName:@"CIAffineTransform"];
            [transformFilter setValue:sourceImage forKey: kCIInputImageKey];
            [transformFilter setValue: [NSValue valueWithCGAffineTransform: rotation] forKey: kCIInputTransformKey];
            sourceImage = transformFilter.outputImage;
            CGRect extent = sourceImage.extent;
            CGAffineTransform translation = CGAffineTransformMakeTranslation(-extent.origin.x, -extent.origin.y);
            [transformFilter setValue:sourceImage forKey: kCIInputImageKey];
            [transformFilter setValue: [NSValue valueWithCGAffineTransform: translation] forKey: kCIInputTransformKey];
            sourceImage = transformFilter.outputImage;

            // 应用滤镜
            extent = sourceImage.extent;
            sourceImage = [sourceImage imageByClampingToExtent];
            CIFilter *filter = [CIFilter filterWithName:@"CIComicEffect"];
            [filter setValue:sourceImage forKey:kCIInputImageKey];
            sourceImage = filter.outputImage;
            sourceImage = [sourceImage imageByCroppingToRect:extent];
            
            // 修正方向问题
            CGFloat newHeight = 1920;
            CGFloat inset = (extent.size.height - newHeight) / 2;
            extent = CGRectInset(extent, 0, inset);
            sourceImage = [sourceImage imageByCroppingToRect:extent];

            CGFloat scale = 1920 / newHeight;
            CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
            [transformFilter setValue:sourceImage forKey: kCIInputImageKey];
            [transformFilter setValue: [NSValue valueWithCGAffineTransform: scaleTransform] forKey: kCIInputTransformKey];
            sourceImage = transformFilter.outputImage;

            translation = CGAffineTransformMakeTranslation(0, -inset * scale);
            [transformFilter setValue:sourceImage forKey: kCIInputImageKey];
            [transformFilter setValue: [NSValue valueWithCGAffineTransform: translation] forKey: kCIInputTransformKey];
            sourceImage = transformFilter.outputImage;

            [request finishWithImage:sourceImage context:nil];
        }];
        
    } else{
        videoComposition = [AVMutableVideoComposition videoCompositionWithPropertiesOfAsset:composition];
        videoComposition.instructions = @[[self createCompositionInstructionsWithCompositionVideoTracks:videoCompositionTracks assetTracks:videoTracks assets:assetArray totalDuration:duration transAnimationType:transitionAnimationType transTime:transTime]];
    }
    //设置分辨率
    CGSize renderSize = TTAVVideoSize;
    videoComposition.renderSize = renderSize;
    videoComposition.frameDuration = videoCompositionTracks[0].minFrameDuration;
    if (complete) {
        complete(composition, videoComposition, audioMix, error);
    }
}

// 创建AVMVideoCompositionInstruction
+ (AVMutableVideoCompositionInstruction *)createCompositionInstructionsWithCompositionVideoTracks:(NSArray *)compositionVideoTracks assetTracks:(NSArray<AVAssetTrack *> *)assetTracks assets:(NSArray<AVAsset *> *)assets totalDuration:(CMTime)totalDuration transAnimationType:(TransitionAnimationType)transAnimationType transTime:(CMTime)transTime{
    CMTimeRange atTime_end = kCMTimeRangeZero;
    __block CMTimeRange atTime_begin = kCMTimeRangeZero;
    CMTime duraton = kCMTimeZero;
    NSMutableArray* layerInstructions = [NSMutableArray array];
    // 视频
    AVMutableVideoCompositionInstruction *videoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    videoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
    
    for (int i = 0; i < compositionVideoTracks.count; i++) {
        AVMutableCompositionTrack *compositionTrack = compositionVideoTracks[i];
        AVAsset *asset = assets[i];
        AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionTrack];
        // 调整视频角度尺寸
        [self changeVideoSizeWithAsset:asset passThroughLayer:layerInstruction];
        // 处理过渡动画
        duraton = CMTimeAdd(duraton, asset.duration);
        if (compositionVideoTracks.count > 1) {
            switch (transAnimationType) {
                case TransitionAnimationNone:
                { // 无过渡
                    atTime_end =  CMTimeRangeMake(duraton, transTime);
                    if (i != compositionVideoTracks.count - 1) {
                        [layerInstruction setOpacity:0 atTime:atTime_end.start];
                    }
                }
                    break;
                case TransitionAnimationEaseInEaseOut:
                { // 淡入淡出
                    atTime_begin = atTime_end;
                    atTime_end =  CMTimeRangeMake(CMTimeAdd(CMTimeSubtract(atTime_end.start, transTime), asset.duration), transTime);
                    CMTimeRangeShow(atTime_begin);
                    CMTimeRangeShow(atTime_end);
                    if (i == 0) {
                        [layerInstruction setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:atTime_end];
                    } else if (i == compositionVideoTracks.count - 1) {
                        [layerInstruction setOpacityRampFromStartOpacity:0.0 toEndOpacity:1.0 timeRange:atTime_begin];
                    } else{
                        [layerInstruction setOpacityRampFromStartOpacity:1.0 toEndOpacity:0.0 timeRange:atTime_end];
                        [layerInstruction setOpacityRampFromStartOpacity:0.0 toEndOpacity:1.0 timeRange:atTime_begin];
                    }
                }
                default:
                    break;
            }
        }
        [layerInstructions addObject:layerInstruction];
    }
    videoCompositionInstruction.layerInstructions = layerInstructions;
    
    return videoCompositionInstruction;
}

// 调整视频角度尺寸
+ (CGAffineTransform)changeVideoSizeWithAsset:(AVAsset *)asset passThroughLayer:(AVMutableVideoCompositionLayerInstruction *)passThroughLayer {
    AVAssetTrack *videoAssetTrack = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
    if (videoAssetTrack == nil) {
        return CGAffineTransformIdentity;
    }
    CGSize naturalSize = videoAssetTrack.naturalSize;
    if ([TTAVVideoCompositionTool videoDegressWithVideoAsset:asset] == 90) {
        naturalSize = CGSizeMake(naturalSize.height, naturalSize.width);
    }
    if ((int)naturalSize.width % 2 != 0) {
        naturalSize = CGSizeMake(naturalSize.width + 1.0, naturalSize.height);
    }
    CGSize videoSize = TTAVVideoSize;
    if ([TTAVVideoCompositionTool videoDegressWithVideoAsset:asset] == 90) {
        CGFloat height = videoSize.width * naturalSize.height / naturalSize.width;
        CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(videoSize.width, videoSize.height/2.0 - height/2.0);
        CGAffineTransform scaleTransform = CGAffineTransformScale(translateToCenter, videoSize.width/naturalSize.width, height/naturalSize.height);
        CGAffineTransform mixedTransform = CGAffineTransformRotate(scaleTransform, M_PI_2);
        [passThroughLayer setTransform:mixedTransform atTime:kCMTimeZero];
        return  scaleTransform;
    } else {
        CGFloat height = videoSize.width * naturalSize.height / naturalSize.width;
        CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(0, videoSize.height/2.0 - height/2.0);
        CGAffineTransform scaleTransform = CGAffineTransformScale(translateToCenter, videoSize.width/naturalSize.width, height/naturalSize.height);
        [passThroughLayer setTransform:scaleTransform atTime:kCMTimeZero];
        return  scaleTransform;
    }
}

// 获取视频角度
+ (NSInteger)videoDegressWithVideoAsset:(AVAsset *)videoAsset {
    NSInteger videoDegress = 0;
    NSArray *assetVideoTracks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
    if (assetVideoTracks.count > 0) {
        AVAssetTrack *videoTrack = assetVideoTracks.firstObject;
        CGAffineTransform affineTransform = videoTrack.preferredTransform;
        if(affineTransform.a == 0 && affineTransform.b == 1.0 && affineTransform.c == -1.0 && affineTransform.d == 0){
            videoDegress = 90;
        }else if(affineTransform.a == 0 && affineTransform.b == -1.0 && affineTransform.c == 1.0 && affineTransform.d == 0){
            videoDegress = 270;
        }else if(affineTransform.a == 1.0 && affineTransform.b == 0 && affineTransform.c == 0 && affineTransform.d == 1.0){
            videoDegress = 0;
        }else if(affineTransform.a == -1.0 && affineTransform.b == 0 && affineTransform.c == 0 && affineTransform.d == -1.0){
            videoDegress = 180;
        }
    }
    return videoDegress;
}

#pragma mark - 图片转视频
+ (void)compositeImageWithImageArray:(NSArray <UIImage *>*)imageArray stayTime:(CGFloat)stayTime transitionAnimation:(TransitionAnimationType)transitionAnimation bgAudioAsset:(nullable AVAsset *)bgAudioAsset complete:(CompositeVideoCompleteBlock)complete{
    AVMutableComposition *composition = [AVMutableComposition composition];
    NSError *error;
    AVMutableAudioMix *audioMix = nil;
    CGFloat animationTime = 0.5 * (transitionAnimation != TransitionAnimationNone);
    CGFloat totalDuration = imageArray.count * stayTime;
    NSString* blackPath = [[NSBundle mainBundle] pathForResource:@"black" ofType:@"mp4"];
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:blackPath]];
    AVMutableCompositionTrack *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime endTime = CMTimeMake(asset.duration.timescale * (CGFloat)totalDuration, asset.duration.timescale);
    CMTimeRange timeRange = CMTimeRangeMake(kCMTimeZero, endTime);
    AVAssetTrack *assetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    [compositionTrack insertTimeRange:timeRange ofTrack:assetTrack atTime:kCMTimeZero error:&error];
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = timeRange;
    AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionTrack];
    [layerInstruction setTransform:assetTrack.preferredTransform atTime:kCMTimeZero];
    [layerInstruction setOpacity:0 atTime:endTime];
    instruction.layerInstructions = @[layerInstruction];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = TTAVVideoSize;
    videoComposition.frameDuration = CMTimeMake(1, 30);
    videoComposition.instructions = @[instruction];
    
    CALayer *bgLayer = [CALayer layer];
    CGSize size = TTAVVideoSize;
    bgLayer.frame = CGRectMake(0, 0, size.width, size.height);
    bgLayer.position = CGPointMake(size.width / 2, size.height / 2);
    NSMutableArray *layers = [NSMutableArray array];
    for (int i = 0;i < imageArray.count; i++) {
        CALayer *imageLayer = [CALayer layer];
        UIImage *image = imageArray[i];
        imageLayer.contents = (__bridge id)image.CGImage;
        imageLayer.bounds = CGRectMake(0, 0, size.width, size.height);
        imageLayer.contentsGravity = kCAGravityResizeAspect;
        imageLayer.backgroundColor = [[UIColor blackColor] CGColor];
        imageLayer.anchorPoint = CGPointMake( 0, 0);
        [bgLayer addSublayer:imageLayer];
        [layers addObject:imageLayer];
        if (i == 0) {
            continue;
        }
        CABasicAnimation *animation = [CABasicAnimation animation];
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.removedOnCompletion = false;
        animation.beginTime = stayTime * i + animationTime;
        animation.duration = animationTime;
        animation.fillMode = kCAFillModeBoth;
        
        switch (transitionAnimation) {
            case TransitionAnimationNone:
            {
                animation.fromValue = @YES;
                animation.toValue = @NO;
                [imageLayer addAnimation:animation forKey:@"hidden"];
            }
                break;
            case TransitionAnimationEaseInEaseOut:
            {
                animation.fromValue = [NSValue valueWithCGPoint:CGPointMake(size.width * i, 0)];
                animation.toValue = [NSValue valueWithCGPoint:CGPointMake(0, 0)];
                [imageLayer addAnimation:animation forKey:@"position"];
            }
                break;
            default:
                break;
        }
    }
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:bgLayer];
    parentLayer.geometryFlipped = YES;
    videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
    // bgm
    if (bgAudioAsset != nil) {
        audioMix = [AVMutableAudioMix audioMix];
        NSMutableArray *audioMixArray = [NSMutableArray array];
        AVMutableCompositionTrack *bgAudioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        AVAssetTrack *assetAudioTrack = [[bgAudioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0];
        [bgAudioTrack insertTimeRange:timeRange ofTrack:assetAudioTrack atTime:kCMTimeZero error:nil];
        AVMutableAudioMixInputParameters *bgAudioTrackParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:bgAudioTrack];
        [bgAudioTrackParameters setVolume:0.03 atTime:kCMTimeZero];
        [audioMixArray addObject:bgAudioTrackParameters];
        audioMix.inputParameters = audioMixArray;
    }
    
    if (complete) {
        complete(composition, videoComposition, audioMix, error);;
    }
}



@end
