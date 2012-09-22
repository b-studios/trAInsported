local ai = {}

local aiList = {}		-- holds all the ai functions/events

local aiUserData = {		--default fallbacks in case a function is not created by the User's AI script.
	init = function () print("default init") end,
	chooseDirection = function () print("No valid \"ai.chooseDirection\" function found. Using fallback.") end,
	blocked = function () print("No valid \"ai.blocked\" function found. Using fallback.") end,
	foundPassengers = function () print("Implement a function \"ai.foundPassengers\" if you want to pick up passengers!") end,
	foundDestination = function () print("Implement a function \"ai.foundDestination\" if you want to earn money!") end
}

local sandbox = require("Scripts/sandbox")

-- maximum times that the script may run (in seconds)
local MAX_LINES_LOADING = 10000
local MAX_LINES_EXECUTING = 1000

local coLoad = nil
linesUsed = 0

function newLineCountHook( maxLines )
	local startTime = love.timer.getTime()
	local time = 0
	local lines = 0
	linesUsed = 0
	return function ( event, l )
		if event == "line" then
			lines = lines + 1
			linesUsed = linesUsed + 1
			time = love.timer.getTime()
			if lines == maxLines then
				error("Taking too long, stopping. Time taken: " .. time-startTime .. "s.")
			end
		end
	end
end

local function safelyLoadAI(chunk, scriptName, sb)

	print("\tCompiling code...")
	debug.sethook(newLineCountHook(MAX_LINES_LOADING), "l")
	local func, message = loadstring(chunk, scriptName)
	debug.sethook()
	if not func then
		print("Could not load script: \n", message)
		coroutine.yield()
	end
	print("\t\tSuccess! Code lines: " .. linesUsed .. " of " .. MAX_LINES_LOADING)
	
	
	print("\tRunning code:")
	func = setfenv(func, sb)
	debug.sethook(newLineCountHook(MAX_LINES_LOADING), "l")
	local ok, message = pcall(func)
	if not ok then
		print("Could not execute script: \n", message)
		coroutine.yield()
	end
	debug.sethook()
	print("\t\tSuccess! Code lines: " .. linesUsed .. " of " .. MAX_LINES_LOADING)
end
	
function runAiFunctionCoroutine(f, ... )
--	f = setfenv(f, sandbox)
	debug.sethook(newLineCountHook(MAX_LINES_EXECUTING), "l")
--	local ok, msg = pcall(f, ...)

	local ok, msg = pcall(f, ...)
	if not ok then
		print("\tError found in your function!", msg, c)
		coroutine.yield()
	end
	debug.sethook()
		 -- throw up to next level
	-- print("\t\tSuccess! Code lines: " .. linesUsed .. " of " .. MAX_LINES_EXECUTING)
	return msg
end


function copyTable(tbl)
	local newTbl = {}
	for k, v in pairs(tbl) do
		if type(v) == "tbl" then
			newTbl[k] = copyTable(v)
		else
			newTbl[k] = v
		end
	end
	return newTbl
end

function ai.new(scriptName)
	print("Opening: " .. scriptName)
	local ok, chunk = pcall(love.filesystem.read, scriptName )
	if not ok then error("Could not open file: " .. chunk) end
	
	if chunk:byte(1) == 27 then error("Binary bytecode prohibited. Open source ftw!") end
	
	local aiID = 0
	
	for i = 1,#aiList+1,1 do
		if aiList[i] == nil then
			aiID = i
			aiList[i] =	copyTable(aiUserData)
			aiList[i].name = scriptName
			break
		end
	end
	
	--set up the ai which the user's script will have access to:
	sb = sandbox.createNew(aiID)
	sb.ai = {}
	--sb.ai = restrictAITable(aiList[aiID])
	print("first print", aiID)
	--printTable(sb)
	
	--this first coroutine compiles and runs the source code of the user's AI script:
	local crLoad = coroutine.create(safelyLoadAI)
	local ok, err = pcall(coroutine.resume, crLoad, chunk, scriptName, sb)
	if coroutine.status(crLoad) ~= "dead" then
		crLoad = nil
		error("\tCoroutine stopped prematurely: " .. aiList[aiID].name)
	end
	crLoad = nil
	print("\tAI loaded.")
	
	--aiList[aiID].init = sb.ai.init		-- if it all went right, now we can set the table.
	aiList[aiID].chooseDirection = sb.ai.chooseDirection
	aiList[aiID].blocked = sb.ai.blocked
	aiList[aiID].foundPassengers = sb.ai.foundPassengers
	aiList[aiID].foundDestination = sb.ai.foundDestination
	
	--printTable(aiList[aiID])
