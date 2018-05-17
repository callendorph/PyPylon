from cython.operator cimport dereference as deref, preincrement as inc
from libcpp cimport bool
from libcpp.string cimport string

cimport numpy as np
import numpy as np
import logging

from enum import Enum

from pylon_def cimport *

cdef gcstring_vector_to_list(gcstring_vector strVec):
    """ Convert a vector of gcstrings into a python list of str objects
    so that they are easier to work with.
    """
    cnt = strVec.size()
    ret = []
    for i in range(0,cnt):
        s = (<string>strVec.at(i)).decode("ascii")
        ret.append(s)
    return(ret)

# Local map for enumerated types that
#   are built from data that comes from the
#   camera.
enumdefs = {}

cdef build_enum(basestring key, IEnumeration* enum_val):
    """ Given the key value for a parameter on a camera and
    a known enumerated parameter object, extract out the enumerated
    types available values.
    """
    cdef gcstring_vector symbols
    enum_val.GetSymbolics(symbols)
    symbStrs = gcstring_vector_to_list(symbols)
    kv = zip(symbStrs, symbStrs)
    enumType = Enum(key + "Enum", kv)
    enumdefs[key] = enumType
    return(enumType)


cdef class DeviceInfo:
    cdef:
        CDeviceInfo dev_info

    @staticmethod
    cdef create(CDeviceInfo dev_info):
        obj = DeviceInfo()
        obj.dev_info = dev_info
        return obj

    property serial_number:
        def __get__(self):
            return (<string>(self.dev_info.GetSerialNumber())).decode('ascii')

    property model_name:
        def __get__(self):
            return (<string>(self.dev_info.GetModelName())).decode('ascii')

    property user_defined_name:
        def __get__(self):
            return (<string>(self.dev_info.GetUserDefinedName())).decode('ascii')

    property device_version:
        def __get__(self):
            return (<string>(self.dev_info.GetDeviceVersion())).decode('ascii')

    property friendly_name:
        def __get__(self):
            return (<string>(self.dev_info.GetFriendlyName())).decode('ascii')

    property vendor_name:
        def __get__(self):
            return (<string>(self.dev_info.GetVendorName())).decode('ascii')

    property device_class:
        def __get__(self):
            return (<string>(self.dev_info.GetDeviceClass())).decode('ascii')

    def __repr__(self):
        return '<DeviceInfo {1}>'.format(self.serial_number, self.friendly_name)

