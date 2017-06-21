TOP=../../..

all: base

base:
	fglcomp -M fglsvgchart.4gl
	fglcomp -M fglsvgchart_demo.4gl
	fglform -M fglsvgchart_demo.per

run:: base
	fglrun fglsvgchart_demo

clean::
	rm -f fglsvgchart.42m
	rm -f fglsvgchart_demo.42m
	rm -f fglsvgchart_demo.42f
