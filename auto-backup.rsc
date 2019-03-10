# Auto backup script
# 
# This script will backup router configuration and upload it to ftp server
# Updated: 2019-03-10
#

{
  # Remote server config
  # change "useremote" to false to disable remote uplaods
  :local useremote true      
  :local address 10.0.0.100
  :local user ftpuser
  :local password  ftppassword

  # use true to enable, false to disable
  :local rsc true
  :local backup true

  # use true to include sensitive data in rsc
  :local sensitive false

  # use true to remove local files
  :local removelocal true



  # nothing to change below this line ...
  :local filename

  :local identity [/system identity get name]
  :local date [/system clock get date]
  :local time [/system clock get time]
  :local month [:tostr ([:find \
    "janfebmaraprmayjunjulaugsepoctnovdec" [:pick $date 0 3] \
  ]/3+1)]
  :if ([:tonum $month]<10) do={
    :set month "0$month"
  }
  :set filename ( \
    $identity."_20".[:pick $date 9 11]."-".$month."-".[:pick $date 4 6]."_". \
    [:pick $time 0 2]."-".[:pick $time 3 5]."-".[:pick $time 6 8] \
  )

  :if ($rsc = true) do={
    /log info message="backup rsc"
    if ($sensitive = true) do={
      /export compact file=$filename
    } else={
      /export compact hide-sensitive file=$filename
    }

    if ($useremote = true) do={
      /tool fetch address=$address src-path=($filename.".rsc") user=$user mode=ftp password=$password \
        dst-path=("backups/".$filename.".rsc") upload=yes
    }

    :if ($removelocal = true) do={
      :delay 2500ms
      /file remove ($filename.".rsc")
    }
  }

  :if ($backup = true) do={
    /system backup save encryption=aes-sha256 name=$filename
    if ($useremote = true) do={
      /tool fetch address=$address src-path=($filename.".backup") user=$user mode=ftp password=$password \
        dst-path=("backups/".$filename.".backup") upload=yes
    }
    
    :if ($removelocal = true) do={
      :delay 2500ms
      /file remove ($filename.".backup")
    }
  }
}
