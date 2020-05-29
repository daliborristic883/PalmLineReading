//
//  ViewController.m
//  FaceSDKTest
//
//  Created by Vasyl Boichuk on 2/25/19.
//  Copyright © 2019 Vasyl Boichuk. All rights reserved.
//

#import "ViewController.h"
#import "PalmLine/Palm.h"
#import "opencv2/imgproc/imgproc.hpp"
@interface ViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *imgBack;
@property (weak, nonatomic) IBOutlet UIImageView *imgPalm;
@property (weak, nonatomic) IBOutlet UIButton *btnChange;
@property (weak, nonatomic) IBOutlet UILabel *lbResult;
@property (assign, nonatomic) BOOL bRight;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *resourcePath = [bundle bundlePath];
    //NSString *resourcePath = [[NSBundle mainBundle] bundlePath];
    NSString *dataPath = [resourcePath stringByAppendingPathComponent:@""];
    const char *pszDataPath = [dataPath UTF8String];
    PalmistryInit((char *)pszDataPath);
    self.bRight = true;
    self.imgBack.image = [UIImage imageNamed:@"back_right.png"];
    self.imgPalm.image = [UIImage imageNamed:@"right.png"];
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (IBAction)onTake:(id)sender {
    UIImage* image;
    CGRect rect;
    if (self.bRight) {
        image = [UIImage imageNamed:@"right.png"];
        int nHeight = image.size.height * 11 / 20;
        int x = image.size.width * 1 / 6;
        int nWidth = image.size.width * 10 / 18;
        rect = CGRectMake(x, image.size.height - nHeight, nWidth, nHeight);
    } else {
        image = [UIImage imageNamed:@"left.png"];
        int nHeight = image.size.height * 11 / 20;
        int x = image.size.width * 6 / 21;
        int nWidth = image.size.width * 10 / 18;
        rect = CGRectMake(x, image.size.height - nHeight, nWidth, nHeight);
    }
    image = [self crop:image crop:rect];
    cv::Mat cvImage = [self toCVMat:image];
    if (self.bRight == false) {
        cv::flip(cvImage, cvImage, 1);
    }
    UIImage* newImage = [self fromCVMat:cvImage];
     cv::Point2f cen(cvImage.cols / 2, cvImage.rows / 2);
    cv::Mat rotImg(cvImage.cols, cvImage.rows, CV_8UC4);
    for(int i = 0;i < cvImage.rows; i++){
        for(int j = 0; j < cvImage.cols; j++){
            int idx = (i*cvImage.cols + j)*4;
            int idx1 = ((rotImg.rows- j - 1) * rotImg.cols + i)*4;
            rotImg.data[idx1]= cvImage.data[idx];
            rotImg.data[idx1 + 1]= cvImage.data[idx + 1];
            rotImg.data[idx1 + 2]= cvImage.data[idx + 2];
            rotImg.data[idx1 + 3]= cvImage.data[idx + 3];
        }
    }
    // cv::Mat RotMat = getRotationMatrix2D(cen, 90, 1.0);
    // double* rot_mat = (double*)RotMat.data;
    //warpAffine(cvImage, cvImage, RotMat, cvImage.size(), 1, 0, cv::Scalar(255,255,255));
    
    //newImage = [self fromCVMat:cvImage];
    
    
    cv::cvtColor(rotImg , rotImg , CV_BGRA2BGR);
    UIImage *imageLut = [UIImage imageNamed:@"LutFile.bmp"];
    cv::Mat cvImageLut = [self toCVMat:imageLut];
    cv::cvtColor(cvImageLut , cvImageLut , CV_BGRA2GRAY);
    cv::Mat outImage;
    PalmistryInfo palminfo;
    PalmistryDetect(rotImg, cvImageLut, outImage, palminfo);
    
    NSString* strResult =[NSString stringWithFormat:@"headline = %d%%, heartline = %d%%, lifeline = %d%%", palminfo.HeadLine, palminfo.HeartLine, palminfo.LifeLine];
    self.lbResult.text = strResult;
    
    UIImage* result = [self fromCVMat:outImage];
    self.imgPalm.image = result;
    //[self dismissViewControllerAnimated:YES completion:nil];
    
    
    
    
    
    
    
    
    self.imgBack.image = NULL;
    return;
    UIAlertController *alertController = [UIAlertController
                                          alertControllerWithTitle:@"" message:@"Select Photo Type"
                                          preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* actionCamera = [UIAlertAction actionWithTitle:NSLocalizedString(@"Camera", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        //
        UIImagePickerController *vc = [[UIImagePickerController alloc] init];
        vc.delegate = self;
        vc.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:vc animated:YES completion:nil];
    }];
    
    [alertController addAction:actionCamera];
    UIAlertAction* actionGallery = [UIAlertAction actionWithTitle:NSLocalizedString(@"Gallery", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        // delete action
        UIImagePickerController *vc = [[UIImagePickerController alloc] init];
        vc.delegate = self;
        vc.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:vc animated:YES completion:nil];
    }];
    
    [alertController addAction:actionGallery];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIImage *)crop:(UIImage*)image crop:(CGRect)cropRect {
    
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, cropRect);
    UIImage *cropedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return cropedImage;
    
}

