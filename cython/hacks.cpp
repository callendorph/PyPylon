/**
 * @file hacks.cpp
 * @description
 *   This file contains a function to get a particular type of object
 * from another object that is only accessible via a '->' operator.
 * Unfortunately, Cython does not seem to handle this case particularly
 * well and we don't have control over what the pylon library does.
 *
 */
#include "hacks.h"

CGrabResultData::CGrabResultData(Pylon::CGrabResultPtr& ptr) : _ptr(ptr) {
}

bool CGrabResultData::GrabSucceeded() {
	return( this->_ptr->GrabSucceeded() );
}

Pylon::String_t CGrabResultData::GetErrorDescription() {
	return( this->_ptr->GetErrorDescription() );
}

uint32_t CGrabResultData::GetErrorCode() {
	return( this->_ptr->GetErrorCode() );
}

Pylon::EPayloadType CGrabResultData::GetPayloadType() {
	return( this->_ptr->GetPayloadType() );
}

Pylon::EPixelType CGrabResultData::GetPixelType() {
	return( this->_ptr->GetPixelType() );

}

uint32_t CGrabResultData::GetWidth() {
	return( this->_ptr->GetWidth() );
}

uint32_t CGrabResultData::GetHeight() {
	return( this->_ptr->GetHeight() );
}

uint32_t CGrabResultData::GetOffsetX() {
	return( this->_ptr->GetOffsetX() );
}

uint32_t CGrabResultData::GetOffsetY() {
	return( this->_ptr->GetOffsetY() );
}

uint32_t CGrabResultData::GetPaddingX() {
	return( this->_ptr->GetPaddingX() );
}

uint32_t CGrabResultData::GetPaddingY() {
	return( this->_ptr->GetPaddingY() );
}

bool CGrabResultData::GetStride(size_t& strideBytes) {
	return( this->_ptr->GetStride(strideBytes) );
}

size_t CGrabResultData::GetImageSize() {
	return( this->_ptr->GetImageSize() );
}

void* CGrabResultData::GetBuffer() {
	return( this->_ptr->GetBuffer() );
}

size_t CGrabResultData::GetPayloadSize() {
	return( this->_ptr->GetPayloadSize() );
}

uint32_t CGrabResultData::GetFrameNumber() { // Deprecated
	return( this->_ptr->GetFrameNumber() );
}

uint64_t CGrabResultData::GetBlockID() {
	return( this->_ptr->GetBlockID() );
}

uint64_t CGrabResultData::GetTimeStamp() {
	return( this->_ptr->GetTimeStamp() );
}

int64_t CGrabResultData::GetID() {
	return( this->_ptr->GetID() );
}

int64_t CGrabResultData::GetImageNumber() {
	return( this->_ptr->GetImageNumber() );
}

int64_t CGrabResultData::GetNumberOfSkippedImages() {
	return( this->_ptr->GetNumberOfSkippedImages() );
}

bool CGrabResultData::IsChunkDataAvailable() {
	return( this->_ptr->IsChunkDataAvailable() );
}

GenApi::INodeMap& CGrabResultData::GetChunkDataNodeMap() {
	return( this->_ptr->GetChunkDataNodeMap() );
}

bool CGrabResultData::HasCRC() {
	return( this->_ptr->HasCRC() );
}

bool CGrabResultData::CheckCRC() {
	return( this->_ptr->CheckCRC() );
}
