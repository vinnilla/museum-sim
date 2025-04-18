local players = game:GetService("Players");

local player = players.LocalPlayer;
local playerGui = player.PlayerGui;
local recipeGui = playerGui:WaitForChild("RecipeGui");

print('Modules/UI/Recipe')

local RecipeGUI = {};

-- Returns the TextLabel "Count" for the provided resourceName
-- @param resourceName: the name of the target resource
-- @return: ScreenGui.Background[ResourceName].Count
function RecipeGUI.getCount(resourceName)
  return recipeGui.Background[resourceName].Count;
end

-- Refreshes the active RecipeGui 
function RecipeGUI.refresh()
  recipeGui = playerGui:WaitForChild("RecipeGui");
end

return RecipeGUI;