set version "0.99.3"

proc showhelp {} {
tk_messageBox -message {Язык аудио дорожки: выбор языка аудио дорожки, 2 знака для ISO 639-1 (DVD) или 3 знака для ISO 639-2 (MKV).

Нормализация: выравнивания громкости и других параметров звука.

Язык субтитров: тоже самое что и язык аудио дорожки. Для включения субтитров поставьте галку Вкл. Если в папке с файлом находится внешние субтитры с совпадающим именем файла, то поумолчанию будут использоваться они. Для использования встроенных субтитров вам придется указать язык.

Кодировка: кодировка субтитров. По умолчанию русские субтитры(srt, ssa) имеют кодировку cp1251, если на выходе субтитры выходят искаженными, можно задать кодировку вручную, например utf-8} -icon info -type ok -title "Помощь..."
}

proc getsubtitleopts {filename} {
	if {!$::subsenabled} {return ""}
	set cmd "-subfont-text-scale 3.8 -font \"$::curdir\\tools\\tahoma.ttf\" -nofontconfig -subcp $::subcp "
	
	if {$::ass == "1"} {
	append cmd " -ass "}
	
	if {[file exist [file rootname $filename].ssa]} {
		append cmd "-sub \"[file rootname $filename].ssa\""
	} elseif {[file exist [file rootname $filename].ass]} {
		append cmd "-sub \"[file rootname $filename].ass\""
	} elseif {[file exist [file rootname $filename].srt]} {
		append cmd "-sub \"[file rootname $filename].srt\""
	} elseif {[file exist [file rootname $filename].idx]} {
		append cmd "-vobsub \"[file rootname $filename]\""
	} elseif {[file exist [file rootname $filename].sub]} {
		append cmd "-sub \"[file rootname $filename].sub\""
	} elseif {[file exist [file rootname $filename].smi]} {
		append cmd "-sub \"[file rootname $filename].smi\""
	} 
	return $cmd
}

proc getscaleopts {} {
	global vdata resx resy
	set aspect [expr ${resx}.0/$resy]
	if {$vdata(aspect) < $aspect} {
		return "crop=:[expr round(($vdata(height)*$vdata(aspect))*($resy.0/$resx))],dsize=[expr $resx.0/$resy.0]"
	} elseif {$::cropwidth} {
		return "crop=[expr round($vdata(height)*($resx.0/$resy))],dsize=[expr $resx.0/$resy.0]"
	} elseif {$::subsenabled} {
		return "expand=:::::[expr $resx.0/$resy.0],"
	} else {
		return ""
	}
}

proc getlangopts {} {
	set cmd ""
	if {$::alang != ""} {append cmd " -alang $::alang"}
	if {$::slang != "" && $::subsenabled} {append cmd " -slang $::slang "}
}

proc analyze {} {
	global vdata
	set file [string map {/ \\} [tk_getOpenFile -initialdir $::initialdir -multiple 0 -filetypes [list [list "Video Files" [list *.avi *.mp4 *.wmv *.mkv *.mpg *.m2v *.mov *.vob *.flv]]]]]
	getvidinfo $file
	if {[catch {tk_messageBox -icon info -type ok -title "Результат анализа файла" -message "Разрешение: $vdata(width)x$vdata(height)\nПропорции: $vdata(aspect)\nЯзык аудио: $vdata(atracks)\nЯзык субтитров: $vdata(stracks)"}]} {
		tk_messageBox -icon error -type ok -title "Ошибка" -message "Неверный формат файла!"
	}
}

proc getrunningdir {} {
	global argv0
	if {[file exist "[pwd]\\aEncoder.exe"]} {
		set curdir [pwd]
	} else {
		foreach curpath [split $::env(path) ;] {
			if {[file exist "${curpath}\\aEncoder.exe"]} {
				set curdir "${curpath}"
			}
		}
	}
	if {![file exist "$curdir\\tools"]} {
		tk_messageBox -message "Error locating tools folder." -icon error -type ok
		exit
	}
	cd $curdir
	return [string map {/ \\} $curdir]
}

