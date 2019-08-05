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
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)
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


function get_screen_and_tag(name)
  for s in screen do
    for i,tag in ipairs(s.tags) do
        if name == tag.name then
            return s, tag
        end
    end
  end
end

s, t = get_screen_and_tag("JXMiner")
awful.spawn("jxdashboard", {
	tag = t,
	screen = s,
})

s, t = get_screen_and_tag("Terminal")
awful.spawn("xterm", {
	tag = t,
	screen = s
})
