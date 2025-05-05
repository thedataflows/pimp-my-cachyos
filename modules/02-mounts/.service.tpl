[Unit]
Description=Service to manage ${WHERE_NAME}.mount
After=network-online.target
Requires=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/systemctl start ${WHERE_NAME}.mount
ExecStop=/usr/bin/systemctl stop ${WHERE_NAME}.mount
RemainAfterExit=yes
TimeoutStartSec=3

[Install]
WantedBy=multi-user.target
