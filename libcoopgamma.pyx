# -*- python -*-
# See LICENSE file for copyright and license details.
cimport cython

from libc.stddef cimport size_t
from libc.stdlib cimport calloc, malloc, free
from libc.stdint cimport int64_t, uint8_t, uint16_t, uint32_t, uint64_t, intptr_t
from libc.errno cimport errno

import enum as _enum


ctypedef int libcoopgamma_support_t
# Values used to indicate the support for gamma adjustments

ctypedef int libcoopgamma_depth_t
# Values used to tell which datatype is used for the gamma ramp stops
# 
# The values will always be the number of bits for integral types, and
# negative for floating-point types

ctypedef int libcoopgamma_lifespan_t
# Values used to tell when a filter should be removed

ctypedef int libcoopgamma_colourspace_t
# Colourspaces



cdef extern from "include-libcoopgamma.h":

    ctypedef struct libcoopgamma_ramps_t:
    # Gamma ramp structure
        size_t u_red_size
        # The number of stops in the red ramp
        size_t u_green_size
        # The number of stops in the green ramp
        size_t u_blue_size
        # The number of stops in the blue ramp
        void* u_red
        # The red ramp
        void* u_green
        # The green ramp
        void* u_blue
        # The blue ramp

    ctypedef struct libcoopgamma_filter_t:
    # Data set to the coopgamma server to apply, update, or remove a filter
        int64_t priority
        # The priority of the filter, higher priority is applied first.
        # The gamma correction should have priority 0.
        char* crtc
        # The CRTC for which this filter shall be applied
        char* fclass
        # Identifier for the filter
        # 
        # The syntax must be "${PACKAGE_NAME}::${COMMAND_NAME}::${RULE}"
        libcoopgamma_lifespan_t lifespan
        # When shall the filter be removed?
        # 
        # If this member's value is `LIBCOOPGAMMA_REMOVE`,
        # only `.crtc` and `.class` need also be defined
        libcoopgamma_depth_t depth
        # The data type and bit-depth of the ramp stops
        libcoopgamma_ramps_t ramps
        # The gamma ramp adjustments of the filter

    ctypedef struct libcoopgamma_crtc_info_t:
    # Gamma ramp meta information for a CRTC
        int cooperative
        # Is cooperative gamma server running?
        libcoopgamma_depth_t depth
        # Is gamma adjustments supported on the CRTC?
        # If not, `.depth`, `.red_size`, `.green_size`,
        # and `.blue_size` are undefined 
        libcoopgamma_support_t supported
        # The data type and bit-depth of the ramp stops
        size_t red_size
        # The number of stops in the red ramp
        size_t green_size
        # The number of stops in the green ramp
        size_t blue_size
        # The number of stops in the blue ramp
        libcoopgamma_colourspace_t colourspace
        # The monitor's colurspace
        int have_gamut
        # Whether `.red_x`, `.red_y`, `.green_x`, `.green_y`, `.blue_x`, `.blue_y`,
        # `.white_x`, and `.white_y` are set.
        # 
        # If this is true, but the colourspace is not RGB (or sRGB),
        # there is something wrong. Please also check the colourspace.
        unsigned red_x
        # The x-value (CIE xyY) of the monitor's red colour, multiplied by 1024
        unsigned red_y
        # The y-value (CIE xyY) of the monitor's red colour, multiplied by 1024
        unsigned green_x
        # The x-value (CIE xyY) of the monitor's green colour, multiplied by 1024
        unsigned green_y
        # The y-value (CIE xyY) of the monitor's green colour, multiplied by 1024
        unsigned blue_x
        # The x-value (CIE xyY) of the monitor's blue colour, multiplied by 1024
        unsigned blue_y
        # The y-value (CIE xyY) of the monitor's blue colour, multiplied by 1024
        unsigned white_x
        # The x-value (CIE xyY) of the monitor's default white point, multiplied by 1024
        unsigned white_y
        # The y-value (CIE xyY) of the monitor's default white point, multiplied by 1024

    ctypedef struct libcoopgamma_filter_query_t:
    # Data sent to the coopgamma server when requestng the current filter table
        int64_t high_priority
        # Do no return filters with higher priority than this value
        int64_t low_priority
        # Do no return filters with lower priority than this value
        char* crtc
        # The CRTC for which the the current filters shall returned
        int coalesce
        # Whether to coalesce all filters into one gamma ramp triplet

    ctypedef struct libcoopgamma_queried_filter_t:
    # Stripped down version of `libcoopgamma_filter` which only contains
    # the information returned in response to "Command: get-gamma"
        int64_t priority
        # The filter's priority
        char* fclass
        # The filter's class
        libcoopgamma_ramps_t ramps
        # The gamma ramp adjustments of the filter

    ctypedef struct libcoopgamma_filter_table_t:
    # Response type for "Command: get-gamma": a list of applied filters
    # and meta-information that was necessary for decoding the response
        size_t red_size
        # The number of stops in the red ramp
        size_t green_size
        # The number of stops in the green ramp
        size_t blue_size
        # The number of stops in the blue ramp
        size_t filter_count
        # The number of filters
        libcoopgamma_queried_filter_t* filters
        # The filters, should be ordered by priority in descending order,
        # lest there is something wrong with the coopgamma server
        # 
        # If filter coalition was requested, there will be exactly one
        # filter (`.filter_count == 1`) and `.filters->class == NULL`
        # and `.filters->priority` is undefined.
        libcoopgamma_depth_t depth
        # The data type and bit-depth of the ramp stops

    ctypedef struct libcoopgamma_error_t:
    # Error message from coopgamma server
        uint64_t number
        # Error code
        # 
        # If `.custom` is false, 0 indicates success, otherwise,
        # 0 indicates that no error code has been assigned
        int custom
        # Is this a custom error?
        int server_side
        # Did the error occur on the server-side?
        char* description
        # Error message, can be `NULL` if `.custom` is false

    ctypedef struct libcoopgamma_context_t:
    # Library state
    # 
    # Use of this structure is not thread-safe create one instance
    # per thread that uses this structure
        libcoopgamma_error_t error
        # The error of the last failed function call
        # 
        # This member is undefined after successful function call
        int fd
        # File descriptor for the socket
        int have_all_headers
        # Whether `libcoopgamma_synchronise` have read the empty end-of-headers line
        int bad_message
        # Whether `libcoopgamma_synchronise` is reading a corrupt but recoverable message
        int blocking
        # Is communication blocking?
        uint32_t message_id
        # Message ID of the next message
        uint32_t in_response_to
        # The ID of outbound message to which the inbound message being read by
        # `libcoopgamma_synchronise` is a response
        char* outbound
        # Buffer with the outbound message
        size_t outbound_head
        # The write head for `outbound`
        size_t outbound_tail
        # The read head for `outbound`
        size_t outbound_size
        # The allocation size of `outbound`
        char* inbound
        # Buffer with the inbound message
        size_t inbound_head
        # The write head for `inbound`
        size_t inbound_tail
        # The read head for `inbound`
        size_t inbound_size
        # The allocation size of `inbound`
        size_t length
        # The value of 'Length' header in the inbound message
        size_t curline
        # The beginning of the current line that is being read by `libcoopgamma_synchronise`

    ctypedef struct libcoopgamma_async_context_t:
    # Information necessary to identify and parse a response from the server
        uint32_t message_id
        # The value of the 'In response to' header in the waited message
        int coalesce
        # Whether to coalesce all filters into one gamma ramp triplet



cdef extern int libcoopgamma_ramps_initialise_(libcoopgamma_ramps_t* this, size_t width) nogil
'''
Initialise a `libcoopgamma_ramps_t`

`this->red_size`, `this->green_size`, and `this->blue_size` must already be set

@param   this   The record to initialise
@param   width  The `sizeof(*(this->red))`
@return         Zero on success, -1 on error
'''

cdef extern void libcoopgamma_ramps_destroy(libcoopgamma_ramps_t* this) nogil
'''
Release all resources allocated to  a `libcoopgamma_ramps_t`,
the allocation of the record itself is not freed

Always call this function after failed call to `libcoopgamma_ramps_initialise
or failed call to `libcoopgamma_ramps_unmarshal

@param  this  The record to destroy
'''

cdef extern int libcoopgamma_filter_initialise(libcoopgamma_filter_t* this) nogil
'''
Initialise a `libcoopgamma_filter_t`

@param   this  The record to initialise
@return        Zero on success, -1 on err
'''

cdef extern void libcoopgamma_filter_destroy(libcoopgamma_filter_t* this) nogil
'''
Release all resources allocated to  a `libcoopgamma_filter_t`,
the allocation of the record itself is not freed

Always call this function after failed call to `libcoopgamma_filter_initialise`
or failed call to `libcoopgamma_filter_unmarshal`

@param  this  The record to destroy
'''

cdef extern int libcoopgamma_crtc_info_initialise(libcoopgamma_crtc_info_t* this) nogil
'''
Initialise a `libcoopgamma_crtc_info_t`

@param   this  The record to initialise
@return        Zero on success, -1 on error
'''

cdef extern void libcoopgamma_crtc_info_destroy(libcoopgamma_crtc_info_t* this) nogil
'''
Release all resources allocated to  a `libcoopgamma_crtc_info_t`,
the allocation of the record itself is not freed

Always call this function after failed call to `libcoopgamma_crtc_info_initialise`
or failed call to `libcoopgamma_crtc_info_unmarshal

@param  this  The record to destroy
'''

