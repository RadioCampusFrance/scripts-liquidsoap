# Script Liquidsoap principal de Radio Campus Grenoble

# On utilise Beets comme librairie musicale, et Showergel pour compléter
# cf. https://martinkirch.github.io/tag/liquidsoap.html
#     https://showergel.readthedocs.io

# Coté syntaxe :
# - les espaces ne sont pas importants, ni l'ordre des paramètres nommés (comme id="truc")
# - fermez bien les parenthèses, crochets et autres accolades !
# - sur une ligne, le # est ce qui est après est ignoré : ça nous permet d'écrire ce genre de commentaires
# - certains paramètres (surtout les délais) sont des nombres à virgule:
#   mais la virgule est en fait un point, et il est obligatoire

# et TOUJOURS utiliser "liquidsoap --check rcg.liq" avant de relancer

############# ON COMMENCE PAR LES REGLAGES ###################################

set("server.telnet", true)
set("server.telnet.bind_addr", "127.0.0.1")
set("server.telnet.port", 1234) # attention à mettre un numéro différent à chaque script qui tourne

# le résultat de "which beet" sur cet ordi (taper `which beet`)
BEET = "/home/campus/.local/bin/beet"

# l'adresse à laquelle écoute l'install Showergel (rcg_gel)
SHOWERGEL = "http://localhost:9080"

# le répertoire de base contenant les émissions:
EMI = "/home/campus/ANTENNE/Emissions/"
# et celui des émissions extérieures
EMI_EXT = "/home/campus/ANTENNE/EmissionsExterieures/"

# niveau (en db RMS) de normalisation dynamique des spots, jingles et bandes-annonces
# attention à adapter en parrallèle le "targetlevel" du plug-in replaygain de Beets
NIVEAU_SPOTS_BA_JINGLES = -19.
	
set("scheduler.fast_queues", 2)
set("scheduler.generic_queues", 4)
set("scheduler.log", true)
set("scheduler.non_blocking_queues", 4)

############# ALLEZ C'EST PARTI ###################################

# on précise "replay_metadata=false" à la plupart des opérateurs switch/random/fallback
# car, par défaut, ils re-envoient les meta-données de la source d'avant quand
# ils rendent la main, ce qui créé des doublons dans la playlist
# par ailleurs : il y a des fausses transitions qui contournent le bug de répétition des meta-données
# https://github.com/savonet/liquidsoap/issues/1476#issuecomment-765901080

############################ EMISSIONS ######################################

def emission(nom)
  def force_titre_emission(md) =
    list.add(("title", nom), md)
  end
  delay(id="#{nom}_", 10000., # 10000s = ~3h, pour éviter de rejouer l'emission si elle a un créneau long
    map_metadata(force_titre_emission, # parce que souvent les emissions sont mal tagguées
      eat_blank(max_blank=10.0, threshold=-50.0, # en cas d'oubli de silence à la fin
        audio_to_stereo( # au cas où un fichier mono est fourni... évite que le décodeur bute dessus en boucle
          playlist(reload_mode="watch", mode="normal", id=nom, "#{EMI}#{nom}")
        )
      )
    )
  )
end

def emission_ext(nom)
  def force_titre_emission(md) =
    list.add(("title", nom), md)
  end
  delay(id="#{nom}_", 10000., # 10000s = ~3h, pour éviter de rejouer l'emission si elle a un créneau long
    map_metadata(force_titre_emission, # parce que souvent les emissions sont mal tagguées
      eat_blank(max_blank=10.0, threshold=-50.0, # en cas d'oubli de silence à la fin
        audio_to_stereo( # au cas où un fichier mono est fourni... évite que le décodeur bute dessus en boucle
          playlist(reload_mode="watch", mode="normal", id=nom, "#{EMI_EXT}#{nom}")
        )
      )
    )
  )
end

### ATTENTION 
### il ne faut appeler emission() qu'une fois par dossier
### donc pour les emissions diffusées à plusieurs créneaux
### on prépare une variable à ré-utiliser dans la grille :

aperophonie = emission("Aperophonie")
Instant_Livres = emission("Instant Livres")
english_talk_radio = emission("English Talk Radio")
chronique_cine = emission("La Chronique Cine")
########## Emissions Temporaires #################

##################################################
metaclassique = emission_ext("Metaclassique")
H1000 = emission_ext("H1000")

# et c'est parti pour la grille

