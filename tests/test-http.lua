-- $Id: test-http.lua,v 1.4 2009/07/22 19:02:46 tomas Exp $

local soap_client = require"soap.client"

local ns, meth, ent = soap_client.call {
  url = "http://validator.soapware.org",
  soapaction = "/validator1",
  namespace = nil,
  method = "easyStructTest",
  entries = {
    {
      tag = "stooges",
      { tag = "curly", attr = { "xsi:type", ["xsi:type"] = "xsd:int", }, -5 },
      { tag = "larry", attr = { "xsi:type", ["xsi:type"] = "xsd:int", }, 5 },
      { tag = "moe",   attr = { "xsi:type", ["xsi:type"] = "xsd:int", }, 41 },
    },
  }}

assert(tonumber(ent[2][1]) == 41)
print"Ok!"
