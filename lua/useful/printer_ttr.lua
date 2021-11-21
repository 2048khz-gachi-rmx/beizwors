for k,v in pairs(BaseWars.SpawnList.Printers.Items) do
	local et = scripted_ents.GetStored(v.ClassName).t
	if not et.PrintAmount then continue end

	printf("%-21s: %d", v.ClassName, v.Price / et.PrintAmount)
end