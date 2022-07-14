Research = Research or {}
Research.Log = Logger("Research", Color(90, 180, 90))

FInc.Recursive("research/*.lua", FInc.SHARED, FInc.RealmResolver())
FInc.Recursive("research/server/*.lua", FInc.SERVER, FInc.RealmResolver())
FInc.Recursive("research/client/*.lua", FInc.CLIENT, FInc.RealmResolver())

FInc.Recursive("research/perks/*", FInc.SHARED,
	FInc.RealmResolver()
		:SetDefault(true)
)