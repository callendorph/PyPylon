from libcpp cimport bool
from libc.stdint cimport uint32_t, uint64_t, int64_t
from libcpp.string cimport string

cdef extern from "pylon_exc.h":
    cdef void raise_py_error()

cdef extern from "Base/GCBase.h":
    cdef cppclass gcstring:
        gcstring(char*)
    cdef cppclass gcstring_vector:
        gcstring_vector()
        gcstring at(size_t index) except +raise_py_error
        uint64_t size()

cdef extern from "GenApi/GenApi.h" namespace 'GenApi':

    ctypedef enum EAccessMode:
        NI,
        NA,
        WO,
        RO,
        RW,
        _UdefinedAccesMode,
        _CycleDetectAccesMode

    bool IsReadable(EAccessMode) except +raise_py_error
    bool IsWritable(EAccessMode) except +raise_py_error
    bool IsImplemented(EAccessMode) except +raise_py_error

    bool IsReadable(INode *) except +raise_py_error
    bool IsWritable(INode *) except +raise_py_error
    bool IsImplemented(INode *) except +raise_py_error

    cdef cppclass INode:
        gcstring GetName(bool FullQualified=False)
        gcstring GetNameSpace()
        gcstring GetDescription()
        gcstring GetDisplayName()
        bool IsFeature()
        gcstring GetValue()
        EAccessMode GetAccessMode()
        bool IsDeprecated()

    # Types an INode could be
    cdef cppclass IValue:
        gcstring ToString()
        void FromString(gcstring, bool verify=True) except +raise_py_error
        EAccessMode GetAccessMode()

    cdef cppclass IBoolean:
        bool GetValue()
        void SetValue(bool) except +raise_py_error
        EAccessMode GetAccessMode()

    cdef cppclass IInteger:
        int64_t GetValue()
        void SetValue(int64_t) except +raise_py_error
        int64_t GetMin()
        int64_t GetMax()
        EAccessMode GetAccessMode()

    cdef cppclass IString
    cdef cppclass IFloat:
        double GetValue()
        void SetValue(double) except +raise_py_error
        double GetMin()
        double GetMax()
        EAccessMode GetAccessMode()

    cdef cppclass IEnumeration:
        int64_t GetIntValue(bool verify=True) except +raise_py_error
        void SetIntValue(int64_t, bool verfy=True) except +raise_py_error
        gcstring ToString()
        void FromString(gcstring, bool verify=True) except +raise_py_error
        void GetSymbolics(gcstring_vector) except +raise_py_error
        EAccessMode GetAccessMode()

    cdef cppclass IEnumEntry:
        int64_t GetValue()
        gcstring GetSymbolic()
        gcstring ToString()
        FromString(gcstring, bool verify=True) except +raise_py_error


    cdef cppclass NodeList_t:
        cppclass iterator:
            INode* operator*()
            iterator operator++()
            bint operator==(iterator)
            bint operator!=(iterator)
        NodeList_t()
        CDeviceInfo& operator[](int)
        CDeviceInfo& at(int)
        iterator begin()
        iterator end()

    cdef cppclass ICategory

    cdef cppclass INodeMap:
        void GetNodes(NodeList_t&)
        INode* GetNode(gcstring& )
        uint32_t GetNumNodes()

cdef extern from *:
    IValue* dynamic_cast_ivalue_ptr "dynamic_cast<GenApi::IValue*>" (INode*) except +
    IBoolean* dynamic_cast_iboolean_ptr "dynamic_cast<GenApi::IBoolean*>" (INode*) except +
    IInteger* dynamic_cast_iinteger_ptr "dynamic_cast<GenApi::IInteger*>" (INode*) except +
    IFloat* dynamic_cast_ifloat_ptr "dynamic_cast<GenApi::IFloat*>" (INode*) except +
    INodeMap* dynamic_cast_inodemap_ptr "dynamic_cast<GenApi::INodeMap*>" (INode*) except +
    INodeMap* dynamic_cast_inodemap_ptr "dynamic_cast<GenApi::INodeMap*>" (INode*) except +
    ICategory* dynamic_cast_icategory_ptr "dynamic_cast<GenApi::ICategory*>" (INode*) except +
    IEnumeration* dynamic_cast_ienumeration_ptr "dynamic_cast<GenApi::IEnumeration*>" (INode*) except +

    IEnumEntry* dynamic_cast_ienumentry_ptr "dynamic_cast<GenApi::IEnumEntry*>" (INode*) except +

