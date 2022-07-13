//
//  TTAVOpenCVSampleBasic.h
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/7/11.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTAVOpenCVSampleBasicTool : NSObject

// 灰度化
+ (UIImage *)ImageToGrayImage:(UIImage *)image;

// ROI合并
+ (UIImage *)mergeImage:(UIImage *)image byROI:(UIImage *)logo;


/** 高斯滤波 边缘处理
    apertureSize：孔径尺寸
 */
+ (UIImage *)GaussianBlurAndCannyImage:(UIImage *)image apertureSize:(int)apertureSize;

// 阈值化
+ (UIImage *)adaptiveThresholdImage:(UIImage *)image;

// 添加马赛克
+(UIImage *)mosaicsToImage:(UIImage *)image level:(int)level;

// 修正方向
+ (UIImage *)scaleAndRotateImageBackCamera:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
