:local domainName "__DOMAIN_NAME__" # DNS record name
:local ifaceName  "ether1"          # IP address iface

:local apiToken "__API_TOKEN__" # Get zone edit token: https://dash.cloudflare.com/profile/api-tokens
:local zoneID   "__ZONE_ID__"   # You can find this in CF web: Select site -> Overview (opened by default) -> In right side: API/Zone ID
:local recordID "__RECORD_ID__" # curl -X GET "https://api.cloudflare.com/client/v4/zones/__ZONE_ID__/dns_records?type=A&name=__DOMAIN_NAME__>" -H "Authorization: Bearer __API_TOKEN__"


# Do not edit below
:local currentIP [/ip address get [find interface=$ifaceName] address]
:set currentIP [:pick $currentIP 0 [:find $currentIP "/"]]

:local cloudflareDNSIP [:resolve $domainName server=1.1.1.1];

:if ($currentIP != $cloudflareDNSIP) do={
  :local comment ("Updated at " . [/system clock get date] . " " . [/system clock get time] . " via RouterOS")

  # If the IP has changed, update the Cloudflare record
  :log info ("Updating Cloudflare record. Old IP: " . $cloudflareDNSIP . " New IP: " . $currentIP);

  :local httpHeaders ("Authorization: Bearer " . $apiToken)
  :local payload ("{\"type\":\"A\",\"name\":\"" . $domainName . "\",\"content\":\"" . $currentIP . "\",\"comment\":\"" . $comment . "\",\"proxied\":false}")
  :local url "https://api.cloudflare.com/client/v4/zones/$zoneID/dns_records/$recordID"

  /tool fetch mode=https url=$url http-method=put http-header-field=$httpHeaders http-data=$payload output=none
}