emissions = switch(id="emissions", replay_metadata=false, [
  ({1w08h00-1w08h10}, aperophonie),
  ({1w11h30-1w11h40}, emission("Vortex et Rotative")),
  ({1w12h30-1w12h40}, emission("Slippery When Wet")),
  ({1w16h00-1w16h10}, emission_ext("La Souterraine")),
  ({1w17h30-1w17h40}, emission("Rhizome")),
  ({1w18h00-1w18h10}, aperophonie),
  ({1w19h00-1w19h10}, emission("Mineur De Son")),
  ({1w20h00-1w20h10}, emission("Pastoral Mecanique")),
  ({1w21h00-1w21h10}, emission("Rotten to the Core")),
  ({1w23h00-1w23h10}, emission("Indie Drome")),
  
#mardi
  ({2w08h00-2w08h10}, aperophonie),
  ({2w16h00-2w16h10}, emission("Le Flou Sur La Langue")),
  ({2w17h00-2w17h10}, H1000),
  ({2w18h00-2w18h10}, aperophonie),
  ({2w19h00-2w19h10}, emission("Dig It")),
  ({2w20h00-2w20h10}, emission("Trafic 908")),		
#mercredi
  ({3w08h00-3w08h10}, aperophonie),
  ({3w10h15-3w10h20}, Instant_Livres),
  ({3w10h30-3w10h32}, chronique_cine),
  ({3w15h30-3w15h40}, emission("Pop en Stock")),
  ({3w17h00-3w17h10}, emission_ext("Starting Block")),
  ({3w18h00-3w18h10}, aperophonie),
  ({3w19h00-3w19h10}, english_talk_radio),
  ({3w19h30-3w19h40}, emission("Voix de Garage")),
  ({3w21h00-3w21h10}, emission("Rockology")),
#jeudi
  ({4w08h00-4w08h10}, aperophonie),
  ({4w15h00-4w15h05}, emission("Contes de Griotte")),
  ({4w17h00-4w17h10}, emission("Intrinseque")),
  ({4w18h00-4w18h10}, aperophonie),
  ({4w19h00-4w19h10}, emission("DegenreE ou Grand Palace")),
  ({4w20h00-4w20h10}, emission("Franche Touche")),
  ({4w20h30-4w20h40}, emission("Wise Up Station")),
  ({4w21h00-4w21h10}, emission("Coma Comete")),
  ({4w23h00-4w23h10}, emission("Modulisme")),
#vendredi
  ({5w07h45-5w07h48}, chronique_cine),
  ({5w08h00-5w08h10}, aperophonie),
  ({5w16h00-5w16h10}, emission_ext("Univox")),
  ({5w16h30-5w16h40}, emission("Microcite")),
  ({5w18h00-5w18h10}, aperophonie), 
  ({5w19h00-5w19h10}, emission("A Rebours ou Sensation Soul")),
  ({5w20h00-5w20h10}, emission("La ou on va ou Expression Jazz")),
  ({5w21h00-5w21h10}, emission("Hertzeresis")),
  ({5w23h00-5w23h10}, emission_ext("Campus Local Club")),
#samedi
  ({6w00h00-6w00h10}, emission_ext("Campus Club")),
  ({6w12h00-6w12h10}, emission("Quezako")),
  ({6w13h00-6w13h10}, emission("Micro Ondes")),
  ({6w17h00-6w17h10}, emission_ext("Radio Muse")),
  ({6w19h00-6w19h10}, emission("Samedi 19h")),
#dimanche
  ({7w09h00-7w09h10}, metaclassique),
  ({7w10h00-3w10h05}, Instant_Livres),
  ({7w10h15-7w10h20}, H1000),
  ({7w12h30-7w12h40}, english_talk_radio),
  ({7w17h00-7w17h10}, emission("Discotheque Dauphinoise")),
  ({7w17h30-7w17h40}, emission("Le Rhume du Son")),
  ({7w19h00-7w19h10}, emission("Backstage")),
  ({7w21h00-7w21h10}, emission("La-haut dans l'Ocean ou Desastre Nocturne")),
# dans son répertoire les soirs de pleine lune :
  ({00h-01h15}, emission("Magic Colors")),
])

### DECROCHAGE - à paramétrer/activer au besoin

decrochage = input.http(id="decrochage", "http://live.campusgrenoble.org/rcg112",
  autostart=false, buffer=5., max=30.)

decrochage_https = input.https(id="decrochage_https", "https://live.campusgrenoble.org/rcg112",
  autostart=false, buffer=5., max=30.)

### DIRECT EXTERIEUR

# identification via les utilisateurs enregistrés dans Showergel
def showergel_auth(user, password) =
    reponse = string_of(http.post(
        headers=[("Content-Type", "application/json")],
        "#{SHOWERGEL}/login",
        data=json_of([
            ("username", user), ("password", password)
        ])
    ))
    if string.contains(
        prefix="((\"HTTP/1.0\", 200, \"OK\"),",
        reponse) then
        log("Access granted to #{user}")
        true
    else
        log("Access denied to #{user}")
        false
    end
end

