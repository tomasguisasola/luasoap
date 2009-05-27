---------------------------------------------------------------------
-- SOAP client.
-- Default is over HTTP, but one can install other modules such as
-- client.https to provide access via HTTPS.
-- See Copyright notice in license.html
-- $Id: client.lua,v 1.2 2009/05/27 13:22:41 tomas Exp $
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
-- @param url String with the location of the server.
-- @param namespace String with the namespace of the elements.
-- @param method String with the method's name.
-- @param entries Table of SOAP elements (LuaExpat's format).
-- @param header Table describing the header of the SOAP-ENV (optional).
-- @return String with namespace, String with method's name and
--	Table with SOAP elements (LuaExpat's format).
---------------------------------------------------------------------
function call(url, namespace, method, method_name, entries, headers)
	local request_sink, tbody = ltn12.sink.table()
	local request_body = soap.encode(namespace, method_name, entries, headers)
	url = {
		url = url,
		method = "POST",
		source = ltn12.source.string(request_body),
		sink = request_sink,
		headers = {
			["Content-Type"] = "text/xml",
			["content-length"] = tostring(request_body:len()),
			["SOAPAction"] = '"'..method..'"',
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

