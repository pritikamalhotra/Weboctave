/*********************************************************************
* 
* This file is a part of Web Interface to Octave project.
* Copyright (C) 2009 Kolo Naukowe Numerykow Uniwersytetu Warszawskiego 
* (Students' Numerical Scientific Group of University of Warsaw)
* 
* e-mail:knn@students.mimuw.edu.pl
* 
* Distributed under terms of GPL License
* 
* 
*********************************************************************/

#include <stdio.h>
#include <errno.h>
#include <dlfcn.h>
#include <sys/types.h>
#include <dirent.h>
#include <limits.h>
#include <string.h>


int lock=0;
char userdir[PATH_MAX+1];
char octadir[PATH_MAX+1];

int unlink(const char * path) 
{
  //void* handle;
  
  //printf("\nUnlink:%s\n",path);
  typedef int (*FP_unlink)(const char*);

  //handle=dlopen("libc.so",RTLD_NOW);

  FP_unlink org_unlink = dlsym(((void *) -1l), "unlink");
  //FP_unlink org_unlink = dlsym(handle, "unlink");
  return org_unlink(path);
}

int chdir(const char *path)
{ 
  printf("\nDirectory changing is not allowed\n");
  errno=EACCES;
  return -1;
}

//int fchdir(int fd)
//{
//  printf("\nDirectory changing is not allowed\n");
//  errno=EACCES;
//  return -1;
//}

 DIR* opendir (const char *dirname)
{
  //printf("\nDirectory operation is not allowed\n");
  //errno=EACCES;
  //return NULL;
  char abspath[PATH_MAX+1];
  typedef DIR* (*FP_opendir)(const char*);
  realpath(dirname,abspath);
  //printf("\nDirectory opened:%s\n",abspath);

  FP_opendir org_opendir = dlsym(((void *) -1l), "opendir");  
  if(!lock)
  {
    return org_opendir(abspath);//anything can be opened before lock
  }
  else
  {
    if(strncmp(abspath,userdir,strlen(userdir))==0) //dirs from user's dir may be opened
    {
      return org_opendir(abspath);
    }
    else if(strncmp(abspath,octadir,strlen(octadir))==0) //dirs from Octave's dir may be opened
    {
      return org_opendir(abspath);
    }
  }
 
  //FP_unlink org_unlink = dlsym(handle, "unlink");
  return NULL;
}

int system (const char *command)
{
  if(!lock)
    if(strcmp(command,"lock")==0)
    {
      lock=1;
      //printf("System commands locked\n");
      return -1;
    }
    else if(strncmp(command,"userdir ",8)==0)
    {
      if(strlen(command)<8)
        return -1;

      //char abspath[PATH_MAX+1];

      realpath(command+8,userdir);

      //strncpy(userdir,command+8,PATH_MAX);
      //printf("User dir set:%s\n",userdir);
      return -1;
    }
    else if(strncmp(command,"octadir ",8)==0)
    {
      if(strlen(command)<8)
        return -1;
      realpath(command+8,octadir);

      //strncpy(userdir,command+8,PATH_MAX);
      //printf("User dir set:%s\n",userdir);
      return -1;
    }



  printf("\nSorry, executing commands denied\n");
  return -1;

//
//  typedef int (*FP_system)(const char*);
//
//printf("\nRun:%s\n",command);
//
//  FP_system org_system = dlsym(((void *) -1l), "system");
//  //FP_unlink org_unlink = dlsym(handle, "unlink");
//  return org_system(command);
//
}

FILE *fopen(const char *path, const char *mode)
{
  typedef FILE* (*FP_func)(const char*,const char*);

  char abspath[PATH_MAX+1];
  int i;

  realpath(path,abspath);

  //printf("\nFile open:%s; real path: %s\n",path,abspath);
  FP_func org_func = dlsym(((void *) -1l), "fopen");

  //opening .octaverc is never a good idea
  //because it is opened before any input;
  //thus cannot be locked by lock variable
  if(strstr(abspath,".octaverc")!=NULL)
    return NULL;
  
  //opening php files is no good at all
  //especially opening config.php is never a good idea
  //because there are clear-text passwords in it
  if(strstr(abspath,".php")!=NULL)
    return NULL;

  if(!lock)
    return org_func(path,mode);
  else
  {
    //  printf(" %d '%s' '%s'\n",strncmp(abspath,userdir,strlen(userdir)),abspath,userdir);
    //for(i=0;i<strlen(userdir);i++)
    //  printf("%c %c %d\n",abspath[i],userdir[i],abspath[i]==userdir[i]); 
    if(strncmp(abspath,userdir,strlen(userdir))==0) //files from user's dir may be opened
    {
      return org_func(abspath,mode);
    }
    else if(strncmp(abspath,octadir,strlen(octadir))==0) //files from Octave's dir may be opened
    {
      return org_func(abspath,mode);
    }
    else
      return NULL; 
  }
}

int execvp(const char *filename, char *const argv[])
{ 
  //printf("\nNo permission to execute:%s\n",filename);
  printf("\nSorry, executing commands denied\n");
  return -1;
}

int kill(pid_t pid, int sig)
{
  errno=EPERM;
  return -1; 
}

