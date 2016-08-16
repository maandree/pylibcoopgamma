PREFIX = /usr
LIBDIR = $(PREFIX)$(LIB)
DATADIR = $(PREFIX)$(DATA)
LICENSEDIR = $(DATADIR)/licenses

PKGNAME = pylibcoopgamma

GPP = gpp
CYTHON = cython
PKGCONFIG = pkg-config
PYTHON = python3

PY_MAJOR = $(shell $(PYTHON) --version | cut -d ' ' -f 2 | cut -d . -f 1)
PY_MINOR = $(shell $(PYTHON) --version | cut -d ' ' -f 2 | cut -d . -f 2)
PY_VER = $(PY_MAJOR)$(PY_MINOR)
PY_VERSION = $(PY_MAJOR).$(PY_MINOR)

PYTHONDIR = $(LIBDIR)/python$(PY_VERSION)

OPTIMISE = -O2
LIBS = python$(PY_MAJOR)

CC_FLAGS = $$($(PKGCONFIG) --cflags $(LIBS)) -std=c99 $(OPTIMISE) -fPIC $(CFLAGS) $(CPPFLAGS)
LD_FLAGS = $$($(PKGCONFIG) --libs $(LIBS)) -lcoopgamma -std=c99 $(OPTIMISE) -shared $(LDFLAGS)

ifeq ($(shell test $(PY_VER) -ge 35 ; echo $$?),0)
PY_OPT2_EXT = opt-2.pyc
else
PY_OPT2_EXT = pyo
endif



.PHONY: all
all: base

.PHONY: base
base: lib

.PHONY: lib
lib: compiled optimised native

.PHONY: compiled
compiled: src/__pycache__/libcoopgamma.cpython-$(PY_VER).pyc

.PHONY: optimised
optimised: src/__pycache__/libcoopgamma.cpython-$(PY_VER).$(PY_OPT2_EXT)

.PHONY: so-files
native: bin/libcoopgamma_native.so

obj/libcoopgamma_native.pyx: src/libcoopgamma_native.pyx.gpp
	@mkdir -p obj
	$(GPP) -s '$$$$' -i src/libcoopgamma_native.pyx.gpp -o $@

obj/%.c: obj/%.pyx
	if ! $(CYTHON) -3 -v $< ; then rm $@ ; false ; fi

obj/%.o: obj/%.c src/*.h
	$(CC) $(CC_FLAGS) -iquote"src" -c -o $@ $<

bin/%.so: obj/%.o
	@mkdir -p bin
	$(CC) $(LD_FLAGS) -o $@ $^

src/__pycache__/%.cpython-$(PY_VER).pyc: src/%.py
	$(PYTHON) -m compileall $<

src/__pycache__/%.cpython-$(PY_VER).$(PY_OPT2_EXT): src/%.py
	$(PYTHON) -OO -m compileall $<



.PHONY: install
install: install-base

.PHONY: install-all
install-all: install-base

.PHONY: install-base
install-base: install-lib install-copyright

.PHONY: install-lib
install-lib: install-source install-compiled install-optimised install-native

.PHONY: install-source
install-source: src/libcoopgamma.py
	mkdir -p -- "$(DESTDIR)$(PYTHONDIR)"
	cp $^ -- "$(DESTDIR)$(PYTHONDIR)"

.PHONY: install-compiled
install-compiled: src/__pycache__/libcoopgamma.cpython-$(PY_VER).pyc
	mkdir -p -- "$(DESTDIR)$(PYTHONDIR)/__pycache__"
	cp $^ -- "$(DESTDIR)$(PYTHONDIR)/__pycache__"

.PHONY: install-optimised
install-optimised: src/__pycache__/libcoopgamma.cpython-$(PY_VER).$(PY_OPT2_EXT)
	mkdir -p -- "$(DESTDIR)$(PYTHONDIR)/__pycache__"
	cp $^ -- "$(DESTDIR)$(PYTHONDIR)/__pycache__"

.PHONY: install-native
install-native: bin/libcoopgamma_native.so
	mkdir -p -- "$(DESTDIR)$(PYTHONDIR)"
	cp $^ -- "$(DESTDIR)$(PYTHONDIR)"

.PHONY: install-copyright
install-copyright: install-copying install-license

.PHONY: install-copying
install-copying: COPYING
	mkdir -p -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"
	cp $^ -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"

.PHONY: install-license
install-license: LICENSE
	mkdir -p -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"
	cp $^ -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"



.PHONY: uninstall
uninstall:
	-rm -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)/LICENSE"
	-rm -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)/COPYING"
	-rmdir -- "$(DESTDIR)$(LICENSEDIR)/$(PKGNAME)"
	-rm -- "$(DESTDIR)$(PYTHONDIR)/__pycache__/libcoopgamma.cpython-$(PY_VER).$(PY_OPT2_EXT)"
	-rm -- "$(DESTDIR)$(PYTHONDIR)/__pycache__/libcoopgamma.cpython-$(PY_VER).pyc"
	-rm -- "$(DESTDIR)$(PYTHONDIR)/libcoopgamma.py"
	-rm -- "$(DESTDIR)$(PYTHONDIR)/libcoopgamma_native.so"



.PHONY: clean
clean:
	-rm -r obj bin src/__pycache__

