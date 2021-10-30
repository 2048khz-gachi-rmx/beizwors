function sql.Check(query, expectres)
	local res = sql.Query(query)

	if res == nil and expectres then
		if sql.Debugging then
			printf("SQL Error(?): expected a result, got nil instead.\nQuery: %s", query)
		end
		return false, false
	end

	if res == false then
		print("SQL Error: \nQuery: %s \n Error: %s", query, sql.LastError())
		return false, true
	end

	if expectres then return res end
end