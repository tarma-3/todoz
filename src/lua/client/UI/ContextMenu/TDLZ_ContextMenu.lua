-- Author:      Enrico B.
-- Repository:  https://github.com/tarma-3/todoz

require "src.lua.client.Service.TDLZ_ItemsFinderService"
require "src.lua.client.UI.Window.TDLZ_TodoListZWindow.TDLZ_TodoListZWindow"
---@class TDLZ_ContextMenu:ISScrollingListBox
---@field viewModel {allItems:table<number,any>}
TDLZ_ContextMenu = ISScrollingListBox:derive("TDLZ_ContextMenu");
local instance = nil
local FONT_HGT_MEDIUM = getTextManager():getFontHeight(UIFont.Medium)
function TDLZ_ContextMenu:searchAndDisplayResults(hashFound)
    self.startIndex = hashFound.startIndex
    self.endIndex = hashFound.endIndex

    local filteredItems = {};
    if string.len(hashFound.text) < 3 then
        self:setVisible(false)
        return
    end

    self:setVisible(true)
    self:setCapture(true)
    self:setAlwaysOnTop(true)
    for index, item in pairs(self.viewModel.allItems) do
        if TDLZ_ItemsFinderService.hasIcon(item) and TDLZ_ItemsFinderService.filterName(hashFound.text, item) then
            table.insert(filteredItems, item)
        end
    end
    table.sort(filteredItems, function(a, b) return #a:getDisplayName() < #b:getDisplayName() end)
    self:clear()
    for index, item in pairs(filteredItems) do
        self:addItem(item:getDisplayName(), item)
    end
    local nOfItemsInMenu = #self.items
    if #self.items > 4 then
        nOfItemsInMenu = 4
    end
    self:setHeight(nOfItemsInMenu * self.itemheight)
end

function TDLZ_ContextMenu:doDrawItem(y, item, alt)
    if not item.height then item.height = self.itemheight end -- compatibililty
    self:drawRect(0, y, self:getWidth(), item.height - 1, 0.9, 0.1, 0.1, 0.1);
    if self.selected == item.index then
        self:drawRect(0, y, self:getWidth(), item.height - 1, 1, 0.2, 0, 0);
    end
    self:drawRectBorder(0, y, self:getWidth(), item.height, 0.5, self.borderColor.r, self.borderColor.g,
        self.borderColor.b);
    local itemPadY = self.itemPadY or (item.height - self.fontHgt) / 2


    local icon = item.item:getIcon()
    if item.item:getIconsForTexture() and not item.item:getIconsForTexture():isEmpty() then
        icon = item.item:getIconsForTexture():get(0)
    end
    if icon then
        local texture = getTexture("Item_" .. icon)
        if texture then
            self:drawTextureScaledAspect2(texture, 0, y + (self.itemheight - FONT_HGT_MEDIUM) / 2, FONT_HGT_MEDIUM + 15,
                FONT_HGT_MEDIUM, 1, 1, 1, 1);
        end
    end
    self:drawText(item.text, 15 + FONT_HGT_MEDIUM, (y) + itemPadY, 0.7, 0.7, 0.7, 1, self.font);
    self:drawText(" #" .. item.item:getName(), 15 + FONT_HGT_MEDIUM, (y) + itemPadY + self.fontHgt, 1, 1, 1, 1, self
        .font);
    y = y + item.height;
    return y;
end

function TDLZ_ContextMenu:onMouseDown(x, y)
    if instance == nil then
        return
    end
    if not self:isMouseOver() then
        self:setVisible(false);
        return
    end
    ISScrollingListBox.onMouseDown(self, x, y)
end

function TDLZ_ContextMenu:onMouseDoubleClick(x, y)
    if self.items[self.selected] ~= nil and self.onCloseCTX ~= nil and self.onCloseCallback ~= nil then
        self.onCloseCallback(self.onCloseCTX,
            {
                text = self.items[self.selected].item:getName(),
                startIndex = self.startIndex,
                endIndex = self.endIndex
            })
        self:setVisible(false)
    end
end

function TDLZ_ContextMenu:destroy()
    self:setVisible(false);
    self:removeFromUIManager();
end

function TDLZ_ContextMenu:setFont(font, padY)
    ISScrollingListBox.setFont(self, font, padY)
    self.itemheight = self.fontHgt * 2 + (self.itemPadY or 0) * 2;
end

---@param x number
---@param y number
---@param width number
---@param height number
---@return TDLZ_ContextMenu
function TDLZ_ContextMenu:new(x, y, width, height)
    local o = {}
    o = ISScrollingListBox:new(x, y, width, height);
    setmetatable(o, self)
    self.__index = self

    o.itemheight = o.fontHgt * 2 + o.itemPadY * 2;

    o.x = x;
    o.y = y;
    o.background = true;
    o.backgroundColor = { r = 0, g = 0, b = 0, a = 0.5 };
    o.borderColor = { r = 0.4, g = 0.4, b = 0.4, a = 1 };
    o.width = width;
    o.height = height;
    o.anchorLeft = true;
    o.anchorRight = false;
    o.anchorTop = true;
    o.anchorBottom = false;
    o.joypadButtons = {};
    o.joypadIndex = 0;
    o.joypadButtonsY = {};
    o.joypadIndexY = 0;
    o.moveWithMouse = false;
    o.onCloseCTX = nil
    o.onCloseCallback = nil

    o.viewModel = {
        allItems = TDLZ_ItemsFinderService.ALL_NOT_OBSOLETE_ITEMS:toList()
    }

    o.startIndex = -1
    o.endIndex = -1

    instance = o
    return o
end

---Set callback on context menu close
---@param onCloseCTX any
---@param onCloseCallback fun(ctx : any,item: { text: string, startIndex: number, endIndex: number })
function TDLZ_ContextMenu:setOnCloseCallback(onCloseCTX, onCloseCallback)
    self.onCloseCTX = onCloseCTX
    self.onCloseCallback = onCloseCallback
end
