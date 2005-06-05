# $Id: Makefile,v 1.10 2005/06/05 17:02:15 tomas Exp $

LUA_DIR= /usr/local/share/lua/5.0

LUAS= src/soap.lua src/http.lua


build clean:

install:
	mkdir -p $(LUA_DIR)/soap
	cp $(LUAS) $(LUA_DIR)/soap