cdef extern int libcoopgamma_filter_query_initialise(libcoopgamma_filter_query_t* this) nogil
'''
Initialise a `libcoopgamma_filter_query_t`

@param   this  The record to initialise
@return        Zero on success, -1 on error
'''

cdef extern void libcoopgamma_filter_query_destroy(libcoopgamma_filter_query_t* this) nogil
'''
Release all resources allocated to  a `libcoopgamma_filter_query_t`,
the allocation of the record itself is not freed

Always call this function after failed call to `libcoopgamma_filter_query_initialise`
or failed call to `libcoopgamma_filter_query_unmarshal`

@param  this  The record to destroy
'''

cdef extern int libcoopgamma_queried_filter_initialise(libcoopgamma_queried_filter_t* this) nogil
'''
Initialise a `libcoopgamma_queried_filter_t`

@param   this  The record to initialise
@return        Zero on success, -1 on error
'''

cdef extern void libcoopgamma_queried_filter_destroy(libcoopgamma_queried_filter_t* this) nogil
'''
Release all resources allocated to  a `libcoopgamma_queried_filter_t`,
the allocation of the record itself is not freed

Always call this function after failed call to `libcoopgamma_queried_filter_initialise`
or failed call to `libcoopgamma_queried_filter_unmarshal

@param  this  The record to destro
'''

cdef extern int libcoopgamma_filter_table_initialise(libcoopgamma_filter_table_t* this) nogil
'''
Initialise a `libcoopgamma_filter_table_t

@param   this  The record to initialise
@return        Zero on success, -1 on error
'''

cdef extern void libcoopgamma_filter_table_destroy(libcoopgamma_filter_table_t* this) nogil
'''
Release all resources allocated to  a `libcoopgamma_filter_table_t`,
the allocation of the record itself is not freed

Always call this function after failed call to `libcoopgamma_filter_table_initialise`
or failed call to `libcoopgamma_filter_table_unmarshal`

@param  this  The record to destroy
'''

cdef extern void libcoopgamma_filter_table_destroy(libcoopgamma_filter_table_t* this) nogil
'''
Release all resources allocated to  a `libcoopgamma_filter_table_t`,
the allocation of the record itself is not freed

Always call this function after failed call to `libcoopgamma_filter_table_initialise`
or failed call to `libcoopgamma_filter_table_unmarshal`

@param  this  The record to destroy
'''

cdef extern int libcoopgamma_error_initialise(libcoopgamma_error_t* this) nogil
'''
Initialise a `libcoopgamma_error_t`

@param   this  The record to initialise
@return        Zero on success, -1 on error
'''

cdef extern void libcoopgamma_error_destroy(libcoopgamma_error_t* this) nogil
'''
Release all resources allocated to  a `libcoopgamma_error_t`,
the allocation of the record itself is not freed

Always call this function after failed call to `libcoopgamma_error_initialise`
or failed call to `libcoopgamma_error_unmarshal`

@param  this  The record to destroy
'''

cdef extern int libcoopgamma_context_initialise(libcoopgamma_context_t* this) nogil
'''
Initialise a `libcoopgamma_context_t`

@param   this  The record to initialise
@return        Zero on success, -1 on error
'''

cdef extern void libcoopgamma_context_destroy(libcoopgamma_context_t* this, int disconnect) nogil
'''
Release all resources allocated to  a `libcoopgamma_context_t`,
the allocation of the record itself is not freed

Always call this function after failed call to `libcoopgamma_context_initialise`
or failed call to `libcoopgamma_context_unmarshal`

@param  this        The record to destroy
@param  disconnect  Disconnect from the server?
'''

cdef extern size_t libcoopgamma_context_marshal(const libcoopgamma_context_t* this, void* buf) nogil
'''
Marshal a `libcoopgamma_context_t` into a buffer

@param   this  The record to marshal
@param   buf   The output buffer, `NULL` to only measure
               how large this buffer has to be
@return        The number of marshalled bytes, or if `buf == NULL`,
               how many bytes would be marshalled if `buf != NULL`
'''

cdef extern int libcoopgamma_context_unmarshal(libcoopgamma_context_t* this, const void* buf, size_t* n) nogil
'''
Unmarshal a `libcoopgamma_context_t` from a buffer

@param   this  The output parameter for unmarshalled record
@param   buf   The buffer with the marshalled record
@param   n     Output parameter for the number of unmarshalled bytes, undefined on failure
@return        `LIBCOOPGAMMA_SUCCESS` (0), `LIBCOOPGAMMA_INCOMPATIBLE_DOWNGRADE`,
               `LIBCOOPGAMMA_INCOMPATIBLE_UPGRADE`, or `LIBCOOPGAMMA_ERRNO_SET`
'''

cdef extern int libcoopgamma_async_context_initialise(libcoopgamma_async_context_t* this) nogil
'''
Initialise a `libcoopgamma_async_context_t`

@param   this  The record to initialise
@return        Zero on success, -1 on error
'''

cdef extern void libcoopgamma_async_context_destroy(libcoopgamma_async_context_t* this) nogil
'''
Release all resources allocated to  a `libcoopgamma_async_context_t`,
the allocation of the record itself is not freed

Always call this function after failed call to `libcoopgamma_async_context_initialise`
or failed call to `libcoopgamma_async_context_unmarshal`

@param  this  The record to destroy
'''

cdef extern size_t libcoopgamma_async_context_marshal(const libcoopgamma_async_context_t* this, void* buf) nogil
'''
Marshal a `libcoopgamma_async_context_t` into a buffer

@param   this  The record to marshal
@param   buf   The output buffer, `NULL` to only measure
               how large this buffer has to be
@return        The number of marshalled bytes, or if `buf == NULL`,
               how many bytes would be marshalled if `buf != NULL`
'''

cdef extern int libcoopgamma_async_context_unmarshal(libcoopgamma_async_context_t* this,
                                                     const void* buf, size_t* n) nogil
'''
Unmarshal a `libcoopgamma_async_context_t` from a buffer

@param   this  The output parameter for unmarshalled record
@param   buf   The buffer with the marshalled record
@param   n     Output parameter for the number of unmarshalled bytes, undefined on failure
@return        `LIBCOOPGAMMA_SUCCESS` (0), `LIBCOOPGAMMA_INCOMPATIBLE_DOWNGRADE`,
               `LIBCOOPGAMMA_INCOMPATIBLE_UPGRADE`, or `LIBCOOPGAMMA_ERRNO_SET`
'''

cdef extern char** libcoopgamma_get_methods() nogil
'''
List all recognised adjustment method

SIGCHLD must not be ignored or blocked

@return  A `NULL`-terminated list of names. You should only free
         the outer pointer, inner pointers are subpointers of the
         outer pointer and cannot be freed. `NULL` on error.
'''

cdef extern int libcoopgamma_get_method_and_site(const char* method, const char* site,
                                                 char** methodp, char** sitep) nogil
'''
Get the adjustment method and site

SIGCHLD must not be ignored or blocked

@param   method   The adjustment method, `NULL` for automatic
@param   site     The site, `NULL` for automatic
@param   methodp  Output pointer for the selected adjustment method,
                  which cannot be `NULL`. It is safe to call
                  this function with this parameter set to `NULL`.
@param   sitep    Output pointer for the selected site, which will
                  be `NULL` the method only supports one site or if
                  `site == NULL` and no site can be selected
                  automatically. It is safe to call this function
                  with this parameter set to `NULL`.
@return           Zero on success, -1 on error
'''

cdef extern char* libcoopgamma_get_pid_file(const char* method, const char* site) nogil
'''
Get the PID file of the coopgamma server

SIGCHLD must not be ignored or blocked

@param   method   The adjustment method, `NULL` for automatic
@param   site     The site, `NULL` for automatic
@return           The pathname of the server's PID file, `NULL` on error
                  or if there server does not use PID files. The later
                  case is detected by checking that `errno` is set to 0.
'''

cdef extern char* libcoopgamma_get_socket_file(const char* method, const char* site) nogil
'''
Get the socket file of the coopgamma server

SIGCHLD must not be ignored or blocked

@param   method   The adjustment method, `NULL` for automatic
@param   site     The site, `NULL` for automatic
@return           The pathname of the server's socket, `NULL` on error
                  or if there server does have its own socket. The later
                  case is detected by checking that `errno` is set to 0,
                  and is the case when communicating with a server in a
                  multi-server display server like mds.
'''

cdef extern int libcoopgamma_connect(const char* method, const char* site, libcoopgamma_context_t* ctx) nogil
'''
Connect to a coopgamma server, and start it if necessary

Use `libcoopgamma_context_destroy` to disconnect

SIGCHLD must not be ignored or blocked

@param   method  The adjustment method, `NULL` for automatic
@param   site    The site, `NULL` for automatic
@param   ctx     The state of the library, must be initialised
@return          Zero on success, -1 on error. On error, `errno` is set
                 to 0 if the server could not be initialised.
'''

cdef extern int libcoopgamma_set_nonblocking(libcoopgamma_context_t* ctx, int nonblocking) nogil
'''
By default communication is blocking, this function
can be used to switch between blocking and nonblocking

After setting the communication to nonblocking,
`libcoopgamma_flush`, `libcoopgamma_synchronise` and
and request-sending functions can fail with EAGAIN and
EWOULDBLOCK. It is safe to continue with `libcoopgamma_flush`
(for `libcoopgamma_flush` it selfand equest-sending functions)
or `libcoopgamma_synchronise` just like EINTR failure.

@param   ctx          The state of the library, must be connected
@param   nonblocking  Nonblocking mode?
@return               Zero on success, -1 on error
'''

