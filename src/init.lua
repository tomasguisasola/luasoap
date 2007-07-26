---------------------------------------------------------------------
-- LuaSoap implementation for Lua.
-- See Copyright Notice in license.html
-- $Id: init.lua,v 1.2 2007/07/26 19:41:13 tomas Exp $
---------------------------------------------------------------------

local assert, ipairs, pairs, tostring, type = assert, ipairs, pairs, tostring, type
require"table"
local tconcat, tinsert, tremove = table.concat, table.insert, table.remove
require"string"
local strfind, format = string.find, string.format
local max = require"math".max
require"lxp.lom"
local parse = lxp.lom.parse

module (...)

_COPYRIGHT = "Copyright (C) 2004-2005 Kepler Project"
_DESCRIPTION = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents"
_VERSION = "LuaSOAP 1.0.0"

local serialize

---------------------------------------------------------------------
-- Serialize the table of attributes.
-- @param a Table with the attributes of an element.
-- @return String representation of the object.
---------------------------------------------------------------------
local function attrs (a)
	if not a then
		return "" -- no attributes
	else
		local c = {}
		if a[1] then
			for i, v in ipairs (a) do
				tinsert (c, format ("%s=%q", v, a[v]))
			end
		else
			for i, v in pairs (a) do
				tinsert (c, format ("%s=%q", i, v))
			end
		end
		if #c > 0 then
			return " "..tconcat (c, " ")
		else
			return ""
		end
	end
end

---------------------------------------------------------------------
-- Serialize the children of an object.
-- @param obj Table with the object to be serialized.
-- @return String representation of the children.
---------------------------------------------------------------------
local function contents (obj)
	if not obj[1] then
		return ""
	else
		local c = {}
		for i, v in ipairs (obj) do
			c[i] = serialize (v)
		end
		return tconcat (c)
	end
end

---------------------------------------------------------------------
-- Serialize an object.
-- @param obj Table with the object to be serialized.
-- @return String with representation of the object.
---------------------------------------------------------------------
serialize = function (obj)
	local tt = type(obj)
	if tt == "string" or tt == "number" then
		return obj
	elseif tt == "table" then
		local t = obj.tag
		assert (t, "Invalid table format (no `tag' field)")
		return format ("<%s%s>%s</%s>", t, attrs(obj.attr), contents(obj), t)
	else
		return ""
	end
end

---------------------------------------------------------------------
-- @param attr Table of object's attributes.
-- @return String with the value of the namespace ("xmlns") field.
---------------------------------------------------------------------
local function find_xmlns (attr)
	for a, v in pairs (attr) do
		if strfind (a, "xmlns", 1, 1) then
			return v
		end
	end
end

---------------------------------------------------------------------
-- Add header element (if it exists) to object.
-- Cleans old header element anyway.
---------------------------------------------------------------------
local header_template = {
	tag = "soap:Header",
}
local function insert_header (obj, header)
	-- removes old header
	if obj[2] then
		tremove (obj, 1)
	end
	if header then
		header_template[1] = header
		tinsert (obj, 1, header_template)
	end
end

local envelope_template = {
	tag = "soap:Envelope",
	attr = { "xmlns:soap", "soap:encodingStyle", "xmlns:xsi", "xmlns:xsd",
		["xmlns:soap"] = "http://schemas.xmlsoap.org/soap/envelope/",
		["soap:encodingStyle"] = "http://schemas.xmlsoap.org/soap/encoding/",
		["xmlns:xsi"] = "http://www.w3.org/2001/XMLSchema-instance",
		["xmlns:xsd"] = "http://www.w3.org/2001/XMLSchema",
	},
	{
		tag = "soap:Body",
		[1] = {
			tag = nil, -- must be filled
			attr = {}, -- must be filled
		},
	}
}

---------------------------------------------------------------------
-- Converts a LuaExpat table into a SOAP message.
-- @param namespace String with the namespace of the elements.
-- @param method String with the method's name.
-- @param entries Table of SOAP elements (LuaExpat's format).
-- @param header Table describing the header of the SOAP envelope (optional).
-- @return String with SOAP envelope element.
---------------------------------------------------------------------
function encode (namespace, method, entries, header)
	-- Cleans old header and insert a new one (if it exists).
	insert_header (envelope_template, header)
	-- Sets new body contents (and erase old content).
	local body = (envelope_template[2] and envelope_template[2][1]) or envelope_template[1][1]
	for i = 1, max (#body, #entries) do
		body[i] = entries[i]
	end
	-- Sets method (actually, the table's tag) and namespace.
	body.tag = (namespace and "m:" or "")..method
	body.attr["xmlns:m"] = namespace
	return serialize (envelope_template)
end

---------------------------------------------------------------------
-- Converts a SOAP message into Lua objects.
-- @param doc String with SOAP document.
-- @return String with namespace, String with method's name and
--	Table with SOAP elements (LuaExpat's format).
---------------------------------------------------------------------
function decode (doc)
	local obj = assert (parse (doc))
	assert (obj.tag:match"%:([^:]*)$" == "Envelope",
		"Not a SOAP Envelope: "..tostring(obj.tag))
	local namespace = find_xmlns (obj.attr)
	local params
	if obj[1].tag == "SOAP-ENV:Body" then
		params = obj[1][1]
	elseif obj[2].tag == "SOAP-ENV:Body" then
		params = obj[2][1]
	else
		error ("Couldn't find SOAP Body!")
	end
	local method = params.tag:match"%:([^:]*)$" or params.tag
	local entries = {}
	for i, el in ipairs (params) do
		entries[i] = el
	end
	return namespace, method, entries
end