proc checkfile {file} {
	if {[file exist $file]} {return 1}
	return [file tail $file]
}

proc checkfiles {curdir} {
	set toolsdir "$curdir\\tools"
	set missing ""
#	foreach cur [list "js32.dll" "MP4Box.exe" "mencoder.exe" "MediaInfo.exe" "MediaInfo.dll"] {
#		if {[set file [checkfile $toolsdir\\$cur]] != 1} {
#			lappend missing $file
#		}
#	}
	if {$missing != ""} {
		tk_messageBox -message "Can not continue, the following file(s) are missing from the tools folder: [join $missing]" -icon error -type ok
		exit
	}
}

proc getoutfile {dir file} {
	set outfile "[string map {/ \\} [file normalize $dir]\\[file rootname [file tail $file]]]"
	while {[file exist [append outfile .mp4]]} {}
	return $outfile
}

proc pauseenc {} {
	.buttons.start configure -text "Дальше" -command resumeenc
	set ::pause 1
}

proc resumeenc {} {
	.buttons.start configure -text "Пауза..." -command pauseenc
	set ::pause 0
}

proc disablegui {} {
	.buttons.start configure -text "Пауза..." -command pauseenc
	.options.bitrate.a configure -state disabled
	.options.bitrate.v configure -state disabled
	.inframe.files configure -state disabled
	.inframe.add configure -state disabled
	.inframe.remove configure -state disabled
	.outframe.browse configure -state disabled
	.options.res.y configure -state disabled
	.options.res.x configure -state disabled
	.options.res.wvga configure -state disabled
	.options.res.vga configure -state disabled
	.options.res.custom configure -state disabled	
	.options.bitrate.vhd configure -state disabled
	.options.bitrate.vsd configure -state disabled
	.options.bitrate.vcustom configure -state disabled
	.misc.normalize configure -state disabled
	.misc.sublang configure -state disabled
	.misc.audiolang configure -state disabled
	.misc.usesubs configure -state disabled
	.options.crop configure -state disabled
	.misc.analyze configure -state disabled
	.misc.help configure -state disabled
	.misc.ass configure -state disabled
}

proc enablegui {} {
	.buttons.start configure -text "Начать!" -state enabled -command convert
	.options.bitrate.a configure -state enabled
	.options.bitrate.v configure -state enabled
	.inframe.files configure -state normal
	.inframe.add configure -state enabled
	.inframe.remove configure -state enabled
	.outframe.browse configure -state enabled
	.options.res.wvga configure -state enabled
	.options.res.vga configure -state enabled
	.options.res.custom configure -state enabled
	.options.bitrate.vhd configure -state enabled
	.options.bitrate.vsd configure -state enabled
	.options.bitrate.vcustom configure -state enabled
	.misc.normalize configure -state enabled
	.misc.sublang configure -state enabled
	.misc.audiolang configure -state enabled
	.misc.usesubs configure -state enabled
	.options.crop configure -state enabled
	.misc.analyze configure -state enabled
	.misc.help configure -state enabled
	.misc.ass configure -state enabled
	setres
	setbr
	.progress.label configure -text "Готово!"
	.progress.name configure -text ""
}

proc filt {file} {
	return [string map {\\ \\\\} $file]
}

proc execmenc {label args} {
	global progvar curdir pipe pause
	set progvar 0
	.progress.label configure -text $label
	wlog "\n--------------------------------------------------------------------------"
	wlog "Executing mencoder with args: ${curdir}\\tools\\mencoder.exe [join $args]"
	set pipe [open "| [filt \"${curdir}\\tools\\mencoder.exe\"] [filt [join $args]] 2>@1" r+]
	fconfigure $pipe -buffering none -blocking 0
	while {![eof $pipe]} {
		if {$pause} {tkwait variable pause}
		set line [gets $pipe]
		if {$line != ""} {
			if {[regexp {^Pos.+\(( ?\d+)%\)} $line tmp val]} {
				set progvar $val
			} else {
				wlog $line
			}
			update
		}
	}
	close $pipe
	set progvar 100
}

