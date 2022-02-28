local FORCE_TYPE = "weapon"

local lootInfo = {
	weapon = {
		small = {
			amt = {1, 2},
			appearChance = 0.5,
			loot = {
				weaponparts = {1, 2, 0.7},
				laserdiode = {2, 4, 0.6},
				lube = {1, 2, 0.4},
				_weapon = {{
					[1] = 7, -- t1: 7/8
					[2] = 1, -- t2: 1/8
				}, 0, 0.6},
			},
		},

		medium = {
			amt = {2, 3},
			appearChance = 0.25,
			loot = {
				weaponparts = {2, 4, 0.8},
				wepkit = {1, 1, 0.2},
				laserdiode = {3, 6, 0.7},
				lube = {2, 4, 0.6},
				_weapon = {{
					[1] = 3, -- t1: 3/4
					[2] = 1, -- t2: 1/4
				}, 0, 0.9}
			},
		}
	},

	scraps = {
		small = {
			appearChance = 0.8,
			amt = {1, 3},
			loot = {
				blank_bp = {3, 9},
				stem_cells = {1, 2, 0.3},
				weaponparts = {1, 1, 0.1},
				laserdiode = {1, 2, 0.2},
				-- circuit_board = {1, 2, 0.3},
				-- capacitor = {1, 4},
				-- adhesive = {1, 1, 0.35},
			}
		},

		medium = {
			appearChance = 0.4,
			amt = {3, 5},
			loot = {
				blank_bp = {10, 16},
				blood_nanobots = {1, 3, 0.2},
				tgt_finder = {1, 1, 0.3},
				laserdiode = {2, 3, 0.2},
				lube = {1, 1, 0.5},
				-- circuit_board = {2, 4, 0.6},
				-- emitter = {1, 1, 0.3},
				-- cpu = {1, 1, 0.2},
				-- capacitor = {3, 7},
				--adhesive = {1, 3, 0.5},
				weaponparts = {1, 1, 0.2}
			}
		}
	},
}

ENT.LootInfo = lootInfo

local function getLootInfo(typ, sz)
	if not lootInfo[typ] then
		errorf("missing loot info about %s", typ)
		return
	end

	if not lootInfo[typ][sz] then
		errorf("missing size loot info about %s [%s]", typ, sz)
		return
	end

	return lootInfo[typ][sz]
end

function ENT:GetLootInfo()
	return getLootInfo(self.CrateType, self.Size)
end

function ENT:GenerateWeapon(dat)
	local bp = Inventory.Blueprints
	local typ = bp.GetRandomType()
	local tier = WeightedRand.Select(dat[1])
	local class = bp.GetWeapon(typ, tier)

	local qual = bp.PickQuality(tier, class)
	local mods = bp.GenerateMods(tier, qual, bp.TierGetMods(tier))
	local stats = bp.GenerateStats(qual)

	local uses = math.floor( Lerp(math.random() ^ 0.8, 2, 5.5) )

	local wep = Inventory.NewItem(class)
	wep:SetQualityName(qual:GetName())
	wep:SetModNames(mods)
	wep:SetStatRolls(stats)
	wep:SetUses(uses)

	local pr = Promise()
	pr.Item = wep

	Inventory.MySQL.NewFloatingItem(wep):Then(pr:Resolver())

	return pr
end

function ENT:GenerateItem(iid, dat)
	if iid == "_weapon" then
		print("generating weapon", self:EntIndex())
		return self:GenerateWeapon(dat)
	end

	local it = Inventory.NewItem(iid)
	if not it then
		errorf("No such item: %s", iid)
		return
	end

	if istable(dat) and isnumber(dat[1]) then
		it:SetAmount(math.random(unpack(dat)))
	end
	local pr = Promise()
	pr.Item = it

	Inventory.MySQL.NewFloatingItem(it):Then(pr:Resolver())

	return pr
end

