local players = game:GetService("Players");
local localPlayer = players.LocalPlayer;

local character = localPlayer.Character or localPlayer.CharacterAdded:Wait();
local humanoid = character:WaitForChild("Humanoid");

if character then
  humanoid.WalkSpeed = 32; -- $5 to double your movement speed
end