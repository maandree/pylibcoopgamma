# -*- python -*-
'''
pylibcoopgamma -- Python library for interfacing with cooperative gamma servers
Copyright (C) 2016  Mattias Andrée (maandree@kth.se)

This library is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this library.  If not, see <http://www.gnu.org/licenses/>.
'''

import enum, libcoopgamma_native


class Support(enum.IntEnum):
    '''
    Values used to indicate the support for gamma adjustments
    
    @value  NO=0     Gamma adjustments are not supported
    @value  MAYBE=1  Don't know whether gamma adjustments are supported
    @value  YES=2    Gamma adjustments are supported
    '''
    NO = 0
    MAYBE = 1
    YES = 2
    
    @staticmethod
    def str(v):
        '''
        Get string representation of a value
        
        @param   v:int  The value, must be value of the enum
        @return  :str   Human-readable string representation of the value
        '''
        if v == Support.NO:
            return 'no'
        if v == Support.YES:
            return 'yes'
        if v == Support.MAYBE:
            return 'maybe'
        raise ValueError()


class Depth(enum.IntEnum):
    '''
    Values used to tell which datatype is used for the gamma ramp stops
    
    The values will always be the number of bits for integral types, and
    negative for floating-point types
    
    @value  UINT8=8    Unsigned 8-bit integer
    @value  UINT16=16  Unsigned 16-bit integer
    @value  UINT32=32  Unsigned 32-bit integer
    @value  UINT64=64  Unsigned 64-bit integer
    @value  FLOAT<0    Single-precision floating-point
    @value  DOUBLE<0   Double-precision floating-point
    '''
    UINT8 = 8
    UINT16 = 16
    UINT32 = 32
    UINT64 = 64
    FLOAT = -1
    DOUBLE = -2
    
    @staticmethod
    def str(v):
        '''
        Get string representation of a value
        
        @param   v:int  The value, must be value of the enum
        @return  :str   Human-readable string representation of the value
        '''
        if v == Depth.UINT8:
            return '8-bits'
        if v == Depth.UINT16:
            return '16-bits'
        if v == Depth.UINT32:
            return '32-bits'
        if v == Depth.UINT64:
            return '64-bits'
        if v == Depth.FLOAT:
            return 'single-precision floating-point'
        if v == Depth.DOUBLE:
            return 'double-precision floating-point'
        raise ValueError()


class Lifespan(enum.IntEnum):
    '''
    Values used to tell when a filter should be removed
    
    @value  REMOVE=0         Remove the filter now
    @value  UNTIL_DEATH>0    Remove the filter when disconnecting from the coopgamma server
    @value  UNTIL_REMOVAL>0  Only remove the filter when it is explicitly requested
    '''
    REMOVE = 0
    UNTIL_DEATH = 1
    UNTIL_REMOVAL = 2
    
    @staticmethod
    def str(v):
        '''
        Get string representation of a value
        
        @param   v:int  The value, must be value of the enum
        @return  :str   Human-readable string representation of the value
        '''
        if v == Lifespan.REMOVE:
            return 'remove'
        if v == Lifespan.UNTIL_DEATH:
            return 'until death'
        if v == Lifespan.UNTIL_REMOVAL:
            return 'until removal'
        raise ValueError()


class Colourspace(enum.IntEnum):
    '''
    Colourspaces
    
    @value  UNKNOWN=0  The colourspace is unknown
    @value  SRGB>0     sRGB (Standard RGB)
    @value  RGB>0      RGB other than sRGB
    @value  NON_RGB>0  Non-RGB multicolour
    @value  GREY>0     Monochrome, greyscale, or some other singlecolour scale
    '''
    UNKNOWN = 0
    SRGB = 1
    RGB = 2
    NON_RGB = 3
    GREY = 4
    
    @staticmethod
    def str(v):
        '''
        Get string representation of a value
        
        @param   v:int  The value, must be value of the enum
        @return  :str   Human-readable string representation of the value
        '''
        if v == Colourspace.UNKNOWN:
            return 'unknown'
        if v == Colourspace.SRGB:
            return 'sRGB'
        if v == Colourspace.RGB:
            return 'RGB'
        if v == Colourspace.NON_RGB:
            return 'non-RGB'
        if v == Colourspace.GREY:
            return 'greyscale'
        raise ValueError()


