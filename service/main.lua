local skynet = require "skynet"
local httpd = require "http.httpd"
local websocket = require "websocket"
local socket = require "socket"
local sockethelper = require "http.sockethelper"
local json = require "cjson"

local agents_addr_ws = {}
local agents_ws_addr = {}
local handler = {}

function handler.on_open(ws)
    skynet.error(string.format("Client connected: %s", ws.addr))
end

function handler.on_message(ws, msg)
	skynet.error("-->",msg)
	local data = json.decode(msg)
	if not data then ws:send_text[[{"c":-1} ]] end --数据格式错误
	if data.c == 1 then
		local addr = skynet.newservice("agent")
		agents_addr_ws[addr]=ws
		agents_ws_addr[ws]=addr
		local ws_server_addr = skynet.self()
		local ret = skynet.call(addr,"lua","start",data,ws_server_addr)
		local adddddr = skynet.queryservice(true,"room_manager")
		ws:send_text(json.encode(ret))
	else
		local addr = agents_ws_addr[ws]
		local ret = skynet.call(addr,"lua","dispatch",data)
		skynet.error("<--",json.encode(ret))
		ws:send_text(json.encode(ret))
	end
end

function handler.on_error(ws, msg)
    skynet.error("Error. Client may be force closed.")
	local addr = agents_ws_addr[ws]
	agents_ws_addr[ws] = nil
	agents_addr_ws[addr] = nil
	if addr then
		skynet.call(addr,"lua","disconnect")
	end
	-- do not need close.
    -- ws:close()
end

function handler.on_close(ws, code, reason)
    skynet.error(string.format("Client disconnected: %s", ws.addr))
	local addr = agents_ws_addr[ws]
    -- do not need close.
    -- ws:close
end 

local function handle_socket(fd, addr)
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(fd), nil)
	skynet.error(code,url,method,header,body)
    if code then
        if url == "/ws" then
            local ws = websocket.new(fd, addr, header, handler)
            ws:start()
        end
    end
end

local CMD={}
function CMD.send(msg,addr)
	local ws = agents_addr_ws[addr]
	if ws then
		skynet.error(json.encode(msg))
		ws:send_text(json.encode(msg))
	end
end

function CMD.close(addr)
	local ws = agents_addr_ws[addr]
	ws:close()
end

skynet.start(function()
	local fd = assert(socket.listen("0.0.0.0",8001))
	skynet.error("fd....",fd)
    socket.start(fd , function(fd, addr)
		skynet.error("start  ",fd,addr)
        socket.start(fd)
        pcall(handle_socket, fd, addr)
    end)
	skynet.newservice("debug_console","0.0.0.0",8000)
	skynet.uniqueservice(true,"room_manager")
	skynet.dispatch("lua",function(session,source,cmd,...)
		local f = assert(CMD[cmd])
		skynet.ret(skynet.pack(f(...)))
	end)
end)
