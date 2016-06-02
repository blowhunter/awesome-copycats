--[[
                                      
     Multicolor Awesome WM config 2.0 
     github.com/copycat-killer        
                            
	 modify: blowhunter/wsyi.tk
--]]

-- {{{ 必须的库文件(Required libraries)
local gears     = require("gears")
local awful     = require("awful")
awful.rules     = require("awful.rules")
                  require("awful.autofocus")
local wibox     = require("wibox")
local beautiful = require("beautiful")
local naughty   = require("naughty")
local drop      = require("scratchdrop")
local lain      = require("lain")
local cjson		= require("cjson")				--解析json数据，天气调用
-- }}}

-- A debugging func
n = function(n) naughty.notify{title="消息", text=tostring(n)} end
last_bat_warning = 0

--[[ {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "额，启动时出现错误！",		--"Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true

        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "额，出现一个错误！",		--"Oops, an error happened!",
                         text = err })
        in_error = false
    end)
end
-- }}}--]]

-- {{{ 自启动应用(Autostart applications)
function run_once(cmd)
  findme = cmd
  firstspace = cmd:find(" ")
  if firstspace then
     findme = cmd:sub(0, firstspace-1)
  end
  awful.util.spawn_with_shell("pgrep -u $USER -x " .. findme .. " > /dev/null || (" .. cmd .. ")")
end

run_once("urxvtd")
run_once("unclutter")
run_once("xcompmgr")					--终端透明支持
run_once("synclient TouchpadOff=1")		--开机设置触控板状态，默认锁定触控板(1);开启触控板(0)
run_once("xset b off")					--关闭响铃
run_once(awful.util.getdir("config") .. "/utils/QQWry.py -u")	--更新QQ的IP位置库
-- }}}

-- {{{ 变量定义(Variable definitions)
-- 本地化(localization)
os.setlocale(os.getenv("LANG"))

-- 初始化beautiful(beautiful init)
beautiful.init(os.getenv("HOME") .. "/.config/awesome/themes/multicolor/theme.lua")

-- 默认(common)
modkey     = "Mod4"
altkey     = "Mod1"
terminal   = "xfce4-terminal" or "gnome-terminal" or "xterm"
editor     = os.getenv("EDITOR") or "gedit" or "nano"  or "vi"
editor_cmd = terminal .. " -e " .. editor

-- 用户定义(user defined）
browser    = "firefox"
browser2   = "iron"
gui_editor = "gvim"
graphics   = "gimp"
mail       = terminal .. " -e mutt "

local layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.fair.horizontal,
    awful.layout.suit.spiral,
    awful.layout.suit.spiral.dwindle,
    awful.layout.suit.max,
}
-- }}}

-- {{{ 标签(Tags)
tags = {
   names = { "1网络", "2终端", "3文档", "4多媒体", "5文件", "6其他", "7聊天", "8开发" },
   layout = { layouts[1], layouts[4], layouts[4], layouts[1], layouts[7], layouts[1], layouts[3], layouts[1] }
}
for s = 1, screen.count() do
-- 每个屏幕拥有自己的标签表(Each screen has its own tag table.)
   tags[s] = awful.tag(tags.names, s, tags.layout)
end
-- }}}

-- {{{ 墙纸(Wallpaper)
if beautiful.wallpaper then
    for s = 1, screen.count() do
        gears.wallpaper.maximized(beautiful.wallpaper, s, true)
    end
end
-- }}}

-- {{{ 桌面菜单 Freedesktop Menu
mymainmenu = awful.menu.new({ items = require("menugen").build_menu(),
                              theme = { height = 24, width = 145 }})
-- }}}

