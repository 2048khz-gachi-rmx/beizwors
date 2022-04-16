-- ?

AIBases.WeaponPools = {
	shotgun = {
		{"cw_shorty"},
		{"cw_saiga12k_official", "cw_m3super90"},
		{"cw_xm1014_official"}
	},
	ar = {
		{"cw_g36c", "cw_ak74"},
		{"cw_acr", "cw_scarh", "cw_l85a2", "cw_tr09_qbz97"},
		{"cw_famasg2_official", "cw_ar15", "cw_tr09_auga3",}
	},

	smg = {
		{"cw_mp5", "cw_mac11", "cw_ump45"},
		{"cw_mp7_official", "cw_mp9_official"}
	},
	pistol = {
		{"cw_makarov", "cw_p99",},
		{"cw_fiveseven", "cw_deagle",}
	},
	sniper = {
		{},
		{"cw_svd_official", "cw_m14",},
		{"cw_l115",}
	},
}


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