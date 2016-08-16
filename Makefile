GPP = gpp
CYTHON = cython
PKGCONFIG = pkg-config

PY_MAJOR = 3

OPTIMISE = -O2
LIBS = python$(PY_MAJOR)

CC_FLAGS = $$($(PKGCONFIG) --cflags $(LIBS)) -std=c99 $(OPTIMISE) -fPIC $(CFLAGS) $(CPPFLAGS)
LD_FLAGS = $$($(PKGCONFIG) --libs $(LIBS)) -lcoopgamma -std=c99 $(OPTIMISE) -shared $(LDFLAGS)


all: bin/libcoopgamma_native.so

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

