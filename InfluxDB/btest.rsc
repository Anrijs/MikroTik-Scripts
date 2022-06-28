#user defines
:global addr [:resolve "0.0.0.0"]; # remote address
:global duration 10 # duration of speed test
:global influxUrl "http://0.0.0.0:8086"
:global influxDb  "Mikrotik"
:global hostname  "lhglte"

:global btestUser "remote-user"
:global btestPassword "remote-user-password"

# varaibles
:local data "lte,host=$hostname "
:local txavg
:local rxavg
:local pingavg

/tool/bandwidth-test address=$addr user=$btestUser password=$btestPassword direction=transmit duration=$duration protocol=tcp connection-count=10 do={
    :set txavg $"tx-total-average"
}

/tool/bandwidth-test address=$addr user=$btestUser password=$btestPassword direction=receive duration=$duration protocol=tcp connection-count=10 do={
    :set rxavg $"rx-total-average"
}

/tool/flood-ping address=$addr count=20 do={
    :set pingavg $"avg-rtt"
}

:set data "$(data)download=$(txavg),upload=$(rxavg),ping=$(pingavg)"

/tool/fetch \
    mode=http \
    url="$influxUrl/write?db=$influxDb" \
    http-method=post \
    output=none \
    http-data=$data
