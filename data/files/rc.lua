-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")


-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
    awful.layout.suit.spiral
}
-- }}}


-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
    -- Each screen has its own tag table.
    -- tags[s] = awful.tag({ "JXMiner", "Terminal" }, s, layouts[1])
    tags[s] = awful.tag.add("JXMiner", {
      gap = 0,
      screen = s,
      layout = layouts[1],
      selected = true,
    })
    tags[s] = awful.tag.add("Terminal", {
      gap = 2,
      screen = s,
      layout = layouts[1]
    })
end

-- }}}

-- {{{ Wibox

-- Create a wibox for each screen and add it
mywibox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
        awful.button({ }, 1, awful.tag.viewonly),
        awful.button({ }, 3, awful.tag.viewtoggle)
)

for s = 1, screen.count() do
    btn = awful.util.table.join(
        awful.button({ }, 1, awful.tag.viewonly ),
        awful.button({ }, 3, awful.tag.viewtoggle),
        awful.button({ }, 1, function(t) spawn_program(t.index) end)
    )

    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, btn)
    mywibox[s] = awful.wibox({ position = "bottom", screen = s, height = 32, bg = "#162229", spacing = 10 })
    mywibox[s]:set_widget(mytaglist[s])
end
-- }}}

awful.rules.rules = {
   { rule = { class = "XTerm" },
       properties = { tag = "Terminal", screen = 1 }},
   { rule = { class = "jxdashboard" },
       properties = { tag = "JXMiner", screen = 1 }},
}


-- Function callback for spawning a single registered program by screen id and tags
function spawn_program(s)
    if s == 1 then
       tg = "JXMiner"
       cmd = "jxdashboard"
    end

    if s == 2 then
       tg = "Terminal"
       cmd = "xterm"
    end

    if tg then
       x, t = get_screen_and_tag(tg)
       run_if_not_running(cmd, {
          tag = t,
          screen = x,
       });
    end
end

-- Function for checking if current program is running or not
function run_if_not_running(program, arguments)
   awful.spawn.easy_async(
      "pgrep " .. program,
      function(stdout, stderr, reason, exit_code)
         if exit_code ~= 0 then
            awful.spawn(program, arguments)
         end
   end)
end


-- Extract the screen id and tag id based on tag name
function get_screen_and_tag(name)
  for s in screen do
    for i,tag in ipairs(s.tags) do
        if name == tag.name then
            return s, tag
        end
    end
  end
end


-- Initial booting, spawn dashboard
spawn_program(1)
