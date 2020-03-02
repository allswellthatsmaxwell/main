#!/bin/bash
## Need to run as sudo.
yum install docker
usermod -a -G docker ec2-user ## if running Amazon Linux
service docker start
"
