---------------------------------------------------------------------
-- SOAP client.
-- Default is over HTTP, but one can install other modules such as
-- client.https to provide access via HTTPS.
-- See Copyright notice in license.html
-- $Id: client.lua,v 1.3 2009/07/22 19:02:46 tomas Exp $
---------------------------------------------------------------------

local assert, tonumber, tostring, pcall = assert, tonumber, tostring, pcall
local concat = require("table").concat

local ltn12 = require("ltn12")
local socket_http = require("socket.http")
local soap = require("soap")

module("soap.client")

-- Support for SOAP over HTTP is default and only depends on LuaSocket
http = socket_http

---------------------------------------------------------------------
-- Call a remote method.
-- @param args Table with the arguments which could be:
-- url: String with the location of the server.
-- soapaction: String with the value of the SOAPAction header.
-- namespace: String with the namespace of the elements.
-- method: String with the method's name.
-- entries: Table of SOAP elements (LuaExpat's format).
-- header: Table describing the header of the SOAP-ENV (optional).
-- internal_namespace: String with the optional namespace used
--  as a prefix for the method name (default = "").
-- @return String with namespace, String with method's name and
--	Table with SOAP elements (LuaExpat's format).
---------------------------------------------------------------------
function call(args)
	local request_sink, tbody = ltn12.sink.table()
	local request_body = soap.encode(args)
	local url = {
		url = args.url,
		method = "POST",
		source = ltn12.source.string(request_body),
		sink = request_sink,
		headers = {
			["Content-Type"] = "text/xml",
			["content-length"] = tostring(request_body:len()),
			["SOAPAction"] = '"'..args.soapaction..'"',
		},
	}

	local protocol = url.url:match"^(%a+)" -- protocol's name
	local mod = assert(_M[protocol], '"'..protocol..'" protocol support not loaded. Try require"soap.client.'..protocol..'" to enable it.')
	local request = assert(mod.request, 'Could not find request function on module soap.client.'..protocol)

	local err, code, headers, status = request(url)
	local body = concat(tbody)
	assert(tonumber(code) == 200, tostring(err or code).."\n\n"..tostring(body))

	local ok, error_or_ns, method, result = pcall(soap.decode, body)
	assert(ok, tostring(error_or_ns).."\n\n"..tostring(body))

	return error_or_ns, method, result
end

