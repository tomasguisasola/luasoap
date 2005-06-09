#!/usr/local/bin/lua
---------------------------------------------------------------------
-- LuaSOAP test file.
-- $Id: test.lua,v 1.4 2005/06/09 21:15:22 mascarenhas Exp $
---------------------------------------------------------------------

require"lxp.lom"
require"soap"

function table.equal (t1, t2)
	assert (type(t1) == type(t2), string.format ("%s (%s) ~= %s (%s)", type(t1),
		tostring(t1), type(t2), tostring(t2)))
	for i, v1 in pairs (t1) do
		local v2 = t2[i]
		local tv1 = type(v1)
		if tv1 == "table" then
			local ok, err = table.equal (v1, v2)
			if not ok then
				return false, err
			end
		elseif v1 ~= v2 then
			return false, string.format ("%s ~= %s", tostring(v1), tostring(v2))
		end
	end
	return true
end

local tests = {
{
	namespace = "Some-URI",
	method = "GetLastTradePrice",
	entries = { { tag = "symbol", "DEF" }, },
	header = {
		tag = "t:Transaction",
		attr = { "xmlns:t", "SOAP-ENV:mustUnderstand",
			["xmlns:t"] = "some-URI",
			["SOAP-ENV:mustUnderstand"] = 1,
		},
		5,
	},
	xml = [[
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	<SOAP-ENV:Header>
		<t:Transaction xmlns:t="some-URI" SOAP-ENV:mustUnderstand="1">
			5
		</t:Transaction>
	</SOAP-ENV:Header>
	<SOAP-ENV:Body>
		<m:GetLastTradePrice xmlns:m="Some-URI">
			<symbol>DEF</symbol>
		</m:GetLastTradePrice>
	</SOAP-ENV:Body>
</SOAP-ENV:Envelope>]]
},

{
	namespace = "Some-URI",
	method = "GetLastTradePriceDetailed",
	entries = {
		{ tag = "Symbol", "DEF" },
		{ tag = "Company", "DEF Corp" },
		{ tag = "Price", 34.1 },
	},
	xml = [[
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	<SOAP-ENV:Body>
		<m:GetLastTradePriceDetailed xmlns:m="Some-URI">
			<Symbol>DEF</Symbol>
			<Company>DEF Corp</Company>
			<Price>34.1</Price>
		</m:GetLastTradePriceDetailed>
	</SOAP-ENV:Body>
</SOAP-ENV:Envelope>]]
},

{
	namespace = "Some-URI",
	method = "GetLastTradePriceResponse",
	entries = {
		{ tag = "Price", 34.5 },
	},
	header = {
		tag = "t:Transaction",
		attr = { "xmlns:t", "xsi:type", "mustUnderstand",
			["xmlns:t"] = "some-URI",
			["xsi:type"] = "xsd:int",
			["mustUnderstand"] = 1,
		},
		5,
	},
	xml = [[
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	<SOAP-ENV:Header>
		<t:Transaction xmlns:t="some-URI" xsi:type="xsd:int" mustUnderstand="1">
			5
		</t:Transaction>
	</SOAP-ENV:Header>
	<SOAP-ENV:Body>
		<m:GetLastTradePriceResponse xmlns:m="Some-URI">
			<Price>34.5</Price>
		</m:GetLastTradePriceResponse>
	</SOAP-ENV:Body>
</SOAP-ENV:Envelope>]]
},

{
	namespace = "Some-URI",
	method = "GetLastTradePriceResponse",
	entries = {
		{
			tag = "PriceAndVolume",
			{ tag = "LastTradePrice", 34.5, },
			{ tag = "DayVolume", 10000, },
		}
	},
	xml = [[
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	<SOAP-ENV:Body>
		<m:GetLastTradePriceResponse xmlns:m="Some-URI">
			<PriceAndVolume>
				<LastTradePrice>
					34.5
				</LastTradePrice>
				<DayVolume>
					10000
				</DayVolume>
			</PriceAndVolume>
		</m:GetLastTradePriceResponse>
	</SOAP-ENV:Body>
</SOAP-ENV:Envelope>]]
},

{
	namespace = nil,
	method = "SOAP-ENV:Fault",
	entries = {
		{ tag = "faultcode", "SOAP-ENV:MustUnderstand", },
		{ tag = "faultstring", "SOAP Must Understand Error", },
	},
	xml = [[
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	<SOAP-ENV:Body>
		<SOAP-ENV:Fault>
			<faultcode>SOAP-ENV:MustUnderstand</faultcode>
			<faultstring>SOAP Must Understand Error</faultstring>
		</SOAP-ENV:Fault>
	</SOAP-ENV:Body>
</SOAP-ENV:Envelope>]]
},

{
	namespace = nil,
	method = "SOAP-ENV:Fault",
	entries = {
		{ tag = "faultcode", "SOAP-ENV:Server", },
		{ tag = "faultstring", "Server Error", },
		{
			tag = "detail",
			{
				tag = "e:myfaultdetails",
				attr = { "xmlns:e", ["xmlns:e"] = "Some-URI", },
				{ tag = "message", "My application didn't work", },
				{ tag = "errorcode", 1001, },
			},
		},
	},
	xml = [[
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
	<SOAP-ENV:Body>
		<SOAP-ENV:Fault>
			<faultcode>SOAP-ENV:Server</faultcode>
			<faultstring>Server Error</faultstring>
			<detail>
				<e:myfaultdetails xmlns:e="Some-URI">
					<message>
						My application didn't work
					</message>
					<errorcode>
						1001
					</errorcode>
				</e:myfaultdetails>
			</detail>
		</SOAP-ENV:Fault>
	</SOAP-ENV:Body>
</SOAP-ENV:Envelope>]]
},

}

for i, t in ipairs(tests) do
	local s = soap.encode (t.namespace, t.method, t.entries, t.header)
	s = string.gsub (s, "[\n\r\t]", "")
	local ds = assert (lxp.lom.parse ([[<?xml version="1.0" encoding="ISO-8859-1"?>]]..s))
	t.xml = string.gsub (t.xml, "[\n\r\t]", "")
	local dx = assert (lxp.lom.parse ([[<?xml version="1.0" encoding="ISO-8859-1"?>]]..t.xml))
	print (table.equal (ds, dx))
end