-- {{{ Wibox
markup     = lain.util.markup

--{{{ 文字时钟(Textclock)
clockicon = wibox.widget.imagebox(beautiful.widget_clock)
mytextclock = awful.widget.textclock(markup("#7788af", "%Y年%m月%d日 %A") .. markup("#de5e1e", " %I:%M:%S %p"), 1) --这里的1是每秒刷新显示
---}}}

--{{{ 日历(CCalendar) >>>定义开始(the start of define)   -----《中国日历(ChinaCalendar)》
--请确认已安装ccal
local calendar_offset = { cur_offset = 0 }	--定义当前日期偏移

function calendar_hide()		---->>定义隐藏日历信息
	if cal_notification ~= nil then
		naughty.destroy(cal_notification)
		cal_notification = nil
		return
	end
	calendar_offset.cur_offset = 0	--鼠标移开后重置当前日期偏移值	
end  --<<定义结束

function calendar_show(t_out, offset)					---->>定义显示日历信息  --t_out变量用来控制快捷键显示日历的时间
	calendar_hide()														---清除此前正在显示的日历信息
	
	local offset = offset or 0											---取得偏移值
	local month = tonumber(os.date('%m'))
	local year = tonumber(os.date('%Y'))
	calendar_offset.cur_offset = calendar_offset.cur_offset + offset	---统计查询日期偏移值
	month = month + calendar_offset.cur_offset							---取得偏移的月份值

	if month > 12 then												------
	   month = month % 12												--	
	   year = year + 1													--
	   if month <= 0 then												--
		   month = 12												 	--	
	   end														    	--	
	elseif month < 1 then												 --取得实际查询年月
	   month = month + 12												--
	   year = year - 1													--	
	   if month <= 0 then												--
		   month = 1													--
	   end																--	
	end																------
	
	--根据实际查询年月取得日历项
	local f = io.popen("ccal -u "..month.. " " ..year.. 
				"|sed  \"s/\x1b\\[7m/<span color=\\'#a42d00\\' background=\\'#99ff99\\'><b>/g\" |sed \"s/\x1b\\[0m/<\\/b><\\/span>/g\"")				--如果当前月份高亮今日日期
	local getCalendar = "<tt><span font='文泉驿等宽正黑 12'><b>"		--建议使用<<文泉驿等宽正黑>>，最好用等宽，轻微偏移。其他字体偏移严重 
							.. f:read() .. "</b>\n<span background='#000'>"
							.. f:read() .. "</span>\n"
							.. f:read("*a"):gsub("\n*$","") 
							.. "</span></tt>" 							----格式化日期
	f:close()

	cal_notification = naughty.notify({									---定义日历界面
		text 		= getCalendar,
		position 	= "top_right",
		fg			= "#ffeeee",
		bg 			= "#003333",
		timeout		= t_out
	})
end		----定义结束<<

function calendar_attach(widget)			---->>定义日历触发和按钮功能
	widget:connect_signal("mouse::enter", function () calendar_show(0) end)
	widget:connect_signal("mouse::leave", function () calendar_hide() end)
	widget:buttons(awful.util.table.join( awful.button({ }, 1, function ()
                                              calendar_show(0, -1) end),
                                          awful.button({ }, 3, function ()
                                              calendar_show(0, 1) end),
                                          awful.button({ }, 4, function ()
                                              calendar_show(0, -1) end),
                                          awful.button({ }, 5, function ()
                                              calendar_show(0, 1) end)))
end		----定义结束<<

calendar_attach(mytextclock)
-- 日历(CCalendar) 定义结束(END)<<<}}}

--{{{ 天气(Weather)		>>>定义开始(the start of define) 《中国天气(ChinaWeather)》
---15年6月25：更新写入文件，加快读取速度，减少网络访问。添加更新时间。以及其他优化
local weather = { 
	city = "白城", 			--如果无法自动获取城市信息，请手动设置需要显示城市的名称
	timeout = 1800,						--设置更新时间 单位：秒(s)
	data_dir = os.getenv("HOME").. "/.config/awesome/weather/data",
	--利用依云的纯真IP脚本实现根据IP获取所在地信息。
	iptool = os.getenv("HOME").. "/.config/awesome/utils/QQWry.py"		
}
function w_getIP()				-->获取目前的IP地址
	local f = io.popen("curl http://members.3322.org/dyndns/getip")
	local ip = f:read()
	f:close()
	return ip
end
function w_get_city()			-->取得IP所在的城市名称，失效时请手动设置-> city
	if weather.city == nil then								---修改判断，提升脚本效率，避免重复获取城市信息
		if w_getIP() == nil then
			weather_erro(1)
		else
			local f = io.popen(weather.iptool.. " " ..w_getIP().. "|sed \"s/\\(.*\\)省\\(.*\\)市\\(.*\\)/\\2/g\"")
			local location = f:read()
			f:close()
			weather.city = location
		end
	end
end

function w_get_data(city)				-->>>定义获取天气数据函数(START)
	if city == nil then									
		weather_erro(1)
		return
	else
		local f = io.popen("curl -H \"Accept-Encoding: gzip\" http://wthrcdn.etouch.cn/weather_mini?city=" ..city.. "| gunzip")	
		local str = f:read("*all")
		f:close()
		if str ~= "" then
			local obj = cjson.decode(str)		----解析json数据
			obj = obj.data
			if obj == nil then
				weather_erro(2)
				return
			else
				local city = obj.city				--获取城市名称
				local cur_tem = obj.wendu			--获取当前气温
				today = obj.forecast[1]
				local today_weather = today.type		--获取当前天气状态
				local update_time = "<b>更新时间: </b><span color='#22ddb8'>" ..os.date("%X").. "</span>"

				local date, date_weather, tem_low, tem_high= {}, {}, {}, {}
				for i=1,5 do												--获取预报天气数据
					dates = obj.forecast[i]
					date[i] = string.format("%14s", dates.date)
					date_weather[i] = string.format("%-9s", dates.type)
					tem_low[i] = string.sub(dates.low, 8)
					tem_high[i] = string.sub(dates.high, 8)
				end
	
				local cur_weather = "当前：" ..today_weather.. " " ..cur_tem.. "℃"							--格式化当前天气数据
				local dates_weather = string.gsub(string.format("<span font='文泉驿微米黑 14' foreground='#c42d20'><b>当前城市： %s</b></span>\n%s\n<span font='文泉驿等宽正黑 13'>%14s<span color='#de5e1e'>(今天)</span>%12s  %s->%s\n%14s\t  %12s  %s->%s\n%14s\t  %12s  %s->%s\n%14s\t  %12s  %s->%s\n%14s\t  %12s  %s->%s</span>", city, update_time, date[1], date_weather[1], tem_low[1], tem_high[1], date[2], date_weather[2], tem_low[2], tem_high[2], date[3], date_weather[3], tem_low[3], tem_high[3], date[4], date_weather[4], tem_low[4], tem_high[4], date[5], date_weather[5], tem_low[5], tem_high[5]), "   ", "　")																			--格式化天气预报数据
				if not io.open(weather.data_dir.. "/weatherData") then
					os.execute("mkdir -p " ..weather.data_dir)
					f = io.open(weather.data_dir.. "/weatherData", 'w')
				else
					f = io.open(weather.data_dir.. "/weatherData", 'w')
				end
				f:write(today_weather.. "\n" ..cur_weather.. "\n" ..dates_weather)
				f:close()
			end
		end
	end
end		--定义结束<<<(END)
--
function w_get_weather(w_type)
	if not io.open(weather.data_dir.. "/weatherData") then
		w_get_data(weather.city)
		f = io.open(weather.data_dir.. "/weatherData", 'r')
	else
		f = io.open(weather.data_dir.. "/weatherData", 'r')
	end
	
	local today_weather = f:read()
	local cur_weather = f:read()
	local dates_weather = f:read("*a")
	
	if w_type == 1 then
		return cur_weather
	elseif w_type == 2 then
		return dates_weather
	elseif w_type == 3 then
		return today_weather
	else
		return nil
	end
end

function w_get_icon()														---定义获取弹框天气图片信息>>>>
	local png_path = nil
	local hour = tonumber(os.date("%H"))									--获取当前的小时
	local png_dir = os.getenv("HOME").. "/.config/awesome/icons/weather/"	--设置图片路径
	
	local city = weather.city
	if hour >= 6 and hour <= 18 
	then
		png_path = png_dir.."白天-"..w_get_weather(3)..".png"
		return png_path
	else
		png_path = png_dir.."夜间-"..w_get_weather(3)..".png"
		return png_path
	end
end	--获取弹框天气图片结束<<<<

function w_forecast_hide()		--->>>定义隐藏弹框显示信息
	if w_notification then
		naughty.destroy(w_notification)
		w_notification = nil
	end
	if w_erro then
		naughty.destroy(w_erro)
	end
end		----定义结束<<<<

function w_forecast_show(t_out)				---->>>定义天气预报显示信息
	w_forecast_hide()

	if weather.city ~= nil and w_get_weather(2) ~= nil then
		w_notification = naughty.notify({									--->>定义天气预报弹框界面
			text 		= w_get_weather(2),
			position 	= "top_right",
			fg			= "#ffeeee",
			bg 			= "#003333",
			icon		= w_get_icon(),
			timeout		= t_out
		})
		return	
	elseif weather.city == nil then						--城市信息获取失败处理								
		weather_erro(2)
		return	
	end	
end			----定义结束<<<<

function weather_attach(widget)			---->>定义天气预报（4天）触发
	widget:connect_signal("mouse::enter", function () w_forecast_show(0) end)
	widget:connect_signal("mouse::leave", function () w_forecast_hide() end)
end		----定义结束<<

function update_weather()				--->>定义更新天气信息
	w_get_city()
	w_get_data(weather.city)
	if not weather.city then 										--城市信息获取失败处理
		weather_erro(2)
		return
	elseif w_get_weather(1) ~= nil then
		weather_text = "<span color='#eca4c4'>" ..w_get_weather(1).. "</span>" 
		weatherwidget:set_markup(weather_text)
	end
end		---定义更新天气信息结束<<

function weather_erro(code)			-->>定义错误处理 
	if code == 1 then										-->获取天气信息失败或者无网络链接处理
		weatherwidget:set_markup("<span color='#D71818'>N/A！</span>")	
		w_erro = naughty.notify({
			position	= "top_left",
			title 		= "天气提醒:",	
			text 		= "获取天气信息失败，请查看网络链接！",
			font		= "文泉驿微米黑 13",
			fg			= "#FF5510",
			bg			= "#2F4F4F",
			timeout 	= 10
		})
	elseif code == 2 then									-->获取城市信息失败处理
		weatherwidget:set_markup("<span color='#D71818'>N/A! </span>")
		w_erro = naughty.notify({ 								--弹出提示信息
 			position	= "top_left",
			title 		= '天气设置提醒：',
			text 		= "城市获取失败!!<br/>请在rc.lua中设置->城市名称(city值)！",
			font		= "文泉驿微米黑 13",
			fg			= "#FF5510",
			bg			= "#2F4F4F",
			timeout 	= 10 
		})
	elseif code == 3 then									-->获取图片失败处理
		w_erro = naughty.notify({
	 		position	= "top_left",
			title 		= "获取图片失败：",	
			text 		= "获取图片失败！",
			font		= "文泉驿微米黑 13",
			fg			= "#FF5510",
			bg			= "#2F4F4F",
			timeout 	= 10
		})
	end
end		--定义错误处理结束<<	

weathericon = wibox.widget.imagebox(beautiful.widget_weather)	--天气图标定义
weatherwidget = wibox.widget.textbox()						--天气插件定义
update_weather()

w_clock = timer({ timeout = weather.timeout })			--更新定时器
w_clock:connect_signal("timeout", update_weather)
w_clock:start()
weather_attach(weatherwidget)							--天气预报（4天）触发
weatherwidget:buttons(awful.util.table.join( awful.button({ }, 1, function () 
												update_weather() 
												w_forecast_show(0) end))) --鼠标左键点击天气更新信息
----天气(weather) 定义结束(END)<<<}}}

-- / fs
fsicon = wibox.widget.imagebox(beautiful.widget_fs)
fswidget = lain.widgets.fs({
    settings  = function()
        widget:set_markup(markup("#80d9d8", fs_now.used .. "% "))
    end
})

--[[ Mail IMAP check
-- commented because it needs to be set before use
mailicon = wibox.widget.imagebox()
mailicon:buttons(awful.util.table.join(awful.button({ }, 1, function () awful.util.spawn(mail) end)))
mailwidget = lain.widgets.imap({
    timeout  = 180,
    server   = "server",
    mail     = "mail",
    password = "keyring get mail",
    settings = function()
        if mailcount > 0 then
            mailicon:set_image(beautiful.widget_mail)
            widget:set_markup(markup("#cccccc", mailcount .. " "))
        else
            widget:set_text("")
            mailicon:set_image(nil)
        end
    end
})
]]

-- CPU
cpuicon = wibox.widget.imagebox()
cpuicon:set_image(beautiful.widget_cpu)
cpuwidget = lain.widgets.cpu({
    settings = function()
        widget:set_markup(markup("#e33a6e", cpu_now.usage .. "% "))
    end
})

-- 核心温度(Coretemp)
tempicon = wibox.widget.imagebox(beautiful.widget_temp)
tempwidget = lain.widgets.temp({
    settings = function()
        widget:set_markup(markup("#f1af5f", coretemp_now .. "°C "), 30)
    end
})

--{{{  电池(Battery)	>>>定义开始(the start of define)  
-- 微量修改 自 依云 网址：site: https://github.com/lilydjwg/myawesomerc
-- Modify from 依云 site: https://github.com/lilydjwg/myawesomerc
--baticon = wibox.widget.imagebox(beautiful.widget_batt)

--battery indicator, using the acpi command ---请确认已安装apci
local battery_state = {
    Unknown     = '<span color="#CDCDCD">↯',
    Idle        = '<span color="#CDCDCD">↯',
    Charging    = '<span color="green">+',
    Discharging = '<span color="#1e69ff">–',
}
function update_batwidget()
    local pipe = io.popen('acpi')
    if not pipe then
        batwidget:set_markup('<span color="red">ERR</span>')
        return
    end

--[[
Battery 0: Unknown, 97%
Battery 1: Unknown, 99%
Battery 0: Discharging, 97%, discharging at zero rate - will never fully discharge.
Battery 1: Unknown, 99%
Battery 0: Discharging, 96%, 02:25:51 remaining
Battery 1: Unknown, 99%
]]
    local bats = {}
    local max_percent = 0
    local max_percent_index = 0
    local index = 0
    for line in pipe:lines() do
        index = index + 1
        local state, percent, rest = line:match('^Battery %d+:%s+([^,]+), ([0-9.]+)%%(.*)')
        local t
        if rest ~= '' then
            t = rest:match('[1-9]*%d:%d+')
        end
        if not t then t = '' end
        percent = tonumber(percent)
        if percent > max_percent then
            max_percent = percent
            max_percent_index = index
        end
        table.insert(bats, {state, percent, t})
    end
    pipe:close()

    if index == 0 then
        batwidget:set_markup('<span color="red">ERR</span>')
        return
    end

    if max_percent <= 30 then
        if bats[max_percent_index][1] == 'Discharging' then
            local t = os.time()
            if t - last_bat_warning > 60 * 5 then
                naughty.notify{
                    preset = naughty.config.presets.critical,
                    title = "电量警报",
                    text = '电池电量只剩下 ' .. max_percent .. '% 了！',
                }
                last_bat_warning = t
            end
            if max_percent <= 10 and not dont_hibernate then
                awful.util.spawn("systemctl hibernate")
            end
        end
    end
    local text = ' '
    for i, v in ipairs(bats) do
        local percent = v[2]
        if percent <= 30 then
            percent = '<span color="red">' .. percent .. '</span>'
        end
        text = text .. (battery_state[v[1]] or battery_state.Unknown) .. percent .. '%'
               .. (v[3] ~= '' and (' ' .. v[3]) or '') .. '</span>'
        if i ~= #bats then
            text = text .. ' '
        end
    end
    batwidget:set_markup(text)
end
batwidget = wibox.widget.textbox('↯??%')
update_batwidget()
bat_clock = timer({ timeout = 5 })
bat_clock:connect_signal("timeout", update_batwidget)
bat_clock:start()
-- 电池定义结束(the end of battery define)<<<}}}

-- ALSA音量控制(ALSA volume)
volicon = wibox.widget.imagebox(beautiful.widget_vol)
volumewidget = lain.widgets.alsa({
    settings = function()
        if volume_now.status == "off" then
            volume_now.level = volume_now.level .. "<span color='red'>M</span>"
        end

        widget:set_markup(markup("#7493d2", volume_now.level .. "% "))
    end
})

-- 网络(Net)
netdownicon = wibox.widget.imagebox(beautiful.widget_netdown)
--netdownicon.align = "middle"
netdowninfo = wibox.widget.textbox()
netupicon = wibox.widget.imagebox(beautiful.widget_netup)
--netupicon.align = "middle"
netupinfo = lain.widgets.net({
    settings = function()
        if iface ~= "network off" and
           string.match(weatherwidget._layout.text, "N/A")
        then
            update_weather()
        end

        widget:set_markup(markup("#51a0eb", net_now.sent .. "k"), 0.5)
        netdowninfo:set_markup(markup("#87af5f", net_now.received .. "k"), 0.5)
    end
})
--{{{ 触摸板（TouchpadToggle）>>>定义开始
touchpadwidget = wibox.widget.imagebox()

function touchpadctl(mode, widget)
	local f = io.popen("synclient -l | grep -c 'TouchpadOff.*=.*1'")
	local status = f:read("*n")
	f:close()
	
	if mode == "update" then
		if status == 1 then
			widget:set_image(beautiful.widget_touchpadOff)	--请确认对应theme文件中已经添加了图片的路径和名称
		else
			widget:set_image(beautiful.widget_touchpadOn)
		end
	else
        if status == 1 then									--如果当前触控板为关闭
        	os.execute("synclient TouchpadOff=0") 			--执行开启触控板命令
        	widget:set_image(beautiful.widget_touchpadOn)	--更改wibox图标
			naughty.notify({ 								--弹出提示信息
	 			position	= "top_left",
				title 		= "触摸板信息:",	
				text 		= "触摸板开启！",
				font		= "文泉驿微米黑 13",
				fg			= "#FF5510",
				bg			= "#2F4F4F",
				timeout 	= 5 })
        else												--如果当前触控板为开启
         	os.execute("synclient TouchpadOff=1")			--执行关闭触控板命令
         	widget:set_image(beautiful.widget_touchpadOff)	--更改wibox图标
			naughty.notify({ 								--弹出提示信息
	 			position	= "top_left",
				title 		= "触摸板信息:",
				text 		= "触摸板关闭！",
				font		= "文泉驿微米黑 13",
				fg			= "#FF5510",
				bg			= "#2F4F4F",
				timeout 	= 5 })
        end	
    end	
end	
--[[touchpad_clock = timer({ timeout = 1000 })
touchpad_clock:connect_signal("timeout", function () touchpadctl("update", touchpadwidget) end)
touchpad_clock:start()--]]

touchpadctl("update", touchpadwidget)  
-- 触摸板(TouchpadToggle)	定义结束<<<}}}

-- 内存(MEM)
memicon = wibox.widget.imagebox(beautiful.widget_mem)
memwidget = lain.widgets.mem({
    settings = function()
        widget:set_markup(markup("#e0da37", mem_now.used .. "M "))
    end
})

-- MPD
mpdicon = wibox.widget.imagebox()
mpdwidget = lain.widgets.mpd({
    settings = function()
        mpd_notification_preset = {
            text = string.format("%s [%s] - %s\n%s", mpd_now.artist,
                   mpd_now.album, mpd_now.date, mpd_now.title)
        }

        if mpd_now.state == "play" then
            artist = mpd_now.artist .. " > "
            title  = mpd_now.title .. " "
            mpdicon:set_image(beautiful.widget_note_on)
        elseif mpd_now.state == "pause" then
            artist = "mpd "
            title  = "paused "
        else
            artist = ""
            title  = ""
            mpdicon:set_image(nil)
        end
        widget:set_markup(markup("#e54c62", artist) .. markup("#b2b2b2", title))
    end
})

-- Spacer
spacer = wibox.widget.textbox(" ")

-- }}}

