local module = {};

local ad_config = require"ad-config";
local ad_secured_config = require"ad-secure-config";
local ad_reasons = require"ad-reasons";
local sha2 = require"sha2";
local read_pin = require"read-pin";

local ad_serial = sha2.sha256(ad_config.machine_id .. os.computerID() .. os.epoch("ingame"));


module.read_key_data = function(drive)
    local path = disk.getMountPath(drive) .. "/ad-data";
    local data = dofile(path);
    data
end

module.send_pay_request = function(decoded_ad_data, amount)
    local serial_val = ad_serial;
    ad_serial = sha2.sha256(ad_config.machine_id .. serial_val)
    local req = {src_ad_data = decoded_ad_data, serial = ad_serial, time = os.epoch("ingame"), value = amount, dest_ad_data=ad_config.ad_deposit_data, ad_authority=ad_secured_config.ad_authority_key};
    rednet.send(ad_config.dispatch_address, req, "ad-payment:transfer/payment");
    local compNumber, response;
    repeat
        compNumber, response = rednet.recieve("ad-payment:transfer/response", 5);
        if ~compNumber then
            return 0, "Protocol Error", os.epoch("ingame")
        end
    until response.serial == serial_val;

    return response.reason, ad_reasons[response.reason], response.time
end

module.send_refund_request = function(decoded_ad_data, amount)
    local serial_val = ad_serial;
    ad_serial = sha2.sha256(ad_config.machine_id .. serial_val)
    local req = {src_ad_data = ad_config.ad_withdrawl_data, serial = ad_serial, time = os.epoch("ingame"), value = amount, dest_ad_data=decoded_ad_data, ad_authority=ad_secured_config.ad_authority_key};
    rednet.send(ad_config.dispatch_address, req, "ad-payment:transfer/refund");
    local compNumber, response;
    repeat
        compNumber, response = rednet.recieve("ad-payment:transfer/response", 5);
        if ~compNumber then
            return 0, "Protocol Error", os.epoch("ingame")
        end
    until response.serial == serial_val;

    return response.reason, ad_reasons[response.reason], response.time
end


module.decode_key_data = function(ad_data)
    local key = sha2.sha256(read_pin("Enter Pin for Access Card"));
    for i,v in ad_data.key do
        ad_data.key = ad_data[i] ^ key[i & 31];
    end
    return ad_data
end

return module