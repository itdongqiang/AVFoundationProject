//
//  TTAVOpenCVSampleBasic.m
//  AVFoundationProject
//
//  Created by 唐东强 on 2022/7/11.
//

#import "TTAVOpenCVSampleBasicTool.h"
#include "opencv2/core.hpp"
#include "opencv2/imgproc.hpp"
#include "opencv2/imgcodecs/ios.h"

using namespace std;
using namespace cv;

@implementation TTAVOpenCVSampleBasicTool

// 灰度化
+ (UIImage *)ImageToGrayImage:(UIImage *)image {
    Mat origin, grayImageMat;
    UIImageToMat(image, origin);
    cvtColor(origin, grayImageMat, COLOR_BGR2GRAY);
    UIImage *grayImage = MatToUIImage(grayImageMat);
    return grayImage;
}

// ROI合并
+ (UIImage *)mergeImage:(UIImage *)image byROI:(UIImage *)logo {
    Mat imageMat, logoMat;
    UIImageToMat(image, imageMat);
    UIImageToMat(logo, logoMat);
    Mat roi(imageMat, cv::Rect(imageMat.cols - logoMat.cols, 0, logoMat.cols, logoMat.rows));
    logoMat.copyTo(roi);
    return MatToUIImage(imageMat);
}

// 高斯滤波 边缘处理
+ (UIImage *)GaussianBlurAndCannyImage:(UIImage *)image apertureSize:(int)apertureSize{
    Mat imageMat, grayMat;
    UIImageToMat(image, imageMat);
    cvtColor(imageMat, grayMat,COLOR_BGR2GRAY);
    // 应用高斯滤波器去除小的边缘
    GaussianBlur(grayMat, grayMat, cv::Size(5, 5), 1.2, 1.2);
    Mat edges;
    /*
     第1个参数，InputArray类型的image，输入图像，即源图像，填Mat类的对象即可，且需为单通道8位图像。
     第2个参数，OutputArray类型的edges，输出的边缘图，需要和源图片有一样的尺寸和类型。
     第3个参数，double类型的threshold1，第一个滞后性阈值。
     第4个参数，double类型的threshold2，第二个滞后性阈值。
     第5个参数，int类型的apertureSize，表示应用Sobel算子的孔径大小，其有默认值3。 Aperture size should be odd between 3 and      7 in function Canny
     */
    Canny(grayMat, edges, 100, 200, apertureSize);
    // 使用白色填充
    imageMat.setTo(Scalar::all(0));
    // 修改边缘颜色
    imageMat.setTo(Scalar(255,188,125,255),edges);
    return MatToUIImage(imageMat);
}

// 阈值化
+ (UIImage *)adaptiveThresholdImage:(UIImage *)image {
    Mat origin, grayImageMat, dstImage;
    UIImageToMat(image, origin);
    cvtColor(origin, grayImageMat, COLOR_BGRA2GRAY);
    /*
     第1个参数，输入图像
     第2个参数，输出图像
     第3个参数，使用 CV_THRESH_BINARY 和 CV_THRESH_BINARY_INV 的最大值
     第4个参数，自适应阈值算法使用：CV_ADAPTIVE_THRESH_MEAN_C 或 CV_ADAPTIVE_THRESH_GAUSSIAN_C
     第5个参数，取阈值类型：CV_THRESH_BINARY/CV_THRESH_BINARY_INV
     第6个参数，用来计算阈值的象素邻域大小: 3, 5, 7, ...
     第7个参数，从平均值减去常数或加权平均值，通常它是正的，但也可能是零或负的。
     */
    cv::adaptiveThreshold(grayImageMat,dstImage, 255, ADAPTIVE_THRESH_MEAN_C, THRESH_BINARY, 3, 1);
    UIImage *grayImage = MatToUIImage(dstImage);
    return grayImage;
}

// 添加马赛克
+(UIImage *)mosaicsToImage:(UIImage *)image level:(int)level {
    //实现功能
    //第一步：将iOS图片转换为openCV图片（Mat矩阵）
    Mat mat_image_src;
    UIImageToMat(image, mat_image_src);

    //第二步：确定宽高
    int width = mat_image_src.cols;
    int height = mat_image_src.rows;

    //将ARGB转换为RGB
    Mat mat_image_dst;
    cvtColor(mat_image_src,mat_image_dst,COLOR_RGBA2RGB,3);

    //克隆一张图片 为了不影响原始图片
    Mat mat_image_clone = mat_image_dst.clone();
    //第三步：马赛克处理
    //分析马赛克算法原理
    //level => 3*3矩形
    //我们可以设置level 进行动态处理
    int x= width - level;
    int y = height - level;

    //一个矩形一个矩形去处理
    for (int i = 0; i < y; i += level) {
        for (int j = 0; j < x; j += level) {
            //创建矩形区域
            Rect2i mosaicsRect = Rect2i(j,i,level,level);
            //原始数据：给Rect2i区域->填充数据
            Mat roi = mat_image_dst(mosaicsRect);

            //让整个Rect2i区域颜色值保持一致
            //mat_image_clone.at<Vec3b>(i,j) ->像素点(颜色值组成-》多个) ->ARGB ->数组
            //mat_image_clone.at<Vec3b>(i,j)[0] R值
            //mat_image_clone.at<Vec3b>(i,j)[1] G值
            //mat_image_clone.at<Vec3b>(i,j)[2] B值
            Scalar scalar = Scalar(
                   mat_image_clone.at<Vec3b>(i,j)[0],
                   mat_image_clone.at<Vec3b>(i,j)[1],
                   mat_image_clone.at<Vec3b>(i,j)[2]);
            //修改后的数据：将处理好的矩形区域->数据->拷贝到图片上
            //CV_8UC3
            //CV_表示:框架的命名空间
            //8表示:每个颜色值是8位
            //U表示:有符号类型(sign -> 有正负 ->简写"S") -128->127、无符号类型(Unsign->只有正数 ->简写"U") 0->255
            //C表示:char类型
            //3表示：3个通道 RGB
            Mat roiCopy = Mat(mosaicsRect.size(),CV_8UC3,scalar);
            roiCopy.copyTo(roi);
        }
    }
    //第四步：将OpenCV格式图片转换为iOS图片格式
    return MatToUIImage(mat_image_dst);
}

// 修正方向
+ (UIImage *)scaleAndRotateImageBackCamera:(UIImage *)image
{
    static int kMaxResolution = 640;
    
    CGImageRef imgRef = image.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    if (width > kMaxResolution || height > kMaxResolution) {
        CGFloat ratio = width/height;
        if (ratio > 1) {
            bounds.size.width = kMaxResolution;
            bounds.size.height = bounds.size.width / ratio;
        } else {
            bounds.size.height = kMaxResolution;
            bounds.size.width = bounds.size.height * ratio;
        }
    }
    
    CGFloat scaleRatio = bounds.size.width / width;
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
    CGFloat boundHeight;
    
    UIImageOrientation orient = image.imageOrientation;
    switch(orient) {
        case UIImageOrientationUp:
            transform = CGAffineTransformIdentity;
            break;
        case UIImageOrientationUpMirrored:
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
        case UIImageOrientationDown:
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
        case UIImageOrientationLeftMirrored:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationLeft:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationRightMirrored:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        case UIImageOrientationRight:
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        default:
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
    }
    
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    } else {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return returnImage;
}


@end