-- {{{ Layout

-- 为每个屏幕创建并添加消息盒子 Create a wibox for each screen and add it
mywibox = {}
mybottomwibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
                    awful.button({ }, 1, awful.tag.viewonly),
                    awful.button({ modkey }, 1, awful.client.movetotag),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, awful.client.toggletag),
                    awful.button({ }, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
                    awful.button({ }, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end)
                    )
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  --没有这个，接下来的 :isvisible()没有意义
												  --Without this, the following :isvisible() makes no sense
                                                  c.minimized = false
                                                  if not c:isvisible() then
                                                      awful.tag.viewonly(c:tags()[1])
                                                  end
                                                  -- This will also un-minimize
                                                  -- the client, if needed
                                                  client.focus = c
                                                  c:raise()
                                              end
                                          end),
                     awful.button({ }, 3, function ()
                                              if instance then
                                                  instance:hide()
                                                  instance = nil
                                              else
                                                  instance = awful.menu.clients({ width=250 })
                                              end
                                          end),
                     awful.button({ }, 4, function ()
                                              awful.client.focus.byidx(1)
                                              if client.focus then client.focus:raise() end
                                          end),
                     awful.button({ }, 5, function ()
                                              awful.client.focus.byidx(-1)
                                              if client.focus then client.focus:raise() end
                                          end))

