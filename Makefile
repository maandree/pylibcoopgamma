.POSIX:

CONFIGFILE = config.mk
include $(CONFIGFILE)

all: libcoopgamma.so
libcoopgamma.o: libcoopgamma.c include-libcoopgamma.h

.pyx.c:
	if ! $(CYTHON) -3 -v $<; then rm -f -- $@; false; fi

.c.o:
	$(CC) -fPIC -c -o $@ $< $(CFLAGS) $(CPPFLAGS)

.o.so:
	$(CC) -shared -o $@ $< $(LDFLAGS)

check: libcoopgamma.so
	./test

install: libcoopgamma.so
	mkdir -p -- "$(DESTDIR)$(PYTHONDIR)"
	cp -- libcoopgamma.so "$(DESTDIR)$(PYTHONDIR)"

uninstall:
	-rm -- "$(DESTDIR)$(PYTHONDIR)/libcoopgamma.so"

clean:
	-rm -rf -- __pycache__/ *.pyc *.pyo *.c *.o *.su *.so

.SUFFIXES:
.SUFFIXES: .so .o .c .pyx

.PHONY: all check install uninstall clean
