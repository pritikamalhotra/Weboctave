#*********************************************************************
# 
# This file is a part of Web Interface to Octave project.
# Copyright (C) 2009 Kolo Naukowe Numerykow Uniwersytetu Warszawskiego 
# (Students' Numerical Scientific Group of University of Warsaw)
# 
# e-mail:knn@students.mimuw.edu.pl
# 
# Distributed under terms of GPL License
# 
# 
#********************************************************************/




CFLAGS=-fPIC -c -Wall
LDFLAGS=-shared -ldl -lstdc++

all: wrapper.so

wrapper.o: wrapper.c
	$(CC) -fPIC  -c $< -o $@

wrapper.so: wrapper.o
	$(CC) -shared $< -ldl -lstdc++ -o $@

clean:
	rm -f wrapper.so wrapper.o