cdef extern int libcoopgamma_flush(libcoopgamma_context_t* ctx) nogil
'''
Send all pending outbound data

If this function or another function that sends a request
to the server fails with EINTR, call this function to
complete the transfer. The `async_ctx` parameter will always
be in a properly configured state if a function fails
with EINTR.

@param   ctx  The state of the library, must be connected
@return       Zero on success, -1 on error
'''

cdef extern int libcoopgamma_synchronise(libcoopgamma_context_t* ctx, libcoopgamma_async_context_t* pending,
                                         size_t n, size_t* selected) nogil
'''
Wait for the next message to be received

@param   ctx       The state of the library, must be connected
@param   pending   Information for each pending request
@param   n         The number of elements in `pending`
@param   selected  The index of the element in `pending` which corresponds
                   to the first inbound message, note that this only means
                   that the message is not for any of the other request,
                   if the message is corrupt any of the listed requests can
                   be selected even if it is not for any of the requests.
                   Functions that parse the message will detect such corruption.
@return            Zero on success, -1 on error. If the the message is ignored,
                   which happens if corresponding `libcoopgamma_async_context_t`
                   is not listed, -1 is returned and `errno` is set to 0. If -1
                   is returned, `errno` is set to `ENOTRECOVERABLE` you have
                   received a corrupt message and the context has been tainted
                   beyond recover.
'''

cdef extern void libcoopgamma_skip_message(libcoopgamma_context_t* ctx) nogil
'''
Tell the library that you will not be parsing a receive message

@param  ctx  The state of the library, must be connected
'''

cdef extern int libcoopgamma_get_crtcs_send(libcoopgamma_context_t* ctx, libcoopgamma_async_context_t* async_ctx) nogil
'''
List all available CRTC:s, send request part

Cannot be used before connecting to the server

@param   ctx        The state of the library, must be connected
@param   async_ctx  Information about the request, that is needed to
                    identify and parse the response, is stored here
@return             Zero on success, -1 on error
'''

cdef extern char** libcoopgamma_get_crtcs_recv(libcoopgamma_context_t* ctx, libcoopgamma_async_context_t* async_ctx) nogil
'''
List all available CRTC:s, receive response part

@param   ctx        The state of the library, must be connected
@param   async_ctx  Information about the request
@return             A `NULL`-terminated list of names. You should only free
                    the outer pointer, inner pointers are subpointers of the
                    outer pointer and cannot be freed. `NULL` on error, in
                    which case `ctx->error` (rather than `errno`) is read
                    for information about the error.
'''

cdef extern char** libcoopgamma_get_crtcs_sync(libcoopgamma_context_t* ctx) nogil
'''
List all available CRTC:s, synchronous version

This is a synchronous request function, as such,
you have to ensure that communication is blocking
(default), and that there are not asynchronous
requests waiting, it also means that EINTR:s are
silently ignored and there no wait to cancel the
operation without disconnection from the server

@param   ctx  The state of the library, must be connected
@return       A `NULL`-terminated list of names. You should only free
              the outer pointer, inner pointers are subpointers of the
              outer pointer and cannot be freed. `NULL` on error, in
              which case `ctx->error` (rather than `errno`) is read
              for information about the error.
'''

cdef extern int libcoopgamma_get_gamma_info_send(const char* crtc, libcoopgamma_context_t* ctx,
                                                 libcoopgamma_async_context_t* async_ctx) nogil
'''
Retrieve information about a CRTC:s gamma ramps, send request part

Cannot be used before connecting to the server

@param   crtc       The name of the CRTC
@param   ctx        The state of the library, must be connected
@param   async_ctx  Information about the request, that is needed to
                    identify and parse the response, is stored here
@return             Zero on success, -1 on error
'''

cdef extern int libcoopgamma_get_gamma_info_recv(libcoopgamma_crtc_info_t* info, libcoopgamma_context_t* ctx,
                                                 libcoopgamma_async_context_t* async_ctx) nogil
'''
Retrieve information about a CRTC:s gamma ramps, receive response part

@param   info       Output parameter for the information, must be initialised
@param   ctx        The state of the library, must be connected
@param   async_ctx  Information about the request
@return             Zero on success, -1 on error, in which case `ctx->error`
                    (rather than `errno`) is read for information about the error
'''

cdef extern int libcoopgamma_get_gamma_info_sync(const char* crtc, libcoopgamma_crtc_info_t* info,
                                                 libcoopgamma_context_t* ctx) nogil
'''
Retrieve information about a CRTC:s gamma ramps, synchronous version

This is a synchronous request function, as such,
you have to ensure that communication is blocking
(default), and that there are not asynchronous
requests waiting, it also means that EINTR:s are
silently ignored and there no wait to cancel the
operation without disconnection from the server

@param   crtc   The name of the CRTC
@param   info   Output parameter for the information, must be initialised
@param   ctx    The state of the library, must be connected
@return         Zero on success, -1 on error, in which case `ctx->error`
                (rather than `errno`) is read for information about the error
'''

cdef extern int libcoopgamma_get_gamma_send(const libcoopgamma_filter_query_t* query,
                                            libcoopgamma_context_t* ctx, libcoopgamma_async_context_t* async_ctx) nogil
'''
Retrieve the current gamma ramp adjustments, send request part

Cannot be used before connecting to the server

@param   query      The query to send
@param   ctx        The state of the library, must be connected
@param   async_ctx  Information about the request, that is needed to
                    identify and parse the response, is stored here
@return             Zero on success, -1 on error
'''

cdef extern int libcoopgamma_get_gamma_recv(libcoopgamma_filter_table_t* table, libcoopgamma_context_t* ctx,
                                            libcoopgamma_async_context_t* async_ctx) nogil
'''
Retrieve the current gamma ramp adjustments, receive response part

@param   table      Output for the response, must be initialised
@param   ctx        The state of the library, must be connected
@param   async_ctx  Information about the request
@return             Zero on success, -1 on error, in which case `ctx->error`
                    (rather than `errno`) is read for information about the error
'''

cdef extern int libcoopgamma_get_gamma_sync(const libcoopgamma_filter_query_t* query,
                                            libcoopgamma_filter_table_t* table, libcoopgamma_context_t* ctx) nogil
'''
Retrieve the current gamma ramp adjustments, synchronous version

This is a synchronous request function, as such,
you have to ensure that communication is blocking
(default), and that there are not asynchronous
requests waiting, it also means that EINTR:s are
silently ignored and there no wait to cancel the
operation without disconnection from the server

@param   query  The query to send
@param   table  Output for the response, must be initialised
@param   ctx    The state of the library, must be connected
@return         Zero on success, -1 on error, in which case `ctx->error`
                (rather than `errno`) is read for information about the error
'''

cdef extern int libcoopgamma_set_gamma_send(const libcoopgamma_filter_t* filtr, libcoopgamma_context_t* ctx,
                                            libcoopgamma_async_context_t* async_ctx) nogil
'''
Apply, update, or remove a gamma ramp adjustment, send request part

Cannot be used before connecting to the server

@param   filtr      The filter to apply, update, or remove, gamma ramp meta-data must match the CRTC's
@param   ctx        The state of the library, must be connected
@param   async_ctx  Information about the request, that is needed to
                    identify and parse the response, is stored here
@return             Zero on success, -1 on error
'''

cdef extern int libcoopgamma_set_gamma_recv(libcoopgamma_context_t* ctx, libcoopgamma_async_context_t* async_ctx) nogil
'''
Apply, update, or remove a gamma ramp adjustment, receive response part

@param   ctx        The state of the library, must be connected
@param   async_ctx  Information about the request
@return             Zero on success, -1 on error, in which case `ctx->error`
                    (rather than `errno`) is read for information about the error
'''

cdef extern int libcoopgamma_set_gamma_sync(const libcoopgamma_filter_t* filtr, libcoopgamma_context_t* ctx) nogil
'''
Apply, update, or remove a gamma ramp adjustment, synchronous version

This is a synchronous request function, as such,
you have to ensure that communication is blocking
(default), and that there are not asynchronous
requests waiting, it also means that EINTR:s are
silently ignored and there no wait to cancel the
operation without disconnection from the server

@param   filtr  The filter to apply, update, or remove, gamma ramp meta-data must match the CRTC's
@param   ctx    The state of the library, must be connected
@return         Zero on success, -1 on error, in which case `ctx->error`
                (rather than `errno`) is read for information about the error
'''



def _libcoopgamma_native_get_methods():
    '''
    List all recognised adjustment method
    
    SIGCHLD must not be ignored or blocked
    
    @return  :list<str>|int  Either the value of `errno` (on failure), or (on success) a list
                             of names. You should only free the outer pointer, inner pointers
                             are subpointers of the outer pointer and cannot be freed.
    '''
    cdef char** methods = libcoopgamma_get_methods()
    cdef bytes bs
    if methods is NULL:
        return int(errno)
    try:
        ret = []
        i = 0
        while methods[i] is not NULL:
            bs = methods[i]
            ret.append(bs.decode('utf-8', 'strict'))
            i += 1
    finally:
        free(methods)
    return ret


