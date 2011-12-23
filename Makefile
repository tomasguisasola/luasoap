# $Id: Makefile,v 1.13 2009/07/22 19:02:46 tomas Exp $
#

VERSION=3.0

LUA_DIR= /usr/local/share/lua/5.1
INSTALL_DIR= $(LUA_DIR)/soap
EXTRA_DIR= $(INSTALL_DIR)/client

LUAS= src/soap.lua src/client.lua src/server.lua
EXTRA= src/client/https.lua

build clean:

install:
	mkdir -p $(INSTALL_DIR)
	cp $(LUAS) $(INSTALL_DIR)
	mkdir -p $(EXTRA_DIR)
	cp $(EXTRA) $(EXTRA_DIR)

uninstall:
	rm -rf $(INSTALL_DIR)

dist:
	cd ..; tar czf luasoap-$(VERSION).tar.gz luasoap-$(VERSION) --exclude .git --exclude rockspecs
	echo Created ../luasoap-$(VERSION).tar.gz