cdef class _PropertyMap:
    cdef:
        INodeMap* map

    @staticmethod
    cdef create(INodeMap* map):
        obj = _PropertyMap()
        obj.map = map
        return obj

    def get_description(self, basestring key):
        cdef bytes btes_name = key.encode()
        cdef INode* node = self.map.GetNode(gcstring(btes_name))

        if node == NULL:
            raise KeyError('Key does not exist')

        return (<string>(node.GetDescription())).decode()


    def get_display_name(self, basestring key):
        cdef bytes btes_name = key.encode()
        cdef INode* node = self.map.GetNode(gcstring(btes_name))

        if node == NULL:
            raise KeyError('Key does not exist')

        return (<string>(node.GetDisplayName())).decode()

    def __getitem__(self, basestring key):
        cdef bytes btes_name = key.encode()
        cdef INode* node = self.map.GetNode(gcstring(btes_name))

        if node == NULL:
            raise KeyError('Key does not exist')

        if not IsReadable(node):
            raise IOError('Key is not readable')

        # We need to try different types and check if the dynamic_cast succeeds... UGLY!
        # Potentially we could also use GetPrincipalInterfaceType here.
        cdef IBoolean* boolean_value = dynamic_cast_iboolean_ptr(node)
        if boolean_value != NULL:
            return boolean_value.GetValue()

        cdef IInteger* integer_value = dynamic_cast_iinteger_ptr(node)
        if integer_value != NULL:
            return integer_value.GetValue()

        cdef IFloat* float_value = dynamic_cast_ifloat_ptr(node)
        if float_value != NULL:
            return float_value.GetValue()

        cdef IEnumeration* enum_val = dynamic_cast_ienumeration_ptr(node)
        if enum_val != NULL:
            enumVal = (<string>(enum_val.ToString())).decode("ascii")
            return(enumVal)

        # Potentially, we can always get the setting by string
        cdef IValue* string_value = dynamic_cast_ivalue_ptr(node)
        if string_value == NULL:
            return

        return (<string>(string_value.ToString())).decode()

    def __setitem__(self, str key, value):
        cdef bytes bytes_name = key.encode()
        cdef INode* node = self.map.GetNode(gcstring(bytes_name))

        if node == NULL:
            raise KeyError('Key does not exist')

        if not IsWritable(node):
            raise IOError('Key is not writable')

        # We need to try different types and check if the dynamic_cast succeeds... UGLY!
        # Potentially we could also use GetPrincipalInterfaceType here.
        cdef IBoolean* boolean_value = dynamic_cast_iboolean_ptr(node)
        if boolean_value != NULL:
            boolean_value.SetValue(value)
            return

        cdef IInteger* integer_value = dynamic_cast_iinteger_ptr(node)
        if integer_value != NULL:
            if value < integer_value.GetMin() or value > integer_value.GetMax():
                raise ValueError('Parameter value for {} not inside valid range [{}, {}], was {}'.format(
                    key, integer_value.GetMin(), integer_value.GetMax(), value))
            integer_value.SetValue(value)
            return

        cdef IFloat* float_value = dynamic_cast_ifloat_ptr(node)
        if float_value != NULL:
            if value < float_value.GetMin() or value > float_value.GetMax():
                raise ValueError('Parameter value for {} not inside valid range [{}, {}], was {}'.format(
                    key, float_value.GetMin(), float_value.GetMax(), value))
            float_value.SetValue(value)
            return

        # @note - We access the enumerated types by string to make it
        #   easier to access from python
        cdef IEnumeration* enum_val = dynamic_cast_ienumeration_ptr(node)
        cdef bytes bvalue
        if enum_val != NULL:
            bvalue = str(value).encode()
            enum_val.FromString(gcstring(bvalue))
            return

        # Potentially, we can always set the setting by string
        cdef IValue* string_value = dynamic_cast_ivalue_ptr(node)
        if string_value == NULL:
            raise RuntimeError('Can not set key %s by string' % key)

        cdef bytes bytes_value = str(value).encode()
        string_value.FromString(gcstring(bytes_value))

    def keys(self):
        node_keys = list()

        # Iterate through the discovered devices
        cdef NodeList_t nodes
        self.map.GetNodes(nodes)

        cdef NodeList_t.iterator it = nodes.begin()
        while it != nodes.end():
            if deref(it).IsFeature() and dynamic_cast_icategory_ptr(deref(it)) == NULL:
                name = (<string>(deref(it).GetName())).decode('ascii')
                node_keys.append(name)
            inc(it)

        return node_keys

    def find_enumerated_types(self):
        # Go through the keys and determine which
        #   values are from enumerated types
        for k in self.keys():
            try:
                enumType = self._extract_enum(k)
            except Exception as exc:
                pass
        return(enumdefs)

    def get_enum_by_key(self, key):
        return(self._extract_enum(key))

    def _extract_enum(self, key):
        try:
            enumType = enumdefs[key]
            return(enumType)
        except KeyError:
            pass

        cdef bytes key_name = key.encode()
        cdef INode* node = self.map.GetNode(gcstring(key_name))

        if node == NULL:
            raise KeyError('Key does not exist')

        if not IsReadable(node):
            raise IOError('Key is not readable')

        cdef IEnumeration* enum_val = dynamic_cast_ienumeration_ptr(node)
        if ( enum_val == NULL ):
            raise ValueError("Not an Enum Type")

        enumType = build_enum(key, enum_val)

        return(enumType)



######################
# Lookup table for different pixel types
# @note - this table is not complete
_fmtLookup = {
    PixelType_Mono8 : (1, 8),
    PixelType_Mono16 : (1, 16),
    PixelType_BGR8packed : (3, 8),
    PixelType_RGB8packed : (3, 8),
    PixelType_RGB16packed : (3, 16),
    PixelType_BGRA8packed : (4, 8),
}