- (unsigned char*) bitmap:(UIImage*)image {
    NSLog( @"Returning bitmap representation of UIImage." );
    int bytesPerRow = image.size.width * 4;
    int byteCount = bytesPerRow * image.size.height;
    int pixelCount = image.size.width * image.size.height;
    // 8 bits each of red, green, blue, and alpha.
    CGContextRef context;
    CGColorSpaceRef colorSpace;
    // Create RGB color space
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    unsigned char *pixelData;
    
    if (!colorSpace)
    {
        NSLog(@"Error allocating color space.");
        return nil;
    }
    
    pixelData = (unsigned char*)malloc(byteCount);
    
    if (!pixelData)
    {
        NSLog(@"Error allocating bitmap memory. Releasing color space.");
        CGColorSpaceRelease(colorSpace);
        
        return nil;
    }
    
    // Create the bitmap context.
    // Pre-multiplied RGBA, 8-bits per component.
    // The source image format will be converted to the format specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate(
                                    (void*)pixelData,
                                    image.size.width,
                                    image.size.height,
                                    8,
                                    bytesPerRow,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast
                                    );
    
    // Make sure we have our context
    if (!context)   {
        free(pixelData);
        NSLog(@"Context not created!");
    }
    
    // Draw the image to the bitmap context.
    // The memory allocated for the context for rendering will then contain the raw image pixelData in the specified color space.
    CGRect rect = { { 0 , 0 }, { image.size.width, image.size.height } };
    
    CGContextDrawImage( context, rect, image.CGImage );
    
    // Now we can get a pointer to the image pixelData associated with the bitmap context.
    pixelData = (unsigned char*) CGBitmapContextGetData(context);
    
    return pixelData;
}

- (cv::Mat) toCVMat:(UIImage*)image{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    return cvMat;
}

- (UIImage*)fromCVMat:(cv::Mat)cvMat{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize() * cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    UIImage* image = [[UIImage alloc] initWithCGImage:imageRef];
    // Getting UIImage from CGImage
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}
- (IBAction)onChange:(id)sender {
    self.bRight = !self.bRight;
    if (self.bRight) {
        self.imgBack.image = [UIImage imageNamed:@"back_right.png"];
        self.imgPalm.image = [UIImage imageNamed:@"right.png"];
        [self.btnChange setTitle:@"R->L" forState:UIControlStateNormal];
    } else {
        self.imgBack.image = [UIImage imageNamed:@"back_left.png"];
        self.imgPalm.image = [UIImage imageNamed:@"left.png"];
        [self.btnChange setTitle:@"L->R" forState:UIControlStateNormal];
    }
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = info[UIImagePickerControllerOriginalImage];
    cv::Mat cvImage = [self toCVMat:image];
    cv::cvtColor(cvImage , cvImage , CV_BGRA2BGR);
    UIImage *imageLut = [UIImage imageNamed:@"LutFile.bmp"];
    cv::Mat cvImageLut = [self toCVMat:imageLut];
    cv::cvtColor(cvImageLut , cvImageLut , CV_BGRA2GRAY);
    cv::Mat outImage;
    PalmistryInfo palminfo;
    PalmistryDetect(cvImage, cvImageLut, outImage, palminfo);
    NSString* strResult =[NSString stringWithFormat:@"headline = %d%%, heartline = %d%%, lifeline = %d%%", palminfo.HeadLine, palminfo.HeartLine, palminfo.LifeLine];
    self.lbResult.text = strResult;
    UIImage* result = [self fromCVMat:outImage];
    self.imgPalm.image = result;
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
