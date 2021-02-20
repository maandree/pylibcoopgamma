PREFIX = /usr

PY_MAJOR   = $$(python --version 2>&1 | cut -d ' ' -f 2 | cut -d . -f 1)
PY_MINOR   = $$(python$(PYTHON_MAJOR) --version 2>&1)
PY_VER     = $(PY_MAJOR)$(PY_MINOR)
PY_VERSION = $(PY_MAJOR).$(PY_MINOR)

PYTHONDIR = $(PREFIX)/lib/python$(PY_VERSION)

CYTHON    = cython
PKGCONFIG = pkg-config
PYTHON    = python$(PY_MAJOR)

CPPFLAGS =
CFLAGS   = -std=c99 -Wall $$($(PKGCONFIG) --cflags python$(PY_MAJOR)) -O2
LDFLAGS  = $$($(PKGCONFIG) --libs python$(PY_MAJOR)) -lcoopgamma
