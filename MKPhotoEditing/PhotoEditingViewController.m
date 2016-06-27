//
//  PhotoEditingViewController.m
//  MKPhotoEditing
//
//  Created by DONLINKS on 16/6/23.
//  Copyright © 2016年 Donlinks. All rights reserved.
//

#import "PhotoEditingViewController.h"
#import "MKImageUtil.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>

NSString *formatIdentifier = @"cn.mkapple.MKPhotoEditingExtension";
NSString *formatVersion = @"1.0";

@interface PhotoEditingViewController () <PHContentEditingController>
@property (strong) PHContentEditingInput *input;
@end

@implementation PhotoEditingViewController
{
    __weak IBOutlet UIImageView *editImageView;
    __weak IBOutlet UIScrollView *btnContentView;
    
    UIImage *displayImage;
    NSArray<NSString *> *filterNameArray;
    
    //当前编辑的滤镜名称
    NSString *currentFilterName;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)setupBasicWithOriginalImage:(UIImage *)image
{
    //滤镜名称都在这里 [CIFilter filterNamesInCategory:kCICategoryBuiltIn]
    filterNameArray = @[@"CIPhotoEffectInstant", //怀旧
                        @"CIPhotoEffectNoir", //黑白
                        @"CIPhotoEffectTransfer", //岁月
                        @"CIPhotoEffectMono", //单色
                        @"CIPhotoEffectFade", //褪色
                        @"CIPhotoEffectTonal", //色调
                        @"CIPhotoEffectProcess", //冲印
                        @"CIPhotoEffectChrome", //珞黄
                        @"CIBoxBlur", //均值模糊
                        @"CIGaussianBlur", //高斯模糊
                        @"CIDiscBlur", //环形卷积模糊
                        @"CIMedianFilter", //中值模糊
                        @"CIMotionBlur", //运动模糊
                        ];
    NSInteger count = filterNameArray.count;
    CGFloat btnWidth = 60;
    CGFloat btnHeight = btnContentView.frame.size.height-10;
    
    for(NSInteger i=0; i<filterNameArray.count; i++){
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(i * (btnWidth+8), 5, btnWidth, btnHeight)];
        
        CIImage *ciImage = [MKImageUtil filterWithOriginalImage:[[CIImage alloc] initWithImage:image] filterName:filterNameArray[i]];
        [btn setImage: [MKImageUtil imageFromCIImage: ciImage] forState:UIControlStateNormal];
        
        btn.imageView.contentMode = UIViewContentModeScaleAspectFit;
        btn.tag = i;
        [btn addTarget:self action:@selector(filterInputImage:) forControlEvents:UIControlEventTouchUpInside];
        [btnContentView addSubview:btn];
    }
    
    btnContentView.contentSize = CGSizeMake(count * (btnWidth + 8)-8, btnContentView.frame.size.height);
}

- (void)filterInputImage:(UIButton *)btn
{
    currentFilterName = filterNameArray[btn.tag];
    
    CIImage *ciImage = [MKImageUtil filterWithOriginalImage:[[CIImage alloc] initWithImage:displayImage]
                                                 filterName: currentFilterName];
    editImageView.image = [MKImageUtil imageFromCIImage: ciImage];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark - PHContentEditingController

//能否对编辑过的数据进行编辑
- (BOOL)canHandleAdjustmentData:(PHAdjustmentData *)adjustmentData {

    //可以根据 adjustmentData 的 formatIdentifier 和 formatVersion 属性来判断当前的数据是否使用过着编辑器来编辑过
    BOOL result = [formatIdentifier isEqualToString: adjustmentData.formatIdentifier] &&
    [formatVersion isEqualToString: adjustmentData.formatVersion];
    if(result){
        //获取上次编辑使用的滤镜名称
        currentFilterName = [[NSString alloc] initWithData:adjustmentData.data encoding:NSUTF8StringEncoding];
    }
    return result;
    
}

- (void)startContentEditingWithInput:(PHContentEditingInput *)contentEditingInput placeholderImage:(UIImage *)placeholderImage {
    self.input = contentEditingInput;
    
    [self setupBasicWithOriginalImage: _input.displaySizeImage];
    displayImage = _input.displaySizeImage;
    editImageView.image = displayImage;
}

- (void)finishContentEditingWithCompletionHandler:(void (^)(PHContentEditingOutput *))completionHandler {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHContentEditingOutput *output = [[PHContentEditingOutput alloc] initWithContentEditingInput:self.input];
        
        //1. 设置输出的adjustmentData
        PHAdjustmentData *adjustmentData = [[PHAdjustmentData alloc] initWithFormatIdentifier:formatIdentifier
                                                                                formatVersion:formatVersion
                                                                                         data:[currentFilterName dataUsingEncoding:NSUTF8StringEncoding]];
        output.adjustmentData = adjustmentData;
        
        //2. 对原图进行相同的编辑
        CIImage *fullSizeImage = [CIImage imageWithContentsOfURL: _input.fullSizeImageURL];
        
        UIGraphicsBeginImageContext(fullSizeImage.extent.size);
        CIImage *filterImage = [MKImageUtil filterWithOriginalImage:fullSizeImage filterName:currentFilterName]; //添加滤镜
        UIImage *drawImage = [UIImage imageWithCIImage:filterImage];
        [drawImage drawInRect:fullSizeImage.extent];
        UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
        NSData *jpegData = UIImageJPEGRepresentation(outputImage, 1.0);
        UIGraphicsEndImageContext();
        
        [jpegData writeToURL:output.renderedContentURL atomically:YES];
        
        completionHandler(output);
    });
}

- (BOOL)shouldShowCancelConfirmation {
    return YES;
}

- (void)cancelContentEditing {
}

@end
