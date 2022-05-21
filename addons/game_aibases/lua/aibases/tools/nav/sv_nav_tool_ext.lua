local bld = AIBases.Builder
local TOOL = AIBases.MarkTool

function TOOL:StartNetwork()
	local navs = navmesh.GetAllNavAreas()

	function networkList(s, e)
		net.Start("aib_navrecv", false)
			net.WriteUInt(s, 32)
			net.WriteUInt(e, 32)

			for i=s, e do
				local cn = navs[i]
				net.WriteUInt(cn:GetID(), 18)
				local dat = cn:GetExtentInfo()
				net.WriteVector(dat.lo)
				net.WriteVector(dat.hi)

				local bybits = navHideSpots(cn)

				local hasSpots = not table.IsEmpty(bybits)
				net.WriteBool(hasSpots)

				if hasSpots then
					net.WriteUInt(table.Count(bybits), 8)
					for bit, data in pairs(bybits) do
						net.WriteUInt(bit, 8)
						net.WriteUInt(#data, 8)
						for bits, vec in pairs(data) do
							net.WriteVector(vec)
						end
					end
				end
			end

		net.Send(self:GetOwner())
	end

	if self:GetOwner():GetWIPNavs() then
		for k,v in pairs(self:GetOwner():GetWIPNavs()) do
			if not v:IsValid() then self:GetOwner():GetWIPNavs()[k] = nil continue end
			v:NW()
		end
	end

	local len = 0
	local s = 1

	for i=1, #navs do
		s = s or i
		len = len + 1

		if i - s > 2000 then
			local s2 = s
			timer.Create("nw_nav" .. s, i / 5000, 1, function()
				networkList(s2, i)
				printf("2 sent %d - %d", s2, i)
			end)

			s = i
		end
	end

	timer.Create("nw_nav_finale", #navs / 5000 + 0.2, 1, function()
		networkList(s, #navs)
		printf("3 sent %d - %d", s, #navs)
	end)

	--[[for i=1, #navs, 2000 do
		timer.Create("nw_nav" .. i, i / 5000, 1, function()
			networkList(i, math.min(#navs, i + 2000))
			print("sent " .. i + 2000 .. "/" .. #navs)
		end)
	end]]
end

local PLAYER = FindMetaTable("Player")
function PLAYER:GetWIPNavs()
	return bld.Navs[self] --bld.NWNav:GetNetworked()[self]
end