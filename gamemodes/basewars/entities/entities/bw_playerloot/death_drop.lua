--

local disabled = true

hook.Add("PlayerDeath", "DropItems", function(ply)
	if disabled then return end

	local inv = Inventory.GetTemporaryInventory(ply)
	local its = inv and inv:GetItems()

	if not its or table.IsEmpty(its) then return end

	local loot = ents.Create("bw_playerloot")
	loot:SetPos(ply:GetPos() + ply:OBBCenter())

	local col = team.GetColor(ply:Team())
	col = Color(col.r, col.g, col.b) -- I LOVE GMOD I LOVE GMOD I LOVE GMOD

	local h, s, v = col:ToHSV()
	col:SetHSV(h, math.Clamp(s, 0, 0.7), math.Clamp(v, 0.2, 0.7))

	loot:SetColor(col)
	loot:Spawn()

	local fr = math.Sign(math.random() - 0.5) * Lerp(math.random(), 0.6, 1)
	local fwd = ply:GetAngles():Forward() * -math.random(80, 120)
	fwd.z = 0

	loot:GetPhysicsObject():SetVelocity(Vector(0, 0, math.random(180, 210)) + fwd)
	loot:GetPhysicsObject():SetAngleVelocity(Vector(fr * 240, math.random(120, 360)))

	for k,v in pairs(its) do
		inv:CrossInventoryMove(v, loot.Storage, v:GetSlot())
	end
end)