for s = 1, screen.count() do

    -- Create a promptbox for each screen
    mypromptbox[s] = awful.widget.prompt()


    -- We need one layoutbox per screen.
    mylayoutbox[s] = awful.widget.layoutbox(s)
    mylayoutbox[s]:buttons(awful.util.table.join(
                            awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
                            awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
                            awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
                            awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))

    -- Create a taglist widget
    mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

    -- Create a tasklist widget
    mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

    -- Create the upper wibox
    mywibox[s] = awful.wibox({ position = "top", screen = s, height = 20 })
    --border_width = 0, height =  20 })

    -- Widgets that are aligned to the upper left
    local left_layout = wibox.layout.fixed.horizontal()
    left_layout:add(mytaglist[s])
    left_layout:add(mypromptbox[s])
    left_layout:add(mpdicon)
    left_layout:add(mpdwidget)

    -- Widgets that are aligned to the upper right
    local right_layout = wibox.layout.fixed.horizontal()
    if s == 1 then right_layout:add(wibox.widget.systray()) end
    --right_layout:add(mailicon)
    --right_layout:add(mailwidget)
    right_layout:add(touchpadwidget)
    right_layout:add(netdownicon)
    right_layout:add(netdowninfo)
    right_layout:add(netupicon)
    right_layout:add(netupinfo)
    right_layout:add(volicon)
    right_layout:add(volumewidget)
    right_layout:add(memicon)
    right_layout:add(memwidget)
    right_layout:add(cpuicon)
    right_layout:add(cpuwidget)
    right_layout:add(tempicon)
    right_layout:add(tempwidget)
    right_layout:add(fsicon)
    right_layout:add(fswidget)
    right_layout:add(weathericon)
    right_layout:add(weatherwidget)