direct_exterieur = input.harbor(id="direct_exterieur",
  auth=showergel_auth,
  buffer=10.,
  max=30.,
  port=9000,
  "direct"  # mountpoint name
)

# pour les tests de direct exterieur 

direct_exterieur_test = input.harbor(id="direct_exterieur_test",
  buffer=10.,
  max=30.,
  auth=showergel_auth,
  port=9000,
  "test"  # mountpoint name
)

# sortie indépendante sur http://live.campusgrenoble.org:9000/exterieurtest.mp3
clock.assign_new(id="direct_exterieur_test_icecast", [
    output.icecast(%mp3,
        host = "192.168.1.13",
        port = 8000,
        user = "source",
        password = "",
        mount = "exterieurtest.mp3",
        mksafe(direct_exterieur_test)
    )
])


############# Musique (et spots)

# on utilise la meta-donnée replaygain_track_gain, calculée par le plug-in Beets "replaygain"
# il y a aussi un "mangeur de blancs" assez agressif pour les débuts/fin de pistes

def beets(id, selector) =
  eat_blank(id="#{id}_", start_blank=true, max_blank=1.0, threshold=-45.0,
    amplify(override="replaygain_track_gain", 1.0,
      request.dynamic.list(id=id,
        fun() -> list.map(fun(item) -> request.create(item),
          get_process_lines(
            "#{BEET} random -f '$path' #{selector}"
          )
        )
      )
    )
  )
end

musique = beets("musique", "^genre:Nuit")
musique_fra = beets("musique_fra", "language:fra ^genre:Nuit")
musique_recente = beets("musique_recente", "added:-9m.. ^genre:Nuit")
musique_nuit = random(id="musique_nuit", replay_metadata=false, [
  beets("musique_nuit_ambiant_tout", "genre:Nuit, genre:Ambiant"),
  beets("musique_nuit_ambiant_recente", "added:-24m.. genre:Nuit, added:-24m.. genre:Ambiant")
])
#genres
musique_ambiant = beets("musique_ambiant", "genre:Ambiant")
musique_chanson = beets("musique_chanson", "genre:Chanson")
musique_classique = beets("musique_classique", "genre:Classique")
musique_country_blues = beets("musique_country_blues", "genre:Country-Blues")
musique_electro = beets("musique_electro", "genre:Electro")
musique_folk_acoustique = beets("musique_folk_acoustique", "genre:Folk-Acoustique")
musique_funk_soul = beets("musique_funk_soul", "genre:Funk-Soul")
musique_hiphop = beets("musique_hiphop", "genre:HipHop")
musique_jazz = beets("musique_jazz", "genre:Jazz")
musique_pop = beets("musique_pop", "genre:Pop")
musique_reggae_dub = beets("musique_reggae_dub", "genre:Reggae-Dub")
musique_rock = beets("musique_rock", "genre:Rock")
musique_world_latino = beets("musique_world_latino", "genre:World-Latino")

def vide(a,b) =
  empty()
end

playlist_quota = random(id="playlist_quota", replay_metadata=false,
  [ musique, musique_recente, musique_fra],
  weights=[35,      45,              20],
  # contournement de la répétition des meta-données: https://github.com/savonet/liquidsoap/issues/1476#issuecomment-765901080
  transition_length=0.,
  transitions=[vide,vide,vide]
)

# delay 2000. : au moins une grosse demi-heure entre les spots ou bande-anonce
spots_ba = delay(2500., id="spots_ba", 
  normalize( # cf. https://www.liquidsoap.info/doc-1.4.3/reference.html#normalize
    target=NIVEAU_SPOTS_BA_JINGLES, gain_max=10., gain_min=-15., k_down=0.5, k_up=0.1, window=1.5,
    random(replay_metadata=false, [
      playlist("/home/campus/ANTENNE/BandeAnnonce", id="bandeannonce", mode="random", reload_mode="watch"),
      playlist("/home/campus/ANTENNE/Spots", id="spot", mode="random", reload_mode="watch")
    ], 
    weights=[1, 1]
    )
  )
)

