# OrigenTFG

## Creació usuari de seguretat al servidor de l'Aucoop

Actualment totes les implementacions que s'han eren en l'entorn de proves que s'havia creat. Per fer-ho més específic, ara s'explicarà tot en l'entorn real. És a dir, es farà un resum per explicar el que s'hauria de posar en el cas que això es s'apliqués ja en l'entorn de proves real.

Primer de tot es començarà per crear l'usuari de seguretat al servidor de l'Aucoop, el qual perquè sigui més fàcil ara es representarà com **sshuser**.

Per crear aquest usuari executem:
```bash
aucoop@servidorAucoop: sudo adduser sshuser
```

Un cop creat l'usuari se li ha de restringir la shell:
```bash
aucoop@servidorAucoop: chsh -s /bin/rbash sshuser
```

En el moment en el que no té la bash normal, ja no pot accedir a altres directoris. El que s'ha de fer seguidament és crear un directori bin dintre el mateix usuari. Aquest directori servirà per posar-hi les comandes permeses. Quan s'hagi creat, s'ha de posar el path per defecte de l'usuari cap a aquest directori:
```bash
aucoop@servidorAucoop: sudo mkdir /home/sshuser/bin
aucoop@servidorAucoop: sudo chmod 755 /home/sshuser/bin
aucoop@servidorAucoop: echo "PATH=$HOME/bin" >> /home/sshuser/.bashrc
aucoop@servidorAucoop: echo "export PATH >> /home/<username>/.bashrc
```

Només queda fer un link de les comandes que es vulguin utilitzar en aquest usuari del directori bin normal, cap al de l'usuari, i per últim, evitar que es pugui modificar el fitxer .bashrc:
```bash
aucoop@servidorAucoop: sudo ln -s /bin/<comanda> /home/sshuser/bin
aucoop@servidorAucoop: chattr +i /home/sshuser/.bashrc
```

Sinó, sempre es pot utilitzar l'script que s'ha creat expressament per crear un usuari, que només pugui executar la comanda SSH. Aquest script necessita un paràmetre, que és el nom de l'usuari. És l'script anomenat creatUser.sh.

## Configuració keys

Com que al servidor de l'Aucoop actualment només estan funcionant amb un usuari, s'hauran d'esborrar les claus les quals no es vulgui que puguin accedir al servidor. Per fer això s'ha d'accedir a /home/aucoop/.ssh/authorized_keys i esborrar la línia de l'usuari que no ens interessi tenir.

Per crear la clau d'aquest nou usari, hem d'executar la comanda:
```bash
sshuser@servidorAucoop: ssh-keygen
```

Un cop creada la clau del nou usuari, s'han d'enviar les claus dels diferents usuaris als servidors oportuns per poder fer la connexió sense problema. Per tant s'ha de passar la clau del client de barcelona, al nou usuari del servidor de l'Aucoop, la clau del servidor de Senegal al nou usuari del servidor de l'Aucoop, i la clau del nou usuari de l'Aucoop al servidor de Senegal. Per tant es realitzaran les següents comandes:
```bash
sshuser@servidorAucoop: ssh-copy-id -i ~/.ssh/id_rsa.pub diadem@127.0.0.1
user@clientBarcelona: ssh-copy-id -i ~/.ssh/id_rsa.pub aucoop@147.83.200.187
diadem@servidorSenegal: ssh-copy-id -i ~/.ssh/id_rsa.pub aucoop@147.83.200.187
```

És important recordar, que per passar la clau del servidor de l'Aucoop al de Senegal, abans el servidor de Senegal s'ha d'haver connectat al de l'Aucoop i ha de permetre fer Reverse-tunnel.

Quan s'han configurat totes les claus, és el moment de començar a desenvolupar la solució al problema de l'estabilitat. Es començarà pel servidor de Senegal.

## Configuració SSH

### Servidor Senegal

S'ha de crear un fitxer a */etc/systemd/system/* acabat amb .service, en el cas actual. El fitxer ha de contenir el següent:
```bash
[Unit]
Description=AutoSSH tunnel to start at boot at local port 6666
After=network.target

[Service]
User=diadem
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -i /home/diadem/.ssh/id_rsa -o
UserKnownHostsFile=/dev/null -N -R 6666:localhost:22 
aucoop@147.83.200.187

[Install]
WantedBy=multi-user.target
```

Aquest servei està penjat i s'anomena autossh-tunnel.service.

Per ser capaços d'activar aquest servei a l'inici hem d'executar les comandes següents:
```bash
diadem@servidorSenegal: sudo systemctl daemon-reload
diadem@servidorSenegal: sudo systemctl start autossh-tunnel.service
diadem@servidorSenegal: sudo systemctl enable autossh-tunnel.service
diadem@servidorSenegal: sudo systemctl status autossh-tunnel
```

L'última comanda ens serveix per veure l'estat del servei. Seguidament s'ha de configurar l'actuació com a client, i l'actuació com a servidor.

Per la configuració com a client s'ha de generar un document a *~/.ssh* anomenat **config**. El document contindrà el següent:
```bash
Host *
      ServerAliveInterval 60
      ServerAliveCountMax 60
      StrictHostKeyChecking no
      ExitOnForwardFailure yes
      TCPKeepAlive yes
```

Un cop creat s'ha permetre que el fitxer sigui llegible i editable per l'usuari i no per cap altre persona:
```bash
diadem@servidorSenegal: chmod 600 ~/.ssh/config
```

Seguidament s'ha de configurar com a servidor modificant el fitxer */etc/ssh/sshd_config* i ha de tenir dos línies com les següents:
```bash
ClientAliveInterval 60
ClientAliveCountMax 60
TCPKeepAlive
```

Amb això ja es té el servidor de Senegal configurat.

### Client de Barcelona

Pel client de Barcelona s'ha optat per crear un script que faci la connexió automàticament fins al servidor de Senegal. L'script és el següent:
```bash
#!/bin/bash
ssh -tt -p 22 aucoop@147.83.200.187 'autossh -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=60 -p 6666 diadem@127.0.0.1'
```

Aquest script també està penjat i s'anomena startSSH.sh.

En aquest cas també s'ha de fer la configuració, però només del client. S'han de seguir els passos de l'anterior, i el fitxer ha de tenir el següent:
```bash
Host *
      ServerAliveInterval 60
      ServerAliveCountMax 60
      ExitOnForwardFailure yes
      TCPKeepAlive yes
```

### Servidor Aucoop

En aquest servidor es disposa de dos usuaris, però és recomanable fer-ho tot amb l'usuari que té privilegis per accedir com a root, ja que d'aquesta manera no s'haurà de fer cap canvi d'usuari.

En aquest cas només s'han de crear les configuracions, ja que no necessitem que el servidor de l'Aucoop faci res més.

Primer de tot s'ha de crear el fitxer que ens permetrà configurar el servidor, que es pot fer modificant el fitxer *sshd_config*:
```bash
ClientAliveInterval 60
ClientAliveCountMax 60
TCPKeepAlive yes
```

Quan hi ha el servidor configurat, s'ha de configurar el propi usuari que s'ha creat per l'SSH. Per tant s'ha de crear un fitxer anomenat **config** al directori de l'usuari */home/sshuser/.ssh/*. El fitxer ha de contenir el següent:
```bash
Host *
     ServerAliveInterval 60
     ServerAliveCountMax 60
     ExitOnForwardFailure yes
     TCPKeepAlive yes
```
