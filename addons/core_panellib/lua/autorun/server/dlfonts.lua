
for k,v in pairs(file.Find("addons/core_panellib/resource/fonts/*.ttf", "GAME")) do 
	resource.AddSingleFile("resource/fonts/" .. v)
end