local ingredientParts = workspace:WaitForChild("Ingredients"):GetChildren();
local craftables = workspace:WaitForChild("Craftables"):GetChildren();
local mainArea = workspace:WaitForChild("MainArea"):GetChildren();
local players = game:GetService("Players");
local contextActionService = game:GetService("ContextActionService")

local player = players.LocalPlayer;
local character = player.Character or player.CharacterAdded:Wait();
local humanoid = character:WaitForChild("Humanoid");
local playerGui = player.PlayerGui;
local recipeGui = playerGui:WaitForChild("RecipeGui");

local craftBox = nil;
local craftBoxPosition = nil;
local craftBoxBillboard = nil;
local craftBoxHighlight = nil;

-- TODO: move hard coded maps into separate shared resource that both client and server can reference
local INGREDIENTS_WEIGHT_MAP = {
  ['Green'] = 50,
  ['Orange'] = 35,
  ['Purple'] = 15,
};
local ingredientWeightMultiplier = 0.1;
local INGREDIENTS_XP_MAP = {
  ['Green'] = 2,
  ['Orange'] = 4,
  ['Purple'] = 6,
};
local INGREDIENTS_PART_MAP = {};
local calculatedExpThresholds = {};
local activeSpawnParticleEmitters = {};

-- TODO: move to shared resource
local function calculateExpThreshold(currentLevel)
  local nextLevel = currentLevel + 1;

  -- first check cache to save having to make repeat calculations
  local cachedValue = calculatedExpThresholds[nextLevel];
  if cachedValue then
    return cachedValue;
  end

  local baseThreshold = 5;
  local baseMultiplier = 5;
  local exponent = 1.6;
  local nextLevelThreshold = baseThreshold + math.round((nextLevel ^ exponent) * baseMultiplier);

  -- cache value for future reference
  if not cachedValue then
    print(`caching level threshold for level {nextLevel} as {nextLevelThreshold}`)
    calculatedExpThresholds[nextLevel] = nextLevelThreshold;
  end

  return nextLevelThreshold;
end

local activeRecipe = {};
local humanoidRunningEvent = nil;
local ingredientTouchedEvent = nil;

local function findGuiCount(ingredientName)
  return recipeGui.Background[ingredientName].Count;
end

local function initiateCraftBox()
  for i, part in pairs(mainArea) do
    local name = part.Name;
    if name == "CraftBox" then
      craftBox = part;
      craftBoxPosition = craftBox.Position;
      craftBoxBillboard = craftBox.BillboardGui;
      craftBoxBillboard.Enabled = false;
      craftBoxHighlight = craftBox.Highlight;
    end
  end
end

local function useCraftBox(actionName, inputState, inputObject)
  if inputState == Enum.UserInputState.Begin then
    print("using craft box");
    contextActionService:UnbindAction("Interact");
    humanoidRunningEvent:Disconnect();

    -- using craft box takes 3 seconds
    task.wait(3);
    
    print("successfully crafted item!")
    local hasSpawned = false;

    -- reveal assets one by one
    for i, product in pairs(craftables) do
      if product.Archivable == true then -- Archivable is a "Model" property that is easily accessed and toggled
        product.Archivable = false;
        local allChildren = product:GetChildren();
        -- this nested loop will only ever run once per craft box use
        for i, child in pairs(allChildren) do
          child.Transparency = 0;
          child.CanCollide = true;
          local particleEmitter = child:WaitForChild("ParticleEmitter");
          particleEmitter.Enabled = true;
          table.insert(activeSpawnParticleEmitters, particleEmitter);
        end
        hasSpawned = true;
        break;
      end
    end

    -- first disable, then despawn all registered active emitters from asset spawning
    local function disableThenDestroy(part)
      part.Enabled = false;
      task.wait(3);
      part:Destroy();
    end
    for i, emitter in pairs(activeSpawnParticleEmitters) do
      task.delay(3, disableThenDestroy, emitter);
    end

    if not hasSpawned then
      print('oh no we are out of craftables!');
      craftBoxBillboard.Enabled = false;
      craftBoxHighlight.Enabled = false;    
      -- TODO: show messaging saying that all craftables have been made (and to wait for next update / ascend?)
    else 
      -- generate new recipe and spawn new ingredients
      generateRecipe();
      spawnIngredients();
    end
  end
