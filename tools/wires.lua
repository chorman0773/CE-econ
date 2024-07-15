local wire = require"wire-transfer";
local config = require"config";


rednet.open(config.global_net);

local last_ack = true;
local waiting_forward = nil;

parallel.waitForAny(function()
    repeat
    local res, error =  pcall(function()
            while not last_ack do
                sleep(1);
            end
            write("Wire Amount>")
            local input = read();
    
            local amount = tonumber(input) or tonumber(input:sub(2));
    
            write("Destination Routing Code>");
            local routing_code = read();
    
            write("Destination Account Number>");
            local account_number = tonumber(read());
            
            last_ack = false;
            wire.send_wire_payment(amount, routing_code, account_number);
            
    end
    );

    if not res then
        printError(error.."\n");
    end
until false
end, function()
    repeat
        local computer, message, protocol = rednet.receive();
        if protocol == "ad-payment:wire-transfer" then
            -- {routing_code = routing_code, amount = amount, account_number = account_number, from_routing_code = config.local_routing_code}
            local rounting_code = message.routing_code;
            local amount = message.amount;
            local account_number = message.account_number;
            local from_routing_code = message.from_routing_code;

            if routing_code == config.local_routing_code then
                wire.recieve_wire_payment(amount, account_number, from_routing_code);
                rednet.send(computer, {rounting_code = routing_code, account_number = account_number}, "ad-payment:wire-transfer/ack");
            else
                waiting_forward = computer;
                if not wire.send_wire_payment(amount, rounting_code, account_number, from_routing_code) then
                    rednet.send(computer, {rounting_code = routing_code, account_number = account_number,why = "No Route"}, "ad-payment:wire-transfer/nak");
                end
            end
            
        elseif protocol == "ad-payment:wire-transfer/ack" then
            write("Wire to "..message.routing_code.." "..message.account_number..": Success\n");
            if waiting_forward then
                rednet.send(waiting_forward, message, "ad-payment:wire-transfer/ack");
            end
            last_ack = true;
        elseif protocol == "ad-payment:wire-transfer/nak" then
            write("Wire to "..message.routing_code.." "..message.account_number..": Failed - "..message.why.."\n");
            if waiting_forward then
                rednet.send(waiting_forward, message, "ad-payment:wire-transfer/nak");
            end
            last_ack = true;
        end
    until false
end)
