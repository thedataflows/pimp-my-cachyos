[Unit]
Description=Local mount unit for $NAME
$AFTER
ConditionPathExists=$WHERE
ConditionPathIsMountPoint=!$WHERE

[Mount]
What=$WHAT
Where=$WHERE
Type=$TYPE
Options=$OPTIONS

[Install]
WantedBy=multi-user.target
