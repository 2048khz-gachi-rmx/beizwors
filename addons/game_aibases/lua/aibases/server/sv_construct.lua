--

function AIBases.ConstructNavs(navs)
	local cnavs = navmesh.GetAllNavAreas()
	local lkup = {}
	local llkup = {}
	for k,v in pairs(cnavs) do lkup[v:GetID()] = v end
	for k,v in pairs(navs) do llkup[v.id] = v end

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