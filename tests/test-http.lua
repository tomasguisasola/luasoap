#!/usr/local/bin/lua50
-- $Id: test-http.lua,v 1.3 2005/07/05 16:34:21 tomas Exp $

function table._tostring (tab, indent, spacing)
	local s = {}
	spacing = spacing or ""
	indent = indent or "\t"
    table.insert (s, "{\n")
    for nome, val in pairs (tab) do
        table.insert (s, spacing..indent)
        local t = type(nome)
		if t == "string" then
            table.insert (s, string.format ("[%q] = ", tostring (nome)))
		elseif t == "number" or t == "boolean" then
            table.insert (s, string.format ("[%s] = ", tostring (nome)))
        else
            table.insert (s, t)
        end
        t = type(val)
        if t == "string" or t == "number" then
            table.insert (s, string.format ("%q", val))
        elseif t == "table" then
            table.insert (s, table._tostring (val, indent, spacing..indent))
        else
            table.insert (s, t)
        end
        table.insert (s, ",\n")
    end
    table.insert (s, spacing.."}")
	return table.concat (s)
end

function table.print (tab, indent, spacing)
	io.write (table._tostring (tab, indent, spacing))
end


require"soap"
require"soap.http"

local ns, meth, ent = soap.http.call ("http://soap.4s4c.com/ssss4c/soap.asp",
	"http://simon.fell.com/calc", "doubler", {
		{
			tag = "nums",
			attr = {
				["xmlns:SOAP-ENC"] = "http://schemas.xmlsoap.org/soap/encoding/",
				["SOAP-ENC:arrayType"] = "xsd:int[5]",
			},
			{ tag = "number", 10 },
			{ tag = "number", 20 },
			{ tag = "number", 30 },
			{ tag = "number", 50 },
			{ tag = "number", 100 },
		},
	})
print(ns, meth)
table.print(ent)

local ns, meth, ent = soap.http.call ("http://localhost/cgi-bin/cgi/t/soap-server.lua",
	"http://simon.fell.com/calc", "doubler", {
		{
			tag = "nums",
			attr = {
				["xmlns:SOAP-ENC"] = "http://schemas.xmlsoap.org/soap/encoding/",
				["SOAP-ENC:arrayType"] = "xsd:int[5]",
			},
			{ tag = "number", 10 },
			{ tag = "number", 20 },
			{ tag = "number", 30 },
			{ tag = "number", 50 },
			{ tag = "number", 100 },
		},
	})
print(ns, meth)
table.print(ent)

local ns, meth, ent = soap.http.call ("http://localhost/cgi-bin/cgi/t/soap-server.lua",
	"some-URI", "listMethods", { "all" })
print(ns, meth)
table.print(ent)

local ns, meth, ent = soap.http.call ("http://localhost/cgi-bin/cgi/t/soap-server.lua",
	"some-URI", "products", { "all" })
print(ns, meth)
table.print(ent)
