GPP = gpp
CYTHON = cython

all: obj/libcoopgamma_native.c

obj/libcoopgamma_native.pyx: src/libcoopgamma_native.pyx.gpp
	@mkdir -p obj
	$(GPP) -s '$$$$' -i src/libcoopgamma_native.pyx.gpp -o $@

obj/%.c: obj/%.pyx
	if ! $(CYTHON) -3 -v $< ; then rm $@ ; false ; fi