def _libcoopgamma_native_get_method_and_site(method : str, site : str):
    '''
    Get the adjustment method and site
    
    SIGCHLD must not be ignored or blocked
    
    @param   method:str?         The adjustment method, `None` for automatic
    @param   site:str?           The site, `None` for automatic
    @return  :int|(:str, :str?)  Either the value of `errno` (on failure), or (on success)
                                 the selected adjustment method and the selected the
                                 selected site. If the adjustment method only supports
                                 one site or if `site` is `None` and no site can be
                                 selected automatically, the selected site (the second
                                 element in the returned tuple) will be `None`.
    '''
    cdef char* cmethod = NULL
    cdef char* csite = NULL
    cdef char* rcsmethod = NULL
    cdef char* rcssite = NULL
    cdef bytes rbsmethod
    cdef bytes rbssite
    try:
        if method is not None:
            buf = method.encode('utf-8') + bytes([0])
            cmethod = <char*>malloc(len(buf) * sizeof(char))
            for i in range(len(buf)):
                cmethod[i] = <char>(buf[i])
        if site is not None:
            buf = site.encode('utf-8') + bytes([0])
            csite = <char*>malloc(len(buf) * sizeof(char))
            for i in range(len(buf)):
                csite[i] = <char>(buf[i])
        rmethod, rsite = None, None
        if libcoopgamma_get_method_and_site(cmethod, csite, &rcsmethod, &rcssite) < 0:
            return int(errno)
        rbsmethod = rcsmethod
        rmethod = rbsmethod.decode('utf-8', 'strict')
        if rcssite is not NULL:
            rbssite = rcssite
            rsite = rbssite.decode('utf-8', 'strict')
        return (rmethod, rsite)
    finally:
        free(cmethod)
        free(csite)
        free(rcsmethod)
        free(rcssite)


def _libcoopgamma_native_get_pid_file(method : str, site : str):
    '''
    Get the PID file of the coopgamma server
    
    SIGCHLD must not be ignored or blocked
    
    @param   method:str?  The adjustment method, `None` for automatic
    @param   site:str?    The site, `None` for automatic
    @return  :int|str?    Either the value of `errno` (on failure), or (on success)
                          the pathname of the server's PID file. `None` if the server
                          does not use PID files.
    '''
    cdef char* cmethod = NULL
    cdef char* csite = NULL
    cdef char* path = NULL
    cdef bytes bs
    try:
        if method is not None:
            buf = method.encode('utf-8') + bytes([0])
            cmethod = <char*>malloc(len(buf) * sizeof(char))
            for i in range(len(buf)):
                cmethod[i] = <char>(buf[i])
        if site is not None:
            buf = site.encode('utf-8') + bytes([0])
            csite = <char*>malloc(len(buf) * sizeof(char))
            for i in range(len(buf)):
                csite[i] = <char>(buf[i])
        path = libcoopgamma_get_pid_file(cmethod, csite)
        if path is not NULL or errno == 0:
            bs = path
            return bs.decode('utf-8', 'strict')
    finally:
        free(cmethod)
        free(csite)
        free(path)
    return int(errno)


def _libcoopgamma_native_get_socket_file(method : str, site : str):
    '''
    Get the socket file of the coopgamma server
    
    SIGCHLD must not be ignored or blocked
    
    @param   method:int|str?  The adjustment method, `None` for automatic
    @param   site:str?        The site, `None` for automatic
    @return  :int|str?        Either the value of `errno` (on failure), or (on success)
                              the pathname of the server's socket, `None` if the server does have
                              its own socket, which is the case when communicating with a server
                              in a multi-server display server like mds
    '''
    cdef char* cmethod = NULL
    cdef char* csite = NULL
    cdef char* path = NULL
    cdef bytes bs
    try:
        if method is not None:
            buf = method.encode('utf-8') + bytes([0])
            cmethod = <char*>malloc(len(buf) * sizeof(char))
            for i in range(len(buf)):
                cmethod[i] = <char>(buf[i])
        if site is not None:
            buf = site.encode('utf-8') + bytes([0])
            csite = <char*>malloc(len(buf) * sizeof(char))
            for i in range(len(buf)):
                csite[i] = <char>(buf[i])
        path = libcoopgamma_get_socket_file(cmethod, csite)
        if path is not NULL or errno == 0:
            bs = path
            return bs.decode('utf-8', 'strict')
    finally:
        free(cmethod)
        free(csite)
        free(path)
    return int(errno)


def _libcoopgamma_native_context_create():
    '''
    Create an instance of `libcoopgamma_context_t`
    
    @return  :(:bool, :int)  Element 0: Whether the call was successful
                             Element 1: The value of `errno` on failure, and on
                                        success, the address of the created instance
    '''
    cdef libcoopgamma_context_t* this
    this = <libcoopgamma_context_t*>malloc(sizeof(libcoopgamma_context_t))
    if this is NULL:
        return (False, int(errno))
    if libcoopgamma_context_initialise(this) < 0:
        saved_errno = int(errno)
        libcoopgamma_context_destroy(this, <int>0)
        free(this)
        return (False, saved_errno)
    return (True, int(<intptr_t><void*>this))


def _libcoopgamma_native_context_free(address : int):
    '''
    Disconnect and free an instance of a `libcoopgamma_context_t`
    
    @param  address:int  The address of the `libcoopgamma_context_t` instance
    '''
    cdef libcoopgamma_context_t* this = <libcoopgamma_context_t*><void*><intptr_t>address
    libcoopgamma_context_destroy(this, <int>1)
    free(this)


def _libcoopgamma_native_context_marshal(address : int):
    '''
    Marshal a `libcoopgamma_context_t` into a buffer
    
    @param   address:int  The address of the instance to marshal
    @return  :int|bytes   Either the value of `errno` (on failure), or (on success)
                          a byte representation of the instance
    '''
    cdef libcoopgamma_context_t* this = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef size_t n = libcoopgamma_context_marshal(this, NULL)
    cdef char* buf = <char*>malloc(n)
    if buf is NULL:
        return int(errno)
    try:
        libcoopgamma_context_marshal(this, buf)
        return bytes(int(<int><unsigned char>(buf[i])) for i in range(int(n)))
    finally:
        free(buf)


def _libcoopgamma_native_context_unmarshal(buf : bytes):
    '''
    Unmarshal a `libcoopgamma_context_t` from a buffer
    
    @param   buf:bytes      The buffer with the marshalled instance
    @return  :(:int, :int)  Element 0: 0 = Success
                                       1 = Incompatible downgrade
                                       2 = Incompatible upgrade
                                       -1 = `errno` is returned
                            Element 1: If [0] = 0:  The address of the unmarshalled instance
                                       If [0] = -1: The value of `errno`
    '''
    cdef size_t _n = 0
    cdef libcoopgamma_context_t* this
    cdef char* bs = NULL
    success = False
    this = <libcoopgamma_context_t*>calloc(1, sizeof(libcoopgamma_context_t))
    if this is NULL:
        return (-1, int(errno))
    try:
        if libcoopgamma_context_initialise(this) < 0:
            return (-1, int(errno))
        bs = <char*>malloc(len(buf) * sizeof(char))
        if bs is NULL:
            return (-1, int(errno))
        for i in range(len(buf)):
            bs[i] = <char><unsigned char>(buf[i])
        ret = int(libcoopgamma_context_unmarshal(this, bs, &_n))
        ret = (ret, int(<intptr_t><void*>this))
        success = True
        return ret
    finally:
        if not success:
            libcoopgamma_context_destroy(this, <int>1)
            free(this)
        free(bs)


def _libcoopgamma_native_context_set_fd(address : int, fd : int):
    '''
    Set the field for socket file descriptor in a `libcoopgamma_context_t` 
    
    @param  address:int  The address of the `libcoopgamma_context_t` instance
    @param  fd:int       The file descriptor
    '''
    cdef libcoopgamma_context_t* this = <libcoopgamma_context_t*><void*><intptr_t>address
    this.fd = fd


def _libcoopgamma_native_async_context_create():
    '''
    Create an instance of `libcoopgamma_context_t`
    
    @return  :(:bool, :int)  Element 0: Whether the call was successful
                             Element 1: The value of `errno` on failure, and on
                                        success, the address of the created instance
    '''
    cdef libcoopgamma_context_t* this
    this = <libcoopgamma_context_t*>malloc(sizeof(libcoopgamma_context_t))
    if this is NULL:
        return (False, int(errno))
    if libcoopgamma_context_initialise(this) < 0:
        saved_errno = int(errno)
        libcoopgamma_context_destroy(this, <int>0)
        free(this)
        return (False, saved_errno)
    return (True, int(<intptr_t><void*>this))


def _libcoopgamma_native_async_context_free(address : int):
    '''
    Free an instance of a `libcoopgamma_async_context_t`
    
    @param  address:int  The address of the `libcoopgamma_async_context_t` instance
    '''
    cdef libcoopgamma_async_context_t* this = <libcoopgamma_async_context_t*><void*><intptr_t>address
    libcoopgamma_async_context_destroy(this)
    free(this)


def _libcoopgamma_native_async_context_marshal(address : int):
    '''
    Marshal a `libcoopgamma_async_context_t` into a buffer
    
    @param   address:int  The address of the instance to marshal
    @return  :int|bytes   Either the value of `errno` (on failure), or (on success)
                          a byte representation of the instance
    '''
    cdef libcoopgamma_async_context_t* this = <libcoopgamma_async_context_t*><void*><intptr_t>address
    cdef size_t n = libcoopgamma_async_context_marshal(this, NULL)
    cdef char* buf = <char*>malloc(n)
    try:
        if buf is NULL:
            return int(errno)
        libcoopgamma_async_context_marshal(this, buf)
        ret = bytes(int(<int><unsigned char>(buf[i])) for i in range(int(n)))
    finally:
        free(buf)
    return ret


