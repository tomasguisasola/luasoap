VERSION=4.0.1
LUA_SOAP_VERSION=luasoap-$(VERSION)

# Default prefix
PREFIX ?= /usr/local

# Lua version and dirs
LUA_SYS_VER ?= 5.3
# System's lua directory (where Lua libraries will be installed)
LUA_DIR ?= $(PREFIX)/share/lua/$(LUA_SYS_VER)
# Installation directories
INSTALL_DIR= $(LUA_DIR)/soap
EXTRA_DIR= $(INSTALL_DIR)/client

MAIN_LUA= src/soap.lua
LUAS= src/client.lua src/server.lua src/wsdl.lua
EXTRA= src/client/https.lua

build clean:

install:
	cp $(MAIN_LUA) $(LUA_DIR)
	mkdir -p $(INSTALL_DIR)
	cp $(LUAS) $(INSTALL_DIR)
	mkdir -p $(EXTRA_DIR)
	cp $(EXTRA) $(EXTRA_DIR)

uninstall:
	rm -rf $(INSTALL_DIR) $(LUA_DIR)/soap.lua

dist:
	ln -fs `pwd` ../$(LUA_SOAP_VERSION)
	cd .. && tar czf $(LUA_SOAP_VERSION).tar.gz $(LUA_SOAP_VERSION) --exclude .git --exclude rockspecs $(LUA_SOAP_VERSION)
	rm -rf ../$(LUA_SOAP_VERSION)
	echo Created ../$(LUA_SOAP_VERSION).tar.gz
