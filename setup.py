from setuptools import setup, find_packages
from Cython.Distutils import build_ext, Extension
import subprocess as sp
import os
import os.path
import sys
import numpy
import glob

def pylon_config(*args, **kwargs):
    """ Invoke pylon-config and get the result
    """
    path = kwargs.get("path", '/opt/pylon5/bin/pylon-config')
    splitby = kwargs.get("splitby", None)

    cmd = [path]
    cmd.extend(args)
    output = sp.check_output(cmd).decode()
    if ( splitby is not None ):
        comps = output.split(splitby)
        ret = [x.strip() for x in comps ]
        ret = [x for x in ret if len(x) > 0]
    else:
        ret = [output.strip()]
    return(ret)

def detect_pylon():
    cconfig = dict()
    cconfig['library_dirs'] = pylon_config("--libdir")
    cconfig['include_dirs'] = pylon_config("--cflags-only-I", splitby="-I")
    cconfig['libraries'] = pylon_config("--libs-only-l", splitby="-l")
    cconfig['runtime_library_dirs'] = cconfig['library_dirs']
    cconfig["extra_link_args"] = pylon_config("--libs-rpath", splitby=" ")
    print("Compiler Config: {}".format(cconfig))
    return cconfig

def is_windows_64bit():
    if 'PROCESSOR_ARCHITEW6432' in os.environ:
        return True
    return os.environ['PROCESSOR_ARCHITECTURE'].endswith('64')

def fake_detect_pylon_windows(pylon_dir=r'C:\Program Files\Basler\pylon 5'):
    if not os.path.isdir(pylon_dir):
        raise RuntimeError('Pylon directory not found')

    if not os.path.isdir(os.path.join(pylon_dir, 'Development')):
        raise RuntimeError('You need to install Pylon with the development options')

    arch = 'x64' if is_windows_64bit() else 'Win32'

    compiler_config = dict()
    compiler_config['include_dirs'] = [
        os.path.join(pylon_dir, 'Development', 'include')
    ]
    compiler_config['library_dirs'] = [
        os.path.join(pylon_dir, 'Runtime', arch),
        os.path.join(pylon_dir, 'Development', 'lib', arch)
    ]
    compiler_config['libraries'] = list([
        elem[:-4] for elem in os.listdir(
            os.path.join(pylon_dir, 'Development', 'lib', arch)
        )
        if  elem.endswith('.lib')
    ])
    return compiler_config

def fake_detect_pylon_osx(pylon_dir='/Library/Frameworks/pylon.framework'):
    if not os.path.isdir(pylon_dir):
        raise RuntimeError('Pylon framework not found')

    compiler_config = dict()
    compiler_config['include_dirs'] = [
        os.path.join(pylon_dir, 'Headers'),
        os.path.join(pylon_dir, 'Headers', 'GenICam')
    ]

    compiler_config['extra_link_args'] = [
        '-rpath', os.path.join(*os.path.split(pylon_dir)[:-1]),
        '-framework', 'pylon'
    ]
    return compiler_config


if sys.platform == 'win32':
    build_options = fake_detect_pylon_windows()
elif sys.platform == 'darwin':
    build_options = fake_detect_pylon_osx()
else:
    build_options = detect_pylon()

# Set build language
build_options['language'] = 'c++'

# Add numpy build options
build_options['include_dirs'].append(numpy.get_include())

pypylon_extensions = [
    Extension(
        'pypylon.cython.version', ['cython/version.pyx', ], **build_options
    ),
    Extension(
        'pypylon.cython.factory', ['cython/factory.pyx' ], **build_options
    ),
]

setup(
    name='pypylon',
    license="custom",
    description="Cython module to provide access to Pylon's SDK.",
    version='0.0.1',
    author="Matthias Blaicher",
    author_email="matthias@blaicher.com",
    cmdclass={'build_ext': build_ext},
    ext_modules=pypylon_extensions,
    packages=find_packages(exclude=['contrib', 'docs', 'tests', 'examples', 'cython']),

    # for the classifiers review see:
    # https://pypi.python.org/pypi?%3Aaction=list_classifiers
    classifiers=[
        'Development Status :: 3 - Alpha',

        'Intended Audience :: Developers',
        'Topic :: Multimedia :: Graphics :: Capture :: Digital Camera'

        'License :: OSI Approved :: BSD License',

        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.2',
        'Programming Language :: Python :: 3.3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
    ],
)
