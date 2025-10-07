[Unit]
Description=Time-based mount attempt for ${NAME}.service

[Timer]
OnCalendar=$STARTAT
RandomizedDelaySec=5
Persistent=true

[Install]
WantedBy=timers.target
