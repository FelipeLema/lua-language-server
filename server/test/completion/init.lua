local core = require 'core'
local parser  = require 'parser'
local buildVM = require 'vm'

local CompletionItemKind = {
    Text = 1,
    Method = 2,
    Function = 3,
    Constructor = 4,
    Field = 5,
    Variable = 6,
    Class = 7,
    Interface = 8,
    Module = 9,
    Property = 10,
    Unit = 11,
    Value = 12,
    Enum = 13,
    Keyword = 14,
    Snippet = 15,
    Color = 16,
    File = 17,
    Reference = 18,
    Folder = 19,
    EnumMember = 20,
    Constant = 21,
    Struct = 22,
    Event = 23,
    Operator = 24,
    TypeParameter = 25,
}

local EXISTS = {}

local function eq(a, b)
    if a == EXISTS and b ~= nil then
        return true
    end
    local tp1, tp2 = type(a), type(b)
    if tp1 ~= tp2 then
        return false
    end
    if tp1 == 'table' then
        local mark = {}
        for k in pairs(a) do
            if not eq(a[k], b[k]) then
                return false
            end
            mark[k] = true
        end
        for k in pairs(b) do
            if not mark[k] then
                return false
            end
        end
        return true
    end
    return a == b
end

rawset(_G, 'TEST', true)

function TEST(script)
    return function (expect)
        local pos = script:find('$', 1, true) - 1
        local new_script = script:gsub('%$', '')
        local ast = parser:ast(new_script, 'lua', 'Lua 5.4')
        local vm = buildVM(ast)
        assert(vm)
        local result = core.completion(vm, new_script, pos)
        if expect then
            assert(result)
            assert(eq(expect, result))
        else
            assert(result == nil)
        end
    end
end

TEST [[
local zabcde
za$
]]
{
    {
        label = 'zabcde',
        kind = CompletionItemKind.Variable,
    }
}

TEST [[
local zabcdefg
local zabcde
zabcde$
]]
{
    {
        label = 'zabcdefg',
        kind = CompletionItemKind.Variable,
    },
    {
        label = 'zabcde',
        kind = CompletionItemKind.Variable,
    },
}

TEST [[
local zabcdefg
za$
local zabcde
]]
{
    {
        label = 'zabcdefg',
        kind = CompletionItemKind.Variable,
    },
    {
        label = 'zabcde',
        kind = CompletionItemKind.Text,
    },
}

TEST [[
local zabcde
zace$
]]
{
    {
        label = 'zabcde',
        kind = CompletionItemKind.Variable,
    }
}

TEST [[
ZABC
local zabc
zac$
]]
{
    {
        label = 'zabc',
        kind = CompletionItemKind.Variable,
    },
    {
        label = 'ZABC',
        kind = CompletionItemKind.Field,
    },
}

TEST [[
ass$
]]
{
    {
        label = 'assert',
        kind = CompletionItemKind.Function,
        documentation = EXISTS,
    }
}

TEST [[
local zabc = 1
z$
]]
{
    {
        label = 'zabc',
        kind = CompletionItemKind.Variable,
        detail = '= 1',
    }
}

TEST [[
local zabc = 1.0
z$
]]
{
    {
        label = 'zabc',
        kind = CompletionItemKind.Variable,
        detail = '= 1.0',
    }
}

TEST [[
local t = {
    abc = 1,
}
t.a$
]]
{
    {
        label = 'abc',
        kind = CompletionItemKind.Enum,
        detail = '= 1',
    }
}

TEST [[
local mt = {}
function mt:get(a, b)
    return 1
end
mt:g$
]]
{
    {
        label = 'get',
        kind = CompletionItemKind.Method,
        documentation = EXISTS,
    }
}

TEST [[
loc$
]]
{
    {
        label = 'local',
        kind = CompletionItemKind.Keyword,
    }
}

TEST [[
t.a = {}
t.b = {}
t.$
]]
{
    {
        label = 'a',
        kind = CompletionItemKind.Field,
    },
    {
        label = 'b',
        kind = CompletionItemKind.Field,
    },
}

TEST [[
t.a = {}
t.b = {}
t.   $
]]
{
    {
        label = 'a',
        kind = CompletionItemKind.Field,
    },
    {
        label = 'b',
        kind = CompletionItemKind.Field,
    },
}

TEST [[
t.a = {}
function t:b()
end
t:$
]]
{
    {
        label = 'b',
        kind = CompletionItemKind.Method,
        documentation = EXISTS,
    },
}

TEST [[
local t = {
    a = {},
}
t.$
xxx()
]]
{
    {
        label = 'a',
        kind = CompletionItemKind.Field,
    },
    {
        label = 'xxx',
        kind = CompletionItemKind.Function,
        documentation = EXISTS,
    },
}

