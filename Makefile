# $Id: Makefile,v 1.11 2005/12/26 18:32:05 tomas Exp $

LUA_DIR= /usr/local/share/lua/5.0

LUAS= src/soap.lua src/http.lua src/server.lua


build clean:

install:
	mkdir -p $(LUA_DIR)/soap
	cp $(LUAS) $(LUA_DIR)/soap