cdef extern from "pylon/PylonIncludes.h" namespace 'Pylon':
    # Common special data types
    cdef cppclass String_t
    cdef cppclass StringList_t

    # Top level init functions
    void PylonInitialize() except +raise_py_error
    void PylonTerminate() except +raise_py_error

    ctypedef enum EImageOrientation:
        ImageOrientation_TopDown,
        ImageOrientation_BottomUp

    ctypedef enum EPixelType:
    # @ note - this is not a complete listing - just
    #    available types in the emulator for now.
        PixelType_Undefined,
        PixelType_Mono8,
        PixelType_Mono16,
        PixelType_RGB8packed,
        PixelType_BGR8packed,
        PixelType_BGRA8packed,
        PixelType_RGB16packed,
        PixelType_YUV422_YUYV_Packed

    bool IsMonoPacked(EPixelType)
    bool IsBayerPacked(EPixelType)
    bool IsRGBPacked(EPixelType)
    bool IsBGRPacked(EPixelType)
    bool IsPacked(EPixelType)
    bool IsPackedInLsbFormat(EPixelType)
    uint32_t PlaneCount(EPixelType)
    EPixelType GetPlanePixelType(EPixelType)
    bool IsPlanar(EPixelType)
    uint32_t BitPerPixel(EPixelType)
    uint32_t SamplesPerPixel(EPixelType)
    bool IsYUV( EPixelType)
    bool IsRGBA(EPixelType)
    bool IsRGB(EPixelType)
    bool IsBGR(EPixelType)
    bool IsBayer(EPixelType)
    bool IsMono(EPixelType)
    bool IsMonoImage(EPixelType)
    bool IsColorImage(EPixelType)
    bool HasAlpha(EPixelType)
    uint32_t GetPixelIncrementX(EPixelType)
    uint32_t GetPixelIncrementY(EPixelType)
    uint32_t BitDepth( EPixelType )

    cdef cppclass IReusableImage:
        bool IsSupportedPixelType( EPixelType pixelType)
        bool IsAdditionalPaddingSupported()
        void Reset( EPixelType pixelType, uint32_t width, uint32_t height) except +raise_py_error

        void Reset( EPixelType pixelType, uint32_t width, uint32_t height, EImageOrientation orientation) except +raise_py_error
        void Reset( EPixelType pixelType, uint32_t width, uint32_t height, size_t paddingX) except +raise_py_error
        void Reset( EPixelType pixelType, uint32_t width, uint32_t height, size_t paddingX, EImageOrientation orientation) except +raise_py_error
        void Release()

    cdef cppclass IImage:
        uint32_t GetWidth()
        uint32_t GetHeight()
        size_t GetPaddingX()
        size_t GetImageSize()
        void* GetBuffer()
        bool IsValid()
        EImageOrientation GetOrientation()
        EPixelType GetPixelType()
        bool GetStride( size_t& strideBytes )
        bool IsUnique()

    cdef cppclass CPylonImage:
        CPylonImage()
        bool IsValid()
        EPixelType GetPixelType()
        uint32_t GetWidth()
        uint32_t GetHeight()
        size_t GetPaddingX()
        EImageOrientation GetOrientation()
        void* GetBuffer()
        size_t GetImageSize()
        bool IsUnique()
        bool GetStride( size_t& strideBytes)


    cdef cppclass CImageFormatConverter:
        cppclass IOutputPixelFormatEnum:
            void SetValue(EPixelType) except +raise_py_error
            EPixelType GetValue()

        IOutputPixelFormatEnum& OutputPixelFormat

        CImageFormatConverter()
        void Initialize( EPixelType sourcePixelType) except +raise_py_error
        bool IsInitialized( EPixelType sourcePixelType)
        void Uninitialize()
        bool ImageHasDestinationFormat( const IImage& sourceImage)
        bool ImageHasDestinationFormat( EPixelType sourcePixelType, size_t sourcePaddingX, EImageOrientation sourceOrientation)
        size_t GetBufferSizeForConversion( const IImage& sourceImage) except +raise_py_error
        size_t GetBufferSizeForConversion( EPixelType sourcePixelType, uint32_t sourceWidth, uint32_t sourceHeight) except +raise_py_error
        void Convert( IReusableImage& destinationImage, const IImage& sourceImage)
        void Convert( IReusableImage& destinationImage,
                      const void* pSourceBuffer,
                      size_t sourceBufferSizeBytes,
                      EPixelType sourcePixelType,
                      uint32_t sourceWidth,
                      uint32_t sourceHeight,
                      size_t sourcePaddingX,
                      EImageOrientation sourceOrientation
                      ) except +raise_py_error
        void Convert( void* pDestinationBuffer, size_t destinationBufferSizeBytes, const IImage& sourceImage) except +raise_py_error
        void Convert( void* pDestinationBuffer,
                      size_t destinationBufferSizeBytes,
                      const void* pSourceBuffer,
                      size_t sourceBufferSizeBytes,
                      EPixelType sourcePixelType,
                      uint32_t sourceWidth,
                      uint32_t sourceHeight,
                      size_t sourcePaddingX,
                      EImageOrientation sourceOrientation
                      ) except +raise_py_error
        INodeMap& GetNodeMap()

    ctypedef enum EPayloadType:
        PayloadType_Undefined,
        PayloadType_Image,
        PayloadType_RawData,
        PayloadType_File,
        PayloadType_ChunkData,
        PayloadType_DeviceSpecific

    cdef cppclass CGrabResultPtr:
        IImage& operator()
        bool IsValid()

    ctypedef enum ETimeoutHandling:
        TimeoutHandling_Return,
        TimeoutHandling_ThrowException

    ctypedef enum EGrabStrategy:
        GrabStrategy_OneByOne,
        GrabStrategy_LatestImageOnly,
        GrabStrategy_LatestImages,
        GrabStrategy_UpcomingImage

    ctypedef enum EGrabLoop:
        GrabLoop_ProvidedByInstantCamera,
        GrabLoop_ProvidedByUser

    cdef cppclass IPylonDevice:
        pass

    cdef cppclass CDeviceInfo:
        String_t GetSerialNumber() except +raise_py_error
        String_t GetUserDefinedName() except +raise_py_error
        String_t GetModelName() except +raise_py_error
        String_t GetDeviceVersion() except +raise_py_error
        String_t GetFriendlyName() except +raise_py_error
        String_t GetVendorName() except +raise_py_error
        String_t GetDeviceClass() except +raise_py_error

    cdef cppclass CInstantCamera:
        CInstantCamera()
        void Attach(IPylonDevice*)
        bool IsPylonDeviceAttached()
        CDeviceInfo& GetDeviceInfo() except +raise_py_error
        void IsCameraDeviceRemoved()
        void Open() except +raise_py_error
        void Close() except +raise_py_error
        bool IsOpen() except +raise_py_error
        IPylonDevice* DetachDevice() except +raise_py_error

        void StartGrabbing() except +raise_py_error
        void StartGrabbing(EGrabStrategy) except +raise_py_error
        void StartGrabbing(EGrabStrategy, EGrabLoop) except +raise_py_error
        void StartGrabbing(size_t maxImages) except +raise_py_error
        void StartGrabbing(size_t maxImages, EGrabStrategy) except +raise_py_error
        void StartGrabbing(size_t maxImages, EGrabStrategy, EGrabLoop) except +raise_py_error
        void StopGrabbing() except +raise_py_error
        bool IsGrabbing()

        bool RetrieveResult(
            unsigned int timeout_ms,
            CGrabResultPtr& grab_result
        ) nogil except +raise_py_error
        bool RetrieveResult(
            unsigned int timeout_ms,
            CGrabResultPtr& grab_result,
            ETimeoutHandling
        ) nogil except +raise_py_error

        bool GrabOne(
            unsigned int timeout_ms,
            CGrabResultPtr& grab_result
        ) nogil except +raise_py_error
        bool GrabOne(
            unsigned int timeout_ms,
            CGrabResultPtr& grab_result,
            ETimeoutHandling
        ) nogil except +raise_py_error

        void ExecuteSoftwareTrigger()
        size_t GetQueuedBufferCount()

        bool IsUsb()
        bool IsGigE()
        bool IsCameraLink()
        bool IsBcon()

        INodeMap& GetNodeMap()
        INodeMap& GetTLNodeMap()
        INodeMap& GetStreamGrabberNodeMap()
        INodeMap& GetEventGrabberNodeMap()
        INodeMap& GetInstantCameraNodeMap()

        # Data Members
        IInteger MaxNumBuffer
        IInteger MaxNumQueuedBuffer
        IInteger MaxNumGrabResults
        IBoolean ChunkNodeMapsEnable
        IInteger StaticChunkNodeMapPoolSize
        IBoolean GrabCameraEvents
        IBoolean MonitorModeActive
        IInteger NumQueuedBuffers
        IInteger NumReadyBuffers
        IInteger NumEmptyBuffers
        IInteger OutputQueueSize
        IBoolean InternalGrabEngineThreadPriorityOverride
        IInteger InternalGrabEngineThreadPriority
        IBoolean GrabLoopThreadUseTimeout
        IInteger GrabLoopThreadTimeout
        IBoolean GrabLoopThreadPriorityOverride
        IInteger GrabLoopThreadPriority

    cdef cppclass DeviceInfoList_t:
        cppclass iterator:
            CDeviceInfo operator*()
            iterator operator++()
            bint operator==(iterator)
            bint operator!=(iterator)
        DeviceInfoList_t()
        CDeviceInfo& operator[](int)
        CDeviceInfo& at(int)
        iterator begin()
        iterator end()

    ctypedef enum EDeviceAccessiblityInfo:
        Accessibility_Unknown,
        Accessibility_Ok,
        Accessibility_Opened,
        Accessibility_OpenedExclusively,
        Accessibility_NotReachable

    ctypedef enum EDeviceAccessMode:
        Control,
        Stream,
        Event,
        Exclusive

    cdef cppclass AccessModeSet:
        AccessModeSet()
        AccessModeSet& set(size_t pos)
        AccessModeSet& reset()
        bool any()
        bool none()
        bool test(size_t)
        unsigned long to_ulong()

    cdef cppclass CTlFactory:
        int EnumerateDevices(DeviceInfoList_t&, bool add_to_list=False)
        IPylonDevice* CreateDevice(CDeviceInfo&) except +raise_py_error
        bool IsDeviceAccessible(CDeviceInfo&, AccessModeSet, EDeviceAccessiblityInfo*) except +raise_py_error

