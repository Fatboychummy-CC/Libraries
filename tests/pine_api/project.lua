---@diagnostic disable: undefined-global We will be using a bunch of globals here defined in another location.

local pine_api = require "pine_api" --[[@as pine_store-base]]

suite.suite "Pine API - Project Endpoint"
  "Info has expected data" (function()
    local ok, response = pine_api.project.info(PINE_TEST_DATA.target_project_id)

    -- Assert response is OK
    if not ok then
      END("Failed to get project info: " .. response)
    end
    ASSERT_TRUE(response.success)
    ASSERT_TYPE(response, "table")
    ASSERT_TYPE(response.project, "table")

    -- Project ID
    EXPECT_TYPE(response.project.id, "number")
    EXPECT_EQ(response.project.id, PINE_TEST_DATA.target_project_id)

    -- Project date info
    EXPECT_TYPE(response.project.date_added, "number")
    EXPECT_TYPE(response.project.date_updated, "number")
    EXPECT_TYPE(response.project.date_release, "number")
    EXPECT_TYPE(response.project.date_publish, "number")

    -- Project owner info
    EXPECT_TYPE(response.project.owner_discord, "string")
    EXPECT_TYPE(response.project.owner_name, "string")

    -- Project info
    EXPECT_TYPE(response.project.name, "string")
    EXPECT_TYPE(response.project.tags, "table")
      -- Tags should be a table of strings
      for _, tag in ipairs(response.project.tags) do
        EXPECT_TYPE(tag, "string")
      end
    EXPECT_TYPE(response.project.keywords, "table")
      -- Keywords should be a table of strings
      for _, keyword in ipairs(response.project.keywords) do
        EXPECT_TYPE(keyword, "string")
      end
    EXPECT_TYPE(response.project.has_thumbnail, "boolean")
    EXPECT_TYPE(response.project.hide_thumbnail, "boolean")
    EXPECT_TYPE(response.project.media_count, "number")
    EXPECT_TYPE(response.project.downloads, "number")
    EXPECT_TYPE(response.project.downloads_recent, "number")
    EXPECT_TYPE(response.project.views, "number")
    EXPECT_TYPE(response.project.views_recent, "number")
    EXPECT_TYPE(response.project.visible, "boolean")

    -- Project info: All below values can be nil, but our test project will have all values
    EXPECT_TYPE(response.project.description, "string")
    EXPECT_TYPE(response.project.description_short, "string")
    EXPECT_TYPE(response.project.description_markdown, "string")
    EXPECT_TYPE(response.project.install_command, "string")
    EXPECT_TYPE(response.project.download_url, "string")
    EXPECT_TYPE(response.project.target_file, "string")
    EXPECT_TYPE(response.project.repository, "string")
  end)


  "Info argument expectations" (function()
    EXPECT_THROWS(pine_api.project.info)
    EXPECT_THROWS(pine_api.project.info, "some string")
    EXPECT_THROWS(pine_api.project.info, {})
    EXPECT_THROWS(pine_api.project.info, function()end)
    EXPECT_NO_THROW(pine_api.project.info, PINE_TEST_DATA.target_project_id)
  end)


  "Info fails on invalid project ID" (function()
    local ok, response = pine_api.project.info(99999999999)

    if ok then
      END(textutils.serialize(response))
    end

    ASSERT_FALSE(ok)
    ASSERT_TYPE(response, "string")
    PASS(response)
  end)


  "Comments have correct data" (function()
    -- We need to get the owner ID of the project so we can test the comments
    -- (in case other people commented on the project for some reason)
    local ok, response = pine_api.project.info(PINE_TEST_DATA.target_project_id)
    if not ok then
      END("Failed to get project info: " .. response)
    end
    ASSERT_TYPE(response, "table")
    ASSERT_TYPE(response.project, "table")
    ASSERT_TYPE(response.project.owner_discord, "string")
    local discord = response.project.owner_discord

    -- Get the comments list.
    local ok, response = pine_api.project.comments(PINE_TEST_DATA.target_project_id)
    if not ok then
      END("Failed to get project comments: " .. response)
    end
    ASSERT_TRUE(response.success)
    ASSERT_TYPE(response, "table")
    ASSERT_TYPE(response.comments, "table")

    local base_comment_id, response_reply_id

    -- Check the comments list for our predefined comments.
    for _, comment in ipairs(response.comments) do
      ASSERT_TYPE(comment, "table")
      EXPECT_TYPE(comment.id, "number")
      EXPECT_TYPE(comment.user_discord, "string")
      EXPECT_TYPE(comment.user_name, "string")
      EXPECT_TYPE(comment.body, "string")
      EXPECT_TYPE(comment.timestamp, "number")
      EXPECT_TYPE(comment.reply_id, "number", "nil")
      EXPECT_EQ(comment.project_id, PINE_TEST_DATA.target_project_id)

      if PINE_TEST_DATA.comments[comment.body] == "base" then
        base_comment_id = comment.id
      elseif PINE_TEST_DATA.comments[comment.body] == "reply" then
        response_reply_id = comment.reply_id
      end
    end

    -- Check if the comments are as expected.
    EXPECT_TYPE(base_comment_id, "number")
    EXPECT_TYPE(response_reply_id, "number")
    EXPECT_EQ(response_reply_id, base_comment_id)
  end)


  "Comments argument expectations" (function()
    EXPECT_THROWS(pine_api.project.comments)
    EXPECT_THROWS(pine_api.project.comments, "some string")
    EXPECT_THROWS(pine_api.project.comments, {})
    EXPECT_THROWS(pine_api.project.comments, function()end)
    EXPECT_NO_THROW(pine_api.project.comments, PINE_TEST_DATA.target_project_id)
  end)


  "Comments fails on invalid project ID" (function()
    local ok, response = pine_api.project.comments(99999999999)

    if ok then
      END(textutils.serialize(response))
    end

    ASSERT_FALSE(ok)
    ASSERT_TYPE(response, "string")
    PASS(response)
  end)


  "Changelog has correct data" (function()
    local ok, response = pine_api.project.changelog(PINE_TEST_DATA.target_project_id)
    if not ok then
      END("Failed to get project changelog: " .. response)
    end
    ASSERT_TRUE(response.success)
    ASSERT_TYPE(response, "table")
    ASSERT_TYPE(response.changelog, "table")

    EXPECT_TYPE(response.changelog.project_id, "number")
    EXPECT_EQ(response.changelog.project_id, PINE_TEST_DATA.target_project_id)
    EXPECT_TYPE(response.changelog.timestamp, "number")
    EXPECT_TYPE(response.changelog.body, "string")
  end)


  "Changelog argument expectations" (function()
    EXPECT_THROWS(pine_api.project.changelog)
    EXPECT_THROWS(pine_api.project.changelog, "some string")
    EXPECT_THROWS(pine_api.project.changelog, {})
    EXPECT_THROWS(pine_api.project.changelog, function()end)
    EXPECT_NO_THROW(pine_api.project.changelog, PINE_TEST_DATA.target_project_id)
  end)


  "Changelog fails on invalid project ID" (function()
    local ok, response = pine_api.project.changelog(99999999999)

    if ok then
      END(textutils.serialize(response))
    end

    ASSERT_FALSE(ok)
    ASSERT_TYPE(response, "string")
    PASS(response)
  end)


  "Changelogs has correct data" (function()
    local ok, response = pine_api.project.changelogs(PINE_TEST_DATA.target_project_id)
    if not ok then
      END("Failed to get project changelogs: " .. response)
    end
    ASSERT_TRUE(response.success)
    ASSERT_TYPE(response, "table")
    ASSERT_TYPE(response.changelogs, "table")

    for _, changelog in ipairs(response.changelogs) do
      ASSERT_TYPE(changelog, "table")
      EXPECT_TYPE(changelog.project_id, "number")
      EXPECT_EQ(changelog.project_id, PINE_TEST_DATA.target_project_id)
      EXPECT_TYPE(changelog.timestamp, "number")
      EXPECT_TYPE(changelog.body, "string")
    end
  end)


  "Changelogs argument expectations" (function()
    EXPECT_THROWS(pine_api.project.changelogs)
    EXPECT_THROWS(pine_api.project.changelogs, "some string")
    EXPECT_THROWS(pine_api.project.changelogs, {})
    EXPECT_THROWS(pine_api.project.changelogs, function()end)
    EXPECT_NO_THROW(pine_api.project.changelogs, PINE_TEST_DATA.target_project_id)
  end)


  "Changelogs fails on invalid project ID" (function()
    local ok, response = pine_api.project.changelogs(99999999999)

    if ok then
      END(textutils.serialize(response))
    end

    ASSERT_FALSE(ok)
    ASSERT_TYPE(response, "string")
    PASS(response)
  end)