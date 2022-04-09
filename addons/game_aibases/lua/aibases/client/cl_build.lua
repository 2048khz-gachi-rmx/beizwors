--

AIBases.Builder = AIBases.Builder or {}
local bld = AIBases.Builder
bld.NW = Networkable("aibuild")

local cols = {
	[AIBases.BRICK_PROP] = Colors.Money,
	[AIBases.BRICK_BOX] = Colors.Golden,
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