cdef class Camera:
    cdef:
        CInstantCamera camera

    @staticmethod
    cdef create(IPylonDevice* device):
        obj = Camera()
        obj.camera.Attach(device)
        return obj

    property device_info:
        def __get__(self):
            dev_inf = DeviceInfo.create(self.camera.GetDeviceInfo())
            return dev_inf

    property opened:
        def __get__(self):
            return self.camera.IsOpen()
        def __set__(self, opened):
            if self.opened and not opened:
                self.camera.Close()
            elif not self.opened and opened:
                self.camera.Open()

    def open(self):
        self.camera.Open()

    def close(self):
        self.camera.Close()

    def __del__(self):
        self.close()
        self.camera.DetachDevice()

    def __repr__(self):
        return '<Camera {0} open={1}>'.format(self.device_info.friendly_name, self.opened)

    def grab_images(self, int nr_images, unsigned int timeout=5000, bool noTimeoutExc=False):
        if not self.opened:
            raise RuntimeError('Camera not opened')

        self.camera.StartGrabbing(nr_images)
        logging.debug("Starting Grab")
        cdef CGrabResultPtr ptr_grab_result
        cdef IImage* img

        cdef ETimeoutHandling errHandling
        if ( noTimeoutExc ):
            errHandling = TimeoutHandling_Return
        else:
            errHandling = TimeoutHandling_ThrowException

        while self.camera.IsGrabbing():
            with nogil:
                # Blocking call into native Pylon C++ SDK code,
                # release GIL so other python threads can run
                ret = self.camera.RetrieveResult(
                    timeout, ptr_grab_result, errHandling
                )
            logging.debug("Retrieve Result")
            funcArgs="CInstantCamera:RetrieveResult({},{},{})".format(
                timeout, ptr_grab_result.IsValid(), errHandling
            )
            if not ret:
                if ( noTimeoutExc ):
                    msg = "This could be a timeout Error"
                else:
                    msg = "Unknown Error Generated by the Basler Camera"
                logging.error("{}: ret=False: {}".format( funcArgs, msg))

                raise RuntimeError("CInstantCamera:RetrieveResult Failure")

            if not ACCESS_CGrabResultPtr_GrabSucceeded(ptr_grab_result):
                error_desc = (<string>(ACCESS_CGrabResultPtr_GetErrorDescription(ptr_grab_result))).decode()
                logging.error("{}: ret=True: Grab Failed: {}".format( funcArgs, error_desc))
                raise RuntimeError(error_desc)

            logging.debug("Grab Success")
            img = &(<IImage&>ptr_grab_result)
            if not img.IsValid():
                logging.error("{}: ret=True, Grab Success, Image is Invalid!".format(funcArgs))
                raise RuntimeError('IImage is not valid.')

            if img.GetImageSize() % img.GetHeight():
                logging.error("Non-standard Image Size Encountered: size={}, height={}, width={}, padX={}".format(img.GetImageSize(), img.GetHeight(), img.GetWidth(), img.GetPaddingX() ) )

            padX = img.GetPaddingX()
            if ( padX > 0 ):
                raise RuntimeError(
                    "PadX={}: X Dimension Padding Unhandled".format(padX)
                )

            chs,bitDepth = _fmtLookup[ img.GetPixelType() ]
            logging.debug(
                "Pixel Format: chs={}, pixdepth={}".format(chs, bitDepth)
            )
            npdtype = "uint{}".format(bitDepth)
            img_data = np.frombuffer(
                (<char*>img.GetBuffer())[:img.GetImageSize()], dtype=npdtype
            )

            if ( chs == 1 ):
                frame = img_data.reshape((img.GetHeight(), -1))
            else:
                frame = img_data.reshape((img.GetHeight(), -1, chs))

            orient = img.GetOrientation()
            if ( orient == ImageOrientation_BottomUp ):
                logging.debug("Flipping image vertically")
                frame = np.flipup(frame)

            yield frame

    def grab_image(self, unsigned int timeout=5000):
        return next(self.grab_images(1, timeout))

    property properties:
        def __get__(self):
            return _PropertyMap.create(&self.camera.GetNodeMap())

    def is_usb(self):
        return(self.camera.IsUsb())

    def is_gige(self):
        return(self.camera.IsGigE())

    def is_cameralink(self):
        return(self.camera.IsCameraLink())

    def is_bcon(self):
        return(self.camera.IsBcon())

    ####################
    # Data Members
    ####################
    property MaxNumBuffer:
        def __get__(self):
            return( self.camera.MaxNumBuffer.GetValue() )
        def __set__(self, val):
            self.camera.MaxNumBuffer.SetValue(val)

    property MaxNumQueuedBuffer:
        def __get__(self):
            return( self.camera.MaxNumQueuedBuffer.GetValue() )
        def __set__(self, val):
            self.camera.MaxNumQueuedBuffer.SetValue(val)

    property MaxNumGrabResults:
        def __get__(self):
            return( self.camera.MaxNumGrabResults.GetValue() )
        def __set__(self, val):
            self.camera.MaxNumGrabResults.SetValue(val)

    property ChunkNodeMapsEnable:
        def __get__(self):
            return( self.camera.ChunkNodeMapsEnable.GetValue() )
        def __set__(self, val):
            self.camera.ChunkNodeMapsEnable.SetValue(val)

    property StaticChunkNodeMapPoolSize:
        def __get__(self):
            return( self.camera.StaticChunkNodeMapPoolSize.GetValue() )
        def __set__(self, val):
            self.camera.StaticChunkNodeMapPoolSize.SetValue(val)

    property GrabCameraEvents:
        def __get__(self):
            return( self.camera.GrabCameraEvents.GetValue() )
        def __set__(self, val):
            self.camera.GrabCameraEvents.SetValue(val)

    property MonitorModeActive:
        def __get__(self):
            return( self.camera.MonitorModeActive.GetValue() )
        def __set__(self, val):
            self.camera.MonitorModeActive.SetValue(val)

    property NumQueuedBuffers:
        def __get__(self):
            return( self.camera.NumQueuedBuffers.GetValue() )

    property NumReadyBuffers:
        def __get__(self):
            return( self.camera.NumReadyBuffers.GetValue() )

    property NumEmptyBuffers:
        def __get__(self):
            return( self.camera.NumEmptyBuffers.GetValue() )

    property OutputQueueSize:
        def __get__(self):
            return( self.camera.OutputQueueSize.GetValue() )
        def __set__(self, val):
            self.camera.OutputQueueSize.SetValue(val)

    property InternalGrabEngineThreadPriorityOverride:
        def __get__(self):
            return( self.camera.InternalGrabEngineThreadPriorityOverride.GetValue() )
        def __set__(self, val):
            self.camera.InternalGrabEngineThreadPriorityOverride.SetValue(val)

    property InternalGrabEngineThreadPriority:
        # Does not seem writable
        def __get__(self):
            return( self.camera.InternalGrabEngineThreadPriority.GetValue() )

    property GrabLoopThreadUseTimeout:
        def __get__(self):
            return( self.camera.GrabLoopThreadUseTimeout.GetValue() )
        def __set__(self, val):
            self.camera.GrabLoopThreadUseTimeout.SetValue(val)

    property GrabLoopThreadTimeout:
        def __get__(self):
            return( self.camera.GrabLoopThreadTimeout.GetValue() )
        def __set__(self, val):
            self.camera.GrabLoopThreadTimeout.SetValue(val)

    property GrabLoopThreadPriorityOverride:
        def __get__(self):
            return( self.camera.GrabLoopThreadPriorityOverride.GetValue() )
        def __set__(self, val):
            self.camera.GrabLoopThreadPriorityOverride.SetValue(val)

    property GrabLoopThreadPriority:
        # Does Not seem writable
        def __get__(self):
            return( self.camera.GrabLoopThreadPriority.GetValue() )


cdef class Factory:
    def __cinit__(self):
        PylonInitialize()

    def __dealloc__(self):
        PylonTerminate()

    def find_devices(self):
        cdef CTlFactory* tl_factory = &GetInstance()
        cdef DeviceInfoList_t devices

        cdef int nr_devices = tl_factory.EnumerateDevices(devices)

        found_devices = list()

        # Iterate through the discovered devices
        cdef DeviceInfoList_t.iterator it = devices.begin()
        while it != devices.end():
            found_devices.append(DeviceInfo.create(deref(it)))
            inc(it)

        return found_devices

    def create_device(self, DeviceInfo dev_info):
        cdef CTlFactory* tl_factory = &GetInstance()
        return Camera.create(tl_factory.CreateDevice(dev_info.dev_info))