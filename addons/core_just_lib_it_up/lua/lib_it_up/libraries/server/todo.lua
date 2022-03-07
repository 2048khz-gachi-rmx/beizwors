todo = {
	prepared = {}
}

local tododb

local del_proc = [[CREATE PROCEDURE `todoDeleteAndReturn` (id INT)
BEGIN
	SELECT * FROM todo WHERE uid = id;
    DELETE FROM todo WHERE uid = id;
END]]

local solve_proc = [[CREATE PROCEDURE `todoSolveAndReturn` (id INT)
BEGIN
	UPDATE todo SET done = TRUE WHERE uid = id;
	SELECT * FROM todo WHERE uid = id;
END]]

local function createProcedures()
	MySQLEmitter(tododb:query(del_proc), true) --don't catch since it'll probably bitch about having the procedures already
	MySQLEmitter(tododb:query(solve_proc), true)
end


local function prepareQueries()
	MySQLEmitter(
		tododb:query("CREATE TABLE IF NOT EXISTS todo (`uid` INT PRIMARY KEY AUTO_INCREMENT, `str` TEXT, `done` BOOL)"),
		true)

	createProcedures()

	local ins = tododb:prepare("INSERT INTO todo(str) VALUES(?)")
	local get_all = tododb:prepare("SELECT * FROM todo")
	local solve = tododb:prepare("CALL todoSolveAndReturn(?)")
	local remove = tododb:prepare("CALL todoDeleteAndReturn(?)")

	todo.prepared.ins = ins
	todo.prepared.get_all = get_all
	todo.prepared.solve = solve
	todo.prepared.remove = remove
end

if not mysqloo.OnConnect then include("mysql.lua") end

mysqloo.UseLiveDB():Then(function(self, db)
	tododb = db
	prepareQueries()
end)



function todo.Add(str)
	todo.prepared.ins:setString(1, str)

	MySQLEmitter(todo.prepared.ins, true):Then(function()
		local em = Embed()
		em:SetText("```\n" .. str .. "```"):SetTitle("To-do added"):SetColor(200, 200, 50)

		discord.SendEmbed("todo", "To-do Tracker", em)
	end)

end



function todo.Get()
	return MySQLEmitter(todo.prepared.get_all, true)
end

function todo.Solve(...)
	local t = {...}
	for k, id in ipairs(t) do
		todo.prepared.solve:setNumber(1, id)

		MySQLEmitter(todo.prepared.solve, true):Then(function(_, _, dat)
			local em = Embed()
			em:SetText("```\n" .. dat[1].str .. "```\nSolved!"):SetTitle("Todo solved!"):SetColor(90, 210, 90)

			discord.SendEmbed("todo", "To-do Tracker", em)
			MsgC(Colors.Sky, "[Todo]: ", color_white, "'", dat[1].str, "':", Colors.Money, " Solved!\n")
		end)
	end
end

function todo.Remove(...)
	local t = {...}
	for k, id in ipairs(t) do
		todo.prepared.remove:setNumber(1, id)

		local em = MySQLEmitter(todo.prepared.remove, true):Then(function(_, _, dat)
			MsgC(Colors.Sky, "[Todo]: ", color_white, "'", dat[1].str, "':", Colors.Red, " Removed!\n")
		end)
		if #t == 1 then
			return em
		end
	end
end

todo.Delete = todo.Remove

function todo.Print()
	local res = todo.Get()

	res:Then(function(em, q, dat)
		local t = {}

		for k,v in ipairs(dat) do
			local str = ("%q"):format(v.str)
			local col = (v.done == 1 and Colors.Money) or Color(240, 200, 70)
			t[k] = {str = str, col = col, uid = v.uid, done = v.done == 1}
		end

		table.sort(t, function(a, b)
			if a.done and not b.done then
				return false
			elseif b.done and not a.done then
				return true
			else
				return a.uid < b.uid
			end
		end)

		local done = false
		MsgC(Colors.Sky, "\n-=== To-do list: ===-", "\n")
		for k,v in ipairs(t) do
			if v.done and not done then
				done = true
				MsgC(Colors.Sky, "\n-=== Completed: ===-", "\n")
			end

			MsgC(Colors.Sky, "#" .. v.uid .. ": ", color_white, v.str, v.col, " -- ", (v.done and "Solved") or "In progress", color_white, "\n")
		end
	end)
end

function todo.Addendum(id, s2)
	--[[local res = sql.Check("SELECT str, adds FROM todo WHERE id ==" .. id, true)
	if not res then return end

	local str = res[1].str
	local adds = tonumber(res[1].adds)

	local add = ("%sAddendum #%d: %s"):format( "\n", adds+1, s2 )

	str = str .. add

	sql.Check("UPDATE todo SET str =" .. SQLStr(str) .. ", adds = adds + 1 WHERE id ==" .. id)

	local em = Embed()
	em:SetText("```\n" .. str .. "```"):SetTitle("Todo addendum:"):SetColor(200, 200, 70)

	discord.SendEmbed("todo", "To-do Tracker", em)]]
end