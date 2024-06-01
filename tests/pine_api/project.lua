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
    ASSERT_FALSE(ok)
    ASSERT_TYPE(response, "string")
  end)
  "GET comments" (function()
    PASS("Not yet implemented")
  end)
  "GET changelog" (function()
    PASS("Not yet implemented")
  end)
  "GET changelogs" (function()
    PASS("Not yet implemented")
  end)