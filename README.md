# OrigenTFG

## Creació usuari de seguretat al servidor de l'Aucoop

Per crear un nou usuari s'ha d'executar la següent comanda:

```bash
sudo adduser USERNAME
```

Un cop creat l'usuari, s'ha de comprovar que no estigui al grup de sudo, per tant s'ha d'executar:

```bash
sudo deluser USERNAME sudo
```

Un cop s'ha tret del grup de sudoers, si ens interessa restringir alguna altre comanda, hi ha diverses opcions:

- Primer de tot es pot canviar el bash de l'usuari, perquè en contes de ser /bin/bash, sigui /bin/rbash. Això provocarà que en contes de tenir un bash normal i corrent, tinguin un \textit{restricted bash}. Aquest bash el que no permet és que l'usuari canvii de directoris, i per tant, no podrà accedir a la informació dels altres usuaris del sistema.

- La segona manera que hi ha per restringir el que faci l'usuari és crear diferents alies, que substitueixin els alies que hi ha creats pel sistema. Per fer això s'ha d'accedir a /home/USERNAME i crear un fitxer anomenat bash\_profile, i en aquest document s'han d'afegir nous alies. Seguidament hi ha un exemple del fitxer:
    ```bash
    alias apt-get="print ''"
    alias su="print ''"
    [...]
    alias alias="printf ''"
    ```
Com es pot veure, el que es fa aquí és bàsicament canviar els alias del sistema, que quan es vulguin executar, traurà un printf. És molt important, al posar la línia final,    ja que sinó no es poden fer alies de totes aquestes comandes. En aquesta opció es posen totes les comandes que no es volen que es puguin executar.

- Per últim, hi ha l'opció contraria a la que s'ha mencionat en el número dos. Bàsicament es tracta de no permetre cap comanda, excepte les que es vulguin permetre, que són les que s'han de citar explícitament. Aquests són els passos que s'han de seguir

1. Canviar la shell de l'usuari per una restricted bash. Això servirà per evitar que es pugui accedir a altres directoris. Per fer això es pot executar la següent comanda:
    ```bash 
     chsh -s /bin/rbash <username>
     ```
2. Crear un directori \textit{bin} dintre el mateix usuari. es poden utilitzar les següents comandes:
     ```bash 
     sudo mkdir /home/<username>/bin
     sudo chmod 755 /home/<username>/bin
     ```
3. Seguidament s'ha de canviar el path per defecte de l'usuari al directori bin.
     ```bash 
     echo "PATH=$HOME/bin" >> /home/<username>/.bashrc
     echo "export PATH >> /home/<username>/.bashrc
     ```
4. El següent pas és crear un link de les comandes que l'usuari necessita. D'aquesta manera es pot assegurar que només pugui executar les comandes que es decideixin. Es pot fer això executant la següent comanda:
     ```bash 
     sudo ln -s /bin/COMMAND /home/<username>/bin/
     ```
5. Per últim, s'ha de restringir l'usuari de modificar el .bashrc, per evitar que es pugui desfer tot el que s'ha fet. Una comanda per executar això és:
     ```bash 
     chattr +i /home/<username>/.bashrc
     ```


## Configuració de les claus

Per tornar a configurar totes les keys, que segurament no es volen tenir per exemple a l'usuari del servidor de l'Aucoop, s'han d'esborrar primer. El que hem de fer és esborrar la clau de ~/.ssh/authorized_keys. S'ha d'esborrar la línia que ens interessi.

Si es vol crear una clau nova s'ha d'executar la comanda:
```bash
ssh-keygen
```
Seguidament es demana on es vol guardar la clau creada. Es recomana deixar-ho per defecte, ja que així és més fàcil localitzar-les. Es guarden a /home/USERNAME/.ssh/id_rsa.

Quan hi hagi la clau creada, s'ha d'enviar al servidor al qual ens volem connectar, perquè d'aquesta manera s'hi podrà accedir sense necessitat de contrasenya. Per enviar-la:
```bash
ssh-copy-id -i ~/.ssh/id_rsa.pub <username>@<ip>
```
Un cop executada la comanda, et demanarà que introdueixis una contrasenya. Per fer-ho tot més fàcil, s'han de deixar buides les contrasenyes, d'aquesta manera no serà necessari entrar-les manualment després.


## Servidor Senegal

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
aucoop@147.83.200.187

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

## Client de Barcelona
Pel client de Barcelona s'ha optat per crear un script que permeti, només d'executar-lo, es connecti amb el servidor de Senegal, per així evitar haver d'entrar primer al servidor de l'Aucoop, i després executar una altre comanda per connectar-se a Senegal. Aquest script no s'executarà automàticament al boot, sinó que l'usuari serà el responsable d'executar-lo quan ell vulgui.

S'ha optat per fer-ho així, perquè no ens interessa que sempre estigui connectat, i a part d'això, normalment es vol una shell quan es connecta per SSH, i si s'hagués de fer automàticament, el més lògic seria muntar el sistema de fitxers del Senegal amb el del propi ordinador. L'script que s'ha implementat és el següent:

```bash
#!/bin/bash

ssh -tt -p 22 aucoop@147.83.200.187 'ssh -o ExitOnForwardFailure=yes -o ServerAliveInterval=60 -o ServerAliveCountMax=60 -p 6666 diadem@127.0.0.1'
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

## Servidor de l'Aucoop

El servidor de l'Auccop actuarà com a client i com a servidor tot i que en principi en cap moment s'executarà cap comanda.

S'ha de tenir en conta, que en aquest servidor tindrem dos usuaris, un usuari que serà el normal, i un altre al qual no se li permetrà accedir com a root, per evitar que des de Senegal, es pugui accedir, i modificar fitxers importants que no es vol que es modifiquin. Per tant, separarem amb quin usuari hem de configurar cada cosa:

### Usuari root:
Amb aquest usuari s'haurà de configurar el servidor. Utilitzarem aquest usuari, perquè en principi és l'únic que té la capacitat de modificar el fitxer sshd\_config.

Per modificar aquest fitxer hem de modificar exactament el mateix que abans, i no tocar ni modificar res més del que ja hi trobem escrit, per evitar problemes en les configuracions, per tant l'únic que hem d'afegir ha de ser:

```bash
ClientAliveInterval 60
ClientAliveCountMax 60
```

Si es vol assegurar que cap usuari que es connecti per ssh pugui entrar en root, podem descomentar la línia de PermitRootLogin i posar-la a "no", per tant les línies que s'haurien de descomentar serien:

```bash
ClientAliveInterval 60
ClientAliveCountMax 60
PermitRootLogin no
```

### Usuari ssh:

Aquest usuari haurà de crear la configuració com a client, ja que utilitzarem aquest usuari com a intermediari.

Per configurar-lo s'ha de fer com s'ha fet els anteriors cops. S'ha de crear un fitxer anomenat **config**. En aquest fitxer ens hem d'assegurar que tinguem també la possibilitat de no rebre resposta del servidor durant una hora, i tot i així seguir connectats, i en cas de fallada, el port s'hauria de tancar automàticament, per tant el fitxer hauria de tenir:
 ```bash
Host *
      ServerAliveInterval 60
      ServerAliveCountMax 60
      ExitOnForwardFailure yes
```
