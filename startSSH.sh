#!/bin/bash

ssh -tt -p 22 aucoop@147.83.200.187 'autossh -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=60 -p 6666 diadem@127.0.0.1'
