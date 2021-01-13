# OrigenTFG

##Servidor Senegal

Primer començarem explicant el que hem implementat al servidor del Senegal. El que volíem en aquest servidor era sobretot que es mantingués la connexió oberta i en cas que s'hagués d'apagar el servidor, que es re-connectes automàticament.

Per tal d'efectuar això, s'ha optat per usar AutoSSH, ja que si la connexió cau, ens permet no haver-nos de preocupar, ja que el programa s'encarregarà de tornar a aixecar l'SSH i re-connectar-se amb el servidor de l'Aucoop.

Primerament es començarà explicant que és el que s'ha fet per implementar l'SSH a l'inici del boot, perquè es connecti automàticament. Per tal d'executar el servei en el boot, hem de crear un fitxer .service a /etc/systemd/system/. En aquest projecte s'ha creat un fitxer anomenat autossh-tunnel.service. En aquest fitxer hi tenim el següent:

```bash
[Unit]
Description=AutoSSH tunnel to start at boot at local port 6666
After=network.target

[Service]
User=servidorSenegal
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -i /home/servidorSenegal/.ssh/id_rsa -o
UserKnownHostsFile=/dev/null -N -R 6666:localhost:22 
servidorAucoop@192.168.20.5

[Install]
WantedBy=multi-user.target
```

A continuació hi ha una explicació de cada línia anterior:

Primerament tenim la descripció del servei, el qual ens descriu el que fa aquest servei. Seguidament tenim la línia "After=network.target", bàsicament significa que aquest servei s'inicia just quan la xarxa de l'ordinador s'activa.

La part de servei, és la part en que decidim que executar. Primer tenim l'usuari amb el qual s'executarà la comanda, això és útil per saber a quin usuari posar el fitxer de configuració, després veiem que tenim l'apartat de l'entorn amb AUTOSSH\_GATETIME=0, això apaga el comportament del gatetime, però apart, també ignora els primers errors alhora de fer ssh, i això ens és molt útil a l'arrencada. Finalment tenim la comanda que s'executarà amb els diferents paràmetres necessaris.

Per últim tenim el multi-user.target, que ens indica que aquest servei s'hauria d'iniciar en el moment d'inicar l'ordinador, com la majoria de serveis, encara que no tinguem una interfície gràfica.

Un cop hem implementat el fitxer correctament, hem de reiniciar els daemons, i permetre que l'AutoSSH s'executi en el boot, per tal de fer això hem d'executar les següents comandes:

```bash
sudo systemctl daemon-reload
sudo systemctl start autossh-tunnel.service
sudo systemctl enable autossh-tunnel.service
```

Un cop hem executat les anterior comandes, ja tenim l'autoSSH iniciat, hem reiniciat el daemon, i ja hem habilitat que s'executi aquest servei quan es fa el boot. Si es vol comprovar l'estat del servei simplement s'ha d'executar:
```bash
sudo systemctl status autossh-tunnel
```

L'Autossh utilitza els fitxers de configuració de l'SSH, per tant, com que el servidor de Senegal actuarà com a client, i com a servidor, s'han de fer les configuracions pertinents.

Es començarà amb la configuració de l'actuació com a client. Per tal d'utilitzar la configuració que hem creat en el fitxer personalitzat, s'ha de crear aquest fitxer anomenat **config** a la carpeta ~/.ssh/. El fitxer es veu de la següent manera:
```bash
Host *
      ServerAliveInterval 60
      ServerAliveCountMax 60
      StrictHostKeyChecking no
      ExitOnForwardFailure yes
```

El que ens indica el fitxer anterior, és que a qualsevol amfitrió al que ens connectem, si el servidor perd la connexió, estarà una hora intentant re-connectar, i si el servidor segueix sense contestar, llavors es tancarà la connexió. A part, si es tanca la connexió, també es tancaran tots els ports que s'han utilitzat. Això és important ja que si passa això i justament es reactiva el servidor, s'hauria d'esperar un temps, o accedir al servidor per poder tornar a accedir al port utilitzat.

Quan hem creat i emplenat el fitxer, ara hem d'executar la següent comanda per tal de que el fitxer sigui llegible i editable per l'usuari, i no per cap altre persona:
```bash
chmod 600 ~/.ssh/config
```

Un cop hem configurat correctament l'SSH com a client, s'ha de configurar com a servidor, ja que també actuarà com a ell, quan l'ordinador de Barcelona es connecti.

Per crear aquesta configuració, s'ha d'anar directament al fitxer de configuració generat per l'SSH, el qual es troba a /etc/ssh/ i el fitxer s'anomena **sshd_config**. Hi ha moltes línies escrites, però totes estan comentades. Per tal de configurar-lo hem de buscar les línies que posen ClientAliveInterval i ClientAliveCountMax, descomentar-les i canviar els números que trobarem al fitxer, per els mateixos números que hem posat a l'apartat anterior.

Per resumir-ho ens quedaria així:
```bash
ClientAliveInterval 60
ClientAliveCountMax 60
```

Després d'això el servidor de Senegal ja estaria configurat i apunt per connectar-se.

##Client de Barcelona
Pel client de Barcelona s'ha optat per crear un script que permeti, només d'executar-lo, es connecti amb el servidor de Senegal, per així evitar haver d'entrar primer al servidor de l'Aucoop, i després executar una altre comanda per connectar-se a Senegal. Aquest script no s'executarà automàticament al boot, sinó que l'usuari serà el responsable d'executar-lo quan ell vulgui.

S'ha optat per fer-ho així, perquè no ens interessa que sempre estigui connectat, i a part d'això, normalment es vol una shell quan es connecta per SSH, i si s'hagués de fer automàticament, el més lògic seria muntar el sistema de fitxers del Senegal amb el del propi ordinador. L'script que s'ha implementat és el següent:

```bash
#!/bin/bash

ssh -tt -p 22 servidorAucoop@192.168.10.5 'ssh -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=60 -p 6666 servidorSenegal@127.0.0.1'
```

La comanda anterior ens servirà primer per connectar-nos al servidor de l'Aucoop, i automàticament, connectar-se al servidor de Senegal a través del localhost.

En aquest cas tenim un paràmetre que és el -tt. Aquest ens serveix per quan ens connectem, tenir un shell visual, ja que sinó ens quedem sense shell quan ens connectem.

Els ports que s'utilitzen, han de ser els mateixos que utilitzem en la crida de l'AutoSSH, i aquesta part és molt important, perquè sinó no serà possible connectar amb el localhost de Senegal i per tant no hi tindrem connexió.

Un cop connectat s'executarà la comanda que tenim entre les cometes "**''**". En aquesta comanda s'hi afegeixen els paràmetres de *ServerAliveInterval* i *ServerAliveCountMax*, perquè al fer-se directament després d'executar l'SSH al servidor de l'Aucoop, no agafa la configuració que trobem en aquest servidor, i tampoc el de l'ordinador de Barcelona actual.

Un cop creat l'script, s'ha de configurar el propi SSH. Aquest cop només és necessari configurar l'SSH del client, ja que ningú s'ha de connectar a aquest ordinador. La configuració es fa exactament igual que abans, es crea un fitxer a ~/.ssh/ anomenat **config**, i és aquesta:

```bash
Host *
      ServerAliveInterval 60
      ServerAliveCountMax 60
      ExitOnForwardFailure yes
```
