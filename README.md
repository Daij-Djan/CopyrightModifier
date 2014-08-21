CoprightModifier
================

modify the copyright HEADER of source files (.h, .m, .swift, .java ... whatever)

1. choose the folder with the files

2. choose if you want to recurse into subdirs (typically yes)

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
   
   2. `${CREATIONDATE}` which is the file's filesystem creation date by default and the **svn lastChange** date of the file IF it is under svn.
   
   3. ${USERNAME} the currently logged in OSX User