class Ramps:
    '''
    Gamma ramp structure
    
    @variable  red:list<int>    The red gamma ramp
    @variable  green:list<int>  The green gamma ramp
    @variable  blue:list<int>   The blue gamma ramp
    '''
    def __init__(self, red, green, blue):
        '''
        Constructor
        
        @param  red:int    The number of stops in the red ramp
        @param  green:int  The number of stops in the green ramp
        @param  blue:int   The number of stops in the blue ramp
        
        -- or --
        
        @param  red:list<int>    The red gamma ramp
        @param  green:list<int>  The green gamma ramp
        @param  blue:list<int>   The blue gamma ramp
        '''
        if isinstance(red, list):
            self.red   = list(red)
            self.green = list(green)
            self.blue  = list(blue)
        else:
            self.red   = [0] * red
            self.green = [0] * green
            self.blue  = [0] * blue
    
    def clone(self):
        '''
        Create a copy of the instance
        '''
        return Ramps(self.red, self.green, self.blue)
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        params = (self.red, self.green, self.blue)
        return 'libcoopgamma.Ramps(%s)' % ', '.join(repr(p) for p in params)


class Filter:
    '''
    Data set to the coopgamma server to apply, update, or remove a filter
    
    @variable  priority:int       The priority of the filter, higher priority
                                  is applied first. The gamma correction should
                                  have priority 0. This is a signed 64-bit integer.
    @variable  crtc:str           The CRTC for which this filter shall be applied 
    @variable  fclass:str         Identifier for the filter.
                                  The syntax must be "${PACKAGE_NAME}::${COMMAND_NAME}::${RULE}".
    @variable  lifespan:Lifespan  When shall the filter be removed?
                                  If this member's value is `LIBCOOPGAMMA_REMOVE`,
                                  only `.crtc` and `.class` need also be defined.
    @variable  depth:Depth        The data type and bit-depth of the ramp stops
    @variable  ramps:Ramps        The gamma ramp adjustments of the filter
    '''
    def __init__(self, priority = None, crtc = None, fclass = None, lifespan = None, depth = None, ramps = None):
        '''
        Constructor
        
        @param  priority:int       The priority of the filter, higher priority
                                   is applied first. The gamma correction should
                                   have priority 0. This is a signed 64-bit integer.
        @param  crtc:str           The CRTC for which this filter shall be applied 
        @param  fclass:str         Identifier for the filter.
                                   The syntax must be "${PACKAGE_NAME}::${COMMAND_NAME}::${RULE}".
        @param  lifespan:Lifespan  When shall the filter be removed?
                                   If this member's value is `LIBCOOPGAMMA_REMOVE`,
                                   only `.crtc` and `.class` need also be defined.
        @param  depth:Depth        The data type and bit-depth of the ramp stops
        @param  ramps:Ramps        The gamma ramp adjustments of the filter
        '''
        self.priority = priority
        self.crtc = crtc
        self.fclass = fclass
        self.lifespan = lifespan
        self.depth = depth
        self.ramps = ramps
    
    def clone(self, shallow = False):
        '''
        Create a copy of the instance
        
        @param  shallow:bool  Create a shallow copy?
        '''
        ramps = self.ramps if shallow else self.ramps.clone()
        return Filter(self.priority, self.crtc, self.fclass, self.lifespan, self.depth, ramps)
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        params = (self.priority, self.crtc, self.fclass, self.lifespan, self.depth, self.ramps)
        return 'libcoopgamma.Filter(%s)' % ', '.join(repr(p) for p in params)


class GamutPoint:
    '''
    The x- and y-values (CIE xyY) of a colour
    
    @variable  x_raw:int  The x-value (CIE xyY) multiplied by 1024
    @variable  y_raw:int  The y-value (CIE xyY) multiplied by 1024
    @variable  x:int      The x-value (CIE xyY)
    @variable  y:int      The y-value (CIE xyY)
    '''
    def __init__(self, x, y):
        '''
        Constructor
        
        @param  x:int  The x-value (CIE xyY) multiplied by 1024
        @param  y:int  The y-value (CIE xyY) multiplied by 1024
        '''
        self.x_raw, self.x = x, x / 1024
        self.y_raw, self.y = y, y / 1024
    
    def clone(self):
        '''
        Create a copy of the instance
        '''
        return GamutPoint(self.x_raw, self.y_raw)
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        params = (self.x_raw, self.y_raw)
        return 'libcoopgamma.GamutPoint(%s)' % ', '.join(repr(p) for p in params)
    
    def __str__(self):
        '''
        Get human-readable string representation of instance
        
        @return  :str  Human-readable string representation of instance
        '''
        return '(%f, %f)' % (self.x, self.y)


