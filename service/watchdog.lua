local skynet = require "skynet"
local socket = require "skynet.socket"
local netpack = require "skynet.netpack"

local CMD = {}
local SOCKET = {}
local gate
local agent = {}
local gameRoom

local MSG = {}

local mydb

function SOCKET.open(fd, addr)
	skynet.error("New client from : " .. addr)
	--agent[fd] = skynet.newservice("agent")
	--skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
skynet.call(gate, "lua", "login", fd)
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect")
	end
end

function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.warning(fd, size)
	-- size K bytes havn't send out in fd
	print("socket warning", fd, size)
end

function SOCKET.data(fd, msg)

	local msgType = string.sub(msg,1,1)
	local msgContext = string.sub(msg,2,string.len(msg))

	local f = MSG[msgType]
	f(fd,msgContext)							--执行登录成功的处理函数,可能没必要单独写一个函数
end

function CMD.start(conf)
	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end

--用于解析消息的函数,对不同类型的消息进行不同的处理

function MSG.L(fd,msg)
	local id = string.sub(msg,1,string.find(msg,"|",1)-1)
	local pwd = string.sub(msg,string.find(msg,"|",1)+1,string.len(msg))

	if skynet.call(mydb, "lua", "login",id,pwd) == true then
		agent[fd] = skynet.newservice("agent")
		skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self(),gameroom = gameRoom })
	local sendMsg
	local size
	sendMsg,size = netpack.pack("L!")
	local msgF = netpack.tostring(sendMsg,size)
	skynet.error("netpack.pack:",string.byte(msgF,1,4))
	socket.write(fd,msgF)					--登录成功,应当将一些用户信息发送至客户端
	else 
		socket.write(fd,"L?")      --用户帐号或密码错误
	end
end


skynet.start(function()
	mydb = skynet.newservice("mydb")
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	gate = skynet.newservice("mygate")
	gameRoom = skynet.newservice("gameroom")
end)
