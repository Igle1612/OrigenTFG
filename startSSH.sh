#!/bin/bash

ssh -tt -p 22 sshuser@192.168.10.5 'autossh -o ServerAliveInterval=180 -o ServerAliveCountMax=30 -p 6666 servidorSenegal@127.0.0.1'