class Gamut:
    '''
    The values of the monitor's colour stimuli
    
    @variable  red:GamutPoint    The red stimuli
    @variable  green:GamutPoint  The green stimuli
    @variable  blue:GamutPoint   The blue stimuli
    @variable  white:GamutPoint  The default whitepoint
    '''
    def __init__(self, red = None, green = None, blue = None, white = None):
        '''
        Constructor
        
        @param  red:GamutPoint|(int, int)    The red stimuli
        @param  green:GamutPoint|(int, int)  The green stimuli
        @param  blue:GamutPoint|(int, int)   The blue stimuli
        @param  white:GamutPoint|(int, int)  The default whitepoint
        '''
        self.red   = GamutPoint(*red)   if isinstance(red,   tuple) else red
        self.green = GamutPoint(*green) if isinstance(green, tuple) else green
        self.blue  = GamutPoint(*blue)  if isinstance(blue,  tuple) else blue
        self.white = GamutPoint(*white) if isinstance(white, tuple) else white
    
    def clone(self, shallow = True):
        '''
        Create a copy of the instance
        
        @param  shallow:bool  Create a shallow copy?
        '''
        if shallow:
            return Gamut(self.red, self.green, self.blue, self.white)
        return Gamut(self.red.clone(), self.green.clone(), self.blue.clone(), self.white.clone())
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        params = (repr(self.red), repr(self.green), repr(self.blue), repr(self.white))
        return 'libcoopgamma.Gamut(%s)' % ', '.join(repr(p) for p in params)


class CRTCInfo:
    '''
    Gamma ramp meta information for a CRTC
    
    @variable  cooperative:bool         Is cooperative gamma server running?
    @variable  depth:Depth?             The data type and bit-depth of the ramp stops
    @variable  supported:Support        Is gamma adjustments supported on the CRTC?
                                        If not, `depth`, `red_size`, `green_size`,
                                        and `blue_size` are undefined
    @variable  red_size:int?            The number of stops in the red ramp
    @variable  green_size:int?          The number of stops in the green ramp
    @variable  blue_size:int?           The number of stops in the blue ramp
    @variable  colourspace:Colourspace  The monitor's colourspace
    @variable  gamut:Gamut?             Measurements of the monitor's colourspace,
                                        `None` if the this information is unavailable.
                                        If this is not `None`, but the colourspace
                                        is not RGB (or sRGB), there is something
                                        wrong. Always check the colourspace.
    '''
    def __init__(self, cooperative = None, depth = None, supported = None, red_size = None,
                 green_size = None, blue_size = None, colourspace = None, gamut = None):
        '''
        Constructor
        
        @param  cooperative:bool         Is cooperative gamma server running?
        @param  depth:Depth?             The data type and bit-depth of the ramp stops
        @param  supported:Support        Is gamma adjustments supported on the CRTC?
                                         If not, `depth`, `red_size`, `green_size`,
                                         and `blue_size` are undefined
        @param  red_size:int?            The number of stops in the red ramp
        @param  green_size:int?          The number of stops in the green ramp
        @param  blue_size:int?           The number of stops in the blue ramp
        @param  colourspace:Colourspace  The monitor's colourspace
        @param  gamut:Gamut|tuple?       Measurements of the monitor's colourspace,
                                         `None` if the this information is unavailable
        '''
        self.cooperative = cooperative
        self.depth = depth
        self.supported = supported
        self.red_size = red_size
        self.green_size = green_size
        self.blue_size = blue_size
        self.colourspace = colourspace
        if gamut is None or isinstance(gamut, Gamut):
            self.gamut = gamut
        else:
            self.gamut = Gamut(*gamut)
    
    def make_ramps(self):
        '''
        Construct a `Ramps` instances for this CRTC
        
        @return  :Ramps  An instance of `Ramps` with same a number of ramp stops
                         matching this CRTC
        '''
        return Ramps(self.red_size, self.green_size, self.blue_size)
    
    def clone(self, shallow = True):
        '''
        Create a copy of the instance
        
        @param  shallow:bool  Create a shallow copy?
        '''
        return CRTCInfo(self.cooperative, self.depth, self.supported, self.red_size,
                        self.green_size, self.blue_size, self.colourspace,
                        self.gamut if shallow else self.gamut.clone())
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        params = (self.cooperative, self.depth, self.supported, self.red_size,
                  self.green_size, self.blue_size, self.colourspace, self.gamut)
        return 'libcoopgamma.CRTCInfo(%s)' % ', '.join(repr(p) for p in params)


