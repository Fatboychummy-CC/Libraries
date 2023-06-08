---@meta

---@class display_utils-hfpb_options High Fidelity Percentage Bar Options
---@field x integer The X position of the left of the percentage bar.
---@field y integer The Y position of the top of the percentage bar.
---@field w integer The width of the percentage bar.
---@field h integer The height of the percentage bar.
---@field background color The color to be used for the unfilled parts of the bar.
---@field filled color The color to be used for the filled parts of the bar.
---@field current color The color to be used for the current fill position in the bar. This should be `value / max`.
---@field allow_overflow boolean? Whether or not to allow the bar to fill beyond its maximum point.


---@class display_utils-hfpb High Fidelity Percentage Bar
---@field x integer The X position of the left of the percentage bar.
---@field y integer The Y position of the top of the percentage bar.
---@field w integer The width of the percentage bar.
---@field h integer The height of the percentage bar.
---@field background color The color to be used for the unfilled parts of the bar.
---@field filled color The color to be used for the filled parts of the bar.
---@field current color The color to be used for the current fill position in the bar.
---@field percent number A value between 0 and 1 representing how full the bar should be. This should be `value / max`.
---@field allow_overflow boolean Whether or not to allow the bar to fill beyond its maximum point.
---@field draw fun() Draw this percent bar.