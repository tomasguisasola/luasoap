package = "luasoap"
version = "3.0.1-1"

source = {
   url="https://github.com/tomasguisasola/luasoap/archive/v3_0_1.tar.gz",
   md5="a796c6b2c7757c634abc1f0ee04b3f98",
   dir="luasoap-3_0_1",
}

description = {
   summary = "Support for SOAP",
   detailed = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents",
   homepage = "http://tomasguisasola.github.io/luasoap/",
   license = "MIT/X11",
}

dependencies = {
   "lua >= 5.0",
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