--    right_layout:add(baticon)
    right_layout:add(batwidget)
    right_layout:add(clockicon)
    right_layout:add(mytextclock)

    -- Now bring it all together (with the tasklist in the middle)
    local layout = wibox.layout.align.horizontal()
    layout:set_left(left_layout)
    --layout:set_middle(mytasklist[s])
    layout:set_right(right_layout)

    mywibox[s]:set_widget(layout)

    -- Create the bottom wibox
    mybottomwibox[s] = awful.wibox({ position = "bottom", screen = s, border_width = 0, height = 20 })
    --mybottomwibox[s].visible = false

    -- Widgets that are aligned to the bottom left
    bottom_left_layout = wibox.layout.fixed.horizontal()

    -- Widgets that are aligned to the bottom right
    bottom_right_layout = wibox.layout.fixed.horizontal()
    bottom_right_layout:add(mylayoutbox[s])

    -- Now bring it all together (with the tasklist in the middle)
    bottom_layout = wibox.layout.align.horizontal()
    bottom_layout:set_left(bottom_left_layout)
    bottom_layout:set_middle(mytasklist[s])
    bottom_layout:set_right(bottom_right_layout)
    mybottomwibox[s]:set_widget(bottom_layout)
end
-- }}}

-- {{{ 鼠标绑定 Mouse Bindings
root.buttons(awful.util.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext),   --查看下一个标签
    awful.button({ }, 5, awful.tag.viewprev)    --查看上一个标签
))
-- }}}

