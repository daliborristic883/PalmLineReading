#pragma once
//#include <opencv2/opencv.hpp>
#include <opencv2/core/core.hpp>

#if defined(_MSC_VER) && defined(PALM_USE_DLLS)
#ifdef PALM_EXPORTS
#define PALM_EXPORT __declspec(dllexport)
#else
#define PALM_EXPORT __declspec(dllimport)
#endif
#else
#define PALM_EXPORT
#endif

typedef struct{
    int HeadLine;
    int HeartLine;
    int LifeLine;
}PalmistryInfo;
PALM_EXPORT void PalmistryInit(char *sFilePath);
PALM_EXPORT void PalmistryDetect(cv::Mat inImage, cv::Mat inLabelImg, cv::Mat& outImage, PalmistryInfo& palminfo);
