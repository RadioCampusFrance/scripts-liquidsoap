# pige d'antenne de Radio Campus Grenoble

# Ce script fonctionne sur une machine dédiée, qui reçoit nos programmes par sa
# carte son, les enregistre dans un fichier par heure (et un dossier par jour)
# et transmet au serveur Icecast (pour l'écoute sur Internet).
# On conserve 50 jours.

# amplify parce que l'entree son est bizarrement faiblarde, dans cette carte son
source = amplify(2.0, input.alsa(device="pcm.liquidsoap"))

output.icecast(id="icecast",
	host = "192.168.1.13",
	port = 8000,
	user = "source",
	password = "",
	mount = "rcg112",
	%mp3.vbr(quality=3),
	source
)

output.file(id="pige",
	%wav,
	"/home/campus/pige/%Y-%m-%d/%Hh%M_%S.wav",
	source,
	reopen_when = {0m} 
)

exec_at(freq=3600., pred={ true },
    fun () -> list.iter(fun(msg) -> log(msg, label="nettoyeur_de_pige"),
        list.append(
            get_process_lines("find /home/campus/pige/* -type f -mtime +50 -delete"),
            get_process_lines("find /home/campus/pige/* -type d -empty -delete")
        )
    )
)