class FilterQuery:
    '''
    Data sent to the coopgamma server when requestng the current filter table
    
    @variable  high_priority:int  Do no return filters with higher priority than
                                  this value. This is a signed 64-bit integer.
    @variable  low_priority:int   Do no return filters with lower priority than
                                  this value. This is a signed 64-bit integer.
    @variable  crtc:str           The CRTC for which the the current filters shall returned
    @variable  coalesce:bool      Whether to coalesce all filters into one gamma ramp triplet
    '''
    def __init__(self, high_priority = 9223372036854775807,
                 low_priority = -9223372036854775808, crtc = None, coalesce = False):
        '''
        Constructor
        
        @param  high_priority:int  Do no return filters with higher priority than
                                   this value. This is a signed 64-bit integer.
        @param  low_priority:int   Do no return filters with lower priority than
                                   this value. This is a signed 64-bit integer.
        @param  crtc:str           The CRTC for which the the current filters shall returned
        @param  coalesce:bool      Whether to coalesce all filters into one gamma ramp triplet
        '''
        self.high_priority = high_priority
        self.low_priority = low_priority
        self.crtc = crtc
        self.coalesce = coalesce
    
    def clone(self):
        '''
        Create a copy of the instance
        '''
        return FilterQuery(self.high_priority, self.low_priority, self.crtc, self.coalesce)
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        params = (self.high_priority, self.low_priority, self.crtc, self.coalesce)
        return 'libcoopgamma.FilterQuery(%s)' % ', '.join(repr(p) for p in params)


class QueriedFilter:
    '''
    Stripped down version of `Filter` which only contains the
    information returned in response to "Command: get-gamma"
    
    @variable  priority:int  The filter's priority. This is a signed 64-bit integer.
    @variable  fclass:str    The filter's class
    @variable  ramps:Ramps   The gamma ramp adjustments of the filter
    '''
    def __init__(self, priority = None, fclass = None, ramps = None):
        '''
        Constructor
        
        @param  priority:int       The filter's priority. This is a signed 64-bit integer.
        @param  fclass:str         The filter's class
        @param  ramps:Ramps|tuple  The gamma ramp adjustments of the filter
        '''
        self.priority = priority
        self.fclass = fclass
        self.ramps = None
        if ramps is not None:
            self.ramps = Ramps(*ramps) if isinstance(ramps, tuple) else ramps
    
    def clone(self, shallow = False):
        '''
        Create a copy of the instance
        
        @param  shallow:bool  Create a sallow copy?
        '''
        ramps = self.ramps if shallow else self.ramps.clone()
        return QueriedFilter(self.priority, self.fclass, ramps)
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        params = (self.priority, self.fclass, self.ramps)
        return 'libcoopgamma.QueriedFilter(%s)' % ', '.join(repr(p) for p in params)


class FilterTable:
    '''
    Response type for "Command: get-gamma": a list of applied filters
    and meta-information that was necessary for decoding the response
    
    @variable  red_size:int                 The number of stops in the red ramp
    @variable  green_size:int               The number of stops in the green ramp
    @variable  blue_size:int                The number of stops in the blue ramp
    @variable  depth:Depth                  The data type and bit-depth of the ramp stops
    @variable  filters:list<QueriedFilter>  The filters, should be ordered by priority
                                            in descending order, lest there is something
                                            wrong with the coopgamma server.
                                            If filter coalition was requested, there will
                                            be exactly one filter and `filters[0].class`
                                            and `filters[0].priority` are undefined.
    '''
    def __init__(self, red_size = None, green_size = None, blue_size = None, depth = None, filters = None):
        '''
        Constructor 
        
        @param  red_size:int                       The number of stops in the red ramp
        @param  green_size:int                     The number of stops in the green ramp
        @param  blue_size:int                      The number of stops in the blue ramp
        @param  depth:Depth                        The data type and bit-depth of the ramp stops
        @param  filters:list<QueriedFilter|tuple>  The filters, should be ordered by priority
                                                   in descending order, lest there is something
                                                   wrong with the coopgamma server.
                                                   If filter coalition was requested, there will
                                                   be exactly one filter and `filters[0].class`
                                                   and `filters[0].priority` are undefined.
        '''
        self.red_size   = red_size
        self.green_size = green_size
        self.blue_size  = blue_size
        self.depth      = depth
        if filters is None:
            self.filters
        else:
            self.filters    = list(QueriedFilter(*f) if isinstance(f, tuple) else f for f in filters)
    
    def make_ramps(self):
        '''
        Construct a `Ramps` instances for this CRTC
        
        @return  :Ramps  An instance of `Ramps` with same a number of ramp stops
                         matching this CRTC
        '''
        return Ramps(self.red_size, self.green_size, self.blue_size)
    
    def clone(self, shallow = False):
        '''
        Create a copy of the instance
        
        @param  shallow:bool  Create a sallow copy?
        '''
        filters = list(self.filters) if shallow else [f.clone() for f in self.filters]
        return FilterTable(self.red_size, self.green_size, self.blue_size, self.depth, filters)
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        params = (self.red_size, self.green_size, self.blue_size, self.depth, self.filters)
        return 'libcoopgamma.FilterTable(%s)' % ', '.join(repr(p) for p in params)


