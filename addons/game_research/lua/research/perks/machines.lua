local tree = Research.Tree:new("Machines")
tree:SetDescription("Upgrades, but better")

file.ForEveryFile("research/perks/machines_ext/*", "LUA", IncludeCS)