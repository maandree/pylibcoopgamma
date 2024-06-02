PREFIX = /usr

PYTHON_MAJOR   = $$(python --version 2>&1 | cut -d ' ' -f 2 | cut -d . -f 1)
PYTHON_MINOR   = $$(python$(PYTHON_MAJOR) --version 2>&1 | cut -d . -f 2)
PYTHON_VER     = $(PYTHON_MAJOR)$(PYTHON_MINOR)
PYTHON_VERSION = $(PYTHON_MAJOR).$(PYTHON_MINOR)

PYTHONDIR = $(PREFIX)/lib/python$(PYTHON_VERSION)

CYTHON    = cython$(PYTHON_MAJOR)
PKGCONFIG = pkg-config
PYTHON    = python$(PYTHON_MAJOR)

CC = c99

CPPFLAGS =
CFLAGS   = -Wall $$($(PKGCONFIG) --cflags python$(PYTHON_MAJOR)) -O2
LDFLAGS  = $$($(PKGCONFIG) --libs python$(PYTHON_MAJOR)) -lcoopgamma