TEST [[
(''):$
]]
(EXISTS)

TEST 'local s = "a:$"' (nil)

TEST 'debug.$'
(EXISTS)

TEST [[
local xxxx = {
    xxyy = 1,
    xxzz = 2,
}

local t = {
    x$
}
]]
{
    {
        label = 'xxxx',
        kind = CompletionItemKind.Variable,
    },
    {
        label = 'xxyy',
        kind = CompletionItemKind.Property,
    },
    {
        label = 'xxzz',
        kind = CompletionItemKind.Property,
    },
    {
        label = 'xpcall',
        kind = CompletionItemKind.Function,
        documentation = EXISTS,
    }
}

TEST [[
print(ff2)
local faa
local f$
print(fff)
]]
{
    {
        label = 'fff',
        kind = CompletionItemKind.Variable,
    },
    {
        label = 'function',
        kind = CompletionItemKind.Keyword,
    },
    {
        label = 'ff2',
        kind = CompletionItemKind.Text,
    },
    {
        label = 'faa',
        kind = CompletionItemKind.Text,
    },
}

TEST [[
local function f(ff$)
    print(fff)
end
]]
{
    {
        label = 'fff',
        kind = CompletionItemKind.Variable,
    },
}

TEST [[
collectgarbage('$')
]]
{
    {
        label = 'collect',
        kind = CompletionItemKind.EnumMember,
        documentation = EXISTS,
        textEdit = {
            start = 16,
            finish = 17,
            newText = '"collect"',
        },
    },
    {
        label = 'stop',
        kind = CompletionItemKind.EnumMember,
        documentation = EXISTS,
        textEdit = {
            start = 16,
            finish = 17,
            newText = '"stop"',
        },
    },
    {
        label = 'restart',
        kind = CompletionItemKind.EnumMember,
        documentation = EXISTS,
        textEdit = {
            start = 16,
            finish = 17,
            newText = '"restart"',
        },
    },
    {
        label = 'count',
        kind = CompletionItemKind.EnumMember,
        documentation = EXISTS,
        textEdit = {
            start = 16,
            finish = 17,
            newText = '"count"',
        },
    },
    {
        label = 'step',
        kind = CompletionItemKind.EnumMember,
        documentation = EXISTS,
        textEdit = {
            start = 16,
            finish = 17,
            newText = '"step"',
        },
    },
    {
        label = 'setpause',
        kind = CompletionItemKind.EnumMember,
        documentation = EXISTS,
        textEdit = {
            start = 16,
            finish = 17,
            newText = '"setpause"',
        },
    },
    {
        label = 'setstepmul',
        kind = CompletionItemKind.EnumMember,
        documentation = EXISTS,
        textEdit = {
            start = 16,
            finish = 17,
            newText = '"setstepmul"',
        },
    },
    {
        label = 'isrunning',
        kind = CompletionItemKind.EnumMember,
        documentation = EXISTS,
        textEdit = {
            start = 16,
            finish = 17,
            newText = '"isrunning"',
        },
    },
}

TEST [[
collectgarbage($)
]]
(EXISTS)

TEST [[
io.read($)
]]
{
    {
        label = '"n"',
        kind = CompletionItemKind.EnumMember,
        documentation = EXISTS,
    },
    {
        label = '"a"',
        kind = CompletionItemKind.EnumMember,
        documentation = EXISTS,
    },
    {
        label = '"l"',
        kind = CompletionItemKind.EnumMember,
        documentation = EXISTS,
    },
    {
        label = '"L"',
        kind = CompletionItemKind.EnumMember,
        documentation = EXISTS,
    },
}

TEST [[
local function f(a, $)
end
]]
(nil)