class ErrorReport:
    '''
    Error message from coopgamma server
    
    @variable  number:int        The error code. If `.custom` is false, 0 indicates success,
                                 otherwise, 0 indicates that no error code has been assigned.
    @variable  custom:bool       Is this a custom error?
    @variable  server_side:bool  Did the error occur on the server-side?
    @variable  description:str?  Error message, can be `None` if `custom` is false
    '''
    def __init__(self, number = None, custom = None, server_side = None, description = None):
        '''
        Constructor
        
        @param  number:int        The error code. If `.custom` is false, 0 indicates success,
                                  otherwise, 0 indicates that no error code has been assigned.
        @param  custom:bool       Is this a custom error?
        @param  server_side:bool  Did the error occur on the server-side?
        @param  description:str?  Error message, can be `None` if `custom` is false
        '''
        self.number = number
        self.custom = custom
        self.server_side = server_side
        self.description = description
    
    def clone(self):
        '''
        Create a copy of the instance
        '''
        return ErrorReport(self.number, self.custom, self.server_side, self.description)
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        params = (self.number, self.custom, self.server_side, self.description)
        return 'libcoopgamma.ErrorReport(%s)' % ', '.join(repr(p) for p in params)
    
    @staticmethod
    def create_error(error):
        '''
        Create an instance of a subclass of `Exception`
        
        @param  error  Error information
        '''
        if isinstance(error, int):
            import os
            return OSError(error, os.strerror(error))
        error = ErrorReport(*error)
        if not error.custom and not error.server_side:
            import os
            return OSError(error.number, os.strerror(error.number))
        else:
            return LibcoopgammaError(error)


class LibcoopgammaError(Exception):
    '''
    libcoopgamma error class
    
    @variable  error:ErrorReport  Error information
    '''
    def __init__(self, error):
        '''
        Constructor
        
        @param  error:ErrorReport  Error information
        '''
        self.error = error
    
    def __str__(self):
        '''
        Return description and error number as a string
        
        @return  :str  Description and error number
        '''
        if self.error.description is not None:
            if self.error.number != 0:
                return '%s (#%i)' % (self.error.description, self.error.number)
            else:
                return '%s' % self.error.description
        else:
            return '#%i' % self.error.number
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        return 'libcoopgamma.LibcoopgammaError(%s)' % repr(self.error)


class IncompatibleDowngradeError(Exception):
    '''
    Unmarshalled state from a newer version, that is not supported, of libcoopgamma
    '''
    def __init__(self):
        '''
        Constructor
        '''
        pass
    
    def __str__(self):
        '''
        Return descriptor of the error
        
        @return  :str  Descriptor of the error
        '''
        return 'Incompatible downgrade error'
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        return 'libcoopgamma.IncompatibleDowngradeError()'


class IncompatibleUpgradeError(Exception):
    '''
    Unmarshalled state from an older version, that is no longer supported, of libcoopgamma
    '''
    def __init__(self):
        '''
        Constructor
        '''
        pass
    
    def __str__(self):
        '''
        Return descriptor of the error
        
        @return  :str  Descriptor of the error
        '''
        return 'Incompatible downgrade error'
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        return 'libcoopgamma.IncompatibleUpgradeErrorError()'


class ServerInitialisationError(Exception):
    '''
    coopgamma server failed to initialise, reason unknown
    '''
    def __init__(self):
        '''
        Constructor
        '''
        pass
    
    def __str__(self):
        '''
        Return descriptor of the error
        
        @return  :str  Descriptor of the error
        '''
        return 'Server initialisation error'
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        return 'libcoopgamma.ServerInitialisationError()'


