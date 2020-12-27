local skynet = require "skynet"
local socket = require "skynet.socket"
local netpack = require "skynet.netpack" --使用netpack

math.randomseed(tostring(os.time()):reverse():sub(1, 7)) --设置随机数的种子

local ROOM = {}						--{agent{1,2,3},isReady{1,2,3},player,currentAgent}
local WATCHDOG
local GATE

local CMD = {}

function CMD.R(source)
		local sendMsg 
		local size
		local msgF
	for i = 1,100 do
		if ROOM[i].player < 3 then
			table.insert(ROOM[i].agent,source)
			ROOM[i].isReady[source] = false
			ROOM[i].player = ROOM[i].player + 1
				
			if ROOM[i].agent[2] == source then
				sendMsg,size = netpack.pack("RL"..isTrueOrFalse(i,ROOM[i].agent[1]))
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[i].agent[2],"lua","send",msgF)

				sendMsg,size = netpack.pack("RN"..isTrueOrFalse(i,ROOM[i].agent[2]))
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[i].agent[1],"lua","send",msgF)
		
			elseif ROOM[i].agent[3] == source then
				sendMsg,size = netpack.pack("RN"..isTrueOrFalse(i,ROOM[i].agent[1]))
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[i].agent[3],"lua","send",msgF)

				sendMsg,size = netpack.pack("RL"..isTrueOrFalse(i,ROOM[i].agent[2]))
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[i].agent[3],"lua","send",msgF)

				sendMsg,size = netpack.pack("RL"..isTrueOrFalse(i,ROOM[i].agent[3]))
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[i].agent[1],"lua","send",msgF)
				sendMsg,size = netpack.pack("RN"..isTrueOrFalse(i,ROOM[i].agent[3]))
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[i].agent[2],"lua","send",msgF)
			end
			
			return i
		end 
	end
end

function CMD.B(source,idStr)
	local id = tonumber(idStr)
	ROOM[id].isReady[source] = true

		local sendMsg 
		local size
		local msgF
	
	skynet.error("isReady",table_leng(ROOM[id].isReady))
	
	if ROOM[id].agent[1] == source then
		if ROOM[id].agent[2] ~= nil then
			sendMsg,size = netpack.pack("BL")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[2],"lua","send",msgF)
		end

		if ROOM[id].agent[3] ~= nil then
			sendMsg,size = netpack.pack("BN")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[3],"lua","send",msgF)
		end
	elseif ROOM[id].agent[2] == source then
		if ROOM[id].agent[1] ~= nil then
			sendMsg,size = netpack.pack("BN")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[1],"lua","send",msgF)
		end

		if ROOM[id].agent[3] ~= nil then
			sendMsg,size = netpack.pack("BL")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[3],"lua","send",msgF)
		end
	elseif ROOM[id].agent[3] == source then
		if ROOM[id].agent[1] ~= nil then
			sendMsg,size = netpack.pack("BL")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[1],"lua","send",msgF)
		end

		if ROOM[id].agent[2] ~= nil then
			sendMsg,size = netpack.pack("BN")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[2],"lua","send",msgF)
		end
	end

skynet.error(allIsReady(id))	

	if table_leng(ROOM[id].isReady) == 3 and allIsReady(id) then

----------------------下面的是进行出牌的判断---------------------------------
		local one = ""
		local two = ""
		local three = ""
		local hole = ""	
		local poke = {}
		poke[1],poke[2],poke[3],hole = pokeRandom()

		skynet.error("agent num:::::::",#ROOM[id].agent)

		for i = 1,3 do
				sendMsg,size = netpack.pack("P"..poke[i])
				local msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[i],"lua","send",msgF)
				sendMsg,size = netpack.pack("H"..hole)
				local msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[i],"lua","send",msgF)
		end
		--[[local randomNum = math.random(1,3)
		skynet.error("randomNum:",randomNum)
				ROOM[id].currentAgent = randomNum
				sendMsg,size = netpack.pack("T")
				local msgF = netpack.tostring(sendMsg,size)
		skynet.call(ROOM[id].agent[randomNum],"lua","send",msgF)]]--
---------------------------------------进行抢地主判断-------------------
		local num = math.random(1,3)
		skynet.error("randomNum:",num)
		ROOM[id].currentAgent = num
		if num == 3 then
			sendMsg,size = netpack.pack("GL")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[1],"lua","send",msgF)
			sendMsg,size = netpack.pack("GN")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[2],"lua","send",msgF)
			sendMsg,size = netpack.pack("G")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[3],"lua","send",msgF)	
		elseif num == 2 then
			sendMsg,size = netpack.pack("GL")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[3],"lua","send",msgF)
			sendMsg,size = netpack.pack("GN")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[1],"lua","send",msgF)
			sendMsg,size = netpack.pack("G")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[2],"lua","send",msgF)
		elseif num == 1 then
			sendMsg,size = netpack.pack("GL")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[2],"lua","send",msgF)
			sendMsg,size = netpack.pack("GN")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[3],"lua","send",msgF)
			sendMsg,size = netpack.pack("G")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[1],"lua","send",msgF)
		end
		

		--[[skynet.error(poke[1])
		skynet.error(poke[2])
		skynet.error(poke[3])
		skynet.error(hole)]]--
	end
