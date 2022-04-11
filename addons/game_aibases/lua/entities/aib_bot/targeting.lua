--
local trIn, trOut = {}, {}
trIn.output = trOut

function ENT:HaveEnemy()
	if ( self:GetEnemy() and IsValid(self:GetEnemy()) ) then
		if ( self:GetRangeTo(self:GetEnemy():GetPos()) > self.LoseTargetDist ) then
			return self:FindEnemy()
		elseif ( self:GetEnemy():IsPlayer() and !self:GetEnemy():Alive() ) then
			return self:FindEnemy()
		end

		return true
	else
		return self:FindEnemy()
	end
end

function ENT:CanTarget(ply)
	if not self:BW_GetBase() then return false end -- wtf
	if ply:BW_GetBase() ~= self:BW_GetBase() then return false end
	if ply.InDevMode then return false end

	return true
end

function ENT:InView(ply)
	trIn.endpos = ply:EyePos()
	trIn.filter = self
	util.TraceLine(trIn)

	local ent = trOut.Entity

	-- didnt hit when aiming straight for the eyes; means no obstacles means ur so fucked homie
	if not trOut.Hit then return ply end

	if ent:IsPlayer() then
		if ent == ply then return ent end
		if self:CanTaget(ent) then return ent end -- eh this'll do
	end

	return false
end

function ENT:FindEnemy()
	local plys = player.GetConstAll()
	trIn.start = self:EyePos()

	for k,v in ipairs(plys) do
		if not self:CanTarget(v) then
			continue
		end

		local tgt = self:InView(v)
		if not tgt then
			continue
		end

		self:SetEnemy(tgt)
		return true
	end

	if self:GetEnemy() then
		self:OnEnemyLost()
	end

	self:SetEnemy(nil)
	return false
end

function ENT:OnEnemyLost()
	self.TrackingEnemy = false
end