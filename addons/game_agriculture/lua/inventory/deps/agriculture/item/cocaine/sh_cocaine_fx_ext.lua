--

local PLAYER = FindMetaTable("Player")

-- pubNW.cx_<COCAINE_ID> = {endTime, intensity}

if CLIENT then
	function PLAYER:HasCocaineEffect(str)
		local id = Agriculture.CocaineNameToID(str)
		local pub = self:GetPublicNW() -- cocaine effects are public for now
		-- todo: should they not be?

		return pub:Get("cx_" .. id, false)
	end
else
	function PLAYER:HasCocaineEffect(str)
		local cx = self._cocks or {}
		return cx[Agriculture.CocaineNameToID(str) or "?"]
	end
end