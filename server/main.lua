player = {}
distressCalls = {}

RegisterNetEvent("ars_ambulancejob:updateDeathStatus", function(death)
    local data = {}
    data.target = source
    data.status = death.isDead
    data.killedBy = death?.weapon or false

    updateStatus(data)
end)

RegisterNetEvent("ars_ambulancejob:revivePlayer", function(data)
    if not hasJob(source, Config.EmsJobs) or not source or source < 1 then return end

    local sourcePed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(data.targetServerId)

    if data.targetServerId < 1 or #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) > 4.0 then
        print(source .. ' probile modder')
    else
        local dataToSend = {}
        dataToSend.revive = true

        TriggerClientEvent('ars_ambulancejob:healPlayer', tonumber(data.targetServerId), dataToSend)
    end
end)

RegisterNetEvent("ars_ambulancejob:healPlayer", function(data)
    if not hasJob(source, Config.EmsJobs) or not source or source < 1 then return end


    local sourcePed = GetPlayerPed(source)
    local targetPed = GetPlayerPed(data.targetServerId)

    if data.targetServerId < 1 or #(GetEntityCoords(sourcePed) - GetEntityCoords(targetPed)) > 4.0 then
        return print(source .. ' probile modder')
    end


    if data.injury then
        TriggerClientEvent('ars_ambulancejob:healPlayer', tonumber(data.targetServerId), data)
    else
        data.anim = "medic"
        TriggerClientEvent("ars_ambulancejob:playHealAnim", source, data)
        data.anim = "dead"
        TriggerClientEvent("ars_ambulancejob:playHealAnim", data.targetServerId, data)
    end
end)

RegisterNetEvent("ars_ambulancejob:createDistressCall", function(data)
    if not source or source < 1 then return end
    distressCalls[#distressCalls + 1] = {
        msg = data.msg,
        gps = data.gps,
        location = data.location,
        name = getPlayerName(source)
    }

    local players = GetPlayers()

    for i = 1, #players do
        local id = tonumber(players[i])

        if hasJob(id, Config.EmsJobs) then
            TriggerClientEvent("ars_ambulancejob:createDistressCall", id, getPlayerName(source))
        end
    end
end)

RegisterNetEvent("ars_ambulancejob:callCompleted", function(call)
    for i = #distressCalls, 1, -1 do
        if distressCalls[i].gps == call.gps and distressCalls[i].msg == call.msg then
            table.remove(distressCalls, i)
            break
        end
    end
end)

RegisterNetEvent("ars_ambulancejob:removAddItem", function(data)
    if data.toggle then
        exports['qs-inventory']:RemoveItem(source, data.item, data.quantity)
    else
        exports['qs-inventory']:AddItem(source, data.item, data.quantity)
    end
end)

RegisterNetEvent("ars_ambulancejob:useItem", function(data)
    if not hasJob(source, Config.EmsJobs) then return end

    local item = exports['qs-inventory']:GetInventory(source).items[data.item]
    if item then
        local slot = item.slot
        local durability = item.metadata and item.metadata.durability or 100
        exports['qs-inventory']:SetItemMetadata(source, slot, { durability = durability - data.value })
    end
end)

RegisterNetEvent("ars_ambulancejob:removeInventory", function()
    if player[source].isDead and Config.RemoveItemsOnRespawn then
        local inventory = exports['qs-inventory']:GetInventory(source)
        for _, item in pairs(inventory) do
            exports['qs-inventory']:RemoveItem(source, item.name, item.count)
        end
    end
end)

RegisterNetEvent("ars_ambulancejob:putOnStretcher", function(data)
    if not player[data.target].isDead then return end
    TriggerClientEvent("ars_ambulancejob:putOnStretcher", data.target, data.toggle)
end)

RegisterNetEvent("ars_ambulancejob:togglePatientFromVehicle", function(data)
    if not player[data.target].isDead then return end
    TriggerClientEvent("ars_ambulancejob:togglePatientFromVehicle", data.target, data.vehicle)
end)

lib.callback.register('ars_ambulancejob:getDeathStatus', function(source, target)
    return player[target] and player[target] or getDeathStatus(target or source)
end)

lib.callback.register('ars_ambulancejob:getData', function(source, target)
    local data = {}
    data.injuries = Player(target).state.injuries or false
    data.status = getDeathStatus(target or source) or Player(target).state.dead
    data.killedBy = player[target] and player[target].killedBy or false

    return data
end)

lib.callback.register('ars_ambulancejob:getDistressCalls', function(source)
    return distressCalls
end)

lib.callback.register('ars_ambulancejob:openMedicalBag', function(source)
    local stashId = "medicalBag_" .. source
    exports['qs-inventory']:RegisterStash(stashId, 10, 50 * 1000)

    return stashId
end)

lib.callback.register('ars_ambulancejob:getItem', function(source, name)
    local inventory = exports['qs-inventory']:GetInventory(source)
    for slot, item in pairs(inventory) do
        if item.name == name then
            return item
        end
    end
    return nil
end)

lib.callback.register('ars_ambulancejob:getMedicsOnline', function(source)
    local count = 0
    local players = GetPlayers()

    for i = 1, #players do
        local id = tonumber(players[i])

        if hasJob(id, Config.EmsJobs) then
            count = count + 1
        end
    end
    return count
end)

RegisterNetEvent('qs-inventory:swapItems', function(payload)
    if string.find(payload.toInventory, "medicalBag_") then
        if payload.fromSlot.name == Config.MedicBagItem then
            TriggerClientEvent('qs-inventory:swapItemsResult', source, false)
            return
        end
    end
    TriggerClientEvent('qs-inventory:swapItemsResult', source, true)
end)

AddEventHandler('onServerResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for index, hospital in pairs(Config.Hospitals) do
            local cfg = hospital

            for id, stash in pairs(cfg.stash) do
                exports['qs-inventory']:RegisterStash(id, stash.slots, stash.weight * 1000)
            end

            for id, pharmacy in pairs(cfg.pharmacy) do
                -- No hay una función específica para registrar una tienda en la documentación proporcionada
                -- Así que aquí dejamos un espacio para integrar esa funcionalidad si está disponible
            end
        end
    end
end)


lib.versionCheck('Arius-Development/ars_ambulancejob')