def _libcoopgamma_native_async_context_unmarshal(buf : bytes):
    '''
    Unmarshal a `libcoopgamma_async_context_t` from a buffer
    
    @param   buf:bytes      The buffer with the marshalled instance
    @return  :(:int, :int)  Element 0: 0 = Success
                                       1 = Incompatible downgrade
                                       2 = Incompatible upgrade
                                       -1 = `errno` is returned
                            Element 1: If [0] = 0:  The address of the unmarshalled instance
                                       If [0] = -1: The value of `errno`
    '''
    cdef size_t _n = 0
    cdef libcoopgamma_async_context_t* this
    cdef char* bs = NULL
    successful = False
    this = <libcoopgamma_async_context_t*>malloc(sizeof(libcoopgamma_async_context_t))
    try:
        if this is NULL:
            return (-1, int(errno))
        if libcoopgamma_async_context_initialise(this) < 0:
            return (-1, int(errno))
        bs = <char*>malloc(len(buf) * sizeof(char))
        if bs is NULL:
            return (-1, int(errno))
        for i in range(len(buf)):
            bs[i] = <char><unsigned char>(buf[i])
        ret = int(libcoopgamma_async_context_unmarshal(this, bs, &_n))
        ret = (ret, int(<intptr_t><void*>this))
        success = True
        return ret
    finally:
        if not success:
            libcoopgamma_async_context_destroy(this)
            free(this)
        free(bs)


def _libcoopgamma_native_connect(method : str, site : str, address : int):
    '''
    Connect to a coopgamma server, and start it if necessary
    
    Use `libcoopgamma_context_destroy` to disconnect
    
    SIGCHLD must not be ignored or blocked
    
    @param   method:str?     The adjustment method, `NULL` for automatic
    @param   site:str?       The site, `NULL` for automatic
    @param   address:int     The address of the state of the library, must be initialised
    @return  :(:bool, :int)  If [0] = `True`: [1] is the socket's file descriptor.
                             If [0] = `False`: [1] is 0 if the server on could not be
                                 initialised, or the value `errno` on other errors
    '''
    cdef char* cmethod = NULL
    cdef char* csite = NULL
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    try:
        if method is not None:
            buf = method.encode('utf-8') + bytes([0])
            cmethod = <char*>malloc(len(buf) * sizeof(char))
            for i in range(len(buf)):
                cmethod[i] = <char>(buf[i])
        if site is not None:
            buf = site.encode('utf-8') + bytes([0])
            csite = <char*>malloc(len(buf) * sizeof(char))
            for i in range(len(buf)):
                csite[i] = <char>(buf[i])
        if libcoopgamma_connect(cmethod, csite, ctx) < 0:
            return (False, int(errno))
        return (True, int(ctx.fd))
    finally:
        free(cmethod)
        free(csite)


def _libcoopgamma_native_set_nonblocking(address : int, nonblocking : bool):
    '''
    By default communication is blocking, this function
    can be used to switch between blocking and nonblocking
    
    After setting the communication to nonblocking,
    `libcoopgamma_flush`, `libcoopgamma_synchronise` and
    and request-sending functions can fail with EAGAIN and
    EWOULDBLOCK. It is safe to continue with `libcoopgamma_flush`
    (for `libcoopgamma_flush` it selfand equest-sending functions)
    or `libcoopgamma_synchronise` just like EINTR failure.
    
    @param   address:int       The address of the state of the library, must be connected
    @param   nonblocking:bool  Nonblocking mode?
    @return  :int              Zero on success, the value of `errno` on error
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    if libcoopgamma_set_nonblocking(ctx, <int>(1 if nonblocking else 0)) < 0:
        return int(errno)
    return 0


def _libcoopgamma_native_flush(address : int):
    '''
    Send all pending outbound data
    
    If this function or another function that sends a request
    to the server fails with EINTR, call this function to
    complete the transfer. The `async_ctx` parameter will always
    be in a properly configured state if a function fails
    with EINTR.
    
    @param   address:int  The address of the state of the library, must be connected
    @return  :int         Zero on success, the value of `errno` on error
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    if libcoopgamma_flush(ctx) < 0:
        return int(errno)
    return 0


def _libcoopgamma_native_synchronise(address : int, pending : list):
    '''
    Wait for the next message to be received
    
    @param   address:int        The address of the state of the library, must be connected
    @param   pending:list<int>  Addresses of the information for each pending request
    @return  :(:bool, :int)     If [0] = 0: [1] is the value of `errno`
                                   [0] = 1: [1] is the selected request
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef libcoopgamma_async_context_t* pends
    cdef libcoopgamma_async_context_t* pend
    cdef size_t selected = 0
    pends = <libcoopgamma_async_context_t*>malloc(len(pending) * sizeof(libcoopgamma_async_context_t))
    try:
        if pends is NULL:
            return (False, int(errno))
        for i in range(len(pending)):
            pend = <libcoopgamma_async_context_t*><void*><intptr_t>(pending[i])
            pends[i] = pend[0]
        if libcoopgamma_synchronise(ctx, pends, <size_t>len(pending), &selected) < 0:
            return (False, int(errno))
    finally:
        free(pends)
    return (True, <int>selected)


def _libcoopgamma_native_skip_message(address : int):
    '''
    Tell the library that you will not be parsing a receive message
    
    @param  address:int  The address of the state of the library, must be connected
    '''
    libcoopgamma_skip_message(<libcoopgamma_context_t*><void*><intptr_t>address)


def _libcoopgamma_native_get_crtcs_send(address : int, async_ctx : int):
    '''
    List all available CRTC:s, send request part
    
    @param   address:int    The address of the state of the library, must be connected
    @param   async_ctx:int  The address of the `AsyncContext` for the request
    @return  :int           Zero on success, the value of `errno` on failure
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef libcoopgamma_async_context_t* actx = <libcoopgamma_async_context_t*><void*><intptr_t>async_ctx
    if libcoopgamma_get_crtcs_send(ctx, actx) < 0:
        return int(errno)
    return 0


def _libcoopgamma_native_get_crtcs_recv(address : int, async_ctx : int):
    '''
    List all available CRTC:s, receive response part
    
    @param   address:int     The address of the state of the library, must be connected
    @param   async_ctx:int   The address of the `AsyncContext` for the request
    @return  :int|list<str>  The value of `errno` (on failure), or (on success)
                             a list of the names of the available CRTC:s
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef libcoopgamma_async_context_t* actx = <libcoopgamma_async_context_t*><void*><intptr_t>async_ctx
    cdef char** crtcs = libcoopgamma_get_crtcs_recv(ctx, actx)
    cdef bytes bs
    if crtcs is NULL:
        return int(errno)
    try:
        ret, i = [], 0
        while crtcs[i] is not NULL:
            bs = crtcs[i]
            ret.append(bs.decode('utf-8', 'strict'))
            i += 1
    finally:
        free(crtcs)
    return ret


def _libcoopgamma_native_get_crtcs_sync(address : int):
    '''
    List all available CRTC:s, synchronous version
    
    This is a synchronous request function, as such,
    you have to ensure that communication is blocking
    (default), and that there are not asynchronous
    requests waiting, it also means that EINTR:s are
    silently ignored and there no wait to cancel the
    operation without disconnection from the server
    
    @param   address:int     The address of the state of the library, must be connected
    @return  :int|list<str>  The value of `errno` (on failure), or (on success)
                             a list of the names of the available CRTC:s
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef char** crtcs = libcoopgamma_get_crtcs_sync(ctx)
    cdef bytes bs
    try:
        if crtcs is NULL:
            return int(errno)
        ret, i = [], 0
        while crtcs[i] is not NULL:
            bs = crtcs[i]
            ret.append(bs.decode('utf-8', 'strict'))
            i += 1
    finally:
        free(crtcs)
    return ret


def _libcoopgamma_native_get_gamma_info_send(crtc : str, address : int, async_ctx : int):
    '''
    Retrieve information about a CRTC:s gamma ramps, send request part
    
    Cannot be used before connecting to the server
    
    @param   crtc:crtc      The name of the CRTC
    @param   address:int    The address of the state of the library, must be connected
    @param   async_ctx:int  The address of the information about the request, that is
                            needed to identify and parse the response, is stored here
    @return  :int           Zero on success, the value of `errno` on error
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef libcoopgamma_async_context_t* actx = <libcoopgamma_async_context_t*><void*><intptr_t>async_ctx
    cdef char* ccrtc = NULL
    try:
        bs = crtc.encode('utf-8') + bytes([0])
        ccrtc = <char*>malloc(len(bs) * sizeof(char))
        if ccrtc is NULL:
            return int(errno)
        for i in range(len(bs)):
            ccrtc[i] = <char>(bs[i])
        if libcoopgamma_get_gamma_info_send(ccrtc, ctx, actx) < 0:
            return int(errno)
    finally:
        free(ccrtc)
    return 0


def _libcoopgamma_native_get_gamma_info_recv(address : int, async_ctx : int):
    '''
    Retrieve information about a CRTC:s gamma ramps, receive response part
    
    @param   address:int           The address of the state of the library, must be connected 
    @param   async_ctx:int         The address of the information about the request
    @return  :int|(:bool, :tuple)  The value of `errno` (on failure) or:
                                   Element 0: whether the call was successful
                                   Element 1: tuple with the data for the structure response (possibly error)
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef libcoopgamma_async_context_t* actx = <libcoopgamma_async_context_t*><void*><intptr_t>async_ctx
    cdef libcoopgamma_crtc_info_t info
    cdef bytes bs
    try:
        if libcoopgamma_crtc_info_initialise(&info) < 0:
            return int(errno)
        if libcoopgamma_get_gamma_info_recv(&info, ctx, actx) < 0:
            desc = None
            if ctx.error.description is not NULL:
                bs = ctx.error.description
                desc = bs.decode('utf-8', 'strict')
            ret = (False, (int(ctx.error.number), ctx.error.custom != 0, ctx.error.server_side != 0, desc))
        else:
            ret = (True, (info.cooperative != 0, int(info.depth), int(info.supported), int(info.red_size),
                          int(info.green_size), int(info.blue_size), int(info.colourspace),
                          None if info.have_gamut == 0 else ((info.red_x, info.red_y),
                                                             (info.green_x, info.green_y),
                                                             (info.blue_x, info.blue_y),
                                                             (info.white_x, info.white_y))))
    finally:
        libcoopgamma_crtc_info_destroy(&info)
    return ret