fond_musical = switch(id="fond_musical", replay_metadata=false, [
  # on evite de lancer les spots à l'heure pile et a la demi, pour ne pas risquer d'être coupé par une émission
  ({ 7h20-18h and (2m-28m or 32m-58m) }, spots_ba),

  # fond musical correspondant à peu près au style des émissions (au cas où y'en a pas:)
  # 
#lundi
  ({1w20h00-1w21h00}, musique_country_blues),
  ({1w21h00-1w22h00}, musique_rock),
#mardi
  ({2w19h00-2w20h00}, musique_hiphop),
  ({2w20h00-2w22h00}, musique_electro),
  ({2w23h00-3w01h00}, musique_ambiant),
#mercredi
  ({3w19h30-3w22h00}, musique_rock),
#jeudi
  ({4w10h00-4w11h00}, musique_classique),
  ({4w19h00-4w20h30}, musique_electro),
  ({4w20h00-4w21h00}, musique_reggae_dub),
  ({4w21h00-4w22h00}, musique_ambiant),
#vendredi
  ({5w20h00-5w21h00}, musique_world_latino),
  ({5w21h00-5w24h00}, musique_electro),
#samedi
  ({6w18h00-6w19h00}, musique_funk_soul),
#dimanche
  ({7w09h00-7w10h00}, musique_classique),
  ({7w18h00-7w19h00}, musique_ambiant),
  ({7w19h00-7w21h00}, musique_rock),
#semaine musicale  
  ({ (1w or 2w or 3w or 4w or 5w) and 6h30-22h30 }, playlist_quota),
  ({ (6w or 7w) and 8h-22h30 }, playlist_quota),
  ({ 0h-6h30 }, musique_nuit),
  ({ true }, musique)
])


########  Tracks inserées depuis Showergel

insert = request.equeue(id='insert')



######## Priorité des sources et transitions

def crossfade_3s(a,b)
    faded = add(normalize=false, [
        fade.in(duration=3., type="exp", b),
        # fondu "à la main" parce que fade.out ne se déclenche qu'en fin de piste, or là on coupe
        amplify(mkfade(duration=3., start=1., stop=0., type="exp", a) ,a)
    ])
    # la durée ci-dessous est plus longue : comme à la fin du fondu le volume est nul,
    # ça peut aussi vider un éventuel buffer
    add_timeout(10., { source.skip(a) ; -1.})
    faded
end

# blank() à la fin rend la source "grille" safe, même si en pratique fond_musical est sans fin
grille = fallback([direct_exterieur, decrochage_https, decrochage, insert, emissions, fond_musical, blank()],
  transitions=[crossfade_3s, crossfade_3s, crossfade_3s, crossfade_3s, crossfade_3s, crossfade_3s],
  track_sensitive=false,
  replay_metadata=false,
  id="grille")


############### JINGLES ##########################

# 780 = au moins 13 minutes de délai entre les jingles
jingles = delay(780., id="jingles",
  normalize( # cf. https://www.liquidsoap.info/doc-1.4.3/reference.html#normalize
    target=NIVEAU_SPOTS_BA_JINGLES, gain_max=10., gain_min=-15., k_down=0.5, k_up=0.1, window=1.5,
    switch([
      ({ 0h-6h }, playlist("/home/campus/ANTENNE/Jingles/Nuit", id="jingles nuit", mode="random", reload_mode="watch")),
      ({ 20m-40m }, playlist("/home/campus/ANTENNE/Jingles/Long", id="jingles longs", mode="random", reload_mode="watch")),
      ({ true }, playlist("/home/campus/ANTENNE/Jingles/Court", id="jingles courts", mode="random", reload_mode="watch"))
    ])
  )
)

# a la fin de chaque track, va piocher un jingle s'il est dispo (après lecture, il n'est pas dispo)
grille_avec_jingle = fallback([jingles, grille], id="grille_avec_jingle", replay_metadata=false,
  # contournement de la répétition des meta-données: https://github.com/savonet/liquidsoap/issues/1476#issuecomment-765901080
  transition_length=0.,
  transitions=[vide,vide])


##################### PUBLI DE LA PLAYLIST ####################################

# attention les on_track doivent être chainés 

# enregistrement (en local) de la playlist, sur showergel:
def post_to_showergel(metadata)
    def recode_n_filter(s) =
        if string.length(s) > 1000 then
            ""
        else
            string.recode(out_enc="UTF-8", s)
        end
    end
    def cleaner(m) =
        (recode_n_filter(fst(m)), recode_n_filter(snd(m)))
    end
    response = http.post(
	headers=[("Content-Type", "application/json")],
	"#{SHOWERGEL}/metadata_log",
	data=json_of(list.map(cleaner, metadata))
    )
end
intermediaire1 = on_track(post_to_showergel, grille_avec_jingle)

def post_to_internet(metadata)
    key = "secret"
    artist = snd(list.hd(list.filter_assoc("artist", metadata), default=("","")))
    title = snd(list.hd(list.filter_assoc("title", metadata), default=("","")))
    artisttitle = url.encode(artist ^ "___" ^ title) # c'est pas un smiley, c'est juste que ___ est un separateur qui date de rivendell...
    if artist != "" or title != "" then
        ignore(https.post(
            "...",
            headers=[("Content-Type","application/x-www-form-urlencoded")],
            data="key=#{key}&artisttitle=#{artisttitle}"
        ))
    end
end
intermediaire2 = on_track(post_to_internet, intermediaire1)

##################### SORTIES ################################################

output.pulseaudio(intermediaire2)
