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

import enum


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
    
    def clone(self) -> Ramps:
        '''
        Create a copy of the instance
        '''
        return Ramps(self.red, self.green, self.blue)
    
    def __repr__(self) -> str:
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
    def __init__(self, priority : int = None, crtc : str = None, fclass : str = None,
                 lifespan : Lifespan = None, depth : Depth = None, ramps : Ramps = None):
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
    
    def clone(self, shallow = False) -> Filter:
        '''
        Create a copy of the instance
        
        @param  shallow:bool  Create a shallow copy?
        '''
        ramps = self.ramps if shallow else self.ramps.clone()
        return Filter(self.priority, self.crtc, self.fclass, self.lifespan, self.depth, ramps)
    
    def __repr__(self) -> str:
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
    
    def clone(self) -> GamutPoint:
        '''
        Create a copy of the instance
        '''
        return GamutPoint(self.x_raw, self.y_raw)
    
    def __repr__(self) -> str:
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        params = (self.x_raw, self.y_raw)
        return 'libcoopgamma.GamutPoint(%s)' % ', '.join(repr(p) for p in params)


class Gamut:
    '''
    The values of the monitor's colour stimuli
    
    @variable  red:GamutPoint    The red stimuli
    @variable  green:GamutPoint  The green stimuli
    @variable  blue:GamutPoint   The blue stimuli
    '''
    def __init__(self, red : GamutPoint = None, green : GamutPoint = None, blue : GamutPoint = None):
        '''
        Constructor
    
        @param  red:GamutPoint    The red stimuli
        @param  green:GamutPoint  The green stimuli
        @param  blue:GamutPoint   The blue stimuli
        '''
        self.red   = red
        self.green = green
        self.blue  = blue
    
    def clone(self, shallow = True) -> Gamut:
        '''
        Create a copy of the instance
        
        @param  shallow:bool  Create a shallow copy?
        '''
        if shallow:
            return Gamut(self.red, self.green, self.blue)
        return Gamut(self.red.clone(), self.green.clone(), self.blue.clone())
    
    def __repr__(self) -> str:
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        params = (repr(self.red), repr(self.green), repr(self.blue))
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
    def __init__(self, cooperative : bool = None, depth : Depth = None, supported : Support = None,
                 red_size : int = None, green_size : int = None, blue_size : int = None,
                 colourspace : Colourspace = None, gamut : Gamut = None):
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
        @param  gamut:Gamut?             Measurements of the monitor's colourspace,
                                         `None` if the this information is unavailable
        '''
        self.cooperative = cooperative
        self.depth = depth
        self.supported = supported
        self.red_size = red_size
        self.green_size = green_size
        self.blue_size = blue_size
        self.colourspace = colourspace
        self.gamut = gamut
    
    def make_ramps(self) -> Ramps:
        '''
        Construct a `Ramps` instances for this CRTC
        
        @return  :Ramps  An instance of `Ramps` with same a number of ramp stops
                         matching this CRTC
        '''
        return Ramps(self.red_size, self.green_size, self.blue_size)
    
    def clone(self, shallow = True) -> CRTCInfo:
        '''
        Create a copy of the instance
        
        @param  shallow:bool  Create a shallow copy?
        '''
        return CRTCInfo(self.cooperative, self.depth, self.supported, self.red_size,
                        self.green_size, self.blue_size, self.colourspace,
                        self.gamut if shallow else self.gamut.clone())
    
    def __repr__(self) -> str:
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
    def __init__(self, high_priority : int, low_priority : int, crtc : str, coalesce : bool):
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
    
    def clone(self) -> FilterQuery:
        '''
        Create a copy of the instance
        '''
        return FilterQuery(self.high_priority, self.low_priority, self.crtc, self.coalesce)
    
    def __repr__(self) -> str:
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
    def __init__(self, priority : int = None, fclass : str = None, ramps : Ramps = None):
        '''
        Constructor
        
        @param  priority:int  The filter's priority. This is a signed 64-bit integer.
        @param  fclass:str    The filter's class
        @param  ramps:Ramps   The gamma ramp adjustments of the filter
        '''
        self.priority = priority
        self.fclass = fclass
        self.ramps = ramps
    
    def clone(self, shallow = False) -> QueriedFilter:
        '''
        Create a copy of the instance
        
        @param  shallow:bool  Create a sallow copy?
        '''
        ramps = self.ramps if shallow else self.ramps.clone()
        return QueriedFilter(self.priority, self.fclass, ramps)
    
    def __repr__(self) -> str:
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
    def __init__(self, red_size : int = None, green_size : int = None, blue_size : int = None,
                 depth : Depth = None, filters : list):
        '''
        Constructor 
        
        @param  red_size:int                 The number of stops in the red ramp
        @param  green_size:int               The number of stops in the green ramp
        @param  blue_size:int                The number of stops in the blue ramp
        @param  depth:Depth                  The data type and bit-depth of the ramp stops
        @param  filters:list<QueriedFilter>  The filters, should be ordered by priority
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
        self.filters    = filters
    
    def make_ramps(self) -> Ramps:
        '''
        Construct a `Ramps` instances for this CRTC
        
        @return  :Ramps  An instance of `Ramps` with same a number of ramp stops
                         matching this CRTC
        '''
        return Ramps(self.red_size, self.green_size, self.blue_size)
    
    def clone(self, shallow = False) -> FilterTable:
        '''
        Create a copy of the instance
        
        @param  shallow:bool  Create a sallow copy?
        '''
        filters = list(self.filters) if shallow else [f.clone() for f in self.filters]
        return FilterTable(self.red_size, self.green_size, self.blue_size, self.depth, filters)
    
    def __repr__(self) -> str:
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
    def __init__(self, number : int = None, custom : bool = None,
                 server_side : bool = None, description : str = None):
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
    
    def clone(self) -> ErrorReport:
        '''
        Create a copy of the instance
        '''
        return ErrorReport(self.number, self.custom, self.server_side, self.description)
    
    def __repr__(self) -> str:
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        params = (self.number, self.custom, self.server_side, self.description)
        return 'libcoopgamma.ErrorReport(%s)' % ', '.join(repr(p) for p in params)


class Context:
    '''
    Library state
    
    Use of this structure is not thread-safe, create
    one instance per thread that uses this structure
    
    @variable  error:ErrorReport  The error of the last failed function call. This
                                  member is undefined after successful function call.
    @variable  fd:int             File descriptor for the socket
    '''
    def __init__(self):
        '''
        Constructor
        '''
        self.error = ErrorReport
        self.fd = None
        self.address = None
    
    def __del__(self):
        '''
        Destructor
        '''
        pass


class AsyncContext:
    '''
    Information necessary to identify and parse a response from the server
    '''
    def __init__(self):
        '''
        Constructor
        '''
        self.address = None
    
    def __del__(self):
        '''
        Destructor
        '''
        pass
