local Data = {};

-- Track how much xp per resource type
Data.xpMap = {
  ['Green'] = 2,
  ['Orange'] = 4,
  ['Purple'] = 6,
};

-- Track how much weight each resource has (for recipe generation)
Data.weightMap = {
  ['Green'] = 50,
  ['Orange'] = 35,
  ['Purple'] = 15,
};
Data.ingredientWeightMultiplier = 0.1;

Data.spawn = {
  height = 3,
  ['Green'] = {
    [1] = Vector3.new(-136, HEIGHT, -125),
    [2] = Vector3.new(-176, HEIGHT, -135),
    [3] = Vector3.new(-94, HEIGHT, -138)
  }
}

return Data;