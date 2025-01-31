[Unit]
Description=Time-based mount attempt for ${NAME}.service

[Timer]
OnCalendar=$STARTAT
RandomizedDelaySec=10
Persistent=true

[Install]
WantedBy=timers.target
