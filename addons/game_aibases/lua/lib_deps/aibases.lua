AIBases = AIBases or {}

FInc.Recursive("aibases/*.lua", FInc.SHARED, FInc.RealmResolver())
FInc.Recursive("aibases/classes/*.lua", FInc.SHARED, FInc.RealmResolver():SetDefault(true))

FInc.Recursive("aibases/server/*.lua", FInc.SERVER, FInc.RealmResolver())
FInc.Recursive("aibases/client/*.lua", FInc.CLIENT, FInc.RealmResolver())