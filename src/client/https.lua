------------------------------------------------------------------------------
-- SOAP client over HTTPS.
-- 
-- See Copyright notice in license.html
------------------------------------------------------------------------------

------------------------------------------------------------------------------
-- @table soap.client
-- @field https LuaSec module https.
local client = require"soap.client"
client.https = require"ssl.https"
