CoprightModifier
================

modify the copyright HEADER of source files (.h, .m, .swift, .java ... whatever)

1. choose the folder with the files

2. IF you want a backup of the whole folder before any modification is done, check the corresponding checkbox. It is off by default as most users will use either git, svn or any other VCS and dont need a backup then.

3. choose if you want to recurse into subdirs (typically yes)

3. choose the type of files to consider (default is .h;.c;.m;.mm;.swift -- should cover most ios apps now and in the future but since the app can easily be used for java apps, this is modifiably)

4. choose to remove any old header from inspected files
    
     **a header is the first block of comments and/or newlines**
        
     the logic is: 
      
        while(line.length==0 || isSingleLineComment || InMultiLineComment) {
            header += line
        }

5. choose wether or not to apply a new header (typically: yes ;))

6. enter the new header into the TextView 

   In the TextView you can enter a header that is applied to each file (either it is BEFORE or INSTEAD of the old header!)
   
   The Template can contain to variables:
   
   1. `${FILENAME}` which is the current file's name
   
   2. `${CREATIONDATE}` which is EITHER the date of the first git commit for this file OR the svn last changed date (cant get svn creation date) OR the file's filesystem creation date.
   
   3. ${USERNAME} which is EITHER the git initial author OR the svn user (that last changed the file) OR the currently logged in OSX User

===

I wrote the code in objC and then coped it in swift again ;)