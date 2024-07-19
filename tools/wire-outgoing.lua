local wire = require"wire-transfer";
local config = require"config";
rednet.open(config.global_net);
repeat
local res, error =  pcall(function()
        write("Wire Amount>")
        local input = read();

        local amount = tonumber(input) or tonumber(input:sub(2));

        write("Routing Code>");
        local routing_code = read();

        write("Account Number>");
        local account_number = tonumber(read());
        
        last_ack = false;
        wire.send_wire_payment(amount, routing_code, account_number);
        
end
);

if not res then
    printError(error.."\n");
end
until false

