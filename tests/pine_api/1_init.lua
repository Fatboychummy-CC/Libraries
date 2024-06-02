_G.PINE_TEST_DATA = {
  target_project_id = nil, -- The test project ID
  authorization = nil, -- The authorization token to use for authed endpoints.
  comments = {
    -- Expectations for the body of comments.
    -- If you are testing with your own project, you can change these to match your comments.
    ["This is a comment"] = "base", -- This comment should NOT have the `reply_id` field. It should be a top-level comment.
    ["This is a reply-comment"] = "reply" -- This comment should have the `reply_id` field, and it should link to the comment above (it should be a reply to the above comment).
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