class Context:
    '''
    Library state
    
    Use of this structure is not thread-safe, create
    one instance per thread that uses this structure
    
    @variable  fd:int  File descriptor for the socket
    '''
    def __init__(self, fd = -1, buf = None):
        '''
        Constructor
        
        @param  fd:int      File descriptor for the socket
        @param  buf:bytes?  Buffer to unmarshal
        '''
        self.address = None
        self.fd = fd
        if buf is None:
            (successful, value) = libcoopgamma_native.libcoopgamma_native_context_create()
            if not successful:
                raise ErrorReport.create_error(value)
        else:
            (error, value) = libcoopgamma_native.libcoopgamma_native_context_unmarshal(buf)
            if error < 0:
                raise ErrorReport.create_error(value)
            elif error == 1:
                raise IncompatibleDowngradeError()
            elif error == 2:
                raise IncompatibleUpgradeError()
        self.address = value
    
    def __del__(self):
        '''
        Destructor
        '''
        if self.address is not None:
            libcoopgamma_native.libcoopgamma_native_context_free(self.address)
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        data = libcoopgamma_native.libcoopgamma_native_context_marshal(self.address)
        if isinstance(data, int):
            raise ErrorReport.create_error(data)
        params = (self.fd, data)
        return 'libcoopgamma.Context(%s)' % ', '.join(repr(p) for p in params)
    
    def connect(self, method = None, site = None):
        '''
        Connect to a coopgamma server, and start it if necessary
        
        Use `del` keyword to disconnect
        
        SIGCHLD must not be ignored or blocked
        
        All other methods in this class requires that this
        method has been called successfully
        
        @param  method:int|str?  The adjustment method, `None` for automatic
        @param  site:str?        The site, `None` for automatic
        '''
        if method is not None and isinstance(method, int):
            method = str(method)
        (successful, value) = libcoopgamma_native.libcoopgamma_native_connect(method, site, self.address)
        if not successful:
            if value == 0:
                raise ServerInitialisationError()
            else:
                raise ErrorReport.create_error(value)
        self.fd = value
    
    def detach(self):
        '''
        After calling this function, communication with the
        server is impossible, but the connection is not
        closed and the when the instance is destroyed the
        connection will remain
        '''
        libcoopgamma_native.libcoopgamma_native_context_set_fd(self.address, -1)
    
    def attach(self):
        '''
        Undoes the action of `detach`
        '''
        libcoopgamma_native.libcoopgamma_native_context_set_fd(self.address, self.fd)
    
    def set_nonbreaking(self, nonbreaking):
        '''
        By default communication is blocking, this function
        can be used to switch between blocking and nonblocking
        
        After setting the communication to nonblocking, `flush`, `synchronise` and
        and request-sending functions can fail with EAGAIN and EWOULDBLOCK. It is
        safe to continue with `flush` (for `flush` it selfand equest-sending functions)
        or `synchronise` just like EINTR failure.
        
        @param  nonblocking:bool  Nonblocking mode?
        '''
        error = libcoopgamma_native.libcoopgamma_native_set_nonblocking(self.address, nonbreaking)
        if error != 0:
            raise ErrorReport.create_error(error)
    
    def flush(self):
        '''
        Send all pending outbound data
        
        If this function or another function that sends a request to the server fails
        with EINTR, call this function to complete the transfer. The `async_ctx` parameter
        will always be in a properly configured state if a function fails with EINTR.
        '''
        error = libcoopgamma_native.libcoopgamma_native_flush(self.address)
        if error != 0:
            raise ErrorReport.create_error(error)
    
    def synchronise(self, pending):
        '''
        Wait for the next message to be received
        
        @param   pending:list<AsyncContext>  Information for each pending request
        @return  :int?                       The index of the element in `pending` which corresponds
                                             to the first inbound message, note that this only means
                                             that the message is not for any of the other request,
                                             if the message is corrupt any of the listed requests can
                                             be selected even if it is not for any of the requests.
                                             Functions that parse the message will detect such corruption.
                                             `None` if the message is ignored, which happens if
                                             corresponding AsyncContext is not listed.
        '''
        pending = [p.address for p in pending]
        (successful, value) = libcoopgamma_native.libcoopgamma_native_synchronise(self.address, pending)
        if not successful:
            if value == 0:
                return None
            else:
                raise ErrorReport.create_error(value)
        else:
            return value
    
    def skip_message(self):
        '''
        Tell the library that you will not be parsing a receive message
        '''
        libcoopgamma_native.libcoopgamma_native_skip_message(self.address)
    
    def get_crtcs_send(self, async_ctx):
        '''
        List all available CRTC:s, send request part
        
        @param  async_ctx:AsyncContext  Slot for information about the request that is
                                        needed to identify and parse the response
        '''
        
        error = libcoopgamma_native.libcoopgamma_native_get_crtcs_send(self.address, async_ctx.address)
        if error != 0:
            raise ErrorReport.create_error(error)
    
    def get_crtcs_recv(self, async_ctx):
        '''
        List all available CRTC:s, receive response part
        
        @param   async_ctx:AsyncContext  Information about the request
        @return  :list<str>              A list of names. You should only free the outer
                                         pointer, inner pointers are subpointers of the
                                         outer pointer and cannot be freed.
        '''
        ret = libcoopgamma_native.libcoopgamma_native_get_crtcs_recv(self.address, async_ctx.address)
        if isinstance(ret, int):
            raise ErrorReport.create_error(ret)
        return ret
    
    def get_crtcs_sync(self):
        '''
        List all available CRTC:s, synchronous version
        
        This is a synchronous request function, as such, you have to ensure that
        communication is blocking (default), and that there are not asynchronous
        requests waiting, it also means that EINTR:s are silently ignored and
        there no wait to cancel the operation without disconnection from the server
        
        @return  :list<str>  A list of names. You should only free the outer pointer, inner
                             pointers are subpointers of the outer pointer and cannot be freed.
        '''
        ret = libcoopgamma_native.libcoopgamma_native_get_crtcs_sync(self.address)
        if isinstance(ret, int):
            raise ErrorReport.create_error(ret)
        return ret
    
    def get_gamma_info_send(self, crtc, async_ctx):
        '''
        Retrieve information about a CRTC:s gamma ramps, send request part
        
        @param  crtc:str                The name of the CRT
        @param  async_ctx:AsyncContext  Slot for information about the request that is
                                        needed to identify and parse the response
        '''
        error = libcoopgamma_native.libcoopgamma_native_get_gamma_info_send(crtc, self.address, async_ctx.address)
        if error != 0:
            raise ErrorReport.create_error(error)
    
    def get_gamma_info_recv(self, async_ctx):
        '''
        Retrieve information about a CRTC:s gamma ramps, receive response part
        
        @param   async_ctx:AsyncContext  Information about the request
        @return  :CRTCInfo               Information about the CRTC
        '''
        value = libcoopgamma_native.libcoopgamma_native_get_gamma_info_recv(self.address, async_ctx.address)
        if isinstance(value, int):
            raise ErrorReport.create_error(value)
        (successful, value) = value
        if not successful:
            raise ErrorReport.create_error(value)
        return CRTCInfo(*value)
    
    def get_gamma_info_sync(self, crtc):
        '''
        Retrieve information about a CRTC:s gamma ramps, synchronous version
        
        This is a synchronous request function, as such, you have to ensure that
        communication is blocking (default), and that there are not asynchronous
        requests waiting, it also means that EINTR:s are silently ignored and
        there no wait to cancel the operation without disconnection from the server
        
        @param   crtc:str   The name of the CRT
        @return  :CRTCInfo  Information about the CRTC
        '''
        value = libcoopgamma_native.libcoopgamma_native_get_gamma_info_sync(crtc, self.address)
        if isinstance(value, int):
            raise ErrorReport.create_error(value)
        (successful, value) = value
        if not successful:
            raise ErrorReport.create_error(value)
        return CRTCInfo(*value)
    
    def get_gamma_send(self, query, async_ctx):
        '''
        Retrieve the current gamma ramp adjustments, send request part
        
        @param  query:FilterQuery       The query to send
        @param  async_ctx:AsyncContext  Slot for information about the request that is
                                        needed to identify and parse the response
        '''
        error = libcoopgamma_native.libcoopgamma_native_get_gamma_send(
                                    query, self.address, async_ctx.address)
        if error != 0:
            raise ErrorReport.create_error(error)
    
    def get_gamma_recv(self, async_ctx):
        '''
        Retrieve the current gamma ramp adjustments, receive response part
        
        @param   async_ctx:AsyncContext  Information about the request
        @return  :FilterTable            Filter table
        '''
        value = libcoopgamma_native.libcoopgamma_native_get_gamma_recv(self.address, async_ctx.address)
        if isinstance(value, int):
            raise ErrorReport.create_error(value)
        (successful, value) = value
        if not successful:
            raise ErrorReport.create_error(value)
        return FilterTable(*value)
    
    def get_gamma_sync(self, query):
        '''
        Retrieve the current gamma ramp adjustments, synchronous version
        
        This is a synchronous request function, as such, you have to ensure that
        communication is blocking (default), and that there are not asynchronous
        requests waiting, it also means that EINTR:s are silently ignored and
        there no wait to cancel the operation without disconnection from the server
        
        @param   query:FilterQuery  The query to send
        @return  :FilterTable       Filter table
        '''
        value = libcoopgamma_native.libcoopgamma_native_get_gamma_sync(query, self.address)
        if isinstance(value, int):
            raise ErrorReport.create_error(value)
        (successful, value) = value
        if not successful:
            raise ErrorReport.create_error(value)
        return FilterTable(*value)
    
    def set_gamma_send(self, filtr, async_ctx):
        '''
        Apply, update, or remove a gamma ramp adjustment, send request part
        
        @param  filtr:Filter            The filter to apply, update, or remove, gamma ramp
                                        meta-data must match the CRTC's
        @param  async_ctx:AsyncContext  Slot for information about the request that is
                                        needed to identify and parse the response
        '''
        error = libcoopgamma_native.libcoopgamma_native_set_gamma_send(filtr, self.address, async_ctx.address)
        if error != 0:
            raise ErrorReport.create_error(error)
    
    def set_gamma_recv(self, async_ctx):
        '''
        Apply, update, or remove a gamma ramp adjustment, receive response part
        
        @param  async_ctx:AsyncContext  Information about the request
        '''
        error = libcoopgamma_native.libcoopgamma_native_set_gamma_recv(self.address, async_ctx.address)
        if error is not None:
            raise ErrorReport.create_error(error)
    
    def set_gamma_sync(self, filtr):
        '''
        Apply, update, or remove a gamma ramp adjustment, synchronous version
        
        This is a synchronous request function, as such, you have to ensure that
        communication is blocking (default), and that there are not asynchronous
        requests waiting, it also means that EINTR:s are silently ignored and
        there no wait to cancel the operation without disconnection from the server
        
        @param   filtr:Filter  The filter to apply, update, or remove,
                               gamma ramp meta-data must match the CRTC's
        '''
        error = libcoopgamma_native.libcoopgamma_native_set_gamma_sync(filtr, self.address)
        if error is not None:
            raise ErrorReport.create_error(error)


