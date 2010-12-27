package = "luasoap"
version = "2.0.2-1"

source = {
url = "",
   url="http://github.com/downloads/tomasguisasola/luasoap/luasoap-2.0.2.tar.gz",
   md5="",
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
   type = "builtin",
   modules = {
      soap  = "src/soap.lua",
      ["soap.server"] = "src/server.lua",
      ["soap.client"] = "src/client.lua",
   }
}

