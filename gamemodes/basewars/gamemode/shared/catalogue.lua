LibItUp.OnInitEntity(function()

BaseWars.SpawnList = {}
BaseWars.Catalogue = {}

local k = 1000
local m = k * 1000
local b = m * 1000

local function CreateCategory(cat)
	local t = {
		Name = cat,
		Items = {},
		Subcategories = {},
		Priority = 0,

		Icon = nil
	}

	BaseWars.SpawnList[cat] = t
	return t
end

local function CreateSubcategory(cat, subcat)
	local t = {
		Name = subcat,
		Items = {},
		Tiers = {},

		Priority = 0,
		Icon = nil
	}
				-- tier detection
	if subcat:match("[%p%s]T(%d+)[%p%s]") then
		t.Priority = -tonumber(subcat:match("[%p%s]T(%d+)[%p%s]"))
	end

	BaseWars.SpawnList[cat].Subcategories[subcat] = t
	return t
end

if CLIENT then
	if not Icon then
		include("lib_it_up/classes/icon.lua")
	end
end

local Icon = Icon or function() end

local cEnts = CreateCategory("Entities")
local cLoadout = CreateCategory("Loadout")

	if CLIENT then
		--local scMelee = CreateSubcategory("Loadout", "Melee")
		--scMelee.Priority = 10

		local scPistols = CreateSubcategory("Loadout", "[CW] Pistols")
		scPistols.Priority = 9
		scPistols.Icon = Icon("https://i.imgur.com/VkH8Yvy.png", "gun.png"):SetSize(24, 24)

		local scArcPistols = CreateSubcategory("Loadout", "[ACW] Pistols")
		scArcPistols.Priority = 8
		scArcPistols.Icon = Icon("https://i.imgur.com/VkH8Yvy.png", "gun.png"):SetSize(24, 24)

		local scShotguns = CreateSubcategory("Loadout", "[CW] Shotguns")
		scShotguns.Priority = 7
		--scShotguns.Icon = Icon("https://i.imgur.com/VkH8Yvy.png", "gun.png"):SetSize(24, 24)

		local scArcShotguns = CreateSubcategory("Loadout", "[ACW] Shotguns")
		scArcShotguns.Priority = 6
		--scShotguns.Icon = Icon("https://i.imgur.com/VkH8Yvy.png", "gun.png"):SetSize(24, 24)

		local scSMGs = CreateSubcategory("Loadout", "[CW] SMGs")
		scSMGs.Priority = 5

		local scArcSMGs = CreateSubcategory("Loadout", "[ACW] SMGs")
		scArcSMGs.Priority = 4

		local scRifles = CreateSubcategory("Loadout", "[CW] Assault Rifles")
		scRifles.Priority = 3

		local scArcRifles = CreateSubcategory("Loadout", "[ACW] Assault Rifles")
		scArcRifles.Priority = 2
	end

local cPrinters = CreateCategory("Printers")
local cRecreational = CreateCategory("Recreational")
local cInventory = CreateCategory("Inventory")

if CLIENT then
	cEnts.Icon = Icon("https://i.imgur.com/1a5sZQc.png", "entities56.png"):SetSize(28, 28)
	--cLoadout.Icon = Icon("https://i.imgur.com/1a5sZQc.png", "entities56.png"):SetSize(28, 28)
	cPrinters.Icon = Icon("https://i.imgur.com/vzrqPxk.png", "coins_pound64.png"):SetSize(28, 28)
	cRecreational.Icon = Icon("https://i.imgur.com/tKMbV5S.png", "gamepad56.png"):SetSize(28, 28)
end

local add = BaseWars.AddToSpawn

local sl = BaseWars.SpawnList

local curTier
local function SetTier(t)
	curTier = t
end

local curTyp
local function SetType(t)
	curTyp = t
end

local function AddItem(cat, typ, class, name, price, mdl)
	local t = {}

	t.ClassName = class
	t.Price = tonumber(price)
	t.Model = mdl
	--t.Level = lv
	t.Tier = curTier

	t.Name = name

	t = add(t)

	local cat_t = sl[cat] or CreateCategory(cat)
	local subcat_t = cat_t.Subcategories[typ] or CreateSubcategory(cat, typ)

	cat_t.Items[#cat_t.Items + 1] = t
	subcat_t.Items[#subcat_t.Items + 1] = t
	if curTier then
		subcat_t.Tiers[curTier] = true
	end

	t.CatID = #cat_t.Items
	t.SubcatID = #subcat_t.Items

	BaseWars.Catalogue[class] = t

	return t
end

local function AddLoadout(typ, class, name, price, mdl, nongun)

	local wep = weapons.GetStored(class)

	mdl = (mdl ~= "" and mdl) or (wep and wep.WorldModel)
	if not mdl then ErrorNoHalt("Failed getting model for weapon " .. class) return end

	name = name or wep.PrintName
	if not name then ErrorNoHalt("wtf is the name " .. class) return end

	local t = AddItem("Loadout", typ, class, name, price, mdl)

	if not nongun then t.Gun = true end
end

local function ReuseLoadout(...)
	return AddLoadout(curTyp, ...)
end

local function AddPrinters(typ, class, name, price, mdl, lim)
	local t = AddItem("Printers", typ, class, name, price, mdl or "models/grp/printers/printer.mdl", lim)
	t.Limit = 1

	local tbl = scripted_ents.GetStored(class)
	if not tbl then return t end

	local rate = tbl.t.DisplayPrintAmount or tbl.t.PrintAmount
	if not rate then return t end

	t.GenerateCloudInfo = function(cl, btn)
		cl:AddSeparator(nil, 16, 4)

		local pnl = vgui.Create("InvisPanel", cl)
		cl:AddPanel(pnl)

		local txt = t.RateFormat and t.RateFormat(rate) or Language("Price", rate) .. "/s."
		local font = "OS20"
		surface.SetFont(font)

		local tw, th = surface.GetTextSize(txt)
		local icSz = th * 0.875
		local fullW = tw + icSz + 4
		pnl:SetTall(th)

		function pnl:Paint(w, h)
			Icons.Money32:Paint(w / 2 - fullW / 2, h / 2 - icSz / 2,
				icSz, icSz)
			surface.SetTextPos(w / 2 - fullW / 2 + icSz + 2, h / 2 - th / 2)
			surface.SetTextColor(150, 150, 150, 100)
			surface.SetFont(font)
			surface.DrawText(txt)
		end
	end

	return t
end

local function ReusePrinters(...)
	return AddPrinters(curTyp, ...)
end

local function AddRecreational(typ, class, name, price, mdl, lim)
	local t = AddItem("Recreational", typ, class, name, price, mdl, lim)
	return t
end

local function AddEntities(typ, class, name, price, mdl, lim)
	local t = AddItem("Entities", typ, class, name, price, mdl, lim)
	return t
end

local function AddInventory(typ, class, name, price, mdl, lim)
	local t = AddItem("Inventory", typ, class, name, price, mdl, lim)
	return t
end

local function ReuseInventory(...)
	return AddInventory(curTyp, ...)
end

local function ReuseEntities(...)
	return AddEntities(curTyp, ...)
end

--[[
	models/weapons/killdrix/w_acre.mdl
	models/weapons/scorpion/w_ev03.mdl
	models/weapons/w_rif_m4a1.mdl



]]



-- Weapons - Misc--


SetType("Weapons - Misc")
	SetTier(1)
		ReuseLoadout("weapon_health", "Heal Gun", k * 500, "models/weapons/w_physics.mdl")
		ReuseLoadout("epicpickax", "Harvester", k * 200, "models/weapons/w_irifle.mdl")
		ReuseLoadout("bw_blowtorch_t1", "Blowtorch T1", k * 500, "models/weapons/w_irifle.mdl")

	SetTier(2)
		ReuseLoadout("bw_blowtorch_t2", "Blowtorch T2", m * 2.5, "models/weapons/w_irifle.mdl")

	SetTier(3)
		ReuseLoadout("bw_blowtorch_t3", "Blowtorch T3", m * 20, "models/weapons/w_irifle.mdl")

	SetTier(4)
		ReuseLoadout("bw_blowtorch_t4", "Blowtorch T4", m * 75, "models/weapons/w_irifle.mdl")

	SetTier(5)
		ReuseLoadout("bw_blowtorch_t5", "Blowtorch T5", m * 200, "models/weapons/w_irifle.mdl")


SetTier(nil)
SetType("Misc.")

-- Printers - Misc.--

	--ReusePrinters("bw_printercap", "Capacity Kit", k * 1000, "models/props_junk/cardboard_box004a.mdl")
	ReusePrinters("bw_printerrack", "Printer Rack", k * 100, "models/grp/rack/rack.mdl")
	--ReusePrinters("bw_printercap2", "Heavy Capacity Kit", m * 125, "models/props_junk/cardboard_box004a.mdl")


-- Printers (T1)--
SetType("Money Printers")

	SetTier(1)
		local man = ReusePrinters("bw_printer_manual", "Manual Printer", 0)
		man.RateFormat = function(t) return Language("Price", t) .. "/use" end

		ReusePrinters("bw_base_moneyprinter", "Basic Printer", 		k * 3.5)
		ReusePrinters("bw_printer_copper", "Copper Printer", 		k * 7.5)
		ReusePrinters("bw_printer_silver", "Silver Printer", 		k * 20)
		ReusePrinters("bw_printer_gold", "Gold Printer", 			k * 60)
		ReusePrinters("bw_printer_platinum", "Platinum Printer", 	k * 150)
		ReusePrinters("bw_printer_diamond", "Diamond Printer", 		k * 350)
		ReusePrinters("bw_printer_nuclear", "Nuclear Printer", 		k * 500)

	SetTier(2)
		ReusePrinters("bw_printer_mobius", "Mobius Printer", 			m * 2.5)
		ReusePrinters("bw_printer_darkmatter", "Dark Matter Printer", 	m * 6)
		ReusePrinters("bw_printer_redmatter", "Red Matter Printer", 	m * 15)
		ReusePrinters("bw_printer_monolith", "Monolith Printer", 		m * 35)
		ReusePrinters("bw_printer_quantum", "Quantum Printer", 			m * 75)
		ReusePrinters("bw_printer_molecular", "Molecular Printer", 		m * 200)

	SetTier(3)
		ReusePrinters("bw_printer_atomic", "Atomic Printer", m * 450)
		ReusePrinters("bw_printer_proton", "Proton Printer", m * 800)
		ReusePrinters("bw_printer_neutron", "Neutron Printer", b * 1.5)
		ReusePrinters("bw_printer_electron", "Electron Printer", b * 3.5)
		ReusePrinters("bw_printer_photon", "Photon Printer", b * 7.5)

SetTier(nil)
SetType(nil)

-- Misc.--

		AddRecreational("Misc.", "synthesizer_accordion", "Synthesizer - Accordion", k * 350, "models/tnf/synth.mdl")
		AddRecreational("Misc.", "synthesizer_organ", "Synthesizer - Organ", k * 350, "models/tnf/synth.mdl")
		AddRecreational("Misc.", "synthesizer_violin", "Synthesizer - Violin", k * 350, "models/tnf/synth.mdl")
		AddRecreational("Misc.", "synthesizer_electric_guitar", "Synthesizer - Electric Guitar", k * 350, "models/tnf/synth.mdl")
		AddRecreational("Misc.", "synthesizer_piano", "Synthesizer - Piano", k * 350, "models/tnf/synth.mdl")
		AddRecreational("Misc.", "synthesizer_sax", "Synthesizer - Saxophone", k * 350, "models/tnf/synth.mdl")
		AddRecreational("Misc.", "synthesizer_harp", "Synthesizer - Harp", k * 350, "models/tnf/synth.mdl")
		AddRecreational("Misc.", "synthesizer_guitar", "Synthesizer - Guitar", k * 350, "models/tnf/synth.mdl")

SetType("Consumables")
	ReuseEntities("bw_repairkit", "Repair Kit", k * 2.5, "models/Items/car_battery01.mdl")

SetType("Generators")
	SetTier(1)
		ReuseEntities("bw_gen_manual", "Manual Generator", 0, "models/props_c17/cashregister01a.mdl")
			.Limit = 1
		ReuseEntities("bw_gen_solar", "Solar Panel", 1500, "models/props_lab/miniteleport.mdl")
		ReuseEntities("bw_gen_scrap", "Scrap Generator", k * 5, "models/props_c17/TrapPropeller_Engine.mdl")
		ReuseEntities("bw_gen_gas", "Gas Generator", k * 20, "models/xqm/hydcontrolbox.mdl")

	SetTier(2)
		ReuseEntities("bw_gen_coalfired", "Coal Fired Generator", k * 75, "models/props_wasteland/laundry_washer003.mdl")
		ReuseEntities("bw_gen_fission", "Fission Reactor", k * 200, "models/props/de_nuke/equipment1.mdl")
		ReuseEntities("bw_gen_fusion", "Fusion Reactor", k * 500, "models/maxofs2d/thruster_propeller.mdl")

	SetTier(3)
		--ReuseEntities("bw_gen_joke", "Numismatic Reactor", m * 150, "models/props_c17/cashregister01a.mdl")
		ReuseEntities("bw_gen_hydroelectric", "Hydroelectric Reactor", m * 1.5, "models/props_wasteland/laundry_washer001a.mdl")
		ReuseEntities("bw_gen_combustion", "Combustion Reactor", m * 20, "models/props_c17/substation_transformer01a.mdl")

SetType("Batteries")
	SetTier(1)
		ReuseEntities("bw_battery_car", "Car Battery", 1500, "models/items/car_battery01.mdl", 2)

SetType("Structures")

	SetTier(1)
		ReuseEntities("bw_spawnpoint", "Spawnpoint", k * 25, "models/props_trainstation/trainstation_clock001.mdl", 1)



SetType("Dispensers")

	SetTier(1)
		--ReuseEntities("bw_vendingmachine", "Vending Machine", k * 20, "models/props_interiors/VendingMachineSoda01a.mdl")
		ReuseEntities("bw_dispenser_health", "Health Dispenser", k * 25, "models/props_combine/health_charger001.mdl")
		ReuseEntities("bw_dispenser_ammo", "Ammo Dispenser", k * 25, "models/props_lab/reciever_cart.mdl")
		ReuseEntities("bw_dispenser_armor", "Armor Dispenser", k * 75, "models/props_combine/suit_charger001.mdl")

	SetTier(2)
		--ReuseEntities("bw_dispenser_armor2", "Armor Dispenser T2", m * 15, "models/props_combine/suit_charger001.mdl")
		--ReuseEntities("bw_dispenser_ammo2", "Ammo Dispenser T2", m * 10, "models/props_lab/reciever_cart.mdl")




SetType("[CW] Pistols")
	SetTier(1)
		ReuseLoadout("cw_makarov", 		"Makarov", 		5 * k)
		ReuseLoadout("cw_m1911", 		"M1911", 		10 * k)
		ReuseLoadout("cw_p99", 			"P99", 			25 * k)
		ReuseLoadout("cw_mr96", 		"MR96", 		75 * k)
		ReuseLoadout("cw_ragingbull", 	"Raging Bull",	200 * k)
		ReuseLoadout("cw_deagle", 		"Deagle", 		350 * k)

SetType("[ACW] Pistols")

	SetTier(1)
		ReuseLoadout("arccw_go_m9", 	"M9", 		25 * k)
		ReuseLoadout("arccw_go_usp", 	"USP", 		75 * k, "models/weapons/w_pist_usp.mdl")
		ReuseLoadout("arccw_go_p250", 	"P250", 	200 * k)		

	SetTier(2)
		ReuseLoadout("arccw_go_tec9", 	"Tec-9", 	750 * k)
		ReuseLoadout("arccw_go_fiveseven", 	"Five-seven", 	2 * m)
		ReuseLoadout("arccw_go_cz75", 		"CZ-75", 		5 * m)
		--ReuseLoadout("arccw_go_r8",		 	"R8 Revolver",	3 * m)
		ReuseLoadout("arccw_go_deagle", 	"Deagle", 		15 * m)


SetType("[CW] Shotguns")

	SetTier(1)
		ReuseLoadout("cw_shorty", 				"Shorty", 	200 * k)
		ReuseLoadout("cw_m3super90", 			"M3", 		750 * k)
		ReuseLoadout("cw_saiga12k_official", 	"Saiga", 	2 * m)
		ReuseLoadout("cw_xm1014_official", 		"M4", 		5 * m)

SetType("[ACW] Shotguns")

	SetTier(1)
		ReuseLoadout("arccw_db", "Sawn-off", 75 * k, "models/weapons/arccw/w_sawnoff.mdl")
		ReuseLoadout("arccw_go_nova", "Nova", 400 * k, nil)
		ReuseLoadout("arccw_dmi_r870_sg_elite", "Remington M870", 550 * k, nil)


SetType("[CW] SMGs")
	SetTier(1)
		ReuseLoadout("cw_ump45", 		"UMP45", 	100 * k)
		ReuseLoadout("cw_mp9_official", "MP9", 		250 * k)
		ReuseLoadout("cw_mac11", 		"MAC11", 	750 * k)
		ReuseLoadout("cw_mp5", 			"MP5", 		2 * m)
		ReuseLoadout("cw_mp7_official", "MP7", 		5.5 * m)

SetType("[ACW] SMGs")

	SetTier(1)
		ReuseLoadout("arccw_dmi_mkgs_banshee", "[ACW] Banshee", 50*k)
		ReuseLoadout("arccw_mw2_tmp", "TMP", 					100*k)
		ReuseLoadout("arccw_mw2_miniuzi", "Mini Uzi", 			250*k)
		ReuseLoadout("arccw_go_mac10", "MAC10", 					850 * k)

	SetTier(2)
		ReuseLoadout("arccw_fml_fas_mp5", "HK MP5K", 				2 * m, "models/weapons/w_smg_mp5.mdl")
		ReuseLoadout("arccw_go_ump", "UMP45 (v1)", 					7.5 * m)
		ReuseLoadout("arccw_go_mp9", "MP9", 						15 * m)
		ReuseLoadout("arccw_go_mp5", "MP5A3", 						30 * m)
		ReuseLoadout("arccw_fml_fas_extra_comando9", "Commando 9", 	55 * m)
		ReuseLoadout("arccw_mw2_ump45", "UMP45 (v2)", 				85 * m)



SetType("[ACW] Assault Rifles")

	SetTier(1)
		--ReuseLoadout("arccw_go_ar15", "AR15", 100 * k)
		ReuseLoadout("arccw_go_galil_ar", "Galil", 		150*k)
		ReuseLoadout("arccw_go_ace", "ACE 22", 			500*k)

	SetTier(2)
		ReuseLoadout("arccw_fml_fas_g36c", "G36", 		1.5*m, nil)
		ReuseLoadout("arccw_fml_fas_ak47", "AK-47", 	5*m, "models/weapons/arccw/fml/fas1/w_ak47.mdl")
		ReuseLoadout("arccw_fml_fas_famas", "FAMAS", 	12.5*m, "models/weapons/arccw/fml/fas1/w_famas.mdl")
		ReuseLoadout("arccw_fml_fas_g3a3", "G3A3", 		20*m, "models/weapons/arccw/fml/fas1/w_g3a3.mdl")
		ReuseLoadout("arccw_go_aug", "AUG", 			35*m)

	SetTier(3)
		ReuseLoadout("arccw_fml_fas_m14", "M14", 60*m, "models/weapons/arccw/fml/fas1/w_m14.mdl")
		ReuseLoadout("arccw_mw2_f2000", "F2000", 100*m)
		ReuseLoadout("arccw_go_sg556", 	"SG556", 	150*m)
		ReuseLoadout("arccw_fml_fas_sg550", "SG550", 275*m, "models/weapons/arccw/fml/fas1/w_sg550.mdl")


SetType("[CW] Assault Rifles")

	SetTier(1)
		ReuseLoadout("cw_g36c", "G36C", 	200*k)
		ReuseLoadout("cw_ak74", "AK74", 	500*k)
		ReuseLoadout("cw_acr", "ACR", 		1.5*m)
		ReuseLoadout("cw_l85a2", "L85A2", 	2.5*m)

	SetTier(2)
		ReuseLoadout("cw_vss", "VSS", 				5*m)
		ReuseLoadout("cw_g3a3", "G3A3", 			10*m)
		ReuseLoadout("cw_scarh", "SCAR-H", 			25*m)
		ReuseLoadout("cw_tr09_tar21", "TAR-21", 	35*m)

	SetTier(3)
		ReuseLoadout("cw_famasg2_official", "FAMAS", 75*m)
		ReuseLoadout("cw_tr09_qbz97", "QBZ-97", 	 125*m)
		ReuseLoadout("cw_tr09_auga3", "AUG A3", 	 200*m)
		ReuseLoadout("cw_ar15", "AR15", 			 500*m)



SetType("[ACW] Sniper Rifles")

	SetTier(1)
		ReuseLoadout("arccw_contender", "G2 Contender", k * 100, "models/weapons/arccw/w_contender.mdl")

	SetTier(2)
		ReuseLoadout("arccw_go_ssg08", "Scout", 750 * k)
		ReuseLoadout("arccw_fml_fas_m24", "M24", 1500 * k,"models/weapons/arccw/fml/fas1/w_m24.mdl")

	SetTier(3)
		ReuseLoadout("arccw_fml_fas_m82", "Barett M82", 3500 * k, "models/weapons/arccw/fml/fas1/w_m82.mdl")

SetTier(nil)

SetType("Refinement")
	ReuseInventory("refinery", "Smeltery", 500 * k, "models/props/CS_militia/furnace01.mdl", 1)
		.Limit = 1

	ReuseInventory("bw_blueprint_ctor", "Blueprint Constructor", 2.5 * m, "models/grp/bpmachine/bpmachine.mdl", 1)
		.Limit = 1

SetType("Production")
	ReuseInventory("bw_blueprint_printer", "Blueprint Printer", 1 * m, "models/props_lab/plotter.mdl", 1)
		.Limit = 1
	ReuseInventory("workbench", "Workbench", 2.5 * m, "models/props/CS_militia/table_shed.mdl", 1)
		.Limit = 1

hook.Run("BW_CatalogueFilled")

end)