-- {{{  按键绑定 Key Bindings
globalkeys = awful.util.table.join(
    -- 屏幕截图 Take a screenshot
    -- https://github.com/copycat-killer/dots/blob/master/bin/screenshot
    awful.key({ altkey }, "p", function() awful.util.spawn("shutter -s") end),		--shutter开启选择截图
	awful.key({ }, "Print", function () awful.util.spawn("scrot -e 'mv $f ~/图片/屏幕截图/ 2>/dev/null'") end),	--全屏截图，并保存到

	-- 触摸板开启/关闭 TouchpadToggle
	awful.key({ }, "XF86TouchpadToggle", function () touchpadctl("change", touchpadwidget) end),
	
	-- 关闭显示屏幕 Turn off screen
	awful.key({ altkey }, "F7",function () os.execute("sleep 1 && xset dpms force off") end),

	-- 显示器亮度控制 Monitor Brightness Control
	awful.key({ }, "XF86MonBrightnessUp", function () os.execute("xbacklight -inc 10") end), --增加屏幕亮度 Increase the brightness
	awful.key({ }, "XF86MonBrightnessDown", function () os.execute("xbacklight -dec 10") end), --降低屏幕亮度 Decrease the brightness

    -- 切换标签 Tag browsing
    awful.key({ modkey }, "Left",   awful.tag.viewprev       ),
    awful.key({ modkey }, "Right",  awful.tag.viewnext       ),
    awful.key({ modkey }, "Escape", awful.tag.history.restore),

    -- 切换非空标签 Non-empty tag browsing
    awful.key({ altkey }, "Left", function () lain.util.tag_view_nonempty(-1) end),
    awful.key({ altkey }, "Right", function () lain.util.tag_view_nonempty(1) end),

    -- 当前焦点窗口 Default client focus 
    awful.key({ altkey }, "k",
        function ()
            awful.client.focus.byidx( 1)
            if client.focus then client.focus:raise() end
        end),
    awful.key({ altkey }, "j",
        function ()
            awful.client.focus.byidx(-1)
            if client.focus then client.focus:raise() end
        end),

    -- 按方向切换焦点窗口 By direction client focus
    awful.key({ modkey }, "j",
        function()
            awful.client.focus.bydirection("down")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "k",
        function()
            awful.client.focus.bydirection("up")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "h",
        function()
            awful.client.focus.bydirection("left")
            if client.focus then client.focus:raise() end
        end),
    awful.key({ modkey }, "l",
        function()
            awful.client.focus.bydirection("right")
            if client.focus then client.focus:raise() end
        end),

    -- 显示菜单项 Show Menu
    awful.key({ modkey }, "w",
        function ()
            mymainmenu:show({ keygrabber = true })
        end),

    -- 显示/隐藏 Wibox Show/Hide Wibox
    awful.key({ modkey }, "b", function ()
        mywibox[mouse.screen].visible = not mywibox[mouse.screen].visible
        mybottomwibox[mouse.screen].visible = not mybottomwibox[mouse.screen].visible
    end),

    -- Layout manipulation
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey,           }, "Tab",
        function ()
            awful.client.focus.history.previous()
            if client.focus then
                client.focus:raise()
            end
        end),
    awful.key({ altkey, "Shift"   }, "l",      function () awful.tag.incmwfact( 0.05)     end),
    awful.key({ altkey, "Shift"   }, "h",      function () awful.tag.incmwfact(-0.05)     end),
    awful.key({ modkey, "Shift"   }, "l",      function () awful.tag.incnmaster(-1)       end),
    awful.key({ modkey, "Shift"   }, "h",      function () awful.tag.incnmaster( 1)       end),
    awful.key({ modkey, "Control" }, "l",      function () awful.tag.incncol(-1)          end),
    awful.key({ modkey, "Control" }, "h",      function () awful.tag.incncol( 1)          end),
    awful.key({ modkey,           }, "space",  function () awful.layout.inc(layouts,  1)  end),
    awful.key({ modkey, "Shift"   }, "space",  function () awful.layout.inc(layouts, -1)  end),
    awful.key({ modkey, "Control" }, "n",      awful.client.restore),

    -- 标准程序 Standard program
    awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),     --启动默认终端
    awful.key({ modkey, "Control" }, "r",      awesome.restart),    --重启awesome
    awful.key({ modkey, "Shift"   }, "q",      awesome.quit),       --退出awesome     （！谨慎使用）

    -- 关闭终端 Dropdown terminal
    awful.key({ modkey,	          }, "z",      function () drop(terminal) end),

    -- 小部件弹出设置 Widgets popups
    awful.key({ altkey,           }, "c",      function () calendar_show(7) end), 				 --显示日历小部件
    awful.key({ altkey,           }, "h",      function () fswidget.show(7) end),                --显示存储小部件
    awful.key({ altkey,           }, "w",      function () w_forecast_show(7) end),              --显示天气小部件

    -- ALSA音频控制 ALSA volume control
    awful.key({ altkey }, "Up",
        function ()
            awful.util.spawn("amixer -q set Master 1%+")
            volumewidget.update()
        end),
    awful.key({ altkey }, "Down",
        function ()
            awful.util.spawn("amixer -q set Master 1%-")
            volumewidget.update()
        end),
    awful.key({ altkey }, "m",
       function ()
            awful.util.spawn("amixer -q set Master playback toggle")
            volumewidget.update()
        end),
    awful.key({ altkey, "Control" }, "m",
        function ()
            awful.util.spawn("amixer -q set Master playback 100%")
            volumewidget.update()
        end),

    -- MPD control
    awful.key({ altkey, "Control" }, "Up",
        function ()
            awful.util.spawn_with_shell("mpc toggle || ncmpc toggle || pms toggle")
            mpdwidget.update()
        end),
    awful.key({ altkey, "Control" }, "Down",
        function ()
            awful.util.spawn_with_shell("mpc stop || ncmpc stop || pms stop")
            mpdwidget.update()
        end),
    awful.key({ altkey, "Control" }, "Left",
        function ()
            awful.util.spawn_with_shell("mpc prev || ncmpc prev || pms prev")
            mpdwidget.update()
        end),
    awful.key({ altkey, "Control" }, "Right",
        function ()
            awful.util.spawn_with_shell("mpc next || ncmpc next || pms next")
            mpdwidget.update()
        end),

    -- 复制到剪贴板 Copy to clipboard
    awful.key({ modkey }, "c", function () os.execute("xsel -p -o | xsel -i -b") end),

    -- 用户程序 User programs
    awful.key({ modkey }, "q", function () awful.util.spawn(browser) end), -- 启动firefox
    awful.key({ modkey }, "i", function () awful.util.spawn(browser2) end),
    awful.key({ modkey }, "s", function () awful.util.spawn(gui_editor) end), --启动gedit
    awful.key({ modkey }, "g", function () awful.util.spawn(graphics) end),   --启动gimp

    -- Prompt
    awful.key({ modkey }, "r", function () mypromptbox[mouse.screen]:run() end),
    awful.key({ modkey }, "x",
              function ()
                  awful.prompt.run({ prompt = "Run Lua code: " },
                  mypromptbox[mouse.screen].widget,
                  awful.util.eval, nil,
                  awful.util.getdir("cache") .. "/history_eval")
              end)
)

