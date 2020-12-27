local skynet = require "skynet"
local socket = require "skynet.socket"
local netpack = require "skynet.netpack" --使用netpack



local WATCHDOG
local host
local send_request

local CMD = {}
local REQUEST = {}
local client_fd
local gameRoom

local roomId         --用户进行游戏的房间Id,如果是nil表示当前用户未处于游戏状态

local MSG = {}
--对应每个类型的消息处理函数
function MSG.B(msg)
	--skynet.error("MSG.B",msg)
	skynet.call(gameRoom,"lua","B",msg)
end

function MSG.R(msg)
	roomId = tostring(skynet.call(gameRoom,"lua","R"))
	local sendMsg 
	local size
	sendMsg,size = netpack.pack("RI"..roomId)
	local msgF = netpack.tostring(sendMsg,size)
	socket.write(client_fd,msgF)
end

function MSG.G(msg)
	skynet.error("roomId",roomId)
	skynet.call(gameRoom,"lua","G",roomId,msg)
end

function MSG.P(msg)
	skynet.call(gameRoom,"lua","P",msg)
end

function MSG.N(msg)
	skynet.call(gameRoom,"lua","N",msg)
end

function MSG.V(msg)
	skynet.call(gameRoom,"lua","V",roomId,msg)
end



function CMD.start(conf)
		local fd = conf.client
		local gate = conf.gate
		gameRoom = conf.gameroom
		WATCHDOG = conf.watchdog

		--skynet.fork(function()
				--while true do
						--socket.write(client_fd, "heartbeat")
						--skynet.sleep(500)
				--end
		--end)

		client_fd = fd
		skynet.call(gate, "lua", "forward", fd)
end

function CMD.getmsg(fd,msg,sz)
		msg = netpack.tostring(msg, sz)
		local msgType = string.sub(msg,1,1)
		local msgContext = ""
		if sz > 1 then
			msgContext = string.sub(msg,2,string.len(msg))
		end 
		--解析收到的消息,进行相应的处理
		
		local f = MSG[msgType]
		f(msgContext)
end
--[[
--获得到的手牌
function CMD.poke(msg)
	local sendMsg 
	local size

	sendMsg,size = netpack.pack("P"..msg)
	local msgF = netpack.tostring(sendMsg,size)
	
	socket.write(client_fd,msgF)
end

--获得到的底牌
function CMD.hole(msg)
	local sendMsg 
	local size

	sendMsg,size = netpack.pack("H"..msg)
	local msgF = netpack.tostring(sendMsg,size)
	
	socket.write(client_fd,msgF)
end

--获得到出牌权
function CMD.take(msg)
	local sendMsg 
	local size

	sendMsg,size = netpack.pack("T"..msg)
	local msgF = netpack.tostring(sendMsg,size)
	
	socket.write(client_fd,msgF)
end]]--

function CMD.send(msg)
	socket.write(client_fd,msg)
end

function CMD.disconnect()
		skynet.exit()
end

skynet.start(function()
		skynet.dispatch("lua", function(_,_, command, ...)
				local f = CMD[command]
				skynet.ret(skynet.pack(f(...)))
		end)
end)
