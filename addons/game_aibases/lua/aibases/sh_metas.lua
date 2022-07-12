-- ?

AIBases.WeaponPools = {
	shotgun = {
		{"cw_shorty"},
		{"cw_saiga12k_official", "cw_m3super90", "arccw_go_mag7"},
		{"cw_xm1014_official", "arccw_go_m1014"}
	},
	ar = {
		{"cw_g36c", "cw_ak74"},
		{"cw_acr", "cw_scarh", "cw_l85a2", "cw_tr09_qbz97"},
		{"cw_famasg2_official", "cw_ar15", "cw_tr09_auga3",}
	},

	smg = {
		{"cw_mp5", "cw_mac11", "cw_ump45", "arccw_go_bizon"},
		{"cw_mp7_official", "cw_mp9_official",},
		{"arccw_fml_fas_mp5", "arccw_go_p90"}
	},
	pistol = {
		{"cw_makarov", "cw_p99", "arccw_go_p250"},
		{"cw_fiveseven", "arccw_fml_fas_g20",},
		{"cw_deagle", "arccw_deagle50", "arccw_mifl_fas2_ragingbull"}
	},
	sniper = {
		{},
		{"cw_svd_official", "cw_m14",},
		{"cw_l115",}
	},
}

LibItUp.OnInitEntity(function()
	local b = bench("CachingAIWeaponModels")

	b:Open()

	for typ, pool in pairs(AIBases.WeaponPools) do
		for _, weps in pairs(pool) do
			for _, cl in pairs(weps) do
				if not isstring(cl) then continue end
				local wep = weapons.GetStored(cl)
				if not wep or not wep.WorldModel then
					print("missing weapon:", cl, wep, wep and wep.WorldModel)
					continue
				end

				local n = b:SubOpen(("% -20s"):format(cl))
				Model(wep.WorldModel)
				Model(wep.ViewModel)
				b:SubClose(n, 2)
			end
		end
	end

	b:Close():print(10)

	local b = bench("CachingAIModels")

	b:Open()

	if SERVER then
		local tiers = scripted_ents.GetStored("aib_bot").t.TierData

		for tier, dat in pairs(tiers) do
			for _, mdl in pairs(dat.models) do
				if not isstring(mdl) then continue end

				local n = b:SubOpen(("% -20s"):format(mdl))
				Model(mdl)
				b:SubClose(n, 2)
			end
		end
	end

	b:Close():print(10)

	b = bench(("AIBaseModels - mod_forcedata = %s, mod_forcetouchdata = %s")
		:format(GetConVar("mod_forcedata"):GetInt(), GetConVar("mod_forcetouchdata"):GetInt())
	)

	local path = "aibases/layouts/"

	local pre = GetConVar("mod_forcetouchdata"):GetInt()
	RunConsoleCommand("mod_forcetouchdata", "0")

	b:Open()
	for k,v in pairs(file.Find(path .. "*", "DATA")) do
		if v:match("_nav%.dat$") then continue end

		local layName = v:gsub("%.dat$", "")
		local lay = AIBases.BaseLayout:new("CachedLayout")
		lay:ReadFrom(layName, false)

		local n = b:SubOpen( ("% -12s"):format(layName) )

			for uid, brick in pairs(lay.UIDBricks) do
				brick:Preload()
			end

		b:SubClose(n, 3)
	end
	b:Close():print(100)

	RunConsoleCommand("mod_forcetouchdata", tostring(pre))
end)

function AIBases.RollWeapon(type, tier)
	local pool = AIBases.WeaponPools[type]
	local valid = not type or type == "random" or (pool and pool[tier] and #pool[tier] > 0)

	if not valid then
		printf("invalid combo: %s T%s", type, tier)
	end

	if not type or type == "random" or not valid then
		for k,v in RandomPairs(AIBases.WeaponPools) do
			if k == type then continue end
			if v[tier] and #v[tier] > 0 then pool, type = v, k break end
		end
	end

	pool = pool[tier]

	return table.SeqRandom(pool)
end

FInc.Recursive("aibases/classes/*.lua", FInc.SHARED, FInc.RealmResolver()
	:SetDefault(true)
)

FInc.Recursive("aibases/tools/*", FInc.SHARED, FInc.RealmResolver()
	:SetDefault(true)
)