local sandbox = {}
--[[
function restrictAITable(table)
   return setmetatable({}, {
     __index = table,
     __newindex = function(t, key, value)
     	if (key == "init" or key == "chooseDirection" or key == "blocked" or key == "foundPassengers" or key == "foundDestination") then
     		if type(value) == "function" then
	     		rawset(t, key, value )
	     	else
	     		error("ai." .. key .. " may only hold a function value!")
	     	end
     	else
			error("Restricted access to table. Can't add: '" .. key .. "' (" .. type(value) .. ")")
		end
	end,
     __metatable = false
   });
end
]]--
local function safeprint(...)
	str = "\t["
	for k, v in ipairs(arg) do
		if not v then print("trying to print nil value!")
		else
			str = str .. "\t".. tostring(v)
		end
	end
	str = str .. "\t]"
	print(str)
end


function sandbox.createNew(aiID)
	sb = {}
	sb.pairs = pairs
	sb.ipairs = ipairs
	sb.table = table
	sb.type = type
	
	sb.print = safeprint
	sb.error = error
	sb.pcall = pcall

	sb.random = math.random
	sb.dropPassenger = passenger.leaveTrain(aiID)
	return sb
end

return sandbox