class AsyncContext:
    '''
    Information necessary to identify and parse a response from the server
    '''
    def __init__(self, buf = None):
        '''
        Constructor
        
        @param  buf:bytes?  Buffer to unmarshal
        '''
        self.address = None
        if buf is None:
            (successful, value) = libcoopgamma_native.libcoopgamma_native_async_context_create()
            if not successful:
                raise ErrorReport.create_error(value)
        else:
            (error, value) = libcoopgamma_native.libcoopgamma_native_async_context_unmarshal(buf)
            if error < 0:
                raise ErrorReport.create_error(value)
            elif error == 1:
                raise IncompatibleDowngradeError()
            elif error == 2:
                raise IncompatibleUpgradeError()
        self.address = value
    
    def __del__(self):
        '''
        Destructor
        '''
        if self.address is not None:
            libcoopgamma_native.libcoopgamma_native_async_context_free(self.address)
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        data = libcoopgamma_native.libcoopgamma_native_async_context_marshal(self.address)
        if isinstance(data, int):
            raise ErrorReport.create_error(data)
        return 'libcoopgamma.AsyncContext(%s)' % repr(data)


def get_methods():
    '''
    List all recognised adjustment method
    
    SIGCHLD must not be ignored or blocked
    
    @return  :list<str>  A list of names. You should only free the outer pointer, inner
                         pointers are subpointers of the outer pointer and cannot be freed.
    '''
    ret = libcoopgamma_native.libcoopgamma_native_get_methods()
    if isinstance(ret, int):
        raise ErrorReport.create_error(ret)
    return ret


