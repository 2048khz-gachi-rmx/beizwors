--
local base = AIBases.AIBase or Emitter:extend()
AIBases.AIBase = base

base.LockStruct = Struct:extend({
	model = {type = TYPE_STRING, default = "models/props_borealis/door_wheel001a.mdl"},
	pos = TYPE_VECTOR,
	ang = TYPE_ANGLE,
})

ChainAccessor(base.LockStruct, "pos", "Pos")
ChainAccessor(base.LockStruct, "ang", "Angles")
ChainAccessor(base.LockStruct, "ang", "Ang")
ChainAccessor(base.LockStruct, "ang", "Angle")

function base:Initialize(name)
	name = tostring(name)
	assert(isstring(name))

	self.Layout = AIBases.BaseLayout:new(self, name)
end


ChainAccessor(base, "Layout", "Layout")


ChainAccessor(base, "Lock", "Lock")


function base:CreateLock()
	self.Lock = base.LockStruct:new()

	return self.Lock
end


function base:Finish()
	assert(self.Lock and self.Lock:Requre(), "incorrect lock")

end


local bwbase = BaseWars.Bases.Base

function bwbase:IsAI()
	return self:GetData().AIBase
end

function bwbase:MakeAI(entr, layouts)
	if entr == nil and self:GetData().AIEntrance == nil then
		errorf("`bwbase:MakeAI(entrance_name, layouts)`: missing entrance name. Give `false` to not have any.")
		return
	elseif entr then
		assertf(isstring(entr), "Entrance must be a string.")
	end

	if layouts == nil and entr ~= false and self:GetData().AILayouts == nil then
		errorf("`bwbase:MakeAI(entrance_name, layouts)`: missing layouts. Either no entrance or give both.")
		return
	elseif layouts then
		assertf(istable(layouts), "Entrance must be a table.")
		assertf(layouts[1] and layouts[2] and layouts[3], "Incorrect layouts table layout.")
	end

	self:AddData("AIBase", true, true)

	if entr ~= false then
		self:AddData("AIEntrance", entr, true)
		self:AddData("AILayouts", layouts, true)
	end

	self:SaveData()
end

function bwbase:AI_ShouldEntTakeDamage(ent, atk)
	if ent.Brick and ent.Brick.type == AIBases.BRICK_PROP then
		return ent.Brick.Breakable -- prop brick ent
	end

	if ent.PermaProps then
		local dat = ent.PersistentData

		if dat and dat.BaseBreakable then
			dmg:ScaleDamage(0.5)
			print("aibase says take")
			return true
		end

		-- permaprops in AI bases dont take dmg unless explicitly set to
		return false
	end

	return true
end