end

local function activateCraftBox()
  print('all ingredients have been collected')
  craftBoxHighlight.Enabled = true;
  -- TODO: display ui messaging "All ingredients have been gathered!"

  -- only allow player to interact with craft box if within 10 studs of craft box
  local playerPosition = nil;
  local function onRunning(speed: number)
    -- get player vector location
    if speed == 0 then
      playerPosition = humanoid.RootPart.Position;
    end

    if playerPosition and craftBoxPosition then
      -- calculate distance between player and craftbox
      local magnitudeDiff = (playerPosition - craftBoxPosition).Magnitude;
      if magnitudeDiff <= 10 then
        -- enable craft box interaction
        craftBoxBillboard.Enabled = true;
        contextActionService:BindAction("Interact", useCraftBox, true, Enum.KeyCode.T, Enum.KeyCode.ButtonR1);
        contextActionService:SetTitle("Interact", "Use");
        contextActionService:SetPosition("Interact", UDim2.new(1, -70, 0, 10));
        -- TODO: show ui for "use craft box" action while in range
      else
        craftBoxBillboard.Enabled = false;
        contextActionService:UnbindAction("Interact");
      end
    end
  end
  humanoidRunningEvent = humanoid.Running:Connect(function(speed: number)
    onRunning(speed);
  end);
end

local function cloneIngredient(ingredient)
	local ingredientClone = ingredient:Clone();
  local ingredientName = ingredientClone.Name;

  -- nested function because this function needs to access the ingredient clone object
  local function onIngredientTouched(_otherPart)
    -- increment ui counter for ingredient collected
    local countTextLabel = findGuiCount(ingredientName);
    local counter = string.match(countTextLabel.Text, "^%d+");
    if counter then
      counter += 1;
    end

    -- check if all of one type of ingredients have been collected and update ui accordingly
    if counter == activeRecipe[ingredientName] then
      countTextLabel.Text = " ✓";
      activeRecipe[ingredientName] = nil;
      -- check if ALL ingredients have been collected
      if next(activeRecipe) == nil then
        ingredientTouchedEvent:Disconnect();
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
    local nextLevelExperienceThreshold = calculateExpThreshold(levelStat.Value);
    if experienceStat.Value >= nextLevelExperienceThreshold then
      levelStat.Value += 1;
      -- TODO: make leveling up more obvious
    end
  end

  -- change properties of hidden base asset
	ingredientClone.Transparency = 0;
	ingredientClone.CanTouch = true;

  -- TODO: replace random generation of ingredient position to random selection of predetermined spawn locations
  ingredientClone.Position = Vector3.new(math.random(-20, 20), 3, math.random(-20, 20));
	ingredientClone.Parent = workspace.Terrain
  ingredientTouchedEvent = ingredientClone.Touched:Connect(onIngredientTouched);
end

function generateRecipe()
  for i, ingredient in pairs(ingredientParts) do
    local name = ingredient.Name;
    INGREDIENTS_PART_MAP[name] = ingredient;
    local ingredientWeight = INGREDIENTS_WEIGHT_MAP[name];
    local ingredientNumber = math.floor(ingredientWeight * ingredientWeightMultiplier);
    activeRecipe[name] = ingredientNumber;
    local countTextLabel = findGuiCount(name);
    countTextLabel.Text = `0/{ingredientNumber}`;
  end
  craftBoxBillboard.Enabled = false;
  craftBoxHighlight.Enabled = false;
  ingredientWeightMultiplier += ingredientWeightMultiplier ^ 2; -- increase multiplier with each generated recipe
end

function spawnIngredients()
  for ingredientName, number in pairs(activeRecipe) do
    for counter = 1, number do
      cloneIngredient(INGREDIENTS_PART_MAP[ingredientName]);
    end
  end
end

-- initialize game
-- TODO: move recipe generation and ingredient spawning to server
initiateCraftBox();
generateRecipe();
spawnIngredients();