Research = Research or {}
Research.Log = Logger("Research", Color(90, 180, 90))

FInc.Recursive("research/*", FInc.SHARED, nil, FInc.RealmResolver())

FInc.Recursive("research/_perks/*", FInc.SHARED)