def _libcoopgamma_native_get_gamma_info_sync(crtc : str, address : int):
    '''
    Retrieve information about a CRTC:s gamma ramps, synchronous version
    
    This is a synchronous request function, as such, you have to ensure that
    communication is blocking (default), and that there are not asynchronous
    requests waiting, it also means that EINTR:s are silently ignored and
    there no wait to cancel the operation without disconnection from the server
    
    @param   crtc:str              The name of the CRTC
    @param   address:int           The address of the state of the library, must be connected
    @return  :int|(:bool, :tuple)  The value of `errno` (on failure) or:
                                   Element 0: whether the call was successful
                                   Element 1: tuple with the data for the structure response (possibly error)
    '''
    cdef char* ccrtc = NULL
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef libcoopgamma_crtc_info_t info
    cdef bytes bs
    try:
        if libcoopgamma_crtc_info_initialise(&info) < 0:
            return int(errno)
        bscrtc = crtc.encode('utf-8') + bytes([0])
        ccrtc = <char*>malloc(len(bscrtc) * sizeof(bscrtc))
        for i in range(len(bscrtc)):
            ccrtc[i] = <char>(bscrtc[i])
        if libcoopgamma_get_gamma_info_sync(ccrtc, &info, ctx) < 0:
            desc = None
            if ctx.error.description is not NULL:
                bs = ctx.error.description
                desc = bs.decode('utf-8', 'strict')
            ret = (False, (int(ctx.error.number), ctx.error.custom != 0, ctx.error.server_side != 0, desc))
        else:
            ret = (True, (info.cooperative != 0, int(info.depth), int(info.supported), int(info.red_size),
                          int(info.green_size), int(info.blue_size), int(info.colourspace),
                          None if info.have_gamut == 0 else ((info.red_x, info.red_y),
                                                             (info.green_x, info.green_y),
                                                             (info.blue_x, info.blue_y),
                                                             (info.white_x, info.white_y))))
    finally:
        libcoopgamma_crtc_info_destroy(&info)
        free(ccrtc)
    return ret


def _libcoopgamma_native_get_gamma_send(query, address : int, async_ctx : int):
    
    '''
    Retrieve the current gamma ramp adjustments, send request part
    
    Cannot be used before connecting to the server
    
    @param   query:Query    The query to send
    @param   address:int    The address of the state of the library, must be connected
    @param   async_ctx:int  The address of the information about the request, that is
                            needed to identify and parse the response, is stored here
    @return                 Zero on success, the value of `errno` on failure
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef libcoopgamma_async_context_t* actx = <libcoopgamma_async_context_t*><void*><intptr_t>async_ctx
    cdef libcoopgamma_filter_query_t qry
    crtc_bs = query.crtc.encode('utf-8') + bytes([0])
    qry.high_priority = <int64_t>(query.high_priority)
    qry.low_priority = <int64_t>(query.low_priority)
    qry.coalesce = <int>(query.coalesce)
    qry.crtc = <char*>malloc(len(crtc_bs) * sizeof(char))
    try:
        if qry.crtc is NULL:
            return int(errno)
        for i in range(len(crtc_bs)):
            qry.crtc[i] = <char>(crtc_bs[i])
        if libcoopgamma_get_gamma_send(&qry, ctx, actx) < 0:
            return int(errno)
    finally:
        free(qry.crtc)
    return 0
    

def _libcoopgamma_native_get_gamma_recv(address : int, async_ctx : int):
    '''
    Retrieve the current gamma ramp adjustments, receive response part
    
    @param   address:int           The address of the state of the library, must be connected
    @param   async_ctx:int         The address of the information about the request
    @return  :int|(:bool, :tuple)  The value of `errno` (on failure) or:
                                   Element 0: whether the call was successful
                                   Element 1: tuple with the data for the structure response (possibly error)
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef libcoopgamma_async_context_t* actx = <libcoopgamma_async_context_t*><void*><intptr_t>async_ctx
    cdef libcoopgamma_filter_table_t table
    cdef bytes bs
    cdef libcoopgamma_ramps_t* rampsp
    cdef char* fclass
    try:
        if libcoopgamma_filter_table_initialise(&table) < 0:
            return int(errno)
        if libcoopgamma_get_gamma_recv(&table, ctx, actx) < 0:
            desc = None
            if ctx.error.description is not NULL:
                bs = ctx.error.description
                desc = bs.decode('utf-8', 'strict')
            ret = (False, (int(ctx.error.number), ctx.error.custom != 0, ctx.error.server_side != 0, desc))
        else:
            filters = [None] * int(table.filter_count)
            for j in range(int(table.filter_count)):
                rampsp = &(table.filters[j].ramps)
                fclass = table.filters[j].fclass
                red   = [None] * rampsp.u_red_size
                green = [None] * rampsp.u_green_size
                blue  = [None] * rampsp.u_blue_size
                if table.depth == -2:
                    for i in range(rampsp.u_red_size):
                        red[i] = (<double*>(rampsp.u_red))[i]
                    for i in range(rampsp.u_green_size):
                        green[i] = (<double*>(rampsp.u_green))[i]
                    for i in range(rampsp.u_blue_size):
                        blue[i] = (<double*>(rampsp.u_blue))[i]
                elif table.depth == -1:
                    for i in range(rampsp.u_red_size):
                        red[i] = (<float*>(rampsp.u_red))[i]
                    for i in range(rampsp.u_green_size):
                        green[i] = (<float*>(rampsp.u_green))[i]
                    for i in range(rampsp.u_blue_size):
                        blue[i] = (<float*>(rampsp.u_blue))[i]
                elif table.depth == 8:
                    for i in range(rampsp.u_red_size):
                        red[i] = (<uint8_t*>(rampsp.u_red))[i]
                    for i in range(rampsp.u_green_size):
                        green[i] = (<uint8_t*>(rampsp.u_green))[i]
                    for i in range(rampsp.u_blue_size):
                        blue[i] = (<uint8_t*>(rampsp.u_blue))[i]
                elif table.depth == 16:
                    for i in range(rampsp.u_red_size):
                        red[i] = (<uint16_t*>(rampsp.u_red))[i]
                    for i in range(rampsp.u_green_size):
                        green[i] = (<uint16_t*>(rampsp.u_green))[i]
                    for i in range(rampsp.u_blue_size):
                        blue[i] = (<uint16_t*>(rampsp.u_blue))[i]
                elif table.depth == 32:
                    for i in range(rampsp.u_red_size):
                        red[i] = (<uint32_t*>(rampsp.u_red))[i]
                    for i in range(rampsp.u_green_size):
                        green[i] = (<uint32_t*>(rampsp.u_green))[i]
                    for i in range(rampsp.u_blue_size):
                        blue[i] = (<uint32_t*>(rampsp.u_blue))[i]
                elif table.depth == 64:
                    for i in range(rampsp.u_red_size):
                        red[i] = (<uint64_t*>(rampsp.u_red))[i]
                    for i in range(rampsp.u_green_size):
                        green[i] = (<uint64_t*>(rampsp.u_green))[i]
                    for i in range(rampsp.u_blue_size):
                        blue[i] = (<uint64_t*>(rampsp.u_blue))[i]
                ramps = (red, green, blue)
                pclass = None
                if fclass is not NULL:
                    bs = fclass
                    pclass = bs.decode('utf-8', 'strict')
                filters[j] = (int(table.filters[j].priority), pclass, ramps)
            ret = (True, (int(table.red_size), int(table.green_size), int(table.blue_size),
                          int(table.depth), filters))
    finally:
        libcoopgamma_filter_table_destroy(&table)
    return ret