proc muxvid {outfile fps sound} {
	wlog "\n--------------------------------------------------------------------------"
	wlog "Executing $::curdir\\tools\\mp4box.exe -fps $fps -aviraw video $::curdir\\video.avi"
	myexec "[filt \"$::curdir\\tools\\mp4box.exe\"] -fps $fps -aviraw video [filt \"$::curdir\\video.avi\"]"
	if {$sound} {
		wlog "\n--------------------------------------------------------------------------"
		wlog "Executing $::curdir\\tools\\mp4box.exe -fps $fps -aviraw audio $::curdir\\video.avi"
		myexec "[filt \"$::curdir\\tools\\mp4box.exe\"] -fps $fps -aviraw audio [filt \"$::curdir\\video.avi\"]"
		file rename -force $::curdir\\video_audio.raw $::curdir\\audio.aac
	}
	file delete -force $::curdir\\video.avi
	muxvidint $outfile $::curdir\\video_video.h264#video $fps
	if {$sound} {
		muxvidint $outfile $::curdir\\audio.aac#audio $fps
	}
}

proc muxvidint {outfile filetoadd fps} {
	global curdir pipe pause
	wlog "\n--------------------------------------------------------------------------"
	wlog "Starting to mux $filetoadd into $outfile with $fps fps"
	set pipe [open "| [filt \"$::curdir\\tools\\mp4box.exe\"] -fps $fps -add [filt \"$filetoadd\"] [filt \"$outfile\"] 2>@1" r]
	fconfigure $pipe -buffering none -blocking 0
	while {![eof $pipe]} {
		if {$pause} {tkwait variable pause}
		set line [gets $pipe]
		if {$line != ""} {
			wlog $line
			if {[regexp {\((\d+)\/100\)} $line tmp val]} {
				set progvar $val
			}
			update
		} 
	}
	close $pipe
}

proc myexec {cmd} {
	global pipe
	set pipe [open "| $cmd 2>@1"]
	set data [read $pipe]
	close $pipe
	return $data
}

proc getvidfps {infile} {
	set fps [string trim [myexec "[filt \"$::curdir\\tools\\MediaInfo.exe\"] --Inform=Video\;%FrameRate% [filt \"$infile\"]"]]
	if {[string is double $fps] && $fps < 31 && $fps > 9} {
		wlog "FPS DETECTION: Got $fps fps"
		return $fps
	}
	wlog "FPS DETECTION: Failed, forcing 25 fps"
	return 25
}

proc getvidinfo {infile} {
	global vdata
	if {[info exist vdata]} {unset vdata}
	wlog "\n--------------------------------------------------------"
	wlog "Getting video info for $infile"
	set data [myexec "[filt \"$::curdir\\tools\\mencoder.exe\"] -nosound -ovc x264 -x264encopts bitrate=1000 -frames 1 -o NUL -vf scale=-10:-1,scale=0:-10 -msglevel decvideo=4:identify=5:statusline=5 [filt \"$infile\"]"]
	wlog $data
	set vdata(sound) [regexp -line {^ID_AUDIO_ID} $data]
	regexp -all -line {^VDec: vo config request - (\d+) x (\d+)} $data tmp vdata(width) vdata(height)
	if {![regexp -all -line {^ID_VIDEO_ASPECT=(.+)$} $data tmp vdata(aspect)]} {
		set vdata(aspect) [expr $vdata(width).0/$vdata(height)]
		set vdata(noaspect) 1
	} else {
		set vdata(noaspect) 0
	}
	set vdata(atracks) ""
	set vdata(stracks) ""
	foreach {tmp audio} [regexp -all -line -inline {^ID_AID_\d+_LANG=(.+)$} $data] {
		lappend vdata(atracks) $audio
	}
	foreach {tmp sub} [regexp -all -line -inline {^ID_SID_\d+_LANG=(.+)$} $data] {
		lappend vdata(stracks) $sub
	}	
}

