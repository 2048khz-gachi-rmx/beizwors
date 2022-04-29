RTPool = RTPool or Emitter:callable()

local entList = RTPool._EntList or muldim:new()
RTPool._EntList = entList

local frmt = function(...)
	return table.concat({...}, ":")
end

function RTPool:Initialize(id)
	if not isstring(id) then errorf("bad argument #1 to RTPool:Initialize() (expected string, got %s)", type(id)) end

	self.Name = name
	self.Max = 10

	self._RTW = 512
	self._RTH = 512

	self.ID = id

	self.Pool = {}	-- [seqID] = {rt, mat}
	self.LockedRTs = {}
	self.IDs = {}
end

function RTPool:AddEntity(ent)
	if not IsEntity(ent) then errorf("bad argument #1 to RTPool:AddEntity() (expected entity, got %s)", type(ent)) end

	entList:Set(true, ent, self)
end

function RTPool:GetEntity(ent)
	self:AddEntity(ent)
	return self:Get(ent)
end

function RTPool:FreeEntity(ent)
	self:Free(ent)
end

function RTPool:SetSize(w, h)
	self._RTW = w
	self._RTH = h
end

-- todo: test this via +mat_texture_size
function RTPool:GetByteSize()
	return self:GetWide() * self:GetTall() * 4 * #self.Pool
end

function RTPool:GetSize()
	return self._RTW, self._RTH
end

function RTPool:GetWide()
	return self._RTW
end

function RTPool:GetTall()
	return self._RTH
end

function RTPool:_CreateRT(num)
	local szFlag = (self:GetWide() > ScrW() or self:GetTall() > ScrH()) and (RT_SIZE_OFFSCREEN or 5) or (RT_SIZE_DEFAULT or 1)
	local rt = GetRenderTargetEx(frmt("RTPool", self.ID, num), self:GetWide(), self:GetTall(),
								szFlag, MATERIAL_RT_DEPTH_SEPARATE, 2 + 1048576, 0, -1)
																-- eheheheheheh

	return rt
end

function RTPool:_CreateMat(num, rt)

	local mat = CreateMaterial( frmt("RTPool", self.ID, num), "UnlitGeneric", {
		["$basetexture"] = rt:GetName(),

		["$vertexcolor"] = 1,
		["$vertexalpha"] = 1,

		["$translucent"] = 1,
	} )

	return mat
end

function RTPool:Get(id)
	local num = self.IDs[id]

	if not num then
		num = table.Count(self.IDs) + 1

		if num > self.Max then
			return false
		end

		self.IDs[id] = num
	end

	local pool = self.Pool[num]
	local rt, mat

	if not pool then
		rt = self:_CreateRT(num)
		mat = self:_CreateMat(num, rt)
		self.Pool[num] = {rt, mat}
		pool = self.Pool[num]
	end

	rt = pool[1]
	mat = pool[2]

	return rt, mat
end

function RTPool:Free(id)

end

function RTPool:Lock(id)

end

hook.Add("EntityActuallyRemoved", "RTPool", function(ent)
	local pools = entList[ent]
	if not pools then return end

	for pool, _ in pairs(pools) do
		if pool:Emit("ShouldFree", ent, true) == false then continue end

		pool:FreeEntity(ent)
	end

	entList[ent] = nil
end)

hook.Add("NotifyShouldTransmit", "RTPool", function(ent, new)
	if not entList[ent] or new then return end

	local pools = entList[ent]

	for pool, _ in pairs(pools) do
		if pool:Emit("ShouldFree", ent) == false then continue end

		pool:FreeEntity(ent)
	end
end)