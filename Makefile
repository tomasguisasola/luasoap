LUA_DIR= /usr/local/share/lua/5.0
VERSION= 1.0.0
PKG= luasoap-$(VERSION)
DIST_DIR= $(PKG)
TAR_FILE= $(PKG).tar.gz
ZIP_FILE= $(PKG).zip
LUAS= src/soap.lua src/http.lua
SRCS= README Makefile \
	$(LUAS) tests/test.lua \
	doc/us/index.html doc/us/manual.html doc/us/license.html doc/us/luasoap.png

dist: dist_dir
	tar -czf $(TAR_FILE) $(DIST_DIR)
	zip -rq $(ZIP_FILE) $(DIST_DIR)/*
	rm -rf $(DIST_DIR)

dist_dir:
	mkdir $(DIST_DIR)
	cp $(SRCS) $(DIST_DIR)

install:
	mkdir -p $(LUA_DIR)/soap
	cp $(LUAS) $(LUA_DIR)/soap

clean:
	rm -f $(TAR_FILE) $(ZIP_FILE)
