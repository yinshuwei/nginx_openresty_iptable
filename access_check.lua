local function log(...)
	ngx.log(ngx.ERR, ...)
end

local function is_ok(ip, forwarded_for)
	if forwarded_for then
		string.gsub(forwarded_for, "[^,]+", function(w) ip=w end )
	end
	ip,_ = string.gsub(ip," ","")

	local redis = require "resty.redis"
	local red = redis:new()	
	red:set_timeout(1000)
	local ok, err = red:connect("192.168.93.130", 6379)
	if not ok then
		log("failed to connect: ", err)
		return false
	end

	local res, err = red:auth("freshfresh_game")
	if not res then
		log("failed to authenticate: ", err)
		return false
	end

	local key = "ip:"..ip
	local ip_result, _ = red: incr(key)
	if ip_result<5 then
		local res, err = red:expire(key, 10)
	end
	if ip_result<10 then
		return true
	end
	return false
end

if not is_ok(ngx.var.remote_addr,ngx.var.http_x_forwarded_for) then
	ngx.exit(ngx.HTTP_BAD_REQUEST)
	return
end