def _libcoopgamma_native_get_gamma_sync(query, address : int):
    '''
    Retrieve the current gamma ramp adjustments, synchronous version
    
    This is a synchronous request function, as such, you have to ensure that
    communication is blocking (default), and that there are not asynchronous
    requests waiting, it also means that EINTR:s are silently ignored and
    there no wait to cancel the operation without disconnection from the server
    
    @param   query:Query           The query to send
    @param   address:int           The address of the state of the library, must be connected
    @return  :int|(:bool, :tuple)  The value of `errno` (on failure) or:
                                   Element 0: whether the call was successful
                                   Element 1: tuple with the data for the structure response (possibly error)
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef libcoopgamma_filter_table_t table
    cdef libcoopgamma_filter_query_t qry
    cdef bytes bs
    cdef libcoopgamma_ramps_t* rampsp
    cdef char* fclass
    crtc_bs = query.crtc.encode('utf-8') + bytes([0])
    qry.high_priority = <int64_t>(query.high_priority)
    qry.low_priority = <int64_t>(query.low_priority)
    qry.coalesce = <int>(query.coalesce)
    qry.crtc = <char*>malloc(len(crtc_bs) * sizeof(char))
    try:
        if qry.crtc is NULL:
            return int(errno)
        for i in range(len(crtc_bs)):
            qry.crtc[i] = <char>(crtc_bs[i])
        if libcoopgamma_filter_table_initialise(&table) < 0:
            saved_errno = int(errno)
            libcoopgamma_filter_table_destroy(&table)
            return saved_errno
        try:
            if libcoopgamma_get_gamma_sync(&qry, &table, ctx) < 0:
                desc = None
                if ctx.error.description is not NULL:
                    bs = ctx.error.description
                    desc = bs.decode('utf-8', 'strict')
                ret = (False, (int(ctx.error.number), ctx.error.custom != 0, ctx.error.server_side != 0, desc))
            else:
                filters = [None] * int(table.filter_count)
                for j in range(int(table.filter_count)):
                    rampsp = &(table.filters[j].ramps)
                    fclass = table.filters[j].fclass
                    red   = [None] * rampsp.u_red_size
                    green = [None] * rampsp.u_green_size
                    blue  = [None] * rampsp.u_blue_size
                    if table.depth == -2:
                        for i in range(rampsp.u_red_size):
                            red[i] = (<double*>(rampsp.u_red))[i]
                        for i in range(rampsp.u_green_size):
                            green[i] = (<double*>(rampsp.u_green))[i]
                        for i in range(rampsp.u_blue_size):
                            blue[i] = (<double*>(rampsp.u_blue))[i]
                    elif table.depth == -1:
                        for i in range(rampsp.u_red_size):
                            red[i] = (<float*>(rampsp.u_red))[i]
                        for i in range(rampsp.u_green_size):
                            green[i] = (<float*>(rampsp.u_green))[i]
                        for i in range(rampsp.u_blue_size):
                            blue[i] = (<float*>(rampsp.u_blue))[i]
                    elif table.depth == 8:
                        for i in range(rampsp.u_red_size):
                            red[i] = (<uint8_t*>(rampsp.u_red))[i]
                        for i in range(rampsp.u_green_size):
                            green[i] = (<uint8_t*>(rampsp.u_green))[i]
                        for i in range(rampsp.u_blue_size):
                            blue[i] = (<uint8_t*>(rampsp.u_blue))[i]
                    elif table.depth == 16:
                        for i in range(rampsp.u_red_size):
                            red[i] = (<uint16_t*>(rampsp.u_red))[i]
                        for i in range(rampsp.u_green_size):
                            green[i] = (<uint16_t*>(rampsp.u_green))[i]
                        for i in range(rampsp.u_blue_size):
                            blue[i] = (<uint16_t*>(rampsp.u_blue))[i]
                    elif table.depth == 32:
                        for i in range(rampsp.u_red_size):
                            red[i] = (<uint32_t*>(rampsp.u_red))[i]
                        for i in range(rampsp.u_green_size):
                            green[i] = (<uint32_t*>(rampsp.u_green))[i]
                        for i in range(rampsp.u_blue_size):
                            blue[i] = (<uint32_t*>(rampsp.u_blue))[i]
                    elif table.depth == 64:
                        for i in range(rampsp.u_red_size):
                            red[i] = (<uint64_t*>(rampsp.u_red))[i]
                        for i in range(rampsp.u_green_size):
                            green[i] = (<uint64_t*>(rampsp.u_green))[i]
                        for i in range(rampsp.u_blue_size):
                            blue[i] = (<uint64_t*>(rampsp.u_blue))[i]
                    ramps = (red, green, blue)
                    pclass = None
                    if fclass is not NULL:
                        bs = fclass
                        pclass = bs.decode('utf-8', 'strict')
                    filters[j] = (int(table.filters[j].priority), pclass, ramps)
                ret = (True, (int(table.red_size), int(table.green_size), int(table.blue_size),
                              int(table.depth), filters))
        finally:
            libcoopgamma_filter_table_destroy(&table)
    finally:
        free(qry.crtc)
    return ret


def _libcoopgamma_native_copy_ramps(intptr_t dest_address, src, libcoopgamma_depth_t depth):
    '''
    Copy a Python ramp-trio into C ramp-trio
    
    @param  dest_address:intptr_t       The address of the C ramp-trio
    @param  src:Ramps                   The Python ramp-trio
    @param  depth:libcoopgamma_depth_t  The data type of the ramp stops
    '''
    cdef libcoopgamma_ramps_t* dest = <libcoopgamma_ramps_t*><void*><intptr_t>dest_address
    cdef uint8_t* r8
    cdef uint8_t* g8
    cdef uint8_t* b8
    cdef uint16_t* r16
    cdef uint16_t* g16
    cdef uint16_t* b16
    cdef uint32_t* r32
    cdef uint32_t* g32
    cdef uint32_t* b32
    cdef uint64_t* r64
    cdef uint64_t* g64
    cdef uint64_t* b64
    cdef float* rf
    cdef float* gf
    cdef float* bf
    cdef double* rd
    cdef double* gd
    cdef double* bd
    cdef size_t rn = <size_t>len(src.red)
    cdef size_t gn = <size_t>len(src.green)
    cdef size_t bn = <size_t>len(src.blue)
    if depth == 8:
        r8 = <uint8_t*>malloc((rn + gn + bn) * sizeof(uint8_t))
        g8 = r8 + rn
        b8 = g8 + gn
        for i in range(int(rn)):
            r8[i] = <uint8_t>(src.red[i])
        for i in range(int(gn)):
            g8[i] = <uint8_t>(src.green[i])
        for i in range(int(bn)):
            b8[i] = <uint8_t>(src.blue[i])
        dest.u_red   = <void*>r8
        dest.u_green = <void*>g8
        dest.u_blue  = <void*>b8
    elif depth == 16:
        r16 = <uint16_t*>malloc((rn + gn + bn) * sizeof(uint16_t))
        g16 = r16 + rn
        b16 = g16 + gn
        for i in range(int(rn)):
            r16[i] = <uint16_t>(src.red[i])
        for i in range(int(gn)):
            g16[i] = <uint16_t>(src.green[i])
        for i in range(int(bn)):
            b16[i] = <uint16_t>(src.blue[i])
        dest.u_red   = <void*>r16
        dest.u_green = <void*>g16
        dest.u_blue  = <void*>b16
    elif depth == 32:
        r32 = <uint32_t*>malloc((rn + gn + bn) * sizeof(uint32_t))
        g32 = r32 + rn
        b32 = g32 + gn
        for i in range(int(rn)):
            r32[i] = <uint32_t>(src.red[i])
        for i in range(int(gn)):
            g32[i] = <uint32_t>(src.green[i])
        for i in range(int(bn)):
            b32[i] = <uint32_t>(src.blue[i])
        dest.u_red   = <void*>r32
        dest.u_green = <void*>g32
        dest.u_blue  = <void*>b32
    elif depth == 64:
        r64 = <uint64_t*>malloc((rn + gn + bn) * sizeof(uint64_t))
        g64 = r64 + rn
        b64 = g64 + gn
        for i in range(int(rn)):
            r64[i] = <uint64_t>(src.red[i])
        for i in range(int(gn)):
            g64[i] = <uint64_t>(src.green[i])
        for i in range(int(bn)):
            b64[i] = <uint64_t>(src.blue[i])
        dest.u_red   = <void*>r64
        dest.u_green = <void*>g64
        dest.u_blue  = <void*>b64
    elif depth == -1:
        rf = <float*>malloc((rn + gn + bn) * sizeof(float))
        gf = rf + rn
        bf = gf + gn
        for i in range(int(rn)):
            rf[i] = <float>(src.red[i])
        for i in range(int(gn)):
            gf[i] = <float>(src.green[i])
        for i in range(int(bn)):
            bf[i] = <float>(src.blue[i])
        dest.u_red   = <void*>rf
        dest.u_green = <void*>gf
        dest.u_blue  = <void*>bf
    else:
        rd = <double*>malloc((rn + gn + bn) * sizeof(double))
        gd = rd + rn
        bd = gd + gn
        for i in range(int(rn)):
            rd[i] = <double>(src.red[i])
        for i in range(int(gn)):
            gd[i] = <double>(src.green[i])
        for i in range(int(bn)):
            bd[i] = <double>(src.blue[i])
        dest.u_red   = <void*>rd
        dest.u_green = <void*>gd
        dest.u_blue  = <void*>bd


def _libcoopgamma_native_set_gamma_send(filtr, address : int, async_ctx : int):
    '''
    Apply, update, or remove a gamma ramp adjustment, send request part
    
    Cannot be used before connecting to the server
    
    @param   filtr:Filter   The filter to apply, update, or remove, gamma ramp
                            meta-data must match the CRTC's
    @param   address:int    The address of the state of the library, must be connected
    @param   async_ctx:int  The address of the information about the request, that is needed to
                            identify and parse the response, is stored here
    @return  :int           Zero on success, the value of `errno` on failure
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef libcoopgamma_async_context_t* actx = <libcoopgamma_async_context_t*><void*><intptr_t>async_ctx
    cdef libcoopgamma_filter_t flr
    crtc_bs = filtr.crtc.encode('utf-8') + bytes([0])
    clss_bs = filtr.fclass.encode('utf-8') + bytes([0])
    flr.priority = <int64_t>(0 if filtr.priority is None else filtr.priority)
    flr.lifespan = <libcoopgamma_lifespan_t>(filtr.lifespan)
    flr.depth = <libcoopgamma_depth_t>(0 if filtr.depth is None else filtr.depth)
    flr.fclass = NULL
    flr.crtc = NULL
    flr.ramps.u_red_size   = len(filtr.ramps.red)   if filtr.ramps is not None else 0
    flr.ramps.u_green_size = len(filtr.ramps.green) if filtr.ramps is not None else 0
    flr.ramps.u_blue_size  = len(filtr.ramps.blue)  if filtr.ramps is not None else 0
    flr.ramps.u_red   = NULL
    flr.ramps.u_green = NULL
    flr.ramps.u_blue  = NULL
    try:
        if filtr.ramps is not None:
            _libcoopgamma_native_copy_ramps(<intptr_t><void*>&(flr.ramps), filtr.ramps, flr.depth)
        flr.crtc = <char*>malloc(len(crtc_bs) * sizeof(char))
        if flr.crtc is NULL:
            return int(errno)
        flr.fclass = <char*>malloc(len(clss_bs) * sizeof(char))
        if flr.fclass is NULL:
            return int(errno)
        for i in range(len(crtc_bs)):
            flr.crtc[i] = <char>(crtc_bs[i])
        for i in range(len(clss_bs)):
            flr.fclass[i] = <char>(clss_bs[i])
        if libcoopgamma_set_gamma_send(&flr, ctx, actx) < 0:
            return int(errno)
    finally:
        free(flr.crtc)
        free(flr.fclass)
        free(flr.ramps.u_red)
    return 0


