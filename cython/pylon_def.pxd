from libcpp cimport bool
from libc.stdint cimport uint32_t, uint64_t, int64_t
from libcpp.string cimport string

cdef extern from "Base/GCBase.h":
    cdef cppclass gcstring:
        gcstring(char*)
    cdef cppclass gcstring_vector:
        gcstring_vector()
        gcstring at(size_t index) except +
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

    bool IsReadable(EAccessMode) except +
    bool IsWritable(EAccessMode) except +
    bool IsImplemented(EAccessMode) except +

    bool IsReadable(INode *) except +
    bool IsWritable(INode *) except +
    bool IsImplemented(INode *) except +

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
        void FromString(gcstring, bool verify=True) except +
        EAccessMode GetAccessMode()

    cdef cppclass IBoolean:
        bool GetValue()
        void SetValue(bool) except +
        EAccessMode GetAccessMode()

    cdef cppclass IInteger:
        int64_t GetValue()
        void SetValue(int64_t) except +
        int64_t GetMin()
        int64_t GetMax()
        EAccessMode GetAccessMode()

    cdef cppclass IString
    cdef cppclass IFloat:
        double GetValue()
        void SetValue(double) except +
        double GetMin()
        double GetMax()
        EAccessMode GetAccessMode()

    cdef cppclass IEnumeration:
        int64_t GetIntValue(bool verify=True) except +
        void SetIntValue(int64_t, bool verfy=True) except +
        gcstring ToString()
        void FromString(gcstring, bool verify=True) except +
        void GetSymbolics(gcstring_vector) except +
        EAccessMode GetAccessMode()

    cdef cppclass IEnumEntry:
        int64_t GetValue()
        gcstring GetSymbolic()
        gcstring ToString()
        FromString(gcstring, bool verify=True) except +


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
    void PylonInitialize() except +
    void PylonTerminate() except +

    ctypedef enum EPixelType:
    # @ note - this is not a complete listing - just
    #    available types in the emulator for now.
        PixelType_Undefined,
        PixelType_Mono8,
        PixelType_Mono16,
        PixelType_RGB8packed,
        PixelType_BGR8packed,
        PixelType_BGRA8packed,
        PixelType_RGB16packed

    ctypedef enum EImageOrientation:
        ImageOrientation_TopDown,
        ImageOrientation_BottomUp

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

    cdef cppclass CGrabResultData:
        bool GrabSucceeded()

    cdef cppclass CGrabResultPtr:
        IImage& operator()
        bool IsValid()
        #CGrabResultData* operator->()

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
        String_t GetSerialNumber() except +
        String_t GetUserDefinedName() except +
        String_t GetModelName() except +
        String_t GetDeviceVersion() except +
        String_t GetFriendlyName() except +
        String_t GetVendorName() except +
        String_t GetDeviceClass() except +

    cdef cppclass CInstantCamera:
        CInstantCamera()
        void Attach(IPylonDevice*)
        bool IsPylonDeviceAttached()
        CDeviceInfo& GetDeviceInfo() except +
        void IsCameraDeviceRemoved()
        void Open() except +
        void Close() except +
        bool IsOpen() except +
        IPylonDevice* DetachDevice() except +

        void StartGrabbing() except +
        void StartGrabbing(EGrabStrategy) except +
        void StartGrabbing(EGrabStrategy, EGrabLoop) except +
        void StartGrabbing(size_t maxImages) except +
        void StartGrabbing(size_t maxImages, EGrabStrategy) except +
        void StartGrabbing(size_t maxImages, EGrabStrategy, EGrabLoop) except +
        void StopGrabbing() except +
        bool IsGrabbing()

        bool RetrieveResult(
            unsigned int timeout_ms,
            CGrabResultPtr& grab_result
        ) nogil except +
        bool RetrieveResult(
            unsigned int timeout_ms,
            CGrabResultPtr& grab_result,
            ETimeoutHandling
        ) nogil except +

        bool GrabOne(
            unsigned int timeout_ms,
            CGrabResultPtr& grab_result
        ) nogil except +
        bool GrabOne(
            unsigned int timeout_ms,
            CGrabResultPtr& grab_result,
            ETimeoutHandling
        ) nogil except +

        void ExecuteSoftwareTrigger()
        size_t GetQueuedBufferCount()

        bool IsUsb()
        bool IsGigE()
        bool IsCameraLink()
        bool IsBcon()

        INodeMap& GetNodeMap()

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

    cdef cppclass CTlFactory:
        int EnumerateDevices(DeviceInfoList_t&, bool add_to_list=False)
        IPylonDevice* CreateDevice(CDeviceInfo&)

# Hack to define a static member function
cdef extern from "pylon/PylonIncludes.h"  namespace 'Pylon::CTlFactory':
    CTlFactory& GetInstance()

# EVIL HACK: We cannot dereference officially with the -> operator. So we use ugly macros...
cdef extern from 'hacks.h':
    bool ACCESS_CGrabResultPtr_GrabSucceeded(CGrabResultPtr ptr)
    String_t ACCESS_CGrabResultPtr_GetErrorDescription(CGrabResultPtr ptr)
    uint32_t ACCESS_CGrabResultPtr_GetErrorCode(CGrabResultPtr ptr)
