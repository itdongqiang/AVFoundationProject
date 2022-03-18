//
//  TTAVVideoCompositionTool.h
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/3/5.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    TransitionAnimationNone = 0,
    TransitionAnimationEaseInEaseOut,
    TransitionAnimation3,
    TransitionAnimation4,
} TransitionAnimationType;

typedef void (^CompositeVideoCompleteBlock)(AVMutableComposition *composition, AVMutableVideoComposition *videoComoposition, AVMutableAudioMix *audioMix, NSError *error);

@interface TTAVVideoCompositionTool : NSObject
+ (void)compositeVideoWithAssetArray:(NSArray <AVAsset *>*)assetArray transitionAnimation:(TransitionAnimationType)transitionAnimation bgAudioAsset:(nullable AVAsset *)bgAudioAsset complete:(CompositeVideoCompleteBlock)complete;

+ (void)compositeImageWithImageArray:(NSArray <UIImage *>*)imageArray stayTime:(CGFloat)stayTime transitionAnimation:(TransitionAnimationType)transitionAnimation bgAudioAsset:(nullable AVAsset *)bgAudioAsset complete:(CompositeVideoCompleteBlock)complete;


@end

NS_ASSUME_NONNULL_END
