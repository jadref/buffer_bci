from distutils.core import setup

try:
    import numpy


except ImportError:
    print "FieldTrip buffer works better with numpy."

setup(name='FieldTrip',
  version='1.0',
  description='Python Fieldtrip Client',
  author='S. Klanke',
  url='https://github.com/jadref/buffer_bci/',
  py_modules = ['FieldTrip']
 )