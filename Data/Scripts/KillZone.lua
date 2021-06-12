-- KillZoneServer.lua
-- Kills any player that enters this component
-- Created by Nicholas Foreman (https://www.coregames.com/user/f9df3457225741c89209f6d484d0eba8)

local Void = script:GetCustomProperty("Trigger"):WaitForObject()

local function enteredVoid(trigger, player)
	if(not player:IsA("Player")) then return end

	player:Die()
end

Void.beginOverlapEvent:Connect(enteredVoid)