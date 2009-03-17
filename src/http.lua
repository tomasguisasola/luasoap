---------------------------------------------------------------------
-- SOAP over HTTP.
-- See Copyright notice in license.html
-- $Id: http.lua,v 1.7 2009/03/17 20:27:45 tomas Exp $
---------------------------------------------------------------------

local assert, error, tonumber, tostring, pcall = assert, error, tonumber, tostring, pcall
local concat = require("table").concat
local ltn12 = require("ltn12")
local request = require("socket.http").request
local soap = require("soap")

module("soap.http")

---------------------------------------------------------------------
-- Call a remote method.
-- @param url String with the location of the server.
-- @param soapaction String with the SOAPAction header value.
-- @param namespace String with the namespace of the elements.
-- @param method_name String with the method's name.
-- @param entries Table of SOAP elements (LuaExpat's format).
-- @param header Table describing the header of the SOAP-ENV (optional).
-- @return String with namespace.
-- @return String with method's name.
-- @return Table with SOAP elements (LuaExpat's format).
---------------------------------------------------------------------
function call(url, soapaction, namespace, method_name, entries, headers)
	local request_sink, tbody = ltn12.sink.table()
	local request_body = soap.encode(namespace, method_name, entries, headers)
	local err, code, headers, status = request{
		url = url,
		method = "POST",
		source = ltn12.source.string(request_body),
		sink = request_sink,
		headers = {
			["Content-Type"] = "text/xml",
			["content-length"] = tostring(request_body:len()),
			["SOAPAction"] = '"'..soapaction..'"',
		},
	}
	local body = concat(tbody)
	if tonumber (code) ~= 200 then
		error (tostring(err or code).."\n\n"..tostring(body))
	end

	local ok, error_or_ns, method, result = pcall(soap.decode, body)
	assert(ok, tostring(error_or_ns).."\n\n"..tostring(body))

	return error_or_ns, method, result
end

