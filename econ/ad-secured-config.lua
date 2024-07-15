local module = {}

local config = require "ad-config"
local read_pin = requires"read-pin";
local sha2 = require"sha2";

local key = sha2.sha256(read_pin("Access AD Config"));

local ad_authority_key = {};

for i, v in ipairs(config.ad_authority_key)
    ad_authority_key[i] = v ^ key[i & 31];
end

module.ad_authority_key = ad_authority_Key;

return module