def get_method_and_site(method = None, site = None):
    '''
    Get the adjustment method and site
    
    SIGCHLD must not be ignored or blocked
    
    @param   method:int|str?  The adjustment method, `None` for automatic
    @param   site:str?        The site, `None` for automatic
    @return  :(:str, :str?)   The selected adjustment method and the selected the
                              selected site. If the adjustment method only supports
                              one site or if `site` is `None` and no site can be
                              selected automatically, the selected site (the second
                              element in the returned tuple) will be `None`.
    '''
    if method is not None:
        method = str(method)
    ret = libcoopgamma_native.libcoopgamma_native_get_method_and_site(method, site)
    if isinstance(ret, int):
        raise ErrorReport.create_error(ret)
    return ret


def get_pid_file(method = None, site = None):
    '''
    Get the PID file of the coopgamma server
    
    SIGCHLD must not be ignored or blocked
    
    @param   method:int|str?  The adjustment method, `None` for automatic
    @param   site:str?        The site, `None` for automatic
    @return  :str?            The pathname of the server's PID file.
                              `None` if the server does not use PID files.
    '''
    if method is not None:
        method = str(method)
    ret = libcoopgamma_native.libcoopgamma_native_get_pid_file(method, site)
    if ret is not None and isinstance(ret, int):
        raise ErrorReport.create_error(ret)
    return ret


def get_socket_file(method = None, site = None):
    '''
    Get the socket file of the coopgamma server
    
    SIGCHLD must not be ignored or blocked
    
    @param   method:int|str?  The adjustment method, `None` for automatic
    @param   site:str?        The site, `None` for automatic
    @return  :str?            The pathname of the server's socket, `None` if the server does have
                              its own socket, which is the case when communicating with a server
                              in a multi-server display server like mds
    '''
    if method is not None:
        method = str(method)
    ret = libcoopgamma_native.libcoopgamma_native_get_socket_file(method, site)
    if ret is not None and isinstance(ret, int):
        raise ErrorReport.create_error(ret)
    return ret