end

function ai.init()
	for aiID = 1, #aiList do
		--the second coroutine loads the ai.init() function in the user's AI script:
		print("Initializing AI:", aiID)
		
		print("--> ai.init")
		local crInit = coroutine.create(runAiFunctionCoroutine)
		ok, msg = coroutine.resume(crInit, aiList[aiID].init)
		if not ok then print("NEW ERROR:", msg) end
		if coroutine.status(crInit) ~= "dead" then
			crInit = nil
			print("\tCoroutine stopped prematurely: " .. aiList[aiID].name .. ".init()")
		end
		crInit = nil
	end
end












function ai.chooseDirection(train, possibleDirs)
	--print("choosing dir:", train.aiID)
	local result = nil
	if aiList[train.aiID] then
		if aiList[train.aiID].chooseDirection then
			local cr = coroutine.create(runAiFunctionCoroutine)
			
			tr = {ID=train.ID, name=train.name, x=tr.tileX, y=tr.tileY, passenger=tr.passenger}		-- don't give the original data to the ai!
			dirs = copyTable(possibleDirs)
			
			ok, result = coroutine.resume(cr, aiList[train.aiID].chooseDirection, tr, dirs)
			if not ok or coroutine.status(cr) ~= "dead" then
				print("\tCoroutine stopped prematurely: " .. aiList[train.aiID].name .. ".chooseDirection()")
			end
		end
	end
	
	--print("ai chose:", result)
	if (result == "N" and possibleDirs["N"]) or (result == "S" and possibleDirs["S"]) or (result == "E" and possibleDirs["E"]) or (result == "W" and possibleDirs["W"]) then
		return result
	else
		return nil
	end
end


function ai.blocked(train, possibleDirs, lastDir)
	local result = nil
	if aiList[train.aiID] then
		if aiList[train.aiID].blocked then
			local cr = coroutine.create(runAiFunctionCoroutine)
			
			tr = {ID=train.ID, name=train.name, x=tr.tileX, y=tr.tileY, passenger=tr.passenger}		-- don't give the original data to the ai!
			dirs = copyTable(possibleDirs)
			
			ok, result = coroutine.resume(cr, aiList[train.aiID].blocked, tr, dirs, lastDir)
			if not ok or coroutine.status(cr) ~= "dead" then
				print("\tCoroutine stopped prematurely: " .. aiList[train.aiID].name .. ".blocked()")
			end
		end
	end
	
	--print("ai chose:", result)
	if (result == "N" and possibleDirs["N"]) or (result == "S" and possibleDirs["S"]) or (result == "E" and possibleDirs["E"]) or (result == "W" and possibleDirs["W"]) then
		return result
	else
		return lastDir		-- retry the same path if there was no new path specified
	end
end

function ai.newPassenger()

end

function ai.foundPassengers(train, p)		-- called when the train enters a tile which holds passengers.
	local result = nil
	if aiList[train.aiID] then
		if aiList[train.aiID].foundPassengers then
			local cr = coroutine.create(runAiFunctionCoroutine)
			
			tr = {ID=train.ID, name=train.name, x=tr.tileX, y=tr.tileY, passenger=tr.curPassenger}		-- don't give the original data to the ai!
			local pCopy = copyTable(p)				-- don't let the ai change the original list of passengers!
			
			ok, result = coroutine.resume(cr, aiList[train.aiID].foundPassengers, tr, pCopy)
			if not ok or coroutine.status(cr) ~= "dead" then
				print("\tCoroutine stopped prematurely: " .. aiList[train.aiID].name .. ".foundPassengers()")
			end
		end
	end
	
	-- if a passenger name was returned, then try to let this passenger board the train:
	if result and not train.curPassenger then		-- ... but only if the train does not currently carry a passenger.
		for k, name in pairs(p) do
			if name == result then
				passenger.boardTrain(train, name)
				break
			end
		end
	end
end

function ai.foundDestination(train)		-- called when the train enters a field that its passenger wants to go to.
	local result = nil
	if aiList[train.aiID] then
		if aiList[train.aiID].foundDestination then
			local cr = coroutine.create(runAiFunctionCoroutine)
			
			tr = {ID=train.ID, name=train.name, x=tr.tileX, y=tr.tileY, passenger=tr.passenger}		-- don't give the original data to the ai!
			
			ok, result = coroutine.resume(cr, aiList[train.aiID].foundDestination, tr)
			if not ok or coroutine.status(cr) ~= "dead" then
				print("\tCoroutine stopped prematurely: " .. aiList[train.aiID].name .. ".foundDestination()")
			end
		end
	end
end
	
return ai
