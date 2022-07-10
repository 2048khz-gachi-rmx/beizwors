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
				if cn:GetID() > bit.lshift(1, 18) then
					printf("%s is more than 2^18!!!!!!")
				end

				local dat = cn:GetExtentInfo()
				net.WriteVector(dat.lo)
				net.WriteVector(dat.hi)

				local bybits = bld.NavHideSpots(cn)

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

util.AddNetworkString("patrol-aib")
net.Receive("patrol-aib", function(_, ply)
	if not bld.Allowed(ply) then return end

	local typ = net.ReadUInt(4)

	if typ == 1 then
		local bot = net.ReadEntity()
		local points = net.ReadUInt(8)

		local out = {}

		for i=1, points do
			local pt = net.ReadVector()
			out[i] = pt
		end

		bld.PNW:SetTable(bot, out)
		bot.PatrolRoute = out
	elseif typ == 0 then
		local bot = net.ReadEntity()
		bld.PNW:SetTable(bot, bot.PatrolRoute or {})
	end
end)