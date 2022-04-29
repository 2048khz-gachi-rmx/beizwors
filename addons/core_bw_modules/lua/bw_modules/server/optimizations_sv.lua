function BW.ApplyPhysSettings()
	physenv.SetPerformanceSettings({
	    LookAheadTimeObjectsVsObject      =     0.15,
	    LookAheadTimeObjectsVsWorld       =     0.3,
	    MaxAngularVelocity                =  7272.7275390625,
	    MaxCollisionChecksPerTimestep     = 10000,
	    MaxCollisionsPerObjectPerTimestep =    3,
	    MaxFrictionMass                   =  2500,
	    MaxVelocity                       =  4000,
	    MinFrictionMass                   =    10
	})
end

timer.Create("phys_shite_thx_garry", 30, 5, BW.ApplyPhysSettings)