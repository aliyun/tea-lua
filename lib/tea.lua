local http = require("socket.http")
local https = require("ssl.https")
local ltn12 = require("ltn12")

local enableDebug = os.getenv('DEBUG') == "tea"

local function debuglog(str)
  if enableDebug then
    print(str)
  end
end

-- Encodes a character as a percent encoded string
local function char_to_pchar(c)
	return string.format("%%%02X", c:byte(1,1))
end

-- encodeURIComponent escapes all characters except the following: alphabetic, decimal digits, - _ . ! ~ * ' ( )
local function encodeURIComponent(str)
	return string.gsub(str, "[^%w%-_%.%!%~%*%'%(%)]", char_to_pchar)
end

local module = {}

function module.merge(...)
  local t = {}
  for _, v in ipairs{...} do
    for key, param in pairs(v) do
      t[key] = param
    end
  end
  return t
end

function module.dump(t)
  print("{")
  if #t == 1 then
    print("no keys")
  end

  for key, value in pairs(t) do
    if type(value) == "table" then
      print("  " .. key .. ": table")
      module.dump(value)
    elseif type(value) == "function" then
      print("  " .. key .. ": function")
    else
      print("  " .. key .. ": " .. value)
    end
  end
  print("}")
end

local function factor3(condition, a, b)
  if condition then
    return a
  else
    return b
  end
end

function module.doRequest(request)
  -- module.dump(request)
  -- Requests information about a document, without downloading it.
  -- Useful, for example, if you want to display a download gauge and need
  -- to know the size of the document in advance
  local protocol = string.lower(request.protocol or "http")
  local port = request.port
  if not port then
    port = factor3(protocol == "https", "443", "80")
  end

  local engine = factor3(protocol == "https", https, http)

  local pathname = request.pathname
  local domain = request.headers.host
  local url = protocol .. "://" .. domain .. ":" .. port .. pathname

  local list = {}
  for key, value in pairs(request.query) do
    list[#list + 1] = key .. "=" .. encodeURIComponent(value)
  end
  local querystring = table.concat(list, "&")

  if string.len(querystring) > 0 then
    url = url .. "?" .. querystring
  end

  local responseBody = {}
  debuglog("> " .. request.method .. " " .. url .. " HTTP/1.1")
  for key, value in pairs(request.headers) do
    debuglog("> " .. key .. ": " .. value)
  end
  debuglog(">")

  local _, c, h, _ = engine.request {
    method = request.method,
    url = url,
    headers = request.headers,
    sink = ltn12.sink.table(responseBody)
  }

  -- r is 1, c is 200, and h would return the following headers:
  -- h = {
  --   date = "Tue, 18 Sep 2001 20:42:21 GMT",
  --   server = "Apache/1.3.12 (Unix)  (Red Hat/Linux)",
  --   ["last-modified"] = "Wed, 05 Sep 2001 06:11:20 GMT",
  --   ["content-length"] = 15652,
  --   ["connection"] = "close",
  --   ["content-Type"] = "text/html"
  -- }

  debuglog("< HTTP/1.1 " .. c .. " ")
  for key, value in pairs(h) do
    debuglog("< " .. key .. ": " .. value)
  end
  debuglog("< ")

  return {
    statusCode = c,
    headers = h,
    body = table.concat(responseBody)
  }
end

function module.newError(obj)
  local err = {}
  err.code = obj.code
  err.message = obj.message;
  err.stack = debug.traceback();
  return err
end

function module.allowRetry(retry, retryTimes)
  if retryTimes == 0 then
    return true
  end

  local retryable = retry["retryable"]
  if not retryable then
    return false
  end

  local maxAttempts = retry["maxAttempts"]
  return retryTimes < maxAttempts
end

function module.getBackoffTime(backoff)
  local policy = backoff["policy"]
  if policy == "no" then
    return 0
  end

  local period = backoff["period"] or 0
  return period
end

return module
