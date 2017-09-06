CoprightModifier
================
modify the copyright HEADER of source files (.swift, .h, .c, .m, .js, .java, .rb,  ... )

howto:
====
1. choose the folder with the files (BEST a folder containing a git repository)

2. IF you want a backup of the whole folder before any modification is done, check the corresponding checkbox. It is off by default as most users will use either git or any other VCS and dont need a backup then.<br/>
**If it is selected,  all files that'd be touched are put into a zip file. Unmodified ones are not backed up!**

3. choose any or none of the options to modify the generation of the new copyright header
	- e.g. choose how to determine the initial author and creation date of a file
	- e.g. choose an open source license to confirm to (or not - depends on your needs)
	- choose which file types to process and what subfolders to skip
	- e.g. ...
	
4. optionally fine tune the generated templates

	![Main Interface](./README-Files/1.png)

5. **OPTIONAL** <br/>
	Save the options you selected so you can easily load them and skip points 1-3 next time or just change files/options as needed
	
6. process the folder(s). (For git repos, depending on the amount of files and the no. of git commits this can take a while)

	![Progress indicator](./README-Files/2.png)

7. REVIEW the changes that would be made to the files that match and confirm or reject them on a per-file basis and 'save' the changes to disk<br/>
**only files that would really be modified, get written to disk**

	![Review changed interface](./README-Files/3.png)
	
#license
the App under './CopyrightModifier' is under GPL2
the Helpers under './Helpers' are under BSD