def _libcoopgamma_native_set_gamma_recv(address : int, async_ctx : int):
    '''
    Apply, update, or remove a gamma ramp adjustment, receive response part
    
    @param   address:int    The address of the state of the library, must be connected
    @param   async_ctx:int  The address of the information about the request
    @return  :tuple?        The value of `errno` (on failure) or:
                            Element 0: whether the call was successful
                            Element 1: tuple with the data for the structure response (possibly error)
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef libcoopgamma_async_context_t* actx = <libcoopgamma_async_context_t*><void*><intptr_t>async_ctx
    cdef bytes bs
    if libcoopgamma_set_gamma_recv(ctx, actx) < 0:
        desc = None
        if ctx.error.description is not NULL:
            bs = ctx.error.description
            desc = bs.decode('utf-8', 'strict')
        return (int(ctx.error.number), ctx.error.custom != 0, ctx.error.server_side != 0, desc)
    return None


def _libcoopgamma_native_set_gamma_sync(filtr, address : int):
    '''
    Apply, update, or remove a gamma ramp adjustment, synchronous version
    
    This is a synchronous request function, as such, you have to ensure that
    communication is blocking (default), and that there are not asynchronous
    requests waiting, it also means that EINTR:s are silently ignored and
    there no wait to cancel the operation without disconnection from the server
    
    @param   filtr:Filter  The filter to apply, update, or remove, gamma ramp
                           meta-data must match the CRTC's
    @param   address:int   The address of the state of the library, must be connected
    @return  :tuple?       The value of `errno` (on failure) or:
                           Element 0: whether the call was successful
                           Element 1: tuple with the data for the structure response (possibly error)
    '''
    cdef libcoopgamma_context_t* ctx = <libcoopgamma_context_t*><void*><intptr_t>address
    cdef libcoopgamma_filter_t flr
    cdef bytes bs
    crtc_bs = filtr.crtc.encode('utf-8') + bytes([0])
    clss_bs = filtr.fclass.encode('utf-8') + bytes([0])
    flr.priority = <int64_t>(0 if filtr.priority is None else filtr.priority)
    flr.lifespan = <libcoopgamma_lifespan_t>(filtr.lifespan)
    flr.depth = <libcoopgamma_depth_t>(0 if filtr.depth is None else filtr.depth)
    flr.fclass = NULL
    flr.crtc = NULL
    flr.ramps.u_red_size   = len(filtr.ramps.red)   if filtr.ramps is not None else 0
    flr.ramps.u_green_size = len(filtr.ramps.green) if filtr.ramps is not None else 0
    flr.ramps.u_blue_size  = len(filtr.ramps.blue)  if filtr.ramps is not None else 0
    flr.ramps.u_red   = NULL
    flr.ramps.u_green = NULL
    flr.ramps.u_blue  = NULL
    try:
        if filtr.ramps is not None:
            _libcoopgamma_native_copy_ramps(<intptr_t><void*>&(flr.ramps), filtr.ramps, flr.depth)
        flr.crtc = <char*>malloc(len(crtc_bs) * sizeof(char))
        if flr.crtc is NULL:
            return int(errno)
        flr.fclass = <char*>malloc(len(clss_bs) * sizeof(char))
        if flr.fclass is NULL:
            return int(errno)
        for i in range(len(crtc_bs)):
            flr.crtc[i] = <char>(crtc_bs[i])
        for i in range(len(clss_bs)):
            flr.fclass[i] = <char>(clss_bs[i])
        if libcoopgamma_set_gamma_sync(&flr, ctx) < 0:
            desc = None
            if ctx.error.description is not NULL:
                bs = ctx.error.description
                desc = bs.decode('utf-8', 'strict')
            return (int(ctx.error.number), ctx.error.custom != 0, ctx.error.server_side != 0, desc)
    finally:
        free(flr.crtc)
        free(flr.fclass)
        free(flr.ramps.u_red)
    return None


class Support(_enum.IntEnum):
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


class Depth(_enum.IntEnum):
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


class Lifespan(_enum.IntEnum):
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


class Colourspace(_enum.IntEnum):
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
            (successful, value) = _libcoopgamma_native_context_create()
            if not successful:
                raise ErrorReport.create_error(value)
        else:
            (error, value) = _libcoopgamma_native_context_unmarshal(buf)
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
            _libcoopgamma_native_context_free(self.address)
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        data = _libcoopgamma_native_context_marshal(self.address)
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
        (successful, value) = _libcoopgamma_native_connect(method, site, self.address)
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
        _libcoopgamma_native_context_set_fd(self.address, -1)
    
    def attach(self):
        '''
        Undoes the action of `detach`
        '''
        _libcoopgamma_native_context_set_fd(self.address, self.fd)
    
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
        error = _libcoopgamma_native_set_nonblocking(self.address, nonbreaking)
        if error != 0:
            raise ErrorReport.create_error(error)
    
    def flush(self):
        '''
        Send all pending outbound data
        
        If this function or another function that sends a request to the server fails
        with EINTR, call this function to complete the transfer. The `async_ctx` parameter
        will always be in a properly configured state if a function fails with EINTR.
        '''
        error = _libcoopgamma_native_flush(self.address)
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
        (successful, value) = _libcoopgamma_native_synchronise(self.address, pending)
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
        _libcoopgamma_native_skip_message(self.address)
    
    def get_crtcs_send(self, async_ctx):
        '''
        List all available CRTC:s, send request part
        
        @param  async_ctx:AsyncContext  Slot for information about the request that is
                                        needed to identify and parse the response
        '''
        
        error = _libcoopgamma_native_get_crtcs_send(self.address, async_ctx.address)
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
        ret = _libcoopgamma_native_get_crtcs_recv(self.address, async_ctx.address)
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
        ret = _libcoopgamma_native_get_crtcs_sync(self.address)
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
        error = _libcoopgamma_native_get_gamma_info_send(crtc, self.address, async_ctx.address)
        if error != 0:
            raise ErrorReport.create_error(error)
    
    def get_gamma_info_recv(self, async_ctx):
        '''
        Retrieve information about a CRTC:s gamma ramps, receive response part
        
        @param   async_ctx:AsyncContext  Information about the request
        @return  :CRTCInfo               Information about the CRTC
        '''
        value = _libcoopgamma_native_get_gamma_info_recv(self.address, async_ctx.address)
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
        value = _libcoopgamma_native_get_gamma_info_sync(crtc, self.address)
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
        error = _libcoopgamma_native_get_gamma_send(
                                    query, self.address, async_ctx.address)
        if error != 0:
            raise ErrorReport.create_error(error)
    
    def get_gamma_recv(self, async_ctx):
        '''
        Retrieve the current gamma ramp adjustments, receive response part
        
        @param   async_ctx:AsyncContext  Information about the request
        @return  :FilterTable            Filter table
        '''
        value = _libcoopgamma_native_get_gamma_recv(self.address, async_ctx.address)
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
        value = _libcoopgamma_native_get_gamma_sync(query, self.address)
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
        error = _libcoopgamma_native_set_gamma_send(filtr, self.address, async_ctx.address)
        if error != 0:
            raise ErrorReport.create_error(error)
    
    def set_gamma_recv(self, async_ctx):
        '''
        Apply, update, or remove a gamma ramp adjustment, receive response part
        
        @param  async_ctx:AsyncContext  Information about the request
        '''
        error = _libcoopgamma_native_set_gamma_recv(self.address, async_ctx.address)
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
        error = _libcoopgamma_native_set_gamma_sync(filtr, self.address)
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
            (successful, value) = _libcoopgamma_native_async_context_create()
            if not successful:
                raise ErrorReport.create_error(value)
        else:
            (error, value) = _libcoopgamma_native_async_context_unmarshal(buf)
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
            _libcoopgamma_native_async_context_free(self.address)
    
    def __repr__(self):
        '''
        Create a parsable string representation of the instance
        
        @return  :str  Parsable representation of the instance
        '''
        data = _libcoopgamma_native_async_context_marshal(self.address)
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
    ret = _libcoopgamma_native_get_methods()
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
    ret = _libcoopgamma_native_get_method_and_site(method, site)
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
    ret = _libcoopgamma_native_get_pid_file(method, site)
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
    ret = _libcoopgamma_native_get_socket_file(method, site)
    if ret is not None and isinstance(ret, int):
        raise ErrorReport.create_error(ret)
    return ret
