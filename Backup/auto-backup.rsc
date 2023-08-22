# Auto backup script
# 
# This script will backup router configuration and upload it to ftp server
# Updated: 2013-08-22
#

# Remote server config
# change "useremote" to false to disable remote uplaods

:local ftpBackup       true
:local ftpAddress      10.0.0.100
:local ftpUser         ftpuser
:local ftpPassword     ftppass
:local ftpPath         /

:local backupPwd       strongpassword

# use true to enable, false to disable
:local rsc    true
:local backup true
:local cloud  true


# automatic values
:local sn    [/system routerboard get serial-number]
:local model [/system routerboard get model]
:local ident [/system identity get name]

# use true to include sensitive data in rsc
:local sensitive false

# use true to remove local files
:local removelocal true

# nothing to change below this line ...
:local filename

:local date [/system clock get date]
:local time [/system clock get time]
:local month [:tostr ([:find "janfebmaraprmayjunjulaugsepoctnovdec" [:pick $date 0 3]] / 3 + 1)]

:if ([:tonum $month]<10) do={
  :set month "0$month"
}

:set filename ( \
  $ident . "_" . $sn . "_" . $date ."_". \
  [:pick $time 0 2]."-".[:pick $time 3 5]."-".[:pick $time 6 8] \
)

:if ($rsc = true) do={
  /log info message="backup rsc"
  if ($sensitive = true) do={
    /export compact file=$filename
  } else={
    /export compact hide-sensitive file=$filename
  }

  if ($ftpBackup = true) do={
    /tool fetch address=$ftpAddress src-path=($filename.".rsc") user=$ftpUser mode=ftp password=$ftpPassword \
      dst-path=($ftpPath . $filename . ".rsc") upload=yes
  }

  :if ($removelocal = true) do={
    :delay 2500ms
    /file remove ($filename.".rsc")
  }
}

:if ($backup = true) do={
  /system backup save encryption=aes-sha256 name=$filename password=$backupPwd
  if ($ftpBackup = true) do={
    /tool fetch address=$ftpAddress src-path=($filename.".backup") user=$ftpUser mode=ftp password=$ftpPassword \
      dst-path=($ftpPath . $filename . ".backup") upload=yes
  }

  :if ($removelocal = true) do={
    :delay 2500ms
    /file remove ($filename.".backup")
  }
}

:if ($cloud = true) do={
  /system backup cloud upload-file action=create-and-upload password=$backupPwd
}
