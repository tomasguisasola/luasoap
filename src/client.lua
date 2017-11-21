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
local soap = require("soap")


local M = {
	_COPYRIGHT = "Copyright (C) 2004-2013 Kepler Project",
	_DESCRIPTION = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents",
	_VERSION = "LuaSOAP 3.0 client",

}

local xml_header_template = '<?xml version="1.0"?>'

local mandatory_soapaction = "Field `soapaction' is mandatory for SOAP 1.1 (or you can force SOAP version with `soapversion' field)"
local mandatory_url = "Field `url' is mandatory"
local invalid_args = "Supported SOAP versions: 1.1 and 1.2.  The presence of soapaction field is mandatory for SOAP version 1.1.\nsoapversion, soapaction = "

local suggested_layers = {
	http = "socket.http",
	https = "ssl.https",
}

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
-- auth: String with desired authentication method (optional).
-- soapversion: Number with SOAP version (default = 1.1).
-- @return String with namespace, String with method's name and
--	Table with SOAP elements (LuaExpat's format).
---------------------------------------------------------------------
function M.call(args)
        local soap_action, content_type_header
        if args.auth == "digest" then
                M.http = require "http-digest"
        else
                M.http = require "socket.http"
        end
	if (not args.soapversion) or tonumber(args.soapversion) == 1.1 then
		soap_action = '"'..assert(args.soapaction, mandatory_soapaction)..'"'
		content_type_header = "text/xml"
	elseif tonumber(args.soapversion) == 1.2 then
		soap_action = nil
		content_type_header = "application/soap+xml"
	else
		assert(false, invalid_args..tostring(args.soapversion)..", "..tostring(args.soapaction))
	end

	local xml_header = xml_header_template
	if args.encoding then
		xml_header = xml_header:gsub('"%?>', '" encoding="'..args.encoding..'"?>')
	end
	local request_body = xml_header..soap.encode(args)
	local request_sink, tbody = ltn12.sink.table()
	local headers = {
		["Content-Type"] = content_type_header,
		["content-length"] = tostring(request_body:len()),
		["SOAPAction"] = soap_action,
	}
	if args.headers then
		for h, v in pairs (args.headers) do
			headers[h] = v
		end
	end
	local url = {
		url = assert(args.url, mandatory_url),
		method = "POST",
		source = ltn12.source.string(request_body),
		sink = request_sink,
		headers = headers,
	}

	local protocol = url.url:match"^(%a+)" -- protocol's name
	local mod = assert(M[protocol], '"'..protocol..'" protocol support unavailable. Try soap.client.'..protocol..' = require"'..suggested_layers[protocol]..'" to enable it.')
	local request = assert(mod.request, 'Could not find request function on module soap.client.'..protocol)

	local one_or_nil, status_code, headers, receive_status = request(url)
        local body
        if args.auth == "digest" then
                body = concat(tbody,"", 2)
        else
	        body = concat(tbody)
        end
	--assert(tonumber(status_code) == 200, "Error on request: "..tostring(one_or_nil or status_code).."\n\n"..tostring(body))
	--if tonumber(status_code) ~= 200 then
	if one_or_nil == nil then
		local error_msg = "Error on response: "..tostring(status_code).."\n\n"..tostring(body)
		local extra_info = {
			http_status_code = status_code,
			http_response_headers = headers,
			receive_status = receive_status,
			body = body,
		}
		return nil, error_msg, extra_info
	end

	local ok, namespace, method, result = pcall(soap.decode, body)
	--assert(ok, "Error while decoding: "..tostring(namespace).."\n\n"..tostring(body))
	if not ok then
		local error_msg = "Error while decoding: "..tostring(namespace).."\n\n"..tostring(body)
		local extra_info = {
			http_status_code = status_code,
			http_response_headers = headers,
			receive_status = receive_status,
			body = body,
			decoding_error = namespace, -- this is pcall's error
			decode_method = method,
			result = result,
		}
		return nil, error_msg, extra_info
	end

	return namespace, method, result
end

---------------------------------------------------------------------
return M