function ENT:GenerateLoot()
	local dat = self:GetLootInfo()
	local toGen = 1
	if dat.amt then
		toGen = math.random(dat.amt[1], dat.amt[2])
	end

	toGen = math.min(toGen, table.Count(dat.loot))

	local prs = {}

	for k,v in RandomPairs(dat.loot) do
		if toGen == 0 then break end
		if v[3] and math.random() > v[3] then continue end

		toGen = toGen - 1

		prs[#prs + 1] = self:GenerateItem(k, v)
	end

	if #prs == 0 then
		self:RespawnIn(10)
		self:Remove()
		return
	end

	return Promise.OnAll(prs):Then(function()
		for k,v in ipairs(prs) do
			local it = v.Item
			it:SetSlot(k)
			self.Storage:AddItem(it, true)
		end

		return 0
	end)
end

ActiveLootCrates = ActiveLootCrates or {}
LootCratesAwaitingRespawn = 0



local function readData()
	Inventory.LootCratePositions = Inventory.LootCratePositions or {}

	local map = game.GetMap()
	local fn = "inventory/lootboxes/" .. map .. "_manual.dat"

	local dat = file.Read(fn, "DATA")

	if not dat then
		file.Write(fn, "")
		return
	end

	local poses = util.JSONToTable(dat)
	if not poses then
		error("failed to read loot crate info for map " .. map)
		return
	end

	Inventory.LootCratePositions = poses
end

local function rollCratePos(num)
	num = num or 1

	local posCopy = table.Copy(Inventory.LootCratePositions)
	local ret = {}

	while #ret < num do
		local key = math.random(1, #posCopy)
		local data = posCopy[key]
		if not data then break end

		if FORCE_TYPE and data[3] ~= FORCE_TYPE then goto nextPos end

		do
			data.key = key
			local lootInfo = getLootInfo(data[3], data[4])

			if lootInfo.appearChance and math.random() > lootInfo.appearChance then
				goto nextPos
			end

			do
				local pos = data[1]

				for _, ent in ipairs(ActiveLootCrates) do
					if ent:GetPos():DistToSqr(pos) < 64^2 then
						goto nextPos
					end
				end

				if pos then
					ret[#ret + 1] = data
				end
			end
		end

		::nextPos::
		table.remove(posCopy, key)
	end

	return ret
end

local entClass = "bw_lootcrate"

local function makeCrate(pos)
	local dat = istable(pos) and pos or rollCratePos()
	if not dat then return end

	local crate = ents.Create(entClass)
	crate.SavedKey = dat.key

	crate:SetPos(dat[1])
	crate:SetAngles(dat[2])

	crate.CrateType = dat[3]
	crate.Size = dat[4]

	crate.Model = dat[5]
	crate:ParseModel(dat[5])
	crate:CreateInventory()

	local pr = crate:GenerateLoot()

	if pr then
		pr:Then(function()
			crate:Spawn()
			crate:Activate()
			crate:GetPhysicsObject():EnableMotion(false)
		end)
	elseif IsValid(crate) then
		--mfw
		crate:Remove()
	end
end

function LootCratesSpawn(amt)
	for i=#ActiveLootCrates, 1, -1 do
		local e = ActiveLootCrates[i]
		if not e:IsValid() then table.remove(ActiveLootCrates, i) end
	end

	local maxCrates = math.max(4, 2 + player.GetCount() / 2)

	amt = amt or maxCrates - #ActiveLootCrates - LootCratesAwaitingRespawn
	if amt <= 0 then return end

	if not Inventory.LootCratePositions then
		readData()
	end

	local spawns = rollCratePos(amt)

	for k,v in ipairs(spawns) do
		makeCrate(v)
	end
end

local function loadCrates()
	Inventory.LootCrates = Inventory.LootCrates or {}

	Inventory.LootCrates.Create = makeCrate
	Inventory.LootCrates.RollPosition = rollCratePos
	Inventory.LootCrates.Reload = function()
		loadCrates()
		readData()
	end

	for k,v in ipairs(ActiveLootCrates) do
		v:RemoveRespawnless()
	end

	ActiveLootCrates = {}
	Inventory.MySQL.WaitStates(LootCratesSpawn, "itemids")
end

if CurTime() > 60 then
	loadCrates()
else
	hook.Add("InventoryReady", "SpawnCrates", loadCrates)
end
