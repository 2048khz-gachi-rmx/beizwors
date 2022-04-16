--

AIBases.Builder = AIBases.Builder or {}
local bld = AIBases.Builder


local cols = {
	[AIBases.BRICK_PROP] = Colors.Money,
	[AIBases.BRICK_BOX] = Colors.Golden,
	[AIBases.BRICK_ENEMY] = Colors.Reddish,
}

hook.Add("PostDrawTranslucentRenderables", "aibases", function()
	local me = CachedLocalPlayer()
	local meid = me:UserID()

	local props = bld.NW:Get(meid)
	if not props then return end

	for ent, typ in pairs(props) do
		if not IsValid(ent) then props[ent] = nil continue end
		local col = cols[typ] or Colors.Red
		render.DrawWireframeBox(ent:GetPos(), ent:GetAngles(), ent:OBBMins(), ent:OBBMaxs(), col, true)
	end
end)

hook.Add("PostDrawTranslucentRenderables", "ainavs", function()
	local me = CachedLocalPlayer()

	local navs = bld.NWNav:GetNetworked()
	if not navs then return end

	for id, dat in pairs(navs) do
		local col = dat.onceCol or dat.col or (dat.ply == me and Colors.Green or Colors.Red)
		render.DrawWireframeBox(vector_origin, angle_zero, dat.min, dat.max, col, true)
		hook.Run("DrawLuaNav", dat)
		dat.onceCol = nil
	end
end)

function AIBases.StartBuild()
	AREAMARK_ACTION = "AIBuildArea"
end


hook.Add("AIBuildArea", "a", function(min, max)
	print("added box:", min, max)
	net.Start("AIBuild_Add")
		net.WriteVector(min)
		net.WriteVector(max)
	net.SendToServer()
end)