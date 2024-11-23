local push = require "push.push"

local CELL_SIZE_IN_PX = 20
local GRID_WIDTH_IN_CELLS = 96
local GRID_HEIGHT_IN_CELLS = 54

local GAME_WIDTH = CELL_SIZE_IN_PX * GRID_WIDTH_IN_CELLS
local GAME_HEIGHT = CELL_SIZE_IN_PX * GRID_HEIGHT_IN_CELLS
local WINDOW_WIDTH, WINDOW_HEIGHT = love.window.getDesktopDimensions()

push:setupScreen(GAME_WIDTH, GAME_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, { fullscreen = true })

local RADIUS_OF_CAUSALITY = 27
local X_MIN = 1 - RADIUS_OF_CAUSALITY
local X_MAX = GRID_WIDTH_IN_CELLS + RADIUS_OF_CAUSALITY
local Y_MIN = 1 - RADIUS_OF_CAUSALITY
local Y_MAX = GRID_HEIGHT_IN_CELLS + RADIUS_OF_CAUSALITY

local TIME_BETWEEN_UPDATES_IN_SECONDS = 0.2

local cells = {}
for i = X_MIN, X_MAX do
  cells[i] = {}
  for j = Y_MIN, Y_MAX do
    cells[i][j] = false
  end
end

local is_paused = true
local timer = 0

function is_valid_coords(i, j)
  return X_MIN <= i and i <= X_MAX and Y_MIN <= j and j <= Y_MAX
end

function love.update(dt)
  timer = timer + dt
  while timer >= TIME_BETWEEN_UPDATES_IN_SECONDS do
    timer = timer - TIME_BETWEEN_UPDATES_IN_SECONDS

    if is_paused then
      return
    end

    local cells_previous = {}
    for i = X_MIN, X_MAX do
      cells_previous[i] = {}
      for j = Y_MIN, Y_MAX do
        if cells[i][j] then
          cells_previous[i][j] = true
        else
          cells_previous[i][j] = false
        end
      end
    end

    for i = X_MIN, X_MAX do
      for j = Y_MIN, Y_MAX do
        local number_of_alive_neighbour_cells = 0
        for _, neighbour in ipairs({ { i + 1, j }, { i + 1, j + 1 }, { i, j + 1 }, { i - 1, j + 1 }, { i - 1, j }, { i - 1, j - 1 }, { i, j - 1 }, { i + 1, j - 1 } }) do
          local _i, _j = neighbour[1], neighbour[2]
          if is_valid_coords(_i, _j) and cells_previous[_i][_j] then
            number_of_alive_neighbour_cells = number_of_alive_neighbour_cells + 1
          end
        end

        if cells_previous[i][j] then
          if number_of_alive_neighbour_cells ~= 2 and number_of_alive_neighbour_cells ~= 3 then
            cells[i][j] = false
          end
        else
          if number_of_alive_neighbour_cells == 3 then
            cells[i][j] = true
          end
        end
      end
    end
  end
end

function love.draw()
  push:start()

  for i = 1, GRID_WIDTH_IN_CELLS do
    for j = Y_MIN, GRID_HEIGHT_IN_CELLS do
      if cells[i][j] then
        love.graphics.rectangle("fill", (i - 1) * CELL_SIZE_IN_PX, (j - 1) * CELL_SIZE_IN_PX, CELL_SIZE_IN_PX - 1,
          CELL_SIZE_IN_PX - 1)
      end
    end
  end

  push:finish()
end

function love.mousepressed(x, y, button, istouch, presses)
  if not is_paused then
    return
  end

  local _x, _y = push:toGame(x, y)
  if _x == nil or _y == nil then
    return
  end

  local i = math.floor(_x / CELL_SIZE_IN_PX) + 1
  local j = math.floor(_y / CELL_SIZE_IN_PX) + 1
  if not is_valid_coords(i, j) then
    return
  end

  cells[i][j] = not cells[i][j]
end

function love.keypressed(key, scancode, isrepeat)
  if key == "z" then
    is_paused = not is_paused
  end

  if key == "x" then
    love.event.quit()
  end

  if key == "c" then
    is_paused = true
    for i = X_MIN, X_MAX do
      cells[i] = {}
      for j = Y_MIN, Y_MAX do
        cells[i][j] = false
      end
    end
  end
end
