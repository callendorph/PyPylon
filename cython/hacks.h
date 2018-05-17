#ifndef HACK_H
#define HACK_H

#include <pylon/PylonIncludes.h>

class CGrabResultData {
public:
  CGrabResultData(Pylon::CGrabResultPtr& ptr);

  bool GrabSucceeded();
  Pylon::String_t GetErrorDescription();
  uint32_t GetErrorCode();
  Pylon::EPayloadType GetPayloadType();
  Pylon::EPixelType GetPixelType();
  uint32_t GetWidth();
  uint32_t GetHeight();
  uint32_t GetOffsetX();
  uint32_t GetOffsetY();
  uint32_t GetPaddingX();
  uint32_t GetPaddingY();
  bool GetStride(size_t& strideBytes);
  size_t GetImageSize();

  void* GetBuffer();
  size_t GetPayloadSize();

  uint32_t GetFrameNumber(); // Deprecated
  uint64_t GetBlockID();
  uint64_t GetTimeStamp();
  int64_t GetID();
  int64_t GetImageNumber();
  int64_t GetNumberOfSkippedImages();

  bool IsChunkDataAvailable();
  GenApi::INodeMap& GetChunkDataNodeMap();

  bool HasCRC();
  bool CheckCRC();

private:
  Pylon::CGrabResultPtr& _ptr;

};


#endif
