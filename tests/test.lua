---------------------------------------------------------------------
-- LuaSOAP test file.
-- $Id: test.lua,v 1.6 2009/07/22 19:02:46 tomas Exp $
---------------------------------------------------------------------

local lom = require"lxp.lom"
local soap = require"soap"

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
		attr = { "xmlns:t", "soap:mustUnderstand",
			["xmlns:t"] = "some-URI",
			["soap:mustUnderstand"] = 1,
		},
		5,
	},
	xml = [[
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	<soap:Header>
		<t:Transaction xmlns:t="some-URI" soap:mustUnderstand="1">
			5
		</t:Transaction>
	</soap:Header>
	<soap:Body>
		<GetLastTradePrice xmlns="Some-URI">
			<symbol>DEF</symbol>
		</GetLastTradePrice>
	</soap:Body>
</soap:Envelope>]]
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
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	<soap:Body>
		<GetLastTradePriceDetailed xmlns="Some-URI">
			<Symbol>DEF</Symbol>
			<Company>DEF Corp</Company>
			<Price>34.1</Price>
		</GetLastTradePriceDetailed>
	</soap:Body>
</soap:Envelope>]]
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
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	<soap:Header>
		<t:Transaction xmlns:t="some-URI" xsi:type="xsd:int" mustUnderstand="1">
			5
		</t:Transaction>
	</soap:Header>
	<soap:Body>
		<GetLastTradePriceResponse xmlns="Some-URI">
			<Price>34.5</Price>
		</GetLastTradePriceResponse>
	</soap:Body>
</soap:Envelope>]]
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
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	<soap:Body>
		<GetLastTradePriceResponse xmlns="Some-URI">
			<PriceAndVolume>
				<LastTradePrice>
					34.5
				</LastTradePrice>
				<DayVolume>
					10000
				</DayVolume>
			</PriceAndVolume>
		</GetLastTradePriceResponse>
	</soap:Body>
</soap:Envelope>]]
},

{
	namespace = nil,
	method = "soap:Fault",
	entries = {
		{ tag = "faultcode", "soap:MustUnderstand", },
		{ tag = "faultstring", "SOAP Must Understand Error", },
	},
	xml = [[
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	<soap:Body>
		<soap:Fault>
			<faultcode>soap:MustUnderstand</faultcode>
			<faultstring>SOAP Must Understand Error</faultstring>
		</soap:Fault>
	</soap:Body>
</soap:Envelope>]]
},

{
	namespace = nil,
	method = "soap:Fault",
	entries = {
		{ tag = "faultcode", "soap:Server", },
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
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
	<soap:Body>
		<soap:Fault>
			<faultcode>soap:Server</faultcode>
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
		</soap:Fault>
	</soap:Body>
</soap:Envelope>]]
},

{
	namespace = nil,
	method = "easyStructTest",
	entries = {
		{ tag = "stooges",
			{
				tag = "curly",
				attr = { "xsi:type", ["xsi:type"] = "xsd:int", },
				-21,
			},
			{
				tag = "larry",
				attr = { "xsi:type", ["xsi:type"] = "xsd:int", },
				59,
			},
			{
				tag = "moe",
				attr = { "xsi:type", ["xsi:type"] = "xsd:int", },
				11,
			},
		},
	},
	xml = [[
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/">
	<soap:Body>
		<easyStructTest>
			<stooges>
				<curly xsi:type="xsd:int">-21</curly>
				<larry xsi:type="xsd:int">59</larry>
				<moe xsi:type="xsd:int">11</moe>
			</stooges>
		</easyStructTest>
	</soap:Body>
</soap:Envelope>]]
},

{
	namespace = nil,
	method = "StringEscapingTest",
	entries = {
		{ tag = "string", "<this was automatically escaped", },
		{ tag = "string", '"this was also &automatically &escaped"', },
		{ tag = "string", 'do not re-escape my &amp;', },
	},
	xml = [[
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:SOAP-ENC="http://schemas.xmlsoap.org/soap/encoding/">
	<soap:Body>
		<StringEscapingTest>
			<string>&lt;this was automatically escaped</string>
			<string>&quot;this was also &amp;automatically &amp;escaped&quot;</string>
			<string>do not re-escape my &amp;</string>
		</StringEscapingTest>
	</soap:Body>
</soap:Envelope>]]
},

}

for i, t in ipairs(tests) do
	local s = soap.encode (t)
	s = string.gsub (s, "[\n\r\t]", "")
	local ok, err = lom.parse ([[<?xml version="1.0" encoding="ISO-8859-1"?>]]..s)
	local ds = assert (ok, (err or '').."\non test #"..i..": "..t.method..'\n'..s)

	t.xml = string.gsub (t.xml, "[\n\r\t]", "")
	local ok, err = lom.parse ([[<?xml version="1.0" encoding="ISO-8859-1"?>]]..t.xml)
	local dx = assert (ok, (err or '').."\non test #"..i..": "..t.method..'\n'..t.xml..'\n'..s)
	assert (table.equal (ds, dx))

	local ns, met, entries = soap.decode ((t.xml:gsub("%>%s%<", "><")))
	assert (ns == t.namespace, "Wrong decoded namespace in method "..t.method..". Expected [["..tostring(t.namespace).."]] but decoded was [["..tostring(ns).."]]")
	assert (met == t.method:gsub("^[_%w]+%:([_%w]+)$", "%1"), "Wrong decoded method in method "..t.method.."; decoded was [["..tostring(met).."]]")
	assert (entries[1].tag == t.entries[1].tag)
end
print(soap._VERSION, "Ok!")
