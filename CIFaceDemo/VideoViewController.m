//
//  VideoViewController.m
//  CIFaceDemo
//
//  Created by Yomob on 2018/12/11.
//  Copyright © 2018年 Yomob. All rights reserved.
//

#import "VideoViewController.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/videoio/cap_ios.h>
//#import "CvEffects/RetroFilter.hpp"
//#import "CvEffects/FaceAnimator.hpp"
#import "FaceAnimator.hpp"

@interface VideoViewController ()<CvVideoCameraDelegate>
{
//    CvVideoCamera* videoCamera;
    BOOL isCapturing;
    
    FaceAnimator::Parameters parameters;
    cv::Ptr<FaceAnimator> faceAnimator;
}

@property (nonatomic, strong) CvVideoCamera *videoCamera;
@property (nonatomic, strong) UIImageView *imageView;
//@property (nonatomic, strong) UIToolbar* toolbar;
//@property (nonatomic, strong) UIButton *startCaptureButton;
//@property (nonatomic, strong) UIButton *stopCaptureButton;

- (void)startCaptureButtonPressed:(id)sender;
- (void)stopCaptureButtonPressed:(id)sender;

@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat navH = ([UIApplication sharedApplication].statusBarFrame.size.height+44);
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake((self.view.frame.size.width*0.5-120), navH, 100, 50)];
    btn.backgroundColor = [UIColor orangeColor];
    [btn setTitle:@"start" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(startCaptureButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *videoBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.frame.size.width*0.5+20, navH, 100, 50)];
    videoBtn.backgroundColor = [UIColor orangeColor];
    [videoBtn setTitle:@"stop" forState:UIControlStateNormal];
    [videoBtn addTarget:self action:@selector(stopCaptureButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:videoBtn];
    
    CGFloat imgY = CGRectGetMaxY(btn.frame);
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, imgY, self.view.frame.size.width, self.view.frame.size.height-imgY)];
    self.imageView.backgroundColor = [UIColor lightGrayColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
    
    [self setupCamera];
}

- (void)setupCamera{
    self.videoCamera = [[CvVideoCamera alloc]
                        initWithParentView:self.imageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition =
    AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset =
    AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation =
    AVCaptureVideoOrientationPortrait;
    self.videoCamera.defaultFPS = 30;
    
    isCapturing = NO;
    
    // Load images
    UIImage* resImage = [UIImage imageNamed:@"glasses.png"];
    UIImageToMat(resImage, parameters.glasses, true);
    cvtColor(parameters.glasses, parameters.glasses, CV_BGRA2RGBA);
    
    resImage = [UIImage imageNamed:@"mustache.png"];
    UIImageToMat(resImage, parameters.mustache, true);
    cvtColor(parameters.mustache, parameters.mustache, CV_BGRA2RGBA);
    
    // Load Cascade Classisiers
    NSString* filename = [[NSBundle mainBundle]
                          pathForResource:@"lbpcascade_frontalface"
                          ofType:@"xml"];
    parameters.faceCascade.load([filename UTF8String]);
    
    filename = [[NSBundle mainBundle]
                pathForResource:@"haarcascade_mcs_eyepair_big"
                ofType:@"xml"];
    parameters.eyesCascade.load([filename UTF8String]);
    
    filename = [[NSBundle mainBundle]
                pathForResource:@"haarcascade_mcs_mouth"
                ofType:@"xml"];
    parameters.mouthCascade.load([filename UTF8String]);
}

- (NSInteger)supportedInterfaceOrientations
{
    // Only portrait orientation
    return UIInterfaceOrientationMaskPortrait;
}

-(void)startCaptureButtonPressed:(id)sender
{
    [self.videoCamera start];
    isCapturing = YES;
    
    faceAnimator = new FaceAnimator(parameters);
}

-(void)stopCaptureButtonPressed:(id)sender
{
    [self.videoCamera stop];
    isCapturing = NO;
}

// Macros for time measurements
#if 1
#define TS(name) int64 t_##name = cv::getTickCount()
#define TE(name) printf("TIMER_" #name ": %.2fms\n", \
1000.*((cv::getTickCount() - t_##name) / cv::getTickFrequency()))
#else
#define TS(name)
#define TE(name)
#endif

- (void)processImage:(cv::Mat&)image
{
    TS(DetectAndAnimateFaces);
    faceAnimator->detectAndAnimateFaces(image);
    TE(DetectAndAnimateFaces);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (isCapturing)
    {
        [self.videoCamera stop];
    }
}

- (void)dealloc
{
    self.videoCamera.delegate = nil;
}

@end
