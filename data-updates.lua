-- no-empty-barrels/data.lua
-- 确保在原版配方生成后执行我们的修改
-- 通过 postfix-patching 来修改已经生成的配方

-- 定义配置选项
local config = {
  remove_empty_barrels_from_fill_recipes = true,  -- 从装桶配方中移除空桶
  remove_empty_barrels_from_empty_recipes = true, -- 从倒桶配方中移除空桶
  keep_empty_barrel_item = true,                  -- 保留空桶物品定义
  debug_logging = false                           -- 启用调试日志
}

-- 日志函数
local function log_debug(message)
  if config.debug_logging then
      log("[NoEmptyBarrels] " .. message)
  end
end

-- 修改现有配方
local function modify_existing_recipes()
  log_debug("开始修改现有桶配方...")
  
  local recipes = data.raw["recipe"]
  if not recipes then
      log("[NoEmptyBarrels] 未找到配方数据！")
      return
  end

  local modified_fill = 0
  local modified_empty = 0

  -- 遍历所有配方，处理装桶、倒桶配方
  for recipe_name, recipe in pairs(recipes) do
      -- 处理“装桶”配方（名称一般是 fluid-name-barrel ，比如 water-barrel ）
      if string.match(recipe_name, "^[a-z0-9%-]+%-barrel$") 
          and recipe.category == "crafting-with-fluid" 
          and config.remove_empty_barrels_from_fill_recipes then
          
          local new_ingredients = {}
          local has_empty_barrel = false
          for _, ing in ipairs(recipe.ingredients) do
              if ing.type == "item" and ing.name == "barrel" then
                  has_empty_barrel = true
                  log_debug("装桶配方[" .. recipe_name .. "]找到空桶原料，准备移除")
              else
                  table.insert(new_ingredients, ing)
              end
          end
          if has_empty_barrel then
              recipe.ingredients = new_ingredients
              modified_fill = modified_fill + 1
          end
      end

      -- 处理“倒桶”配方（名称一般是 empty-fluid-name-barrel ，比如 empty-water-barrel ）
      if string.match(recipe_name, "^empty%-[a-z0-9%-]+%-barrel$") 
          and recipe.category == "crafting-with-fluid" 
          and config.remove_empty_barrels_from_empty_recipes then
          
          local new_results = {}
          local has_empty_barrel = false
          for _, res in ipairs(recipe.results) do
              if res.type == "item" and res.name == "barrel" then
                  has_empty_barrel = true
                  log_debug("倒桶配方[" .. recipe_name .. "]找到空桶产物，准备移除")
              else
                  table.insert(new_results, res)
              end
          end
          if has_empty_barrel then
              recipe.results = new_results
              modified_empty = modified_empty + 1
          end
      end
  end

  log("[NoEmptyBarrels] 完成配方修改！移除装桶配方空桶：" 
      .. modified_fill .. " 个，移除倒桶配方空桶：" .. modified_empty .. " 个")
end

-- 如果需要隐藏空桶物品（当 keep_empty_barrel_item 为 false 时）
local function handle_empty_barrel_item()
  if not config.keep_empty_barrel_item then
      local empty_barrel = data.raw["item"]["barrel"]
      if empty_barrel then
          -- 添加 hidden 标记，让物品在游戏内隐藏
          empty_barrel.flags = empty_barrel.flags or {}
          table.insert(empty_barrel.flags, "hidden")
          log_debug("空桶物品已标记为隐藏")
      end
  end
end

-- 注册模组加载完成后执行的逻辑（Factorio 数据阶段处理）
-- 注意：Factorio 模组数据阶段，直接调用函数即可（无需 events 绑定，因为是数据修改）
modify_existing_recipes()
handle_empty_barrel_item()