TEST [[
self.results.list[#$]
]]
{
    {
        label = 'self.results.list+1',
        kind = CompletionItemKind.Snippet,
        textEdit = {
            start = 20,
            finish = 20,
            newText = 'self.results.list+1] = ',
        },
    },
}

TEST [[
self.results.list[#self.re$]
]]
{
    {
        label = 'self.results.list+1',
        kind = CompletionItemKind.Snippet,
        textEdit = {
            start = 20,
            finish = 27,
            newText = 'self.results.list+1] = ',
        },
    },
    {
        label = 'results',
        kind = CompletionItemKind.Field,
    },
}

TEST [[
fff[#ff$]
]]
{
    {
        label = 'fff+1',
        kind = CompletionItemKind.Snippet,
        textEdit = {
            start = 6,
            finish = 8,
            newText = 'fff+1] = ',
        },
    },
    {
        label = 'fff',
        kind = CompletionItemKind.Field,
    }
}

TEST [[
local _ = fff.kkk[#$]
]]
{
    {
        label = 'fff.kkk',
        kind = CompletionItemKind.Snippet,
        textEdit = {
            start = 20,
            finish = 20,
            newText = 'fff.kkk]',
        },
    },
}

TEST [[
local t = {
    a = 1,
}

t .    $
]]
(EXISTS)

TEST [[
local t = {
    a = 1,
}

t .    $ b
]]
(EXISTS)

TEST [[
local t = {
    a = 1,
}

t $
]]
(nil)

TEST [[
local t = {
    a = 1,
}

t $.
]]
(nil)

TEST [[
local xxxx
xxxx$
]]
{
    {
        label = 'xxxx',
        kind = CompletionItemKind.Variable,
    },
}

TEST [[
local xxxx
local XXXX
xxxx$
]]
{
    {
        label = 'xxxx',
        kind = CompletionItemKind.Variable,
    },
    {
        label = 'XXXX',
        kind = CompletionItemKind.Variable,
    },
}

TEST [[
local t = {
    xxxxx = 1,
}
xx$
]]
{
    {
        label = 'xxxxx',
        kind = CompletionItemKind.Text,
    },
}

TEST [[
local index
tbl[ind$]
]]
{
    {
        label = 'index',
        kind = CompletionItemKind.Variable,
    },
}

TEST [[
return function ()
    local t = {
        a = {},
        b = {},
    }
    t.$
end
]]
{
    {
        label = 'a',
        kind = CompletionItemKind.Field,
    },
    {
        label = 'b',
        kind = CompletionItemKind.Field,
    },
}

TEST [[
local ast = 1
local t = 'as$'
local ask = 1
]]
(nil)

TEST [[
local add

function f(a$)
    local _ = add
end
]]
{
    {
        label = 'add',
        kind = CompletionItemKind.Variable,
    },
}

TEST [[
function table.i$
]]
(EXISTS)

TEST [[
do
    xx.$
end
]]
(nil)

require 'config' .config.runtime.version = 'Lua 5.4'
--TEST [[
--local *$
--]]
--{
--    {
--        label = 'toclose',
--        kind = CompletionItemKind.Keyword,
--    }
--}

--TEST [[
--local *tocl$
--]]
--{
--    {
--        label = 'toclose',
--        kind = CompletionItemKind.Keyword,
--    }
--}

TEST [[
local mt = {}
mt.__index = mt
local t = setmetatable({}, mt)

t.$
]]
{
    {
        label = '__index',
        kind = CompletionItemKind.Field,
    }
}

TEST [[
local elseaaa
ELSE = 1
if a then
else$
]]
{
    {
        label = 'elseaaa',
        kind = CompletionItemKind.Variable,
    },
    {
        label = 'ELSE',
        kind = CompletionItemKind.Enum,
        detail = EXISTS,
    },
    {
        label = 'else',
        kind = CompletionItemKind.Keyword,
    },
    {
        label = 'elseif',
        kind = CompletionItemKind.Keyword,
    }
}

TEST [[
---@$
]]
(EXISTS)

TEST [[
---@cl$
]]
{
    {
        label = 'class',
        kind = CompletionItemKind.Keyword
    }
}

TEST [[
---@class ABC
---@class BBC : $
]]
{
    {
        label = 'ABC',
        kind = CompletionItemKind.Class,
    },
    {
        label = 'BBC',
        kind = CompletionItemKind.Class,
    },
}

TEST [[
---@class abc
local abcd
---@type a$
]]
{
    {
        label = 'abc',
        kind = CompletionItemKind.Class,
    },
}

TEST [[
---@class abc
local abcd
---@type $
]]
{
    {
        label = 'abc',
        kind = CompletionItemKind.Class,
    },
}

TEST [[
---@class abc
local abcd
---@type xxx|$
]]
{
    {
        label = 'abc',
        kind = CompletionItemKind.Class,
    }
}

TEST [[
---@alias abc abb
---@type a$
]]
{
    {
        label = 'abc',
        kind = CompletionItemKind.Class,
    },
}

TEST [[
---@class Class
---@param x C$
]]
{
    {
        label = 'Class',
        kind = CompletionItemKind.Class,
    },
}

TEST [[
---@param $
function f(a, b, c)
end
]]
{
    {
        label = 'a',
        kind = CompletionItemKind.Interface,
    },
    {
        label = 'b',
        kind = CompletionItemKind.Interface,
    },
    {
        label = 'c',
        kind = CompletionItemKind.Interface,
    },
}

TEST [[
---@param xyz Class
---@param xxx Class
function f(x$)
]]
{
    {
        label = 'xyz',
        kind = CompletionItemKind.Interface,
    },
    {
        label = 'xxx',
        kind = CompletionItemKind.Interface,
    },
}
