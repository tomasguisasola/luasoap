package = "luasoap"
version = "1.1-1"

source = {
   url="http://luasoap.luaforge.net/luasoap-1.1-1.tar",
}

description = {
   summary = "Support for SOAP",
   detailed = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents",
   homepage = "http://luasoap.luaforge.net/",
   license = "MIT/X11",
}

dependencies = {
   "lua >= 5.1",
   "luaexpat >= 1.1.0-3",
   "luasocket >= 2.0.2-1",
}

build = {
   type = "none",
}

