%.42f: %.per 
	fglform -M $<

%.42m: %.4gl 
	fglcomp -M $*


MODS=$(patsubst %.4gl,%.42m,$(wildcard *.4gl))
FORMS=$(patsubst %.per,%.42f,$(wildcard *.per))

all:: $(MODS) $(FORMS)

fglgallery_demo.42m: fglgallery.42m

run: all
	FGLIMAGEPATH="images-public:images-private:." fglrun fglgallery_demo

simple: all
	FGLIMAGEPATH="images-public:images-private:." fglrun simple_gallery

#if you have fglwebrun installed on your machine
webrun: all
	FGLIMAGEPATH="images-public:images-private:." fglwebrun fglgallery_demo.42m

#if you have fgldeb installed on your machine
deb: all
	FGLIMAGEPATH="images-public:images-private:." fgldeb fglgallery_demo

clean:
	rm -f *.42?

echo:
	echo "MODS:$(MODS)"
