------------------------------------------------------------------------------
-- LuaSOAP support for service development.
-- See Copyright Notice in license.html
-- $Id:$
------------------------------------------------------------------------------

local assert, pairs, pcall, require, setmetatable, tostring, type, unpack = assert, pairs, pcall, require, setmetatable, tostring, type, unpack

local cgilua = cgilua or require"cgilua"
local soap = require"soap"
local string = require"string"
local table = require"table"


------------------------------------------------------------------------------
local M = {
	_COPYRIGHT = "Copyright (C) 2004-2015 Kepler Project",
	_DESCRIPTION = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents",
	_VERSION = "LuaSOAP 4.0 service helping functions",

	encoding = "utf-8", -- default encoding
}
M.__index = M

------------------------------------------------------------------------------
function M:xml_header ()
	return '<?xml version="1.0" encoding="'..self.encoding..'"?>\n'
end

------------------------------------------------------------------------------
function M:respond(resp, header)
	cgilua.header("Content-length", string.len(resp))
	cgilua.header("Connection", "close")
	cgilua.contentheader("text", "xml")
	if header then
		cgilua.put(header)
	end
	cgilua.put(resp)
end

------------------------------------------------------------------------------
function M:builderrorenvelope(faultcode, faultstring, extra)
	faultstring = faultstring:gsub("([<>])", { ["<"] = "&lt;", [">"] = "&gt;", })
	return soap.encode({
		entries = {
			{ tag = "faultcode", faultcode, },
			{ tag = "faultstring", faultstring, },
			extra,
		},
		method = "soap:Fault",
	})
end

------------------------------------------------------------------------------
function M:decodedata(doc)
	local namespace, elem_name, elems = soap.decode(doc)
	local func = self.methods[elem_name].method
	assert(type(func) == "function", "Unavailable method: `"..tostring(elem_name).."'")

	return namespace, func, (elems or {})
end

------------------------------------------------------------------------------
function M:callfunc(func, namespace, arg_table)
	local result = { pcall(func, namespace, arg_table) }
	local ok = result[1]
	if not ok then
		result = self:builderrorenvelope("soap:ServiceError", result[2])
	else
		table.remove(result, 1)
		if #result == 1 then
			result = result[1]
		end
	end
	return ok, result
end

---------------------------------------------------------------------
local function generate_disco()
	return self:xml_header().."<discovery></discovery>"

end

------------------------------------------------------------------------------
-- Exports methods that can be used by the server.
-- @param desc Table with the method description.
------------------------------------------------------------------------------
function M:export(desc)
	local f = desc.method
	desc.method = function (...) -- ( namespace, unpack(arguments) )
		local res = f(...)
		return soap.encode{
			namespace = self.targetNamespace,
			method = desc.response.name,
			entries = res,
		}
	end
	self.methods[desc.name] = desc
end

------------------------------------------------------------------------------
-- Handles the request received by the calling script.
-- @param postdata String with POST data from the server.
-- @param querystring String with the query string.
------------------------------------------------------------------------------
function M:handle_request(postdata, querystring)
	cgilua.seterroroutput(self.fatalerrorfunction())

	local namespace, func, arg_table
	local header
	if postdata then
		namespace, func, arg_table = self:decodedata(postdata)
		header = self:xml_header()
	else
		if querystring and querystring:lower() == "wsdl" then -- WSDL service
			func = function ()
				-- import all wsdl functions into server
				for n, m in pairs(require"soap.wsdl") do
					assert (self[n] == nil, "Module 'soap.wsdl' not allowed to override method 'soap."..n.."'")
					self[n] = m
				end
				return self:generate_wsdl ()
			end
		elseif querystring == "disco" then -- discovery service
--			func = function ()
--				return __service.disco or generate_disco()
--			end
		else
--			func = __methods["listMethods"]
--			header = self:xml_header()
		end
		arg_table = {}
	end

	local ok, result = callfunc(func, namespace, arg_table)
	respond(result, header)
end

------------------------------------------------------------------------------
-- Create a new SOAP server
-- @param server_description Table with SOAP server description and configuration.
-- @return Table with server representation.

function M.new (server)
	server.fatalerrorfunction = function (msg)
		server:respond (
			server:builderrorenvelope ("soap:ServerError", msg)
		)
    end
	return setmetatable (server, M)
end

------------------------------------------------------------------------------
return M
