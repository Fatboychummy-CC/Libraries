--- Small library to test performance of functions.
--- Meant to be ran in CraftOS-PC, as it has os.epoch "nano".

local performance = {}
local min, max = math.min, math.max
local epoch = os.epoch

--- Measures the time it takes to run a function.
---@param func function The function to run.
---@param ... any The arguments to pass to the function.
---@return number milliseconds The time it took to run the function.
function performance.measure(func, ...)
  local start = epoch "nano" ---@diagnostic disable-line:param-type-mismatch
  func(...)
  local finish = epoch "nano" ---@diagnostic disable-line:param-type-mismatch
  return (finish - start) / 1e6
end

--- Measures the time it takes to run a function n times.
---@param func function The function to run.
---@param n integer The number of times to run the function.
---@param ... any The arguments to pass to the function.
---@return number min_milliseconds The minimum time it took to run the function.
---@return number max_milliseconds The maximum time it took to run the function.
---@return number avg_milliseconds The average time it took to run the function.
---@return number total_milliseconds The total time it took to run the function n times.
function performance.measure_n(func, n, ...)
  local min_milliseconds = math.huge
  local max_milliseconds = -math.huge
  local total_milliseconds = 0

  local measure = performance.measure

  for _ = 1, n do
    local milliseconds = measure(func, ...)

    min_milliseconds = min(min_milliseconds, milliseconds)
    max_milliseconds = max(max_milliseconds, milliseconds)
    total_milliseconds = total_milliseconds + milliseconds
  end

  local avg_milliseconds = total_milliseconds / n
  return min_milliseconds, max_milliseconds, avg_milliseconds, total_milliseconds
end

--- Displays the results of a performance test, given a name and the results.
---@param name string The name of the test.
---@param min_milliseconds number The minimum time it took to run the function.
---@param max_milliseconds number The maximum time it took to run the function.
---@param avg_milliseconds number The average time it took to run the function.
---@param total_milliseconds number The total time it took to run the function n times.
---@param n integer The number of times the function was run.
function performance.display(name, min_milliseconds, max_milliseconds, avg_milliseconds, total_milliseconds, n)
  term.setTextColor(colors.purple)
  print(name)

  term.setTextColor(colors.white)
  write("Iterations  : ")
  term.setTextColor(colors.yellow)
  print(n)

  term.setTextColor(colors.white)
  write("Total time  : ")
  term.setTextColor(colors.yellow)
  print(("%4.8f"):format(total_milliseconds), "ms")

  term.setTextColor(colors.white)
  write("Minimum time: ")
  term.setTextColor(colors.yellow)
  print(("%4.8f"):format(min_milliseconds), "ms")


  term.setTextColor(colors.white)
  write("Maximum time: ")
  term.setTextColor(colors.yellow)
  print(("%4.8f"):format(max_milliseconds), "ms")


  term.setTextColor(colors.white)
  write("Average time: ")
  term.setTextColor(colors.yellow)
  print(("%4.8f"):format(avg_milliseconds), "ms")

  print()
end

function performance.test(name, func, n, ...)
  local min_milliseconds, max_milliseconds, avg_milliseconds, total_milliseconds = performance.measure_n(func, n, ...)
  performance.display(name, min_milliseconds, max_milliseconds, avg_milliseconds, total_milliseconds, n)

  os.queueEvent("fast_yield")
  os.pullEvent("fast_yield")
end

return performance