local Players = game:GetService('Players');

-- TODO: implement datastore for persisting leaderboard data (needs game to be deployed to test functionality)
local function leaderboardSetup(player)
  -- local userId = tostring(player.UserId);
  -- track joined player stats and add player to leaderboard
  local leaderboard = Instance.new('Folder');
  leaderboard.Name = 'leaderstats';
  leaderboard.Parent = player;

  -- LEVEL
  local initialLevelValue = 1;
  -- local initialLevelValue = levelStore:GetAsync(userId) or 1;
  local level = Instance.new('IntValue', leaderboard);
  level.Name = 'Level';
  level.Value = initialLevelValue;

  local levelPriority = Instance.new('NumberValue', level);
  levelPriority.Name = 'Priority';
  levelPriority.Value = 10;

  local isPrimary = Instance.new('BoolValue', level);
  isPrimary.Name = 'IsPrimary';
  isPrimary.Value = true;

  -- EXPERIENCE
  local initialExperience = 0;
  local experience = Instance.new('IntValue', leaderboard);
  experience.Name = 'Total XP';
  experience.Value = initialExperience;

  local experiencePriority = Instance.new('NumberValue', experience);
  experiencePriority.Name = 'Priority';
  experiencePriority.Value = 5;
  
  -- local checkpointValue = '1_0';
  -- -- local checkpointValue = checkpointStore:GetAsync(userId) or '1_0';
  -- local checkpoint = Instance.new('StringValue', leaderboard);
  -- checkpoint.Name = 'Checkpoint';
  -- checkpoint.Value = checkpointValue;
  -- local checkpointPriority = Instance.new('NumberValue', checkpoint);
  -- checkpointPriority.Name = 'Priority';
  -- checkpointPriority.Value = 1;

  -- -- bind checkpoint handler to player on respawn
  -- player.CharacterAdded:Connect(function(character)
  --   goToCheckpoint(character, checkpoint.Value);
  -- end)
end

Players.PlayerAdded:Connect(leaderboardSetup);