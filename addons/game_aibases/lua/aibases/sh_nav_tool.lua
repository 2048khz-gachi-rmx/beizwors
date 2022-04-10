StartTool("AIBaseBuild")

TOOL.Category = "AIBases"
TOOL.Name = "NavTool"

if SERVER then
	util.AddNetworkString("aib_navrecv")
end

function TOOL:StartNetwork()
	local navs = navmesh.GetAllNavAreas()

	function networkList(s, e)
		net.Start("aib_navrecv")
			net.WriteUInt(s, 32)
			net.WriteUInt(e, 32)

			for i=s, e do
				local cn = navs[i]
				local dat = cn:GetExtentInfo()
				net.WriteVector(dat.lo)
				net.WriteVector(dat.hi)
			end

		net.Broadcast()
	end

	for i=1, #navs, 2500 do
		timer.Create("nw_nav" .. i, i / 5000, 1, function()
			networkList(i, math.min(#navs, i + 2500))
			print("sent " .. i + 2500 .. "/" .. #navs)
		end)
	end
end

function TOOL:Reload()
	if not AIBases.Builder.Allowed(self:GetOwner()) then return end

	if SERVER then
		self:StartNetwork(self:GetOwner())
	end
end

EndTool()


Navs = {}

net.Receive("aib_navrecv", function(len, p)
	print("recv navs:", len / 8)
	local s, e = net.ReadUInt(32), net.ReadUInt(32)

	for i=s, e do
		local min, max = net.ReadVector(), net.ReadVector()
		Navs[i] = {
			min = min,
			max = max
		}
	end
end)