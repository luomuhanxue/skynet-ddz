local skynet = require "skynet"
require "skynet.manager"
local socket = require "socket"

local students = {}

local questions = {}

local CMD = {}

local student_fds = {}

local FristID

function CMD.createUser(fd,info)
	FristID = info
	student_fds[info] = fd
	local student_info={seeds={}}

	--students[info]={}
	local sfile = io.open(string.format("students/%s",info),"w")
	local file_data= sfile:read "*a"
	if file_data and #file_data > 0 then
		student_info.seeds[1] = tonumber(file_data)
	else
		student_info.seeds[1]=(os.time() - skynet.starttime() + skynet.now())%1000
		sfile:write(student_info.seeds[1])
	end
	sfile:close()
	students[info]=student_info
	socket.write(fd,string.pack(">s2","\001Welcome to lua exam!"))
	return "Welcome to lua exam!"
end

local questions_flag = {}

local function getRandom(idx)
	local range
	local start=0
	if idx < 5 then
		range = 16
	elseif idx == 7 then
		range,start = 3,25
	elseif idx < 8 then
		range,start = 9,16
	else
		range,start = 12,28
	end
	while true do
		local q_idx = math.random(range)
		print(q_idx)
		if not questions_flag[q_idx+start] then
			return q_idx + start
		end
	end
end

function CMD.getQuestions(idx,info)
	local seed = students[info].seeds[1]
	math.randomseed(seed)
	local r_idx = getRandom(idx)
	print(r_idx)
	questions_flag[r_idx] = true
	
	local file = io.open(string.format("students/%03d%s",idx,info),"w+")
	file:write(questions[r_idx])
	file:close()
	
	socket.write(student_fds[info],string.pack(">s2","\002"..questions[r_idx]))
	return "ok"
end


skynet.start(function()
	skynet.dispatch("lua",function(session,address,cmd,...)
		local f = CMD[cmd]		
		skynet.ret(skynet.pack(f(...)))
	end)

	for i = 1,40 do
		local temp_file = io.open(string.format("data/%03d",i),"rb")
		local file_data = temp_file:read "*a"
		temp_file:close()
		questions[i]=file_data
		print(file_data)
	end

	skynet.register "exam"
end)

