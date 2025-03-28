local M = {}

local ts_label_type = '"@markup.link.label.markdown_inline"'
local ts_url_type = '"@markup.link.url.markdown_inline"'

local syn_id_name = function(bufnr, row, col, filter)
    local found = "not found"
    local items = vim.inspect_pos(bufnr, row, col, filter)
    -- treesitter
    if #items.treesitter > 0 then
        for _, capture in ipairs(items.treesitter) do
            local syn = vim.inspect(capture.hl_group)
            -- print(syn)
            if syn == ts_url_type then
                return syn
            elseif syn == ts_label_type then
                found = ts_label_type
            end
        end
    end

    return found
end

local find_next_syntax = function(bufnr, lnum, col)
    local step = 1
    local max = 0
    while max < 1000 do
        local cur_syn = syn_id_name(bufnr, lnum, col)
        -- print("cur syn", lnum, col, cur_syn)
        if cur_syn == ts_url_type then
            break
        end
        col = col + step
        max = max + 1
    end
    return col
end

--- @param lnum integer
--- @param col integer
--- @param step integer
--- @param t string
--- @return integer
function M.ts_find_corner(bufnr, lnum, col, step, t)
    local max = 0
    while max < 1000 do
        local cur_syn = syn_id_name(bufnr, lnum, col)
        -- print("cur syn", lnum, col, t, cur_syn)
        if cur_syn ~= t then
            break
        end
        -- print("a syn", col)
        col = col + step
        max = max + 1
    end
    return col - step
end

function M.ts_syn_type()
    local pos = vim.fn.getpos(".")
    local b = pos[1]
    local l = pos[2]
    local c = pos[3]
    local t = syn_id_name()
    -- print("pos", l, c, t)
    if t == ts_url_type then
        local c1 = M.ts_find_corner(b, l - 1, c - 1, -1, t)
        local c2 = M.ts_find_corner(b, l - 1, c - 1, 1, t)
        -- print("corner", c1, c2)
        return { [1] = c1 + 1, [2] = c2 + 1, [3] = 0 }
    elseif t == ts_label_type then
        local nc = find_next_syntax(b, l - 1, c - 1)
        -- print("nc", nc)
        local c1 = M.ts_find_corner(b, l - 1, nc, -1, ts_url_type)
        local c2 = M.ts_find_corner(b, l - 1, nc, 1, ts_url_type)
        return { c1 + 1, c2 + 1, 0 }
    end
    -- print("not hit any", t)
    return { [1] = 0, [2] = 1, [3] = -1 }
end

return M
