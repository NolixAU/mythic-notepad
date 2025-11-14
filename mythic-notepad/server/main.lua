local function trim(str)
        if not str then
                return ""
        end

        return (string.gsub(str, "^%s+", ""):gsub("%s+$", ""))
end

local NOTE_METADATA_LIMIT = 1024

local function sanitizeNote(text)
        local cleaned = trim(text or "")
        cleaned = cleaned:gsub("\r\n", "\n")
        cleaned = cleaned:gsub("\r", "\n")

        if #cleaned > 1000 then
                cleaned = cleaned:sub(1, 1000)
        end

        return cleaned
end

local function buildNoteMetadata(noteText, author)
        local meta = {
                Note = noteText,
                Author = author,
                Created = os.time(),
        }

        local encoded = json.encode(meta)
        if not encoded then
                return nil, false, "Failed to encode note data"
        end

        local trimmed = false

        while #encoded > NOTE_METADATA_LIMIT and #meta.Note > 0 do
                trimmed = true

                local overflow = #encoded - NOTE_METADATA_LIMIT
                local newLength = #meta.Note - math.max(overflow, 1)

                if newLength <= 0 then
                        return nil, false, "Note is too long"
                end

                meta.Note = meta.Note:sub(1, newLength)
                encoded = json.encode(meta)

                if not encoded then
                        return nil, false, "Failed to encode note data"
                end
        end

        if meta.Note == "" then
                return nil, false, "Note cannot be empty"
        end

        return meta, trimmed
end

AddEventHandler("Notepad:Shared:DependencyUpdate", RetrieveComponents)

function RetrieveComponents()
        Callbacks = exports["mythic-base"]:FetchComponent("Callbacks")
        Execute = exports["mythic-base"]:FetchComponent("Execute")
        Fetch = exports["mythic-base"]:FetchComponent("Fetch")
        Inventory = exports["mythic-base"]:FetchComponent("Inventory")
end

local function getAuthorName(char)
        if not char then
                return nil
        end

        local first = char:GetData("First") or ""
        local last = char:GetData("Last") or ""

        local name = trim(string.format("%s %s", first, last))
        if name == "" then
                return nil
        end

        return name
end

local function registerItems()
        Inventory.Items:RegisterUse("notepad", "Notepad", function(source, item)
                local plyr = Fetch:Source(source)
                if not plyr then
                        return
                end

                local char = plyr:GetData("Character")
                if not char then
                        return
                end

                Callbacks:ClientCallback(source, "Notepad:CreateNote", {}, function(result)
                        if not result or result.cancelled then
                                if result and result.error then
                                        Execute:Client(source, "Notification", "Error", result.error)
                                end
                                return
                        end

                        local noteText = sanitizeNote(result.text)
                        if noteText == "" then
                                Execute:Client(source, "Notification", "Error", "Note cannot be empty")
                                return
                        end

                        local meta, trimmed, err = buildNoteMetadata(noteText, getAuthorName(char))
                        if not meta then
                                Execute:Client(source, "Notification", "Error", err or "Failed to save note")
                                return
                        end

                        local added = Inventory:AddItem(char:GetData("SID"), "note", 1, meta, 1)
                        if not added then
                                Execute:Client(source, "Notification", "Error", "Could not add note to inventory")
                        else
                                local message = trimmed and "Created Note" or "Created Note"
                                Execute:Client(source, "Notification", "Success", message)
                        end
                end)
        end)

        Inventory.Items:RegisterUse("note", "Notepad", function(source, item)
                if not item or not item.MetaData then
                        Execute:Client(source, "Notification", "Error", "This note is blank")
                        return
                end

                local data = {
                        text = item.MetaData.Note or "",
                        author = item.MetaData.Author,
                        created = item.MetaData.Created,
                }

                Callbacks:ClientCallback(source, "Notepad:ViewNote", data, function()
                        -- no return data needed
                end)
        end)
end

AddEventHandler("Core:Shared:Ready", function()
        exports["mythic-base"]:RequestDependencies("Notepad", {
                "Callbacks",
                "Execute",
                "Fetch",
                "Inventory",
        }, function(error)
                if #error > 0 then
                        return
                end

                RetrieveComponents()
                registerItems()
        end)
end)