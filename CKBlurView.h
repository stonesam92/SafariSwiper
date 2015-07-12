//
//  CKBlurView.h
//  CKBlurView
//
//  Created by Conrad Kramer on 10/25/13.
//  Copyright (c) 2013 Kramer Software Productions, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const CKBlurViewQualityDefault;

extern NSString * const CKBlurViewQualityLow;

NS_CLASS_AVAILABLE_IOS(7_0) @interface CKBlurView : UIView

/**
 Quality of the blur. The lower the quality, the more performant the blur. Must be one of `CKBlurViewQualityDefault` or `CKBlurViewQualityLow`. Defaults to `CKBlurViewQualityDefault`.
 */
@property (assign, nonatomic) NSString *blurQuality;

/**
 Radius of the Gaussian blur. Defaults to 5.0.
 */
@property (assign, nonatomic) CGFloat blurRadius;

/**
 Bounds to be blurred, in the receiver's coordinate system. Defaults to CGRectNull.
 */
@property (assign ,nonatomic) CGRect blurCroppingRect;

/**
 Boolean indicating whether the edge of the view should be softened. Defaults to YES.
 */
@property (assign, nonatomic) BOOL blurEdges;

@end
