TDLZ_TodoListZWindowController = {}

---On execute button click
---@param winCtx TDLZ_TodoListZWindow Window Context
function TDLZ_TodoListZWindowController.onExecuteClick(winCtx)
    local hlist = winCtx.listbox.highlighted:toList()
    table.sort(hlist, function(a, b)
        return a < b
    end)
    local allItemsInListbox = winCtx.listbox:getItems()
    -- DEBUG
    for rowNumber, rowValue in pairs(hlist) do
        local itemToCheck = allItemsInListbox[rowValue]
        local hashList = TDLZ_StringUtils.findAllHashTagName(itemToCheck.lineString)
        for k, hashname in pairs(hashList) do
            -- Remove #
            local cleanedHashname = string.sub(hashname.text, 2)
            local itemFound = TDLZ_OwnedItemService.findByName(cleanedHashname)
            if itemFound:size() > 0 then
                itemToCheck.isChecked = true
            else
                itemToCheck.isChecked = false
            end
        end
    end
    TDLZ_TodoListZWindowController.saveAllJournalData(winCtx, allItemsInListbox)
    winCtx:refreshUIElements();
end

---@param winCtx TDLZ_TodoListZWindow
---@param button any
function TDLZ_TodoListZWindowController.onClick(winCtx, button)
    if button.internal == "NEXTPAGE" then
        winCtx.model.notebook.currentPage = winCtx.model.notebook.currentPage + 1;
    elseif button.internal == "PREVIOUSPAGE" then
        winCtx.model.notebook.currentPage = winCtx.model.notebook.currentPage - 1;
    elseif button.internal == "DELETEPAGE" then
        winCtx.entry:setText("");
        winCtx.entry.javaObject:setCursorLine(0);
    elseif button.internal == "LOCKBOOK" then
        winCtx.lockButton:setImage(getTexture("media/ui/lock.png"));
        winCtx.lockButton.internal = "UNLOCKBOOK";
        winCtx.model.notebook:setLockedBy(winCtx.character:getUsername());
        winCtx.title:setEditable(false);
        winCtx.entry:setEditable(false);
        winCtx.lockButton:setTooltip("Allow the journal to be edited");
        winCtx:setJoypadButtons(winCtx.joyfocus)
    elseif button.internal == "UNLOCKBOOK" then
        winCtx.lockButton:setImage(getTexture("media/ui/lockOpen.png"));
        winCtx.lockButton.internal = "LOCKBOOK";
        winCtx.model.notebook:setLockedBy(nil);
        winCtx.title:setEditable(true);
        winCtx.entry:setEditable(true);
        winCtx.lockButton:setTooltip("Prevent the journal from being edited");
        winCtx:setJoypadButtons(winCtx.joyfocus)
    end

    winCtx:refreshUIElements()
end

local run = 0
--- Toggle item state
---@param winCtx TDLZ_TodoListZWindow Window Context
---@param itemData TDLZ_ISListItemDataModel Ticked item data
function TDLZ_TodoListZWindowController.onOptionTicked(winCtx, itemData)
    run = run + 1
    print("On ticked " .. run .. " " .. itemData.lineString .. " " .. itemData.lineNumber)
    itemData.isChecked = not itemData.isChecked
    TDLZ_TodoListZWindowController.saveJournalData(winCtx, itemData)
    -- Refresh the UI (and the list accordingly)
    winCtx:refreshUIElements();
end

---comment
---@param winCtx any
---@param itemData TDLZ_ISListItemDataModel
---@return string
function TDLZ_TodoListZWindowController.saveJournalData(winCtx, itemData)
    -- for ln, lnString in pairs(itemData.lines) do print(lnString) end
    -- In this function, an "x" is removed or inserted between the square brackets of the ticked element
    local toWrite = ""
    for ln, lnString in pairs(itemData.lines) do
        local sep = "\n"
        if ln == 1 then
            sep = "";
        end
        if ln == itemData.lineNumber then
            if itemData.isChecked then
                -- add x
                lnString = lnString:gsub(CK_BOX_CHECKED_R_PATTERN, function(space)
                    return space .. "[x]"
                end, 1)
            else
                -- remove
                lnString = lnString:gsub(CK_BOX_CHECKED_PATTERN, function(space)
                    return space .. "[_]"
                end, 1)
            end
            toWrite = toWrite .. sep .. lnString
        else
            toWrite = toWrite .. sep .. lnString
        end
    end
    -- Save modified text
    itemData.notebook:addPage(itemData.pageNumber, toWrite);
    TDLZ_TodoListZWindowController.getHashnames(winCtx)
    return toWrite;
end

---commented
---@param winCtx TDLZ_TodoListZWindow
---@param allItemsInListbox table<number, TDLZ_ISListItemDataModel>
function TDLZ_TodoListZWindowController.saveAllJournalData(winCtx, allItemsInListbox)
    local toWrite = ""
    for ln, itemData in pairs(allItemsInListbox) do
        local textLine = itemData.lineString

        local sep = "\n"
        if ln == 1 then
            sep = "";
        end

        if itemData.isCheckbox then
            if itemData.isChecked then
                -- add x
                textLine = textLine:gsub(CK_BOX_CHECKED_R_PATTERN, function(space)
                    return space .. "[x]"
                end, 1)
            else
                -- remove
                textLine = textLine:gsub(CK_BOX_CHECKED_PATTERN, function(space)
                    return space .. "[_]"
                end, 1)
            end
            toWrite = toWrite .. sep .. textLine
        else
            toWrite = toWrite .. sep .. textLine
        end
    end
    winCtx.model.notebook.currentNotebook:addPage(winCtx.model.notebook.currentPage, toWrite)
    TDLZ_TodoListZWindowController.getHashnames(winCtx)
    return toWrite;
end

---@deprecated
---@param winCtx TDLZ_TodoListZWindow
---@return table<number,any>
function TDLZ_TodoListZWindowController.getHashnames(winCtx)
    local text = ""
    for i = 1, winCtx.model.notebook.numberOfPages, 1 do
        if winCtx.model.notebook.currentNotebook:seePage(i) ~= nil then
            text = text .. winCtx.model.notebook.currentNotebook:seePage(i) .. " "
        end
    end
    local pageHashnames = TDLZ_StringUtils.findAllHashTagName(text)
    pageHashnames = TDLZ_StringUtils.removeAllHash(pageHashnames)
    local items = getAllItems()
    local rtnItems = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i);
        if not item:getObsolete() and not item:isHidden() then
            --print("i-> " .. item:getName())
            for key, value in pairs(pageHashnames) do
                if value == item:getName() then
                    table.insert(rtnItems, item)
                    break
                end
            end
        end
    end
    return rtnItems
end


---@return table<number,any>
function TDLZ_TodoListZWindowController.getHashnames2(currentNotebook)
    local text = ""
    for i = 1, currentNotebook:getCustomPages():size(), 1 do
        if currentNotebook:seePage(i) ~= nil then
            text = text .. currentNotebook:seePage(i) .. " "
        end
    end
    local pageHashnames = TDLZ_StringUtils.findAllHashTagName(text)
    pageHashnames = TDLZ_StringUtils.removeAllHash(pageHashnames)
    local items = getAllItems()
    local rtnItems = {}
    for i = 0, items:size() - 1 do
        local item = items:get(i);
        if not item:getObsolete() and not item:isHidden() then
            --print("i-> " .. item:getName())
            for key, value in pairs(pageHashnames) do
                if value == item:getName() then
                    table.insert(rtnItems, item)
                    break
                end
            end
        end
    end
    return rtnItems
end