end

function CMD.G(source,roomId,msg)
	local id = tonumber(roomId)
	table.insert(ROOM[id].Landlord,tonumber(msg))

	local sendMsg 
	local size
	local msgF
	local num = ROOM[id].currentAgent

skynet.error("currentAgent",num)

	if table_leng(ROOM[id].Landlord) < 3 then
		if num == 3 then
			sendMsg,size = netpack.pack("GL"..msg)
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[1],"lua","send",msgF)
			sendMsg,size = netpack.pack("GN"..msg)
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[2],"lua","send",msgF)	
		elseif num == 2 then
			sendMsg,size = netpack.pack("GL"..msg)
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[3],"lua","send",msgF)
			sendMsg,size = netpack.pack("GN"..msg)
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[1],"lua","send",msgF)
		elseif num == 1 then
			sendMsg,size = netpack.pack("GL"..msg)
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[2],"lua","send",msgF)
			sendMsg,size = netpack.pack("GN"..msg)
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[id].agent[3],"lua","send",msgF)
		end

		num = num + 1

		if num > 3 then
			ROOM[id].currentAgent = 1
			num = 1
		else 
			ROOM[id].currentAgent = num
		end
	
		sendMsg,size = netpack.pack("G")
		msgF = netpack.tostring(sendMsg,size)
		skynet.call(ROOM[id].agent[num],"lua","send",msgF)
		return
	end

	local num1 = ROOM[id].currentAgent
skynet.error("currentAgent111",num1)

	if ROOM[id].Landlord[1] == 1 then
		if ROOM[id].Landlord[2] == 0 and ROOM[id].Landlord[3] == 0 then
			if num1 == 3 then
				num1 = 1
			else			
				num1 = num1 + 1
			end
			ROOM[id].Final = num1
			ROOM[id].currentAgent = num1
			if num1 == 3 then
				sendMsg,size = netpack.pack("FL")
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[id].agent[1],"lua","send",msgF)
				sendMsg,size = netpack.pack("FN")
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[id].agent[2],"lua","send",msgF)	
			elseif num1 == 2 then
				sendMsg,size = netpack.pack("FL")
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[id].agent[3],"lua","send",msgF)
				sendMsg,size = netpack.pack("FN")
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[id].agent[1],"lua","send",msgF)
			elseif num1 == 1 then
				sendMsg,size = netpack.pack("FL")
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[id].agent[2],"lua","send",msgF)
				sendMsg,size = netpack.pack("FN")
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[id].agent[3],"lua","send",msgF)
			end
				sendMsg,size = netpack.pack("F")
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[id].agent[num1],"lua","send",msgF)
				sendMsg,size = netpack.pack("T")
				msgF = netpack.tostring(sendMsg,size)
				skynet.call(ROOM[id].agent[num1],"lua","send",msgF)
		end
	else
	
	end
end

function CMD.P(source,pokeMsg)
	local roomId = tonumber(string.sub(pokeMsg,1,2))
	local num = ROOM[roomId].currentAgent

	if string.sub(pokeMsg,3,3) == "N" then
		ROOM[roomId].noTake = ROOM[roomId].noTake + 1
	else
		ROOM[roomId].noTake = 0
	end

	local sendMsg 
	local size
	local msgF

	if num == 3 then
			sendMsg,size = netpack.pack("CL"..pokeMsg)
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[roomId].agent[1],"lua","send",msgF)
			sendMsg,size = netpack.pack("CN"..pokeMsg)
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[roomId].agent[2],"lua","send",msgF)	
	elseif num == 2 then
			sendMsg,size = netpack.pack("CL"..pokeMsg)
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[roomId].agent[3],"lua","send",msgF)
		sendMsg,size = netpack.pack("CN"..pokeMsg)
		msgF = netpack.tostring(sendMsg,size)
		skynet.call(ROOM[roomId].agent[1],"lua","send",msgF)
	elseif num == 1 then
			sendMsg,size = netpack.pack("CL"..pokeMsg)
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[roomId].agent[2],"lua","send",msgF)
		sendMsg,size = netpack.pack("CN"..pokeMsg)
		msgF = netpack.tostring(sendMsg,size)
		skynet.call(ROOM[roomId].agent[3],"lua","send",msgF)
	end

	num = num + 1

	if num > 3 then
		ROOM[roomId].currentAgent = 1
		num = 1
	else 
		ROOM[roomId].currentAgent = num
	end
	
	if ROOM[roomId].noTake == 2 then
		sendMsg,size = netpack.pack("TN")
		for i = 1,3 do
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[roomId].agent[i],"lua","send",msgF)
		end
		sendMsg,size = netpack.pack("T")
		msgF = netpack.tostring(sendMsg,size)
		skynet.call(ROOM[roomId].agent[num],"lua","send",msgF)
	else
		sendMsg,size = netpack.pack("T")
		msgF = netpack.tostring(sendMsg,size)
		skynet.call(ROOM[roomId].agent[num],"lua","send",msgF)
	end
