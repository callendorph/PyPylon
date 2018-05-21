# PyPylon
An experimental python wrapper around the Basler Pylon 5 library.
Its initial ideas were inspired by the [python-pylon](https://github.com/srgblnch/python-pylon) which is also a cython based wrapper around the Basler pylon library.

However, in contrast to `python-pylon` this code directly instanciates the Pylon C++ classes inside the cython code instead of adding another C++ abstraction layer. In addition it tries to automagically configure your build environment and to provide you with a PEP8 conform pythonic access to your camera.

While the basic code seems to work, I'd like to point out, that it still in early alpha stage. You will probably stumble over bugs.

## Current TODO list and development targets
 - [x] Test with color cameras
 - [x] Handle different image packing other than Mono8
 - [x] Try triggered images and such
 - [ ] Add some callbacks on events
 - [ ] Test code under Windows/OSX

CJA: I've taken the existing code and updated it for 5.0.12:
 - Added handling for limited set multichannel images (ie, RGB8, BGR8, BGRA8, YCbCr, etc.)
 - Added better exception handling - ie, Pylon::GenericException gets mapped to a RuntimeError now.
 - Added better configuration and control of the grabbing mechanism.
 - Added ability to get/set enumerated types. I've also added some code to extract the symbolic values of enumerated types into python enums.
 - Added image frame meta-data like timestamp, blockid, skipped frames, etc.
 - Added check for accessibility on the device. If you try to open a device that is already open, it throws a nasty terminate exception that can't be caught in cython.
 - I'm primarily testing in py2.7 - so there may be dragons in py3.x. Submit a PR if you think there is a bug.

## Simple usage example
```python
>>> import pypylon
>>> pypylon.pylon_version.version
'5.0.1.build_6388'
>>> available_cameras = pypylon.factory.find_devices()
>>> available_cameras
[<DeviceInfo Basler acA2040-90um (xxxxxxx)>]
>>> cam = pypylon.factory.create_device(available_cameras[0])
>>> cam.opened
False
>>> cam.open()

>>> cam.properties['ExposureTime']
10000.0
>>> cam.properties['ExposureTime'] = 1000
>>> # Go to full available speed
... cam.properties['DeviceLinkThroughputLimitMode'] = 'Off'
>>>

>>> import matplotlib.pyplot as plt
>>> for image,meta in cam.grab_images(1):
...     print(meta)
...     plt.imshow(image)
...     plt.show()
```

## Grabbing with your own loop
```python
>>> import pypylon as pylon
>>> import cv2
>>> pylon.pylon_version.version
'5.0.12.build_11829'
>>> available_cameras = pylon.factory.find_devices()
>>> cam = pylon.factory.create_device(available_cameras[0])
>>> cam.opened
False
>>> cam.open()
>>> cam.MaxNumBuffer = 5
>>> cam.properties["PixelFormat"] = "RGB8"
>>> cam.start_grabbing(
...     pylon.GrabStrategy.LatestImageOnly,
...     pylon.GrabLoop.ProvidedByUser
...     )
>>> while(True):
...     img, meta = cam.read(1000)
...     if ( meta.skipped > 0 ):
...         print("Skipped Frames: {}".format(meta.skipped))
...     cv2.imshow("vid", img)
...     k = cv2.waitKey(1)
...     if ( key == ord('q') ):
...         break
```
