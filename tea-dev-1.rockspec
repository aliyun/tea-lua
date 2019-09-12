package = "tea"
version = "dev-1"
source = {
   url = "git://github.com/aliyun/tea-lua.git"
}
description = {
   summary = "The Tea core library for Lua",
   detailed = "",
   homepage = "https://github.com/aliyun/tea-lua",
   license = "Apache 2.0"
}
dependencies = {
   "lua >= 5.1",
   "luasocket >= 3.0rc1-2",
   "luasec >= 0.7"
}

build = {
   type = "builtin",
   modules = {
      tea = "lib/tea.lua"
   }
}
