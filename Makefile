TOP=../../..

all: base

base:
	fglcomp -M fglsvgchart.4gl
	fglcomp -M fglsvgchart_demo.4gl
	fglform -M fglsvgchart_demo.per

run:: base
	fglrun fglsvgchart_demo

fglsvgchart_demo.gar: fglsvgchart.42m fglsvgchart_demo.42m fglsvgchart_demo.42f
	fglgar gar --application fglsvgchart_demo.42m -o fglsvgchart_demo.gar

fglsvgchart_demo.war: fglsvgchart_demo.gar
	fglgar war --input-gar fglsvgchart_demo.gar --output fglsvgchart_demo.war

runjgas: fglsvgchart_demo.war
	fglgar run --war fglsvgchart_demo.war

clean::
	rm -f *.42m *.42f *.gar *.war
