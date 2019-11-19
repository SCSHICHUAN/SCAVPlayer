//
//  Thumbnail.m
//  CloudEye
//
//  Created by iOS-PointCompany on 16/9/12.
//  Copyright © 2016年 SHICHUAN. All rights reserved.
//

#import "Thumbnail.h"

@implementation Thumbnail


+(UIImage *)imageWithCaptureView:(CALayer *)layer
{
    //开启上下文
    UIGraphicsBeginImageContextWithOptions(layer.bounds.size, NO, 0.0f);
    
    //获取上下文
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    //渲染控制器的view的图层到上下文
    //图层只能用render（渲染） 不能用draw（画）
    [layer renderInContext:ctx];
    
    //获取截屏图片
    UIImage *thumbnailImage = UIGraphicsGetImageFromCurrentImageContext();
    //关闭上下文
    UIGraphicsEndImageContext();
    
    return thumbnailImage;
}


@end
