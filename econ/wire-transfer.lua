local module = {}

local config = require"config";

function module.send_wire_payment(amount, routing_code, account_number, from_routing_code)
    if not from_routing_code then
        local file = fs.open(config.ad_log_directory .. "/wire-logs", "a");
        local ts = os.epoch("ingame");
        file.writeLine("WIRE TO "..routing_code.." "..amount.." TO ".." (TIMESTAMP "..ts..")");
        file.close();
    else
        local file = fs.open(config.ad_log_directory .. "/wire-logs", "a");
        local ts = os.epoch("ingame");
        file.writeLine("WIRE RELAY FROM "..from_routing_code.." "..amount.." TO "..routing_code..":"..account_number.." (TIMESTAMP "..ts..")");
        file.close();
    end


    from_routing_code = from_routing_code or config.local_routing_code;
    local routing_dest;

    if routing_code == config.local_routing_code then
        return module.recieve_wire_payment(amount, account_number, from_routing_code);
    end

    if config.routing_codes and config.routing_codes[routing_code] then
        routing_dest = config.routing_codes[routing_code];
    elseif config.wire_relay then
        routing_dest = config.wire_relay;
    else 
        return false;
    end

    rednet.send(routing_dest, {routing_code = routing_code, amount = amount, account_number = account_number, from_routing_code = from_routing_code}, "ad-payment:wire-transfer");
    return true;
end

function module.recieve_wire_payment(amount, account_number, from_routing_code)
    local file = fs.open(config.ad_log_directory .. "/wire-logs", "a");
    local ts = os.epoch("ingame");
    file.writeLine("WIRE FROM "..from_routing_code.." "..amount.." TO "..account_number.." (TIMESTAMP "..ts..")");
    file.close();
end

return module