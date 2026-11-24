local player = game:GetService("Players").LocalPlayer;
local function generate_random_ms()
    local roll = math.random(1, 100)
    if roll <= 98 then -- change number if needed (i hope i dont have to explain how ts works)
        return math.random(-20, 40) -- perfect
    else
        if math.random(1, 2) == 1 then -- great
            return math.random(-95, -21)
        else
            return math.random(41, 190)
        end
    end
end

local track_system;
for index, module in next, getloadedmodules() do 
    local module_value = require(module);
    if type(module_value) == "table" and rawget(module_value, "new") then 
        local first_upvalue = getupvalues(module_value.new)[1];
        if type(first_upvalue) == "table" and rawget(first_upvalue, "twister") then 
            track_system = module_value; break;
        end
    end
end

local function get_track_action_functions(ts)
    local press, release; 
    for _, f in next, ts do 
        if type(f) == "function" then 
            local c = getconstants(f);
            if table.find(c, "press") then press = f;
            elseif table.find(c, "release") then release = f; end
            if press and release then break; end
        end
    end
    return press, release;
end

local function get_local_track_system(session)
    local local_slot_index = getupvalue(session.set_local_game_slot, 1);
    for _, f in next, session do 
        if type(f) == "function" then 
            local obj = getupvalues(f)[1];
            if type(obj) == "table" and rawget(obj, "count") and obj:count() <= 4 then 
                return obj:get(local_slot_index);
            end
        end
    end
end

local old_new = track_system.new;
track_system.new = function(...)
    local track_functions = old_new(...);
    local args = {...};
    if args[2]._players._slots:get(args[3])._name == player.Name then 
        for index, track_function in next, track_functions do 
            local upvalues = getupvalues(track_function);
            if type(upvalues[1]) == "table" and rawget(upvalues[1], "profilebegin") then 
                local notes_table = upvalues[2];
                track_functions[index] = function(self, slot, session)
                    local local_ts = get_local_track_system(session);
                    local press_track, release_track = get_track_action_functions(local_ts);
                    local test_press_name = getconstant(press_track, 10);
                    local test_release_name = getconstant(release_track, 6);
                    for note_index = 1, notes_table:count() do 
                        local note = notes_table:get(note_index);
                        if note then 
                            local test_press, test_release = note[test_press_name], note[test_release_name];
                            local note_track_index = note:get_track_index(note_index);
                            local pressed, _, press_delay = test_press(note);
                            -- default humanizer
                            if not rawget(note, "__custom_target") then
                                note.__custom_target = generate_random_ms()
                            end
                            if pressed and press_delay >= note.__custom_target then
                                press_track(local_ts, session, note_track_index);
                                session:debug_any_press();
                                if rawget(note, "get_time_to_end") then 
                                    delay(math.random(5, 18) / 100, function()
                                        release_track(local_ts, session, note_track_index);
                                    end);
                                end
                            end
                            if test_release then 
                                local released, _, release_delay = test_release(note);
                                if released and release_delay >= note.__custom_target then 
                                    delay(math.random(2, 5) / 100, function()
                                        release_track(local_ts, session, note_track_index);
                                    end);
                                end
                            end
                        end
                    end
                    return track_function(self, slot, session);
                end;
            end
        end
    end
    return track_functions;
end;
