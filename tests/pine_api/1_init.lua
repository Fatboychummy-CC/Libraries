_G.PINE_TEST_DATA = {
  target_project_id = 87, -- The test project ID
  authorization = nil, -- The authorization token to use for authed endpoints.
}

if type(PINE_TEST_DATA.target_project_id) ~= "number" then
  error("Cannot test pine_api: Missing target project ID.", 0)
end

--[[ -- I think we can just disable the tests if the authorization token is missing.
if type(PINE_TEST_DATA.authorization) ~= "string" then
  error("Cannot test pine_api: Missing authorization token.", 0)
end
]]