------------转发接受到的出牌内容,还应该要有牌型和值等信息,否则其他客户端接受到需要再次解析

end

function CMD.N(source,msg)
	
end

function CMD.V(source,id,msg)
	local roomId = tonumber(id)
	skynet.error("CMD.V",roomId)
	local sendMsg 
	local size
	local msgF
	if source == ROOM[roomId].agent[ROOM[roomId].Final] then
		-------------------地主胜利----------------
		for i = 1,3 do
			sendMsg,size = netpack.pack("V1")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[roomId].agent[i],"lua","send",msgF)
		end
		skynet.error("final vectory")
	else	
		-------------------平民胜利----------------
		for i = 1,3 do
			sendMsg,size = netpack.pack("V0")
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[roomId].agent[i],"lua","send",msgF)
		end
		skynet.error("final fail")
	end

	for k,v in pairs(ROOM[roomId].isReady) do
		ROOM[roomId].isReady[k] = false
	end
end



--扑克牌的随机算法
function pokeRandom()
	local onePoke = ""
	local twoPoke = ""
	local threePoke = ""
	local holeCard = ""
	local randomNum

	for i=1,54,1 do
		while true do
			randomNum = math.random()
			if randomNum <= 0.25 then
				if #onePoke < 34 then	
					if i < 10 then
						onePoke = onePoke.."0"..tostring(i)
					else
						onePoke = onePoke..tostring(i)
					end
					break
				end
			elseif randomNum > 0.25 and randomNum <= 0.50 then
				if #twoPoke < 34 then
					if i < 10 then
						twoPoke = twoPoke.."0"..tostring(i)
					else
						twoPoke = twoPoke..tostring(i)
					end
					break
				end
			elseif randomNum > 0.50 and randomNum <= 0.75 then
				if #threePoke < 34 then
					if i < 10 then
						threePoke = threePoke.."0"..tostring(i)
					else
						threePoke = threePoke..tostring(i)
					end
					break
				end
			elseif randomNum > 0.75 and randomNum <= 0.85 then
				if #holeCard < 6 then
					if i < 10 then
						holeCard = holeCard.."0"..tostring(i)
						
					else
						holeCard = holeCard..tostring(i)
					end
					break
				end			
			end
		end
	end
	return onePoke,twoPoke,threePoke,holeCard
end

function allIsReady(id)
	for k,v in pairs(ROOM[id].isReady) do
		if v == false then
			return false
		end
	end
	return true
end

function table_leng(t)
	local leng=0
	for k, v in pairs(t) do
		leng=leng+1
	end
	return leng
end

function isTrueOrFalse(id,agent)
	if ROOM[id].isReady[agent] then
		return "1"
	else
		return "0"
	end
end

function sendToAllAgent(roomId,num,head,msg)
	local sendMsg 
	local size
	local msgF

	if num == 3 then
			sendMsg,size = netpack.pack(head.."L"..msg)
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[roomId].agent[1],"lua","send",msgF)
		sendMsg,size = netpack.pack(head.."N"..msg)
		msgF = netpack.tostring(sendMsg,size)
		skynet.call(ROOM[roomId].agent[2],"lua","send",msgF)	
	elseif num == 2 then
			sendMsg,size = netpack.pack(head.."L"..msg)
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[roomId].agent[3],"lua","send",msgF)
		sendMsg,size = netpack.pack(head.."N"..msg)
		msgF = netpack.tostring(sendMsg,size)
		skynet.call(ROOM[roomId].agent[1],"lua","send",msgF)
	elseif num == 1 then
			sendMsg,size = netpack.pack(head.."L"..msg)
			msgF = netpack.tostring(sendMsg,size)
			skynet.call(ROOM[roomId].agent[2],"lua","send",msgF)
		sendMsg,size = netpack.pack(head.."N"..msg)
		msgF = netpack.tostring(sendMsg,size)
		skynet.call(ROOM[roomId].agent[3],"lua","send",msgF)
	end
end

skynet.start(function()
		skynet.dispatch("lua", function(session,source, command, ...)
				local f = CMD[command]
				skynet.ret(skynet.pack(f(source,...)))
		end)
		for i = 1, 100 do
			ROOM[i] = {player = 0,agent = {},isReady = {},currentAgent = 0,noTake = 0,Final = 0,Landlord = {}}
		end
end)