clientkeys = awful.util.table.join(
    awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),      --全屏当前焦点窗口
    awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),     --关闭当前焦点窗口
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
    awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
    awful.key({ modkey,           }, "n",
        function (c)
            -- The client currently has the input focus, so it cannot be
            -- minimized, since minimized clients can't have the focus.
            c.minimized = true
        end),
    awful.key({ modkey,           }, "m",
        function (c)
            c.maximized_horizontal = not c.maximized_horizontal
            c.maximized_vertical   = not c.maximized_vertical
        end)
)

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, 9 do
    globalkeys = awful.util.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9,
                  function ()
                        local screen = mouse.screen
                        local tag = awful.tag.gettags(screen)[i]
                        if tag then
                           awful.tag.viewonly(tag)
                        end
                  end),
        awful.key({ modkey, "Control" }, "#" .. i + 9,
                  function ()
                      local screen = mouse.screen
                      local tag = awful.tag.gettags(screen)[i]
                      if tag then
                         awful.tag.viewtoggle(tag)
                      end
                  end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.movetotag(tag)
                     end
                  end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
                  function ()
                      local tag = awful.tag.gettags(client.focus.screen)[i]
                      if client.focus and tag then
                          awful.client.toggletag(tag)
                      end
                  end))
end

clientbuttons = awful.util.table.join(
    awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
    awful.button({ modkey }, 1, awful.mouse.client.move),
    awful.button({ modkey }, 3, awful.mouse.client.resize))

