
rememberPassengers = {}

function ai.lol()
	a = math.random()
end

function printTable(table, lvl)
	if not type(table) == "table" then
		print("not a table!")
		return
	end
	
	lvl = lvl or 0
	for k, v in pairs(table) do
		if type(v) == "table" then
			printTable(table, lvl + 1)
		else
			str = ""
			for i = 1,lvl do
				str = str .. "\t"
			end
			print(str, k, v)
		end
	end
end


function ai.init()
	print("Initialized! Hello World!")
end


function printTable(table, lvl)
	lvl = lvl or 0
if lvl > 2 then return end
	for k, v in pairs(table) do
		if type(v) == "table" then
			--printTable(table, lvl + 1)
		else
			str = ""
			for i = 1,lvl do
				str = str .. "\t"
			end
			print(str, k, v)
		end
	end
end

function chooseSmart(train, possibleDirections)
	if train.passenger then
		print("train.passenger destination:", rememberPassengers[train.passenger].destX, rememberPassengers[train.passenger].destY)
		printTable(rememberPassengers)
		print("train.pos:", train.x, train.y)
		if possibleDirections["N"] and rememberPassengers[train.passenger].destY < train.y and random() < .9 then
			print("I think North is best")
			return "N"
		end
		if possibleDirections["S"] and rememberPassengers[train.passenger].destY > train.y and random() < .9 then
			print("I think South is best")
			return "S"
		end
		if possibleDirections["E"] and rememberPassengers[train.passenger].destX > train.x and random() < .9 then
			print("I think East is best")
			return "E"
		end
		if possibleDirections["W"] and rememberPassengers[train.passenger].destX < train.x and random() < .9 then
			print("I think West is best")
			return "W"
		end
	end
end

function chooseRandom(train, possibleDirections)
	tbl = {}
	if possibleDirections["N"] then
		tbl[#tbl+1] = "N"
	end
	if possibleDirections["S"] then
		tbl[#tbl+1] = "S"
	end
	if possibleDirections["E"] then
		tbl[#tbl+1] = "E"
	end
	if possibleDirections["W"] then
		tbl[#tbl+1] = "W"
	end
	return tbl[random(#tbl)]
end

function ai.chooseDirection(train, possibleDirections)
	-- choose a direction that makes sense.
	-- otherwise, return a random direction:
	return chooseSmart(train, possibleDirections) or chooseRandom(train, possibleDirections)
end

function ai.blocked(train, possibleDirections, lastDirection)
	return chooseSmart(train, possibleDirections) or chooseRandom(train, possibleDirections)
end

function ai.foundPassengers(train, passengers)
	if train.passenger and train.passenger:find("VIP") then return nil end
	
	for k, p in pairs(passengers) do
		print(p)
		if p:find("VIP") then
			print("found VIP!")
			if train.passenger then
				dropPassenger(train)
			end
			return p
		end
	end
	return passengers[1]
end

function ai.foundDestination(train)
	print("get off!")
	dropPassenger(train)
end

function ai.newPassenger(name, x, y, destX, destY)
	rememberPassengers[name] = {x=x,y=y,destX=destX,destY=destY}
end
