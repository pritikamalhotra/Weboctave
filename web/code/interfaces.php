<?php
/*********************************************************************
*
* This file is a part of Web Interface to Octave project.
* Copyright (C) 2008 Kolo Naukowe Numerykow Uniwersytetu Warszawskiego
* (Students' Numerical Scientific Group of University of Warsaw)
*
* e-mail:knn@students.mimuw.edu.pl
*
* Distributed under terms of GPL License
*
*
*********************************************************************/


 interface Content
 {
    // function initializing content of the page
    public function Initialize();     
    
    // showing page
    public function ShowContent();
 }
 
 
?>