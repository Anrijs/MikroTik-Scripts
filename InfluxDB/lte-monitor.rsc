:global influxUrl "http://0.0.0.0:8086"
:global influxDb  "Mikrotik"
:global hostname  "chateau18"

:global exists do={
    :if ([:typeof $1] = "nil") do={
      :return no
    } else={
      :return yes
    }
}

/interface/lte/monitor numbers=lte1 once do={
    :local payload "lte,host=$hostname "

    :local bandnum 0
    :local bandwidth 0

    :local b0 [:typeof $"primary-band"]

    :if ($b0 = "nil") do={ 
      # cat4 modem
        :local pos1      [:find $"earfcn" "band "]
        :local pos2      [:find $"earfcn" ","]
        :local pos3      [:find $"earfcn" "bandwidth "]
        :local pos4      [:find $"earfcn" "Mhz"]

        :set bandnum   [:pick $"earfcn" ($pos1+5) $pos2]
        :set bandwidth [:pick $"earfcn" ($pos3+10) $pos4]
    } else={
      :local pos1      [:find $"primary-band" "@"]
      :local pos2      [:find $"primary-band" "M"]

      :set bandnum   [:pick $"primary-band" 1 $pos1]
      :set bandwidth [:pick $"primary-band" ($pos1+1) $pos2]
    }

    :if ($banddum != 0) do={
        :set payload (payload . "bandnum=$bandnum,bandwidth=$bandwidth")

        # signal info
        :if ([$exists $rssi]) do={ :set payload (payload . ",rssi=$rssi") }
        :if ([$exists $rsrp]) do={ :set payload (payload . ",rsrp=$rsrp") }
        :if ([$exists $rsrq]) do={ :set payload (payload . ",rsrq=$rsrq") }
        :if ([$exists $sinr]) do={ :set payload (payload . ",sinr=$sinr") }

        :if ([$exists $cqi]) do={ :set payload (payload . ",cqi=$cqi") }
        :if ([$exists $ri]) do={ :set payload (payload . ",ri=$ri") }
        :if ([$exists $mcs]) do={ :set payload (payload . ",mcs=$mcs") }

        # cell info
        :if ([$exists enb-id]) do={ :set payload (payload . ",enb-id=$(enb-id)") }
        :if ([$exists sector-id]) do={ :set payload (payload . ",sector-id=$(sector-id)") }
        :if ([$exists current-cellid]) do={ :set payload (payload . ",current-cellid=$(current-cellid)") }
        :if ([$exists phy-cellid]) do={ :set payload (payload . ",phy-cellid=$(phy-cellid)") }
    } else={
      :put "failed to get band info"
      :return
    }

    /tool/fetch mode=http url="$influxUrl/write?db=$influxDb" http-method=post http-data="$payload" output=none
}

