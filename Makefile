VERSION= 1.0a
PKG= luasoap-$(VERSION)
DIST_DIR= $(PKG)
TAR_FILE= $(PKG).tar.gz
ZIP_FILE= $(PKG).zip
LIBS= /usr/local/lua/soap/
LUAS= soap.lua http.lua
SRCS= README Makefile \
	$(LUAS) test.lua \
	index.html manual.html license.html luasoap.png

dist: dist_dir
	tar -czf $(TAR_FILE) $(DIST_DIR)
	zip -lq $(ZIP_FILE) $(DIST_DIR)/*
	rm -rf $(DIST_DIR)

dist_dir:
	mkdir $(DIST_DIR)
	cp $(SRCS) $(DIST_DIR)

install:
	mkdir -p $(LIBS)
	cp $(LUAS) $(LIBS)

clean:
	rm $(TAR_FILE) $(ZIP_FILE)