cdef extern from "pylon/PylonIncludes.h"  namespace 'Pylon::CTlFactory':
    CTlFactory& GetInstance()

cdef extern from "pylon/PylonIncludes.h" namespace 'Pylon::CImageFormatConverter':
    bool IsSupportedInputFormat( EPixelType sourcePixelType)
    bool IsSupportedOutputFormat( EPixelType destinationPixelType)

cdef extern from "pylon/PylonIncludes.h" namespace 'Pylon::CPylonImage':
    CPylonImage Create(EPixelType pixelType, uint32_t width, uint32_t height) except +raise_py_error
    CPylonImage Create(EPixelType pixelType, uint32_t width, uint32_t height, size_t paddingX) except +raise_py_error
    CPylonImage Create(EPixelType pixelType, uint32_t width, uint32_t height, size_t paddingX, EImageOrientation orientation) except +raise_py_error


# The pylon library uses CGrabResultPtr as a means of protecting the
#   pointer of the GrabResultData object. This object has most of its
#   constructors and other operators set to private so we can create those
#   objects. This problematic for us because Cython can't use the '->'
#   operator override.
# However, fear not, the below code is a wrapper around the CGrabResultPtr
#   in C++ to access a 'CGrabResultData' object. This object is not exactly
#   the same as a Pylon::CGrabResultData but it will work as a stand-in in
#   the Cython code.
cdef extern from 'hacks.h':
    cdef cppclass CGrabResultData:
        CGrabResultData(CGrabResultPtr& ptr)
        bool GrabSucceeded()
        String_t GetErrorDescription()
        uint32_t GetErrorCode()
        EPayloadType GetPayloadType()
        EPixelType GetPixelType()
        uint32_t GetWidth()
        uint32_t GetHeight()
        uint32_t GetOffsetX()
        uint32_t GetOffsetY()
        uint32_t GetPaddingX()
        uint32_t GetPaddingY()
        bool GetStride(size_t& strideBytes)
        size_t GetImageSize()

        void* GetBuffer()
        size_t GetPayloadSize()

        uint32_t GetFrameNumber() # Deprecated
        uint64_t GetBlockID()
        uint64_t GetTimeStamp()
        int64_t GetID()
        int64_t GetImageNumber()
        int64_t GetNumberOfSkippedImages()

        bool IsChunkDataAvailable()
        INodeMap& GetChunkDataNodeMap()

        bool HasCRC()
        bool CheckCRC()
