VERSION= 1.0a
PKG= luasoap-$(VERSION)
TAR_FILE= $(PKG).tar.gz
ZIP_FILE= $(PKG).zip
LIBS= /usr/local/lua/soap/
LUAS= soap.lua http.lua
SRCS= README Makefile \
	$(LUAS) test.lua \
	index.html manual.html license.html luasoap.png

dist:
	mkdir $(PKG)
	cp $(SRCS) $(PKG)
	tar -czf $(TAR_FILE) $(PKG)
	zip -lq $(ZIP_FILE) $(PKG)/*
	rm -rf $(PKG)

install:
	mkdir -p $(LIBS)
	cp $(LUAS) $(LIBS)

clean:
	rm $(TAR_FILE) $(ZIP_FILE)
