local ENTITY = FindMetaTable("Entity")

AIBases.Builder = AIBases.Builder or {}
local bld = AIBases.Builder

function ENTITY:GetAIBuilders()
	return bld.EntTracker:GetOrSet(self)
end

util.AddNetworkString("AIBuild_Add")

net.Receive("AIBuild_Add", function(len, ply)
	if not bld.Allowed(ply) then print("unallowed AIBuild", ply) return end

	local min, max = net.ReadVector(), net.ReadVector()
	local center = (min + max) / 2
	min = min - center
	max = max - center

	local woll = ents.Create("aib_wall")
	woll:SetPos(center)

	woll:Spawn()
	woll:InitPhys(min, max)
	woll:Activate()

	_brs = woll
	AIBases.Builder.AddBrick(ply, woll, AIBases.BRICK_BOX)
end)

concommand.Add("aibases_savelayout", function(ply, _, arg)
	if not bld.Allowed(ply) then return end

	local name = arg[1]
	if not arg[1] then print("give a name tard") return end

	local overwrite = arg[2]
	if file.Exists("aibases/" .. name .. ".dat", "DATA") and overwrite ~= "yes" then
		ply:ChatPrint("layout already exists: make second arg 'yes' to confirm overwrite")
		print("layout already exists: make second arg 'yes' to confirm overwrite")
		return
	end

	print("saving layout `" .. name .. "`...")

	local layout = AIBases.BaseLayout:new(name)


	local tool = GetTool("AIBaseBuild", ply)
	if not tool then print("no tool") return end

	local bents = tool:GetList()
	printf("%d bricks", table.Count(bents))

	local brs = {}

	for ent, id in pairs(bents) do
		if not IsValid(ent) then AIBases.Builder.AddBrick(ply, ent, nil) continue end

		local base = AIBases.IDToBrick(id)
		local brick = base:Build(ent)
		layout:AddBrick(brick)
		--brs[#brs + 1] = brick
	end

	local out = layout:Serialize() --

	file.CreateDir("aibases/layouts")
	file.Write("aibases/layouts/" .. name .. ".dat", out)
end)