proc cleanup {} {
	file delete $::curdir\\audio.aac
	file delete $::curdir\\video_video.h264
	catch {file delete divx2pass.log}
}

proc convert {} {
	global outdir progvar
	if {[expr $::resx % 4] != 0 || [expr $::resy % 4] != 0} {
		tk_messageBox -message "The specified resolution dimensions are not multiples of 4 (mod4), please adjust the resolution!" -icon error -type ok
		return
	}
	if {[.inframe.files get 0 end] == "" || ![file exist $outdir]} {return}
	if {[.options.bitrate.v get] > 5000} {
		.options.bitrate.v delete 0 end
		.options.bitrate.v insert end 5000
	}
	if {[.options.bitrate.a get] > 256} {
		.options.bitrate.v delete 0 end
		.options.bitrate.v insert end 256
	}
	disablegui

	foreach file [.inframe.files get 0 end] {
		set outfile [getoutfile $outdir $file]
		.progress.name configure -text "$file"
		wlog "Starting to convert $file to $outfile"
		set fps [getvidfps $file]
		getvidinfo $file
		if {[catch {execmenc "(1/3)" [turbo1stpass $file $fps $::vdata(sound)]}]} {set error 1; break}
		if {[catch {execmenc "(2/3)" [normalsecondpass $file $fps $::vdata(sound)]}]} {set error 1; break}
		set progvar 0
		.progress.label configure -text "(3/3)"
		if {[catch {muxvid $outfile $fps $::vdata(sound)}]} {set error 3; break}
		cleanup
		set progvar 100
		wlog "File converted successfully!\n================================================================="
	}
	enablegui
	if {[info exist error]} {
		if {$error == "1"} {
			tk_messageBox -message "Unable to encode.[debugmsg]" -icon error -type ok
			wlog "Error encoding video..."
		} elseif {$error == "3"} {
			tk_messageBox -message "Muxing failed.[debugmsg]" -icon error -type ok
			wlog "Error muxing..."
		}
	}
}

proc debugmsg {} {
	if {$::log} {
		return ""
	}
	return " Rerun with -debug and post the generated log.txt file!"
}

proc fixfps {cmd fps} {
	return [append cmd " -ofps $fps"]
}

proc getsound {sound} {
	if {$sound} {
		return "-oac faac -channels 2 -faacopts mpeg=4:object=2:br=[.options.bitrate.a get] [getnormalize]"
	} else {
		return "-oac copy "
	}
}

proc turbo1stpass {infile fps sound} {
	return [fixfps "\"$infile\" -of avi -srate 44100 -ovc x264 [getsound $sound]-x264encopts level=30:pass=1:bitrate=[.options.bitrate.v get]:vbv-maxrate=1500:vbv-bufsize=2000:subme=0:analyse=0:partitions=none:ref=1:turbo=2:me=dia:bframes=0:threads=auto:no-cabac [getsubtitleopts $infile] -vf [getscaleopts]scale=-10:-1,scale=0:-10,scale=${::resx}:-10::::::1,scale=-10:${::resy}::::::1,harddup -o NUL" $fps]
}

proc normalsecondpass {infile fps sound} {
	return [fixfps "\"$infile\" -of avi -srate 44100 -ovc x264 [getsound $sound]-x264encopts level=30:pass=2:bitrate=[.options.bitrate.v get]:vbv-maxrate=1500:vbv-bufsize=2000:subme=6:analyse=0:partitions=none:ref=1:bframes=0:threads=auto:no-cabac [getsubtitleopts $infile] -vf [getscaleopts]scale=-10:-1,scale=0:-10,scale=0:-10,scale=${::resx}:-10::::::1,scale=-10:${::resy}::::::1,harddup -o \"$::curdir\\video.avi\"" $fps]
}

