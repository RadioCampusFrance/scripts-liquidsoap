#!/usr/bin/liquidsoap

set("log.file.path", "/tmp/liquidsoap_radio.log")

local_playlist = playlist.safe("/srv/ftp/music/", mode="random")

stream_rfi = input.http("http://live02.rfi.fr/rfimonde-96k.mp3", id="stream_rfi_ok")

rfi_horaires = switch([({00h00-7h55},local_playlist),({7h55-8h10},stream_rfi),({8h10-17h55},local_playlist),({17h55-18h10},stream_rfi),({18h10-23h59},local_playlist)])

live = input.http("http://live.radio-campus.org:8000/radiocampusfrance.mp3")

live_decale = input.http("http://live.radio-campus.org:8000/orleans", id="live_ok", buffer = 5.)


content = fallback(track_sensitive=false, [live, live_decale, rfi_horaires, local_playlist])

output.alsa(content)

#adresse de streams alternatifs
#radiocampus france : http://live.radio-campus.org:8000/radiocampusfrance.mp3
#radiocampus musique : http://live.radio-campus.org:8000/radiocampusmusique.mp3
#campus orleans non securise http://orleans.radiocampus.org:8000/stream_rco_live.mp3
#campus orleans securise https://streams.labomedia.org:8443/stream_rco_live.mp3
#studio zef http://www.studiozef.fr:8000/zef.mp3
#secours si pb de stream sur les serveurs de la labomedia http://live.radio-campus.org:8000/orleans

