local ingredientParts = workspace:WaitForChild("Ingredients"):GetChildren();
local mainArea = workspace:WaitForChild("MainArea"):GetChildren();
local players = game:GetService("Players");
local contextActionService = game:GetService("ContextActionService")

local player = players.LocalPlayer;
local playerGui = player.PlayerGui;
local recipeGui = playerGui:WaitForChild("RecipeGui");

local craftBox = nil;
local craftBoxTextLabel = nil;
local craftBoxTextLabelBaseText = "Craft!";
local craftBoxTextLabelDisabled = `<s>{craftBoxTextLabelBaseText}</s>`;

-- TODO: move hard coded maps into separate shared resource that both client and server can reference
local INGREDIENTS_WEIGHT_MAP = {
  ['Green'] = 50,
  ['Orange'] = 35,
  ['Purple'] = 15,
};

local INGREDIENTS_XP_MAP = {
  ['Green'] = 1,
  ['Orange'] = 2,
  ['Purple'] = 3,
};

local EXPERIENCE_THRESHOLD_PER_LEVEL = {
  -- [1] = 0,
  [2] = 10,
  [3] = 20,
  [4] = 35,
  [5] = 50,
  [6] = 65,
  [7] = 85,
  [8] = 105,
  [9] = 125,
};

local INGREDIENTS_PART_MAP = {};

local activeRecipe = {};

local function findGuiCount(ingredientName)
  return recipeGui.Background[ingredientName].Count;
end

local function initiateCraftBox()
  for i, part in pairs(mainArea) do
    local name = part.Name;
    if name == "CraftBox" then
      craftBox = part;
      craftBoxTextLabel = craftBox.BillboardGui.TextLabel;
      craftBoxTextLabel.Text = craftBoxTextLabelDisabled;
      break;
    end
  end
end

local function activateCraftBox()
  print('all ingredients have been collected')
  craftBoxTextLabel.Text = craftBoxTextLabelBaseText;

  -- TODO: set up code to allow player to interact with craft box only when player character is near box
  -- local function collectTreasure(actionName, inputState, inputObject)
  --   if inputState == Enum.UserInputState.Begin then
  --     print("Collect treasure")
  --   end
  -- end
  
  -- contextActionService:BindAction("Interact", collectTreasure, true, Enum.KeyCode.T, Enum.KeyCode.ButtonR1)
  -- contextActionService:SetTitle("Interact", "Collect")
  -- contextActionService:SetPosition("Interact", UDim2.new(1, -70, 0, 10))
end

local function generateRecipe()
  local weightMultiplier = 0.1;

  for i, ingredient in pairs(ingredientParts) do
    local name = ingredient.Name;
    INGREDIENTS_PART_MAP[name] = ingredient;
    local ingredientWeight = INGREDIENTS_WEIGHT_MAP[name];
    local ingredientNumber = math.floor(ingredientWeight * weightMultiplier);
    activeRecipe[name] = ingredientNumber;
    local countTextLabel = findGuiCount(name);
    countTextLabel.Text = `0/{ingredientNumber}`;
  end
end

local function cloneIngredient(ingredient)
	local ingredientClone = ingredient:Clone();
  local ingredientName = ingredientClone.Name;

  -- nested function because this function needs to access the ingredient clone object
  local function onIngredientTouched(_otherPart)
    -- increment ui counter for ingredient collected
    local countTextLabel = findGuiCount(ingredientName);
    local counter = string.match(countTextLabel.Text, "^%d+");
    counter += 1;

    -- check if all of one type of ingredients have been collected and update ui accordingly
    if counter == activeRecipe[ingredientName] then
      countTextLabel.Text = " ✓";
      activeRecipe[ingredientName] = nil;
      -- check if ALL ingredients have been collected
      if next(activeRecipe) == nil then
        activateCraftBox();
      end
    else 
      countTextLabel.Text = `{counter}/{activeRecipe[ingredientName]}`;
    end

    -- only despawn ingredient part once counter and ui have been updated
    ingredientClone:Destroy();

    -- player gains experience per ingredient gathered
    local leaderStats = player and player:FindFirstChild('leaderstats');
    local experienceStat = leaderStats and leaderStats:FindFirstChild('Total XP');
    experienceStat.Value += INGREDIENTS_XP_MAP[ingredientName];
    -- check if player has reached next level xp threshold and increment level accordingly
    local levelStat = leaderStats and leaderStats:FindFirstChild('Level');
    local nextLevel = levelStat.Value + 1;
    local nextLevelExperienceThreshold = EXPERIENCE_THRESHOLD_PER_LEVEL[nextLevel];
    if experienceStat.Value >= nextLevelExperienceThreshold then
      levelStat.Value = nextLevel;
      -- TODO: make leveling up more obvious
    end
  end

	ingredientClone.Transparency = 0
	ingredientClone.CanTouch = true

  -- change spawn coords as needed
  ingredientClone.Position = Vector3.new(math.random(-20, 20), 3, math.random(-20, 20));
  -- ingredientClone.Position = Vector3.new(math.random(-100, 100), 3, math.random(-100, 100));
	ingredientClone.Parent = workspace.Terrain
  ingredientClone.Touched:Connect(onIngredientTouched);
end

local function spawnIngredients()
  print('activeRecipe', activeRecipe);
  for ingredientName, number in pairs(activeRecipe) do
    for counter = 1, number do
      cloneIngredient(INGREDIENTS_PART_MAP[ingredientName]);
    end
  end
end

initiateCraftBox();
generateRecipe();
spawnIngredients();