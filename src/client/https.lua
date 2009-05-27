---------------------------------------------------------------------
-- SOAP client over HTTPS.
-- 
-- See Copyright notice in license.html
-- $Id: https.lua,v 1.2 2009/05/27 13:22:41 tomas Exp $
---------------------------------------------------------------------

require"soap.client"
soap.client.https = require"ssl.https"
