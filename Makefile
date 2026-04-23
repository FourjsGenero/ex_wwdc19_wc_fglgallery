#gnu make compatible make file
#on windows use clientqa's wintools to have gnu make or install it with
#> winget install GnuWin32.Make
#(installs in C:\Program Files (x86)\GnuWin32)

ifdef windir
  WINDIR=$(windir)
endif
ifdef WINDIR
#avoid gnu make exporting git bash as shell if found
  export SHELL=cmd
  CP=copy /Y
  SLASH=\\
#using only fglrun makes window try to start fglrun.js !!
  FGLRUN=fglrun.exe
  DOT_BAT=.bat
  RM_F=del /s /q
  RM_RF=rmdir /s /q
  STD_DEV_NULL= >NUL
  ERR_DEV_NULL= 2>NUL
  PATHSEP=;
else
  CP=cp
  SLASH=/
  FGLRUN=fglrun
  RM_F=rm -f
  RM_RF=rm -rf
  PATHSEP=:
endif

%.42f: %.per 
	fglform -M $<

%.42m: %.4gl 
	fglcomp -M $*


MODS=$(patsubst %.4gl,%.42m,$(wildcard *.4gl))
FORMS=$(patsubst %.per,%.42f,$(wildcard *.per))
export FGLIMAGEPATH=images-public$(PATHSEP)images-private$(PATHSEP).

all:: $(MODS) $(FORMS)

fglgallery_demo.42m: fglgalleryX.42m

run: all
	$(FGLRUN) fglgallery_demo

simple: all
	$(FGLRUN) simple_gallery

fglwebrun:
	git clone https://github.com/FourjsGenero/tool_fglwebrun.git fglwebrun

#if you have fglwebrun installed on your machine
webrun: all fglwebrun
	fglwebrun$(SLASH)fglwebrun$(DOT_BAT) fglgallery_demo.42m

#if you have fgldeb installed on your machine
deb: all
	fgldeb fglgallery_demo

clean:
	$(RM_F) *.42?  $(STD_DEV_NULL) $(ERR_DEV_NULL)
	-$(RM_RF) fglwebrun $(STD_DEV_NULL) $(ERR_DEV_NULL)

echo:
	echo "MODS:$(MODS)"
	echo "FORMS:$(FORMS)"
