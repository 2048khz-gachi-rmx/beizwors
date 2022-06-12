local PLAYER = debug.getregistry().Player

function PLAYER:SetTitle(title, db)
	title = title or ""

	self:SetNWString("Title", title)

	if db then
		self:SetPData("Title", title)
	end
end

function PLAYER:FetchTitle()
	local title = self:GetPData("Title", nil)
	local pr = Promise()

	if not title then pr:Resolve() end
	pr:Resolve(title)

	return pr
end

function PLAYER:GrantTitleAccess()
	self:SetPData("TitleAccess", true)
	self.HasTitleAccess = true
	self:SetNWBool("TitleAccess", true)
end

function PLAYER:RevokeTitleAccess()
	self:SetPData("TitleAccess", false)
	self.HasTitleAccess = false
	self:SetNWBool("TitleAccess", false)
end

function PLAYER:SetTitleAccess(bool)
	self:SetPData("TitleAccess", tobool(bool))
	self.HasTitleAccess = tobool(bool)
	self:SetNWBool("TitleAccess", tobool(bool))
end

function PLAYER:GetTitleAccess()
	if self.HasTitleAccess == nil then
		self.HasTitleAccess = self:GetPData("TitleAccess", false)
			or self:IsAdmin()
	end

	return self.HasTitleAccess
end

function PLAYER:ReadTitle()
	return self:GetPData("Title", nil)
end

hook.Add("PlayerInitialSpawn", "ApplyTitle", function(ply)
	ply:FetchTitle():Then(function(_, t)
		ply:SetTitle(t)
	end)
	ply:SetNWBool("TitleAccess", ply:GetTitleAccess())
end)