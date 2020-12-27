local skynet = require "skynet"
local mysql = require "skynet.db.mysql"

local user = {}


local function dump(res)
		local pwd
		local id
		if type(res) == "table" then
			for k,v in pairs(res) do
				if type(v) == "table" then
					dump(v)
				else
					if k == "id" then
						id = v
					else
						pwd = v
					end
					if id ~= nil then
						user[id] = pwd
					end
					if user[id] ~= nil then
						skynet.error(id,"....",user[id])
						id = nil
						pwd = nil
					end
				end
			end
		end
end

local CMD = {}

function CMD.disconnect()
		skynet.error("disconnect")
		db:disconnect()
end

function CMD.login(id,pwd)
		if user[id] == pwd then
			return true
		end

		return false
end

skynet.start(function()

		skynet.dispatch("lua", function(_,_, command, ...)
				local f = CMD[command]
				skynet.ret(skynet.pack(f(...)))
		end)

		local function on_connect(db)
				skynet.error("on_connect")
		end
				db = mysql.connect({
				host = "127.0.0.1",
				port = 3306,
				database = "mypoker",
				user = "root",
				password = "123456",
				max_packet_size = 1024*1024,
				on_connect = on_connect
})
		if not db then
				skynet.error("failed to connect")
		else
			skynet.error("success connect to mysql server")
		end

		local res = db:query("select *from user")
		dump(res)
		

end)
