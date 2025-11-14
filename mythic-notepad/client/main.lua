local _open = false
local _mode = nil
local _cb = nil
local Animations = nil

AddEventHandler("Notepad:Shared:DependencyUpdate", RetrieveComponents)

function RetrieveComponents()
        Callbacks = exports["mythic-base"]:FetchComponent("Callbacks")
        Animations = exports["mythic-base"]:FetchComponent("Animations")
end

AddEventHandler("Core:Shared:Ready", function()
        exports["mythic-base"]:RequestDependencies("Notepad", {
                "Callbacks",
                "Animations",
        }, function(error)
                if #error > 0 then
                        return
                end

                RetrieveComponents()
                RegisterCallbacks()
        end)
end)

function RegisterCallbacks()
        Callbacks:RegisterClientCallback("Notepad:CreateNote", function(data, cb)
                if _open then
                        cb({ cancelled = true, error = "Notepad already open" })
                        return
                end

                _open = true
                _mode = "write"
                _cb = cb

                SetNuiFocus(true, true)
                SendNUIMessage({
                        action = "NOTEPAD_OPEN",
                        data = {
                                mode = "write",
                                text = "",
                                author = data and data.author or nil,
                                created = data and data.created or nil,
                        },
                })

                if Animations then
                        Animations.Emotes:Play("notepad", false, false, true)
                end
        end)

        Callbacks:RegisterClientCallback("Notepad:ViewNote", function(data, cb)
                if _open then
                        cb(false)
                        return
                end

                _open = true
                _mode = "read"
                _cb = cb

                SetNuiFocus(true, true)
                SendNUIMessage({
                        action = "NOTEPAD_OPEN",
                        data = {
                                mode = "read",
                                text = data and data.text or "",
                                author = data and data.author or nil,
                                created = data and data.created or nil,
                        },
                })

                if Animations then
                        Animations.Emotes:Play("notepad", false, false, true)
                end
        end)
end

local function closeUi()
        SetNuiFocus(false, false)
        SendNUIMessage({ action = "NOTEPAD_CLOSE" })
        _open = false
        _mode = nil
        _cb = nil
        if Animations then
                Animations.Emotes:ForceCancel()
        end
end

RegisterNUICallback("Notepad:Submit", function(data, cb)
        if _cb ~= nil then
                _cb({
                        cancelled = false,
                        text = data and data.text or "",
                })
                _cb = nil
        end

        closeUi()
        cb("OK")
end)

RegisterNUICallback("Notepad:Close", function(data, cb)
        if _cb ~= nil then
                if _mode == "write" then
                        _cb({ cancelled = true })
                else
                        _cb(true)
                end
                _cb = nil
        end

        closeUi()
        cb("OK")
end)

AddEventHandler("onResourceStop", function(res)
        if res == GetCurrentResourceName() and _open then
                closeUi()
        end
end)