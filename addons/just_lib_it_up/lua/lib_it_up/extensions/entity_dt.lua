-- garry suck my dick

ENTITY.oldInstallDataTable = ENTITY.oldInstallDataTable or ENTITY.InstallDataTable

function ENTITY:OnDTVarChanged(...)
	--classic notify hook (uses NetworkVarNotify, buggy)
end

-- for new notify system use ent:On("DTChanged", function(self, dt_name, old_val, new_val, predicted) end)

-- if `predicted` is true, that means this was called due to local realm setting the DTVar
-- otherwise, that means it was received via the net notification system

-- predicted updates use `old` as the real, currently-set-by-the-server var
-- so setting a variable clientside multiple times in a row will keep old_val as the real unpredicted var

if SERVER then util.AddNetworkString("DTVarChangeNotify") end

if not table.KeysToValues then include("table.lua") end

local queue = {}

local sz = {
	Int = 32,
}

local typs = {
	String = 0,
	Bool = 1,
	Float = 2,
	Int = 3,
	Vector = 4,
	Angle = 5,
	Entity = 6
}

local backTyps = table.KeysToValues(typs)
local typLen = #backTyps

function ENTITY:NotifyDTVars(pvs)
	if not self:IsValid() then return end
	if not queue[self] or table.Count(queue[self]) == 0 then return end

	net.Start("DTVarChangeNotify")
		net.WriteEntity(self)
		net.WriteUInt(table.Count(queue[self]), 8)

		for k,v in pairs(queue[self]) do
			local ind, typ, val = unpack(v)
			net.WriteUInt(ind, 5)
			net.WriteUInt(typs[typ], bit.GetLen(typLen))
			net["Write" .. typ] (val, sz[typ])
		end

	net.SendPVS(self:GetPos())

	table.Empty(queue[self])
end

function ENTITY:QueueNotifyChange(ind, typ, name, old, new)
	if CLIENT then return end
	if old == new then return end --fuck off

	queue[self] = queue[self] or {}
	local me = queue[self]

	me[name] = {ind, typ, new}

	local notify = self.NotifyDTVars

	timer.Create(("%p"):format(self), 0, 1, function() notify(self) end)

end

local notifQueue = {}

local notifyDT --pre-definition, see client part

function ENTITY:InstallDataTable()
	self:oldInstallDataTable()

	local datatable = select(2, debug.getupvalue(self.CallDTVarProxies, 1))

	self._dt_data = datatable

	local dt_rev = {}
	self._dt_reverse = dt_rev

	self.CallDTVarProxies = BlankFunc

	self.DTVar = function( ent, typename, index, name )

		local GetFunc = ent[ "GetDT" .. typename ]

		local SetFunc = function(ent, slot, val)
			local old = GetFunc(ent, slot)
			if old == val then return end --fuck off

			ent:Emit("DTChanged", typename, old, val, true)
			return ent[ "SetDT" .. typename ] (ent, slot, val)
		end

		if not SetFunc or not GetFunc then
			MsgN( "Couldn't addvar " , name, " - type ", typename," is invalid!" )
			return
		end

		local type_curry = function(func)
			return function(ent, name, old, new)
				func(ent, index, typename, name, old, new)
			end
		end

		datatable[name] = {
			index = index,
			SetFunc = SetFunc,
			GetFunc = GetFunc,
			typename = typename,
			Notify = {
				type_curry(self.OnDTVarChanged),
				type_curry(self.QueueNotifyChange)
			}
		}

		dt_rev[typename .. index] = datatable[name]
		datatable[name].name = name

		return datatable[name]
	end

	local ind = self:EntIndex()

	if notifQueue[ind] and CLIENT then
		timer.Simple(0, function()
			if not IsValid(self) then return end --???
			notifyDT(self, notifQueue[ind])
		end)
	end

end


if CLIENT then

	local function callCallbacks(ent, dt, val)
		local name = dt.name
		local old = dt.GetFunc(ent, dt.index)
		if old == val then old = nil end -- :)
		ent:Emit("DTChanged", name, old, val, false)
	end

	function notifyDT(ent, all_data)

		local rev = ent._dt_reverse

		--[[
			["String"] = {
				[1] = {datatable_stuff},
				[2] = {datatable_stuff},
				...
			}
		]]

		for typ, indvals in pairs(all_data) do

			for ind, val in pairs(indvals) do
				if not rev[typ .. ind] then continue end
				callCallbacks(ent, rev[typ .. ind], val)
			end
		end

	end

	net.Receive("DTVarChangeNotify", function(len)

		local entID = net.ReadUInt(16)
		local valid = true

		if not IsValid(Entity(entID)) then
			notifQueue[entID] = {}
			valid = false
		end

		local amt = net.ReadUInt(8)

		local dat = {}

		for i=1, amt do
			local ind = net.ReadUInt(5)
			local id = net.ReadUInt(bit.GetLen(typLen))
			local typ = backTyps[id]

			local val = net["Read" .. typ] (sz[typ])

			dat[typ] = dat[typ] or {}
			dat[typ][ind] = val
		end

		local ent = Entity(entID)

		if valid then
			notifyDT(ent, dat)
		else
			notifQueue[entID] = dat
		end

	end)
end