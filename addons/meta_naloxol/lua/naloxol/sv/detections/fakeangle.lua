--

local nx = NX
local dt = NX.Detection:new("fakeangles", 0)


hook.Add("FinishMove", "NX_Fakeangles", function(ply, mv)
	if NX.ShouldIgnore(ply) then return end

	local ea, mva = ply:EyeAngles(), mv:GetAngles()
	local diff = ea - mva
	local diff_total = math.abs(diff[1]) + math.abs(diff[2]) + math.abs(diff[3])

	if diff_total > 30 then
		dt:Detect(ply, diff_total)
	end
end)