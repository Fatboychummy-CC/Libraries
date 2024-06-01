_G.PINE_TEST_DATA = {
  target_project_id = nil, -- The test project ID
  authorization = nil, -- The authorization token to use for authed endpoints.
  comments = {
    -- Expectations for the body of comments.
    ["This is a comment"] = "base", -- This comment should NOT have the `reply_id` field.
    ["This is a reply-comment"] = "reply" -- This comment should have the `reply_id` field, and it should link to the comment above.
  }
}

if type(PINE_TEST_DATA.target_project_id) ~= "number" then
  error("Cannot test pine_api: Missing target project ID.", 0)
end

--[[ -- I think we can just disable the tests if the authorization token is missing.
if type(PINE_TEST_DATA.authorization) ~= "string" then
  error("Cannot test pine_api: Missing authorization token.", 0)
end
]]