proc getnormalize {} {
	if {[.misc.normalize instate selected]} {
		return "-af volnorm "
	}
	return ""
}

proc addfiles {} {
	global outdir initialdir
	set files [tk_getOpenFile -initialdir $initialdir -multiple 1 -filetypes [list [list "Video Files" [list *.avi *.mp4 *.wmv *.mkv *.mpg *.m2v *.mov *.vob *.flv]]]]
	set initialdir [string map {/ \\} [file dirname [lindex $files 0]]]
	set filestoadd ""
	foreach file [lsort -unique $files] {
		set file [string map {/ \\} $file]
		set dup 0
		foreach cur [.inframe.files get 0 end] {
			if {$cur == $file} {
				set dup 1
			}
		}
		if {!$dup} {
			lappend filestoadd $file
		}
	}
	if {$filestoadd != ""} {
		eval ".inframe.files insert end $filestoadd"
		if {$outdir == ""} {
			set outdir [string map {/ \\} [file normalize [file dirname [lindex $filestoadd 0]]]]
		}
	}
}

proc removefiles {} {
	if {[.inframe.files curselection] != ""} {
		foreach cur [lsort -integer -decreasing [.inframe.files curselection]] {
			.inframe.files delete $cur
		}
	}
}

proc setres {} {
	global resolution resx resy
	if {$::resolution == 0} {
		set resx 480
		set resy 320
	} elseif {$::resolution == 1} {
		set resx 800
		set resy 480
	} 
}

proc setbr {} {
	global br bra brv
	if {$::br == 0} {
		set brv 500
		set bra 96
	} elseif {$::br == 1} {
		set brv 1000
		set bra 128
	} 
}

proc wlog {msg} {
	if {$::log} {
		puts $::logfs "[clock format [clock seconds] -format %T] $msg"
	}
}

proc loaddirs {} {
	global initialdir outdir subcp normalize subsenabled cropwidth alang slang br brv bra resolution resx resy ass
	if {[file exist "$::curdir\\aEncoder.ini"]} {
		set fs [open $::curdir\\aEncoder.ini r]
		fconfigure $fs -blocking 1
		set initialdir [gets $fs]
		set outdir [gets $fs]
		set subcp [gets $fs]
		set normalize [gets $fs]
		set subsenabled [gets $fs]
		set cropwidth [gets $fs]
		set alang [gets $fs]
		set slang [gets $fs]
		set br [gets $fs]
		set brv [gets $fs]
		set bra [gets $fs]
		set resolution [gets $fs]
		set resx [gets $fs]
		set resy [gets $fs]
		set ass [gets $fs]
		close $fs
		if {![file exist $initialdir]} {
			set initialdir ""
		}
		if {![file exist $outdir]} {
			set outdir ""
		}
	}
}

package req tile
set initialdir ""
set outdir ""
set subcp "cp1251"
set normalize "1"
set subsenabled "0"
set cropwidth "0"
set alang "rus"
set slang "rus"
set br "0"
set brv "500"
set bra "96"
set resolution "0"
set resx "480"
set resy "320"
set ass "0"




wm title . "aEncoder v$version   "
wm minsize . 400 0
wm resizable . 1 0

grid [ttk::labelframe .inframe -text "Исходные файлы"] -row 0 -column 0 -padx 1 -ipadx 1 -ipady 1 -sticky nswe
grid [ttk::labelframe .outframe -text "Конечная папка для файлов"] -row 1 -column 0 -padx 1 -padx 1 -ipady 1 -sticky nswe
grid [ttk::labelframe .options -text "Настройки видео"] -row 2 -column 0 -padx 1 -sticky nswe
grid [ttk::labelframe .progress -text "Ход выполнения"] -row 4 -column 0 -padx 2 -pady 2 -ipady 1 -sticky nswe
grid [ttk::frame .buttons] -row 5 -column 0 -sticky we

