local Script = "https://raw.githubusercontent.com/BBD31/Haggus.gg/refs/heads/main/Hook/Script.json"
local Wander = false
local HWID = {}
if Script.HWID == true then
    Wander = true
end
function HWID:Check(Value)
    HWID = Value or Wander
       require()
	return(Value)
end
local wait = task.wait
while Wander do 
    wait(0.5) or task.wait(0.5)
    HWID:Check(HWID)
end
