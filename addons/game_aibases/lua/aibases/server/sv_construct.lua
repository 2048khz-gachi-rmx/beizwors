--

function AIBases.ConstructNavs(navs)
	local cnavs = navmesh.GetAllNavAreas()
	local lkup = {}
	local llkup = {}
	for k,v in pairs(cnavs) do lkup[v:GetID()] = v end
	for k,v in pairs(navs) do llkup[v.uid] = v end

	for k, lnav in pairs(navs) do
		lnav:Spawn(lkup)
	end

	for k, lnav in pairs(navs) do
		lnav:PostSpawn(lkup, llkup)
	end
end


function AIBases.ConstructLayout(lay)
	for k,v in pairs(lay.Bricks) do
		v:Spawn()
	end


end

function AIBases.ConstructBase(base)
	local lay = base:GetLayout()
end

local guns = {
	"cw_acr",
	"cw_mp5",
	"cw_ump45",
	"cw_mp9_official",
	"cw_mac11",
	"cw_mp7_official",
}

function AIBases.ConstructEnemies(spots)
	--[[local out = {}

	for k,v in pairs(spots) do
		local en = ents.Create("aib_bot")
		out[en] = true

		en:Give(table.Random(guns))
		en:SetPos(v)
		en:Spawn()
		en:Activate()
	end

	return out]]
end