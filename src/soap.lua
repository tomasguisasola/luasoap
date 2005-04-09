---------------------------------------------------------------------
-- LuaSoap implementation for Lua.
-- See Copyright Notice in license.html
-- $Id: soap.lua,v 1.6 2005/04/09 15:23:11 tomas Exp $
---------------------------------------------------------------------

require"lxp.lom"

local assert, ipairs, pairs, tostring, type = assert, ipairs, pairs, tostring, type
local getn, tconcat, tinsert, tremove = table.getn, table.concat, table.insert, table.remove
local format, strfind = string.format, string.find
local max = math.max
local parse = lxp.lom.parse

module (arg and arg[1])

_COPYRIGHT = "Copyright (C) 2004-2005 Kepler Project"
_DESCRIPTION = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents"
_NAME = "LuaSOAP"
_VERSION = "1.0.0"

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
		if getn (c) > 0 then
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
		contents = ""
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
	tag = "SOAP-ENV:Header",
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
	tag = "SOAP-ENV:Envelope",
	attr = { "xmlns:SOAP-ENV", "SOAP-ENV:encodingStyle",
		["xmlns:SOAP-ENV"] = "http://schemas.xmlsoap.org/soap/envelope/",
		["SOAP-ENV:encodingStyle"] = "http://schemas.xmlsoap.org/soap/encoding/",
	},
	{
		tag = "SOAP-ENV:Body",
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
-- @param header Table describing the header of the SOAP-ENV (optional).
-- @return String with SOAP-ENV element.
---------------------------------------------------------------------
function encode (namespace, method, entries, header)
	-- Cleans old header and insert a new one (if it exists).
	insert_header (envelope_template, header)
	-- Sets new body contents (and erase old content).
	local body = (envelope_template[2] and envelope_template[2][1]) or envelope_template[1][1]
	for i = 1, max (getn(body), getn(entries)) do
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
	assert (obj.tag == "SOAP-ENV:Envelope", "Not a SOAP Envelope: "..
		tostring(obj.tag))
	local namespace = find_xmlns (obj.attr)
	if obj[1].tag == "SOAP-ENV:Body" then
		obj = obj[1]
	elseif obj[2].tag == "SOAP-ENV:Body" then
		obj = obj[2]
	else
		error ("Couldn't find SOAP Body!")
	end
	local _, _, method = strfind (obj[1].tag, "^.*:(.*)$")
	local entries = {}
	for i, el in ipairs (obj[1]) do
		entries[i] = el
	end
	return namespace, method, entries
end
