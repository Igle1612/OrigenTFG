#!/bin/bash
if [ $# -ne 1 ]
then
	echo "Usage: Necessita un paràmetre, que és el nom de l'usuari"
	exit 0
else
	adduser $1
	chsh -s /bin/rbash $1
	mkdir /home/$1/bin
	chmod 755 /home/$1/bin
	echo "PATH=$HOME/bin" >> /home/$1/.bashrc
	echo "export PATH" >> /home/$1/.bashrc
	sudo ln -s /bin/ssh /home/$1/bin/
fi
exit 0
