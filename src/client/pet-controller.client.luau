local RunService = game:GetService("RunService");
local players = game:GetService("Players");

local pets = workspace:WaitForChild("Pets"):GetChildren();

local player = players.LocalPlayer;
local character = player.Character or player.CharacterAdded:Wait();

local smoothness = 0.1;

local function spawnPet()
  for i, pet in pairs(pets) do
    local name = pet.Name;

    -- TODO: generalize
    if name == 'BabyBean' then
      local clone = pet:Clone();
      clone.Parent = workspace.Terrain;
      -- TP to starting position
      clone:MoveTo(Vector3.new(0, 0, 5));

      local function followPlayer()
        local rootPart = character.HumanoidRootPart
        local modelPrimaryPart = clone.PrimaryPart or model:FindFirstChild("HumanoidRootPart") or model:FindFirstChildWhichIsA("BasePart")
    
        if not modelPrimaryPart then
            warn("Model does not have a primary part or base part to move!")
            return
        end
    
        -- Calculate the target position and rotation
        local targetCFrame = rootPart.CFrame * CFrame.new(0, -2, 7)
        local currentCFrame = modelPrimaryPart.CFrame

        -- Interpolate between the current CFrame and the target CFrame
        modelPrimaryPart.CFrame = currentCFrame:Lerp(targetCFrame, smoothness)
    end

      RunService.Heartbeat:Connect(followPlayer);
    end
  end

end

spawnPet();