TOP=../../..

BINS=\
 fglsvgchart.42m\
 fglsvgchart_demo.42m\
 fglsvgchart_demo.42f

all: $(BINS) doc

run:: $(BINS)
	fglrun fglsvgchart_demo

doc:
	fglcomp --build-doc fglsvgchart.4gl
	mv fglsvgchart.html docs

fglsvgchart.42m: fglsvgchart.4gl
	fglcomp -M fglsvgchart.4gl

fglsvgchart_demo.42m: fglsvgchart_demo.4gl
	fglcomp -M fglsvgchart_demo.4gl

fglsvgchart_demo.42f: fglsvgchart_demo.per
	fglform -M fglsvgchart_demo.per

fglsvgchart_demo.gar: $(BINS)
	fglgar gar --application fglsvgchart_demo.42m -o fglsvgchart_demo.gar

fglsvgchart_demo.war: fglsvgchart_demo.gar
	fglgar war --input-gar fglsvgchart_demo.gar --output fglsvgchart_demo.war

runjgas: fglsvgchart_demo.war
	fglgar run --war fglsvgchart_demo.war

clean::
	rm -f *.42m *.42f *.gar *.war fglsvgchart.html fglsvgchart.xa
