[Unit]
Description=Service to manage ${NAME}.mount
After=network-online.target
Requires=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl start ${NAME}.mount
ExecStop=/usr/bin/systemctl stop ${NAME}.mount
RemainAfterExit=yes
TimeoutStartSec=5

[Install]
WantedBy=multi-user.target