grid [ttk::label .progress.file -width 6 -text "Файл:"] -row 0 -column 0 -sticky w
grid [ttk::label .progress.name -text "" -width 60] -row 0 -column 1 -sticky w -padx 1
grid [ttk::label .progress.label -width 6 -text ""] -row 1 -column 0 -padx 1
grid [ttk::progressbar .progress.bar -variable progvar] -row 1 -column 1 -padx 1 -sticky we
set progvar 0
grid [ttk::scrollbar .inframe.scroll -orient vertical -command [list .inframe.files yview]] -sticky nswe  -row 0 -column 1 -rowspan 2
grid [listbox .inframe.files -width 40 -height 5 -selectmode extended -yscrollcommand [list .inframe.scroll set]] -row 0 -column 0 -sticky we -rowspan 2
grid [ttk::button .inframe.add -text "Добавить..." -command {addfiles} -width 10] -row 0 -column 2 -padx 1 -sticky nswe
grid [ttk::button .inframe.remove -text "Удалить" -command {removefiles} -width 10] -row 1 -column 2 -padx 1 -sticky nswe
grid [ttk::entry .outframe.fileentry -width 40 -textvariable outdir -state disabled] -row 0 -column 0 -sticky we
grid [ttk::button .outframe.browse -text "Обзор..." -command {set outdir [string map {/ \\} [tk_chooseDirectory -initialdir $::outdir -mustexist 1]]} -width 8] -row 0 -column 1 -padx 1
grid [ttk::frame .options.bitrate] -column 0 -row 0 -sticky ns
grid [ttk::label .options.bitrate.label -text "Битрейт (kbit/s)"] -column 0 -row 0 -columnspan 6 -sticky n
grid [ttk::radiobutton .options.bitrate.vhd -text "Низкое качество" -variable br -value 0 -command setbr] -row 2 -column 0 -columnspan 6 -sticky w
grid [ttk::radiobutton .options.bitrate.vsd -text "Высокое качество" -variable br -value 1 -command setbr] -row 3 -column 0 -columnspan 6 -sticky w
grid [ttk::radiobutton .options.bitrate.vcustom -text "Своё" -variable br -value 2 -command setbr] -row 4 -column 0 -sticky w
grid [ttk::label .options.bitrate.vlabel -text "(Видео"] -row 4 -column 1
grid [ttk::label .options.bitrate.vklabel -text "kbit/s,"] -row 4 -column 3
grid [ttk::label .options.bitrate.alabel -text "Аудио"] -row 4 -column 4
grid [ttk::label .options.bitrate.aklabel -text "kbit/s)"] -row 4 -column 6
grid [ttk::entry .options.bitrate.v -width 4 -cursor xterm -textvariable brv] -row 4 -column 2
grid [ttk::entry .options.bitrate.a -width 3 -cursor xterm -textvariable bra] -row 4 -column 5
grid [ttk::separator .options.sep -orient vertical] -row 0 -column 1 -sticky ns -pady 3
grid [ttk::frame .options.res] -column 2 -row 0 -sticky ns
grid [ttk::label .options.res.label -text "Разрешение экрана"] -column 0 -row 0 -columnspan 6
grid [ttk::radiobutton .options.res.wvga -variable resolution -value 0 -text "HVGA (480x320)" -command setres] -column 1 -row 2 -columnspan 4 -sticky w
grid [ttk::radiobutton .options.res.vga -variable resolution -value 1 -text "WVGA (800x480)" -command setres] -column 1 -row 3 -columnspan 4 -sticky w
grid [ttk::radiobutton .options.res.custom -variable resolution -value 2 -text "Своё" -command setres] -column 1 -row 4 -sticky w
grid [ttk::entry .options.res.x -width 4 -textvariable resx -cursor xterm] -column 2 -row 4
grid [ttk::label .options.res.labelx -text "x" -width 1] -column 3 -row 4
grid [ttk::entry .options.res.y -width 4 -textvariable resy -cursor xterm] -column 4 -row 4
grid [ttk::separator .options.sep2] -column 0 -columnspan 3 -row 1 -sticky we
grid [ttk::checkbutton .options.crop -variable cropwidth -text "Обрезать под заданное разрешение"] -column 0 -columnspan 3 -row 2
grid [ttk::button .buttons.start -text "Начать!" -width 8 -command convert] -row 0 -column 1
grid [ttk::button .buttons.exit -text "Выход" -width 8 -command exit] -row 0 -column 2
grid [ttk::labelframe .misc -text "Дополнительные настройки"] -row 3 -column 0 -padx 1 -sticky nswe
grid [ttk::label .misc.al -text "Язык аудио дорожки:"] -row 0 -column 0 -padx 2 -sticky w
grid [ttk::entry .misc.audiolang -width 6 -textvariable alang] -row 0 -column 1 -sticky w
grid [ttk::label .misc.sl -text "Язык субтитров:"] -row 1 -column 0 -padx 2 -sticky w
grid [ttk::entry .misc.sublang -width 6 -textvariable slang] -row 1 -column 1 -sticky w
grid [ttk::button .misc.help -text "?" -width 1 -command showhelp] -row 1 -rowspan 1 -column 4 -pady 2 -sticky nswe
grid [ttk::entry .misc.subcp -width 10 -textvariable subcp] -row 1 -column 3 -sticky w
grid [ttk::checkbutton .misc.normalize -text "Нормализовать" -variable normalize -state enabled] -row 0 -column 2 -pady 2 -sticky w
grid [ttk::checkbutton .misc.ass -text "Вкл. оформление ASS" -variable ass -state enabled] -row 2 -column 2 -pady 2 -sticky w
grid [ttk::button .misc.analyze -text "Анализ файла.." -width 4 -command analyze] -row 2 -rowspan 1 -column 0 -pady 2 -sticky nswe
grid [ttk::checkbutton .misc.usesubs -text "Вкл.                Кодировка:" -variable subsenabled -state enabled] -row 1 -column 2 -sticky w
grid columnconfigure . 0 -weight 1
grid columnconfigure .inframe 0 -weight 1
grid columnconfigure .outframe 0 -weight 1
grid columnconfigure .options {0 2} -weight 1
grid columnconfigure .progress 1 -weight 1
grid columnconfigure .buttons {0 3} -weight 1
grid columnconfigure .misc {1 2 3} -weight 1
grid rowconfigure .options {0 1 2} -weight 1
grid rowconfigure .options.bitrate {1 5} -weight 1
grid rowconfigure .options.res {1 5} -weight 1

set pause 0
set curdir "[pwd]"
checkfiles $curdir
loaddirs
focus -force .

wm protocol . WM_DELETE_WINDOW exit

if {$argv == "-debug"} {
	set log 1
	set logfs [open $curdir/log.txt w]
	fconfigure $logfs -buffering none
	wlog "Version: $::version"
} {
	set log 0
}

rename exit __exit
proc exit {args} {
	catch {exec tskill [pid $::pipe]}
	if {$::initialdir != "" && $::outdir != ""} {
		set fs [open "$::curdir\\aEncoder.ini" w]
		puts $fs $::initialdir
		puts $fs $::outdir
		puts $fs $::subcp
		puts $fs $::normalize
		puts $fs $::subsenabled
		puts $fs $::cropwidth
		puts $fs $::alang
		puts $fs $::slang
		puts $fs $::br
		puts $fs $::brv
		puts $fs $::bra
		puts $fs $::resolution
		puts $fs $::resx
		puts $fs $::resy
		puts $fs $::ass
		flush $fs
		close $fs
	}
	if {$::log} {
		flush $::logfs
		close $::logfs
	}
	__exit
}