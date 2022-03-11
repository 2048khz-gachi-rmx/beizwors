PriorityTable = PriorityTable or Class:extend()

function PriorityTable:Initialize()
	self[1] = {} 	-- [prio] = {values}
	self[2] = {} 		-- sorted array of priority numbers existing in `prios`
end	

function PriorityTable:Add(val, prio)
	local prios, arr = self[1], self[2]

	if not prios[prio] then
		local prev = 0

		for k,v in ipairs(arr) do
			if prio > v then
				table.insert(arr, k, prio)
				print("inserted new", arr, k, prio)
				goto ins
			end
		end

		arr[#arr + 1] = prio
		print("inserted first", arr, 1, prio)
		::ins::
		prios[prio] = {val}
	else
		local t = prios[prio]
		t[#t + 1] = val
	end

	return self
end
PriorityTable.Insert = PriorityTable.Add

function PriorityTable:Remove(val)
	local prios, arr = self[1], self[2]

	-- optional: add `prio` argument for quick find

	for pkey, pnum in ipairs(arr) do
		local t = prios[pnum]
		for i=#t, 1, -1 do
			if val == v then
				if #t == 1 then
					prios[pnum] = nil
					table.remove(arr, pkey)
				else
					table.remove(t, k)
				end
				break
			end
		end
	end
end


local function stateless(tbl, ctrl)
	local prioNum, curPrio, arrPos = ctrl[1], ctrl[2], ctrl[3]

	prioNum = prioNum + 1
	local t = tbl[1][curPrio]
	if not t then
		return
	end -- ran out of prios in array

	local val = t[prioNum]
	if not val then
		-- ran out of values in prio array; go onto the next one
		ctrl[1], ctrl[2], ctrl[3] = 0, tbl[2][arrPos + 1], arrPos + 1
		return stateless(tbl, ctrl)
	end

	ctrl[1], ctrl[2], ctrl[3] = prioNum + 1, curPrio, arrPos
	ctrl[4] = ctrl[4] + 1
	return ctrl, val, ctrl[4]
end

function PriorityTable:Iter()
	local ctrl = {}
	ctrl[1], ctrl[2], ctrl[3] = 0, self[2][1], 1
	ctrl[4] = 0

	return stateless, self, ctrl
end

PriorityTable.iter = PriorityTable.Iter
PriorityTable.pairs = PriorityTable.Iter
PriorityTable.ipairs = PriorityTable.Iter