-- 设置按键
root.keys(globalkeys)
-- }}}

-- {{{ 规则
awful.rules.rules = {
    -- 所有设置的端都遵循此规则.
    { rule = { },
      properties = { border_width = beautiful.border_width,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     keys = clientkeys,
                     buttons = clientbuttons,
	                   size_hints_honor = false } },
    { rule = { class = "xterm" },
		properties = { opacity = 0.90 } },

    { rule = { class = "MPlayer" },
        properties = { floating = true } },

    { rule = { class = "Dwb" },
        properties = { tag = tags[1][1] } },

    { rule = { class = "Iron" },
        properties = { tag = tags[1][1] } },

    { rule = { instance = "plugin-container" },
        properties = { tag = tags[1][1] } },

	{ rule = { class = "Gimp" },
    	properties = { tag = tags[1][4] } },
	
	{ rule = { class= "Firefox" },
		properties = { tag = tags[1][1] } },
	
	{ rule = { class= "pidgin" },
		properties = {tag = tags[1][7] } },

    { rule = { class = "Gimp", role = "gimp-image-window" },
        properties = { maximized_horizontal = true,
 			maximized_vertical = true } },
}
-- }}}

-- {{{ 信号
-- signal function to execute when a new client appears.
client.connect_signal("manage", function (c, startup)
    -- enable sloppy focus
    c:connect_signal("mouse::enter", function(c)
        if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
            and awful.client.focus.filter(c) then
            client.focus = c
        end
    end)

    if not startup and not c.size_hints.user_position
       and not c.size_hints.program_position then
        awful.placement.no_overlap(c)
        awful.placement.no_offscreen(c)
    end

    local titlebars_enabled = false
    if titlebars_enabled and (c.type == "normal" or c.type == "dialog") then
        -- buttons for the titlebar
        local buttons = awful.util.table.join(
                awful.button({ }, 1, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.move(c)
                end),
                awful.button({ }, 3, function()
                    client.focus = c
                    c:raise()
                    awful.mouse.client.resize(c)
                end)
                )

        -- widgets that are aligned to the right
        local right_layout = wibox.layout.fixed.horizontal()
        right_layout:add(awful.titlebar.widget.floatingbutton(c))
        right_layout:add(awful.titlebar.widget.maximizedbutton(c))
        right_layout:add(awful.titlebar.widget.stickybutton(c))
        right_layout:add(awful.titlebar.widget.ontopbutton(c))
        right_layout:add(awful.titlebar.widget.closebutton(c))

        -- the title goes in the middle
        local middle_layout = wibox.layout.flex.horizontal()
        local title = awful.titlebar.widget.titlewidget(c)
        title:set_align("center")
        middle_layout:add(title)
        middle_layout:buttons(buttons)

        -- now bring it all together
        local layout = wibox.layout.align.horizontal()
        layout:set_right(right_layout)
        layout:set_middle(middle_layout)

        awful.titlebar(c,{size=16}):set_widget(layout)
    end
end)

-- No border for maximized clients
client.connect_signal("focus",
    function(c)
        if c.maximized_horizontal == true and c.maximized_vertical == true then
            c.border_color = beautiful.border_normal
        else
            c.border_color = beautiful.border_focus
        end
    end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

-- {{{ Arrange signal handler
for s = 1, screen.count() do screen[s]:connect_signal("arrange", function ()
        local clients = awful.client.visible(s)
        local layout  = awful.layout.getname(awful.layout.get(s))

        if #clients > 0 then -- Fine grained borders and floaters control
            for _, c in pairs(clients) do -- Floaters always have borders
                -- No borders with only one humanly visible client
                if layout == "max" then
                    c.border_width = 0
                elseif awful.client.floating.get(c) or layout == "floating" then
                    c.border_width = beautiful.border_width
                elseif #clients == 1 then
                    clients[1].border_width = 0
                    if layout ~= "max" then
                        awful.client.moveresize(0, 0, 2, 0, clients[1])
                    end
                else
                    c.border_width = beautiful.border_width
                end
            end
        end
      end)
end
-- }}}
