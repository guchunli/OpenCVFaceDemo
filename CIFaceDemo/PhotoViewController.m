//
//  PhotoViewController.m
//  CIFaceDemo
//
//  Created by Yomob on 2018/12/11.
//  Copyright © 2018年 Yomob. All rights reserved.
//

#import "PhotoViewController.h"
#import <opencv2/videoio/cap_ios.h>
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc/types_c.h>
#import <opencv2/imgcodecs/ios.h>

@interface PhotoViewController ()<UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    cv::CascadeClassifier faceDetector;
}
@property (nonatomic,strong) UIImageView *imageView;

@end

@implementation PhotoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat navH = ([UIApplication sharedApplication].statusBarFrame.size.height+44);
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake((self.view.frame.size.width-100)*0.5, navH, 100, 50)];
    btn.backgroundColor = [UIColor orangeColor];
    [btn setTitle:@"图片识别" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(choosePic) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    CGFloat imgY = CGRectGetMaxY(btn.frame);
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, imgY, self.view.frame.size.width, self.view.frame.size.height-imgY)];
    self.imageView.backgroundColor = [UIColor lightGrayColor];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:self.imageView];
}

- (void)choosePic{
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    __weak typeof(self)weakSelf = self;
    
    UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"拍照" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf takePhoto];
    }];
    [actionSheet addAction:cameraAction];
    UIAlertAction *calbumAction = [UIAlertAction actionWithTitle:@"相册" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [weakSelf choosePhoto];
    }];
    [actionSheet addAction:calbumAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [actionSheet addAction:cancelAction];
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark == private method
- (void)choosePhoto
{
    // 从相册中选取
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    controller.delegate = self;
    [self presentViewController:controller
                       animated:YES
                     completion:^(void){
                         NSLog(@"Picker View Controller is presented");
                     }];
}

- (void)takePhoto
{
    // 拍照
    UIImagePickerController *controller = [[UIImagePickerController alloc] init];
    controller.sourceType = UIImagePickerControllerSourceTypeCamera;
    //前摄像头
    controller.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    controller.delegate = (id)self;
    [self presentViewController:controller
                       animated:YES
                     completion:^(void){
                         NSLog(@"Picker View Controller is presented");
                     }];
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    __weak typeof(self) weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^() {
        
        UIImage *portraitImg = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
        portraitImg = [self fixOrientationImage:portraitImg];
        weakSelf.imageView.image = portraitImg;
        [weakSelf faceDetectWithImage:portraitImg];
        
    }];
}

- (UIImage *)fixOrientationImage:(UIImage *)image {
    
    if (image.imageOrientation == UIImageOrientationUp) return image;
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationUpMirrored:
            break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        case UIImageOrientationUp:
        case UIImageOrientationDown:
        case UIImageOrientationLeft:
        case UIImageOrientationRight:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, image.size.width, image.size.height,
                                             CGImageGetBitsPerComponent(image.CGImage), 0,
                                             CGImageGetColorSpace(image.CGImage),
                                             CGImageGetBitmapInfo(image.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.height,image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,image.size.width,image.size.height), image.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

#pragma mark - 识别人脸
- (void)faceDetectWithImage:(UIImage *)image {
    
    // Load cascade classifier from the XML file
    NSString* cascadePath = [[NSBundle mainBundle]
                             pathForResource:@"haarcascade_frontalface_alt"
                             ofType:@"xml"];
    faceDetector.load([cascadePath UTF8String]);
    
    //Load image with face
    //    UIImage* image = [UIImage imageNamed:@"photo.jpg"];
    cv::Mat faceImage;
    UIImageToMat(image, faceImage);
    
    // Convert to grayscale
    cv::Mat gray;
    cvtColor(faceImage, gray, CV_BGR2GRAY);
    
    // Detect faces
    std::vector<cv::Rect> faces;
    faceDetector.detectMultiScale(gray, faces, 1.1,
                                  2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(30, 30));
    
    // Draw all detected faces
    for(unsigned int i = 0; i < faces.size(); i++)
    {
        const cv::Rect& face = faces[i];
        // Get top-left and bottom-right corner points
        cv::Point tl(face.x, face.y);
        cv::Point br = tl + cv::Point(face.width, face.height);
        
        // Draw rectangle around the face
        cv::Scalar magenta = cv::Scalar(255, 0, 255);
        cv::rectangle(faceImage, tl, br, magenta, 4, 8, 0);
    }
    
    // Show resulting image
    self.imageView.image = MatToUIImage(faceImage);
}

@end
