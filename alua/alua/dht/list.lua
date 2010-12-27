module("alua.dht.list", package.seeall)

util    = require("alua.util")
id      = require("alua.dht.identifier")

-- local comp_func = id.comp_sort

-- function new(elements, maxn, comp)
--     local list = {}
--     list.comp_func = comp
--     list.maxn = maxn
--     list.elements = {}
--     
--     if elements then
--         for i, element in ipairs(elements) do
--             table.insert(list.elements, element)
--         end
--         table.sort(list.elements, list.comp_func)
--     
--         while #list.elements > list.maxn do
--             table.remove(list.elements)
--         end
--     end
--     
--     return list
-- end

function new(zero_id, maxn)
    local list = {}
    list.comp_func = id.comp_sort
    list.maxn = maxn
    list.zero_id = zero_id
    list.u_elements = {}
    list.l_elements = {}
    return list
end


local function belongs(list, element)
    for i, v in ipairs(list.u_elements) do
        if id.compare(v, element) == 0 then
            return true
        end
    end
    
    for i, v in ipairs(list.l_elements) do
        if id.compare(v, element) == 0 then
            return true
        end
    end
    
    return false
end

function insert(list, element)
    if not belongs(list, element) then
        if id.compare(element, list.zero_id) == 1 then
            table.insert(list.u_elements, element)
            table.sort(list.u_elements, list.comp_func)
        elseif id.compare(element, list.zero_id) == -1 then
            table.insert(list.l_elements, element)
            table.sort(list.l_elements, list.comp_func)
        else
            -- do nothing
        end
                       
        while #list.u_elements + #list.l_elements > list.maxn do
            if #list.l_elements > 0 then
                table.remove(list.l_elements)
            else
                table.remove(list.u_elements)
            end
        end
    end
end

function insertn(list, elements)
    for i, element in ipairs(elements) do
        if not belongs(list, element) then
            -- TODO Ineficiente pois vai ter ordenar a cada iteração
            insert(list, element)
        end
    end
end

function pop(list)
    if #list.u_elements > 0 then
        return table.remove(list.u_elements, 1)
    elseif #list.l_elements > 0 then
        return table.remove(list.l_elements, 1)
    else
        return nil
    end
end


function first(list)
    if #list.u_elements > 0 then
        return list.u_elements[1]
    elseif #list.l_elements > 0 then
        return list.l_elements[1]
    else
        return nil
    end
end


function is_empty(list)
    return #list.l_elements == 0 and #list.u_elements == 0
end

function to_table(list)
    local elements = {}
    
    for i, element in ipairs(list.u_elements) do
        table.insert(elements, element)
    end
    
    for i, element in ipairs(list.l_elements) do
        table.insert(elements, element)
    end
    
    return elements
end

function to_string(list)
    local str = ""
    local count = 1
    
    for i, element in ipairs(list.u_elements) do
        if count < list.maxn then
            str = str .. id.to_string(element) .. " -> "
        else
            str = str .. id.to_string(element)
        end
        count = count + 1
    end
    
    for i, element in ipairs(list.l_elements) do
        if count < list.maxn then
            str = str .. id.to_string(element) .. " -> "
        else
            str = str .. id.to_string(element)
        end
        count = count + 1
    end

    return str
end
