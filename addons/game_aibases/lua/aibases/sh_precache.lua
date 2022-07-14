local pre = GetConVar("mod_forcetouchdata"):GetInt()
RunConsoleCommand("mod_forcetouchdata", "0")

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

				Model(wep.WorldModel)
				Model(wep.ViewModel)
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

				Model(mdl)
			end
		end
	end

	b:Close():print(10)

	b = bench(("AIBaseModels - mod_forcedata = %s, mod_forcetouchdata = %s")
		:format(GetConVar("mod_forcedata"):GetInt(), GetConVar("mod_forcetouchdata"):GetInt())
	)

	local path = "aibases/layouts/"

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

		b:SubClose(n, 50)
	end
	b:Close():print(100)

	RunConsoleCommand("mod_forcetouchdata", tostring(pre))
end)