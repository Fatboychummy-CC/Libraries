_G.PINE_TEST_DATA = {
  target_project_id = nil, -- The test project ID
  authorization = nil, -- The authorization token to use for authed endpoints.
}

if type(PINE_TEST_DATA.target_project_id) ~= "number" then
  error("Cannot test pine_api: Missing target project ID.", 0)
end
if type(PINE_TEST_DATA.authorization) ~= "string" then
  error("Cannot test pine_api: Missing authorization token.", 0)
end