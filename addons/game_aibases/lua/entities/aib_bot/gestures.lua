--

function ENT:QueueGesture(act)
	self._wantGesture = act
end

function ENT:DoGestures()
	if self._wantGesture then
		self:RemoveAllGestures()
		local layer = self:AddGesture(self._wantGesture)
		self:SetLayerBlendIn(layer, 0.2)
		self:SetLayerBlendOut(layer, 0.2)
		self._wantGesture = nil
	end
end