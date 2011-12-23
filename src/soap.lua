---------------------------------------------------------------------
-- LuaSoap implementation for Lua.
-- See Copyright Notice in license.html
-- $Id: soap.lua,v 1.9 2009/07/22 19:02:46 tomas Exp $
---------------------------------------------------------------------

local assert, ipairs, pairs, tonumber, tostring, type = assert, ipairs, pairs, tonumber, tostring, type
local table = require"table"
local tconcat, tinsert, tremove = table.concat, table.insert, table.remove
local string = require"string"
local strfind, format = string.find, string.format
local max = require"math".max
local lom = require"lxp.lom"
local parse = lom.parse


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
-- Escape xml escape characters in a string
-- @param text String to escape characters in.
-- @return String with escape characters replaced with escape codes.
---------------------------------------------------------------------
function escape(text)
	local escaped_text = text:gsub('&', '&amp;')
	escaped_text = escaped_text:gsub("'", '&apos;')
	escaped_text = escaped_text:gsub('"', '&quot;')
	escaped_text = escaped_text:gsub('>', '&gt;')
	escaped_text = escaped_text:gsub('<', '&lt;')
	
	return escaped_text
end

---------------------------------------------------------------------
-- Unescape xml unescape characters in a string
-- @param text String to unescape characters in.
-- @return String with escape codes replaced with escape characters.
---------------------------------------------------------------------
function unescape(text)
	local unescaped_text = text:gsub('&amp;', '&')
	unescaped_text = unescaped_text:gsub('&apos;', "'")
	unescaped_text = unescaped_text:gsub('&quot;', '"')
	unescaped_text = unescaped_text:gsub('&gt;', '>')
	unescaped_text = unescaped_text:gsub('&lt;', '<')
		
	return unescaped_text
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
	if tt == "string" then
		obj = unescape(obj)
		obj = escape(obj)
		return obj
	elseif tt == "number" then
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
		["xmlns:soap"] = nil, -- to be filled
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
local xmlns_soap = "http://schemas.xmlsoap.org/soap/envelope/"
local xmlns_soap12 = "http://www.w3.org/2003/05/soap-envelope"

---------------------------------------------------------------------
-- Converts a LuaExpat table into a SOAP message.
-- @param args Table with the arguments, which could be:
-- namespace: String with the namespace of the elements.
-- method: String with the method's name;
-- entries: Table of SOAP elements (LuaExpat's format);
-- header: Table describing the header of the SOAP envelope (optional);
-- internal_namespace: String with the optional namespace used
--	as a prefix for the method name (default = "");
-- soapversion: Number of SOAP version (default = 1.1);
-- @return String with SOAP envelope element.
---------------------------------------------------------------------
local function encode (args)
	if tonumber(args.soapversion) == 1.2 then
		envelope_template.attr["xmlns:soap"] = xmlns_soap12
	else
		envelope_template.attr["xmlns:soap"] = xmlns_soap
	end
	local xmlns = "xmlns"
	if args.internal_namespace then
		xmlns = xmlns..":"..args.internal_namespace
		args.method = args.internal_namespace..":"..args.method
	end
	-- Cleans old header and insert a new one (if it exists).
	insert_header (envelope_template, args.header)
	-- Sets new body contents (and erase old content).
	local body = (envelope_template[2] and envelope_template[2][1]) or envelope_template[1][1]
	for i = 1, max (#body, #args.entries) do
		body[i] = args.entries[i]
	end
	-- Sets method (actually, the table's tag) and namespace.
	body.tag = args.method
	body.attr[xmlns] = args.namespace
	return serialize (envelope_template)
end

--
-- Find the first child with a tag.
-- Usefull to ignore white spaces.
-- @param obj Table with XML elements (LOM structure).
-- return Table (LOM structure) of the first child.
local function find_first_child(obj)
    for _,o in ipairs(obj) do
        if type(o) == "table" and obj.tag then
            return o
        end
    end
end

---------------------------------------------------------------------
-- Converts a SOAP message into Lua objects.
-- @param doc String with SOAP document.
-- @return String with namespace, String with method's name and
--	Table with SOAP elements (LuaExpat's format).
---------------------------------------------------------------------
local function decode (doc)
	local obj = assert (parse (doc))
	local ns = obj.tag:match ("^(.-):")
	assert (obj.tag == ns..":Envelope", "Not a SOAP Envelope: "..
		tostring(obj.tag))
	local namespace = find_xmlns (obj.attr)
	local o = find_first_child(obj)
	if o.tag == ns..":Body" or o.tag == "SOAP-ENV:Body" then
		obj = find_first_child(o)
	else
		error ("Couldn't find SOAP Body!")
	end
	local method = obj.tag:match ("%:([^:]*)$") or obj.tag

	local entries = {}
	for i, el in ipairs (obj) do
		entries[i] = el
	end
	return namespace, method, entries
end

---------------------------------------------------------------------
return {
	_COPYRIGHT = "Copyright (C) 2004-2011 Kepler Project",
	_DESCRIPTION = "LuaSOAP provides a very simple API that convert Lua tables to and from XML documents",
	_VERSION = "LuaSOAP 2.1.1",

	decode = decode,
	encode = encode,
}
