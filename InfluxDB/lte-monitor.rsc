:global influxUrl "http://0.0.0.0:8086"
:global influxDb  "Mikrotik"
:global hostname  "chateau18"


# Returns true if value exists/not null
#   arg1: vakue to check
:local exists do={
    :if ([:typeof $1] = "nil") do={
      :return no
    } else={
      :return yes
    }
}

# Returns parsed band data
#   arg1: band info string
#   returns band data array
:local parseBandStr do={
  :local pos1      [:find $1 "@"]
  :local pos2      [:find $1 "M"]
  :local pos3      [:find $1 "earfcn: "]
  :local pos4      [:find $1 "phy-cellid: "]

  :local band      [:pick $1 1 $pos1]
  :local bandwidth [:pick $1 ($pos1+1) $pos2]
  :local isnr      ([:pick $1 0 1]="n")

  :local earfcn    [:pick $1 ($pos3+8) ($pos4-1)]
  :local cellid    [:pick $1 ($pos4+12) [:len $1]]

  :return {
    "bandnum"=$band;
    "bandwidth"=$bandwidth;
    "isnr"=$isnr;
    "earfcn"=$earfcn;
    "cellid"=$cellid;
  }
}

# Returns formated influxdb field string 
#   arg1: band data array
#   arg2: influxdb field prefix
#   returns band data array
:local bandInfoToInflux do={
  :local str (str . "$2" . "bandnum=" . $1->"bandnum")
  :set   str (str . ",$2" . "bandwidth=" . $1->"bandwidth")
  :set   str (str . ",$2" . "earfcn=" . $1->"earfcn")
  :set   str (str . ",$2" . "cellid=" . $1->"cellid")

  :return $str
}

/interface/lte/monitor numbers=lte1 once do={
    :local payload "lte,host=$hostname "
    :local capayload ""

    :local b0 [:typeof $"primary-band"]
    :local b1 [:typeof $"ca-band"]

    :if ($b0 = "nil") do={ 
      # cat4 modem
      :local pos1      [:find $"earfcn" "band "]
      :local pos2      [:find $"earfcn" ","]
      :local pos3      [:find $"earfcn" "bandwidth "]
      :local pos4      [:find $"earfcn" "Mhz"]

      :local bandnum   [:pick $"earfcn" ($pos1+5) $pos2]
      :local bandwidth [:pick $"earfcn" ($pos3+10) $pos4]

      :set payload (payload . "bandnum=$bandnum,bandwidth=$bandwidth")
    } else={
      # ca capable modem
      :local bandinfo [$parseBandStr $"primary-band"]
      :set payload (payload . [$bandInfoToInflux $bandinfo ""])
    }

    :if ($b1 = "nil") do={
      # no ca bands
    } else={
      :local nrnum 1
      :local canum 1
      :local pos   0
      :local count [:len $"ca-band"]

      # parse all ca bands
      :while ($pos < $count) do={
        :local bandstr [:pick $"ca-band" $pos]
        :set pos ($pos+1)

        :local bandinfo [$parseBandStr $bandstr]
        :local prefix ("ca" . $canum)

        # check if is NR or LTE
        :if ($bandinfo->"isnr") do={
          :set prefix ("nr" . $nrnum)
          :set nrnum ($nrnum+1)
        } else={
          :set canum ($canum+1)
        }

        :set capayload (capayload . "," . [$bandInfoToInflux $bandinfo ($prefix . "-")]) 
      }
    }

    # signal info
    :if ([$exists $rssi]) do={ :set payload (payload . ",rssi=$rssi") }
    :if ([$exists $rsrp]) do={ :set payload (payload . ",rsrp=$rsrp") }
    :if ([$exists $rsrq]) do={ :set payload (payload . ",rsrq=$rsrq") }
    :if ([$exists $sinr]) do={ :set payload (payload . ",sinr=$sinr") }

    :if ([$exists $cqi]) do={ :set payload (payload . ",cqi=$cqi") }
    :if ([$exists $ri]) do={ :set payload (payload . ",ri=$ri") }
    :if ([$exists $mcs]) do={ :set payload (payload . ",mcs=$mcs") }

    # nr signal info
    :if ([$exists $"nr-rsrp"]) do={ :set payload (payload . ",nr-rsrp=$(nr-rsrp)") }
    :if ([$exists $"nr-rsrq"]) do={ :set payload (payload . ",nr-rsrq=$(nr-rsrq)") }
    :if ([$exists $"nr-sinr"]) do={ :set payload (payload . ",nr-sinr=$(nr-sinr)") }
       
    :if ([$exists $"nr-cqi"]) do={ :set payload (payload . ",nr-cqi=$(nr-cqi)") }
    :if ([$exists $"nr-ri"]) do={ :set payload (payload . ",nr-ri=$(nr-ri)") }
    :if ([$exists $"nr-mcs"]) do={ :set payload (payload . ",nr-mcs=$(nr-mcs)") }

    # cell info
    :if ([$exists $"enb-id"]) do={ :set payload (payload . ",enb-id=$(enb-id)") }
    :if ([$exists $"sector-id"]) do={ :set payload (payload . ",sector-id=$(sector-id)") }
    :if ([$exists $"current-cellid"]) do={ :set payload (payload . ",current-cellid=$(current-cellid)") }
    :if ([$exists $"phy-cellid"]) do={ :set payload (payload . ",phy-cellid=$(phy-cellid)") }
    
    :set payload (payload . capayload)

    /tool/fetch mode=http url="$influxUrl/write?db=$influxDb" http-method=post http-data="$payload" output=none
}
