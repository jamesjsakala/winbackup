# winbackup
An MSDOS Batch Script To Backup Windows Databases , Data and Settings
The Script is able to backup Microsoft SQL Databases , MySQL Databases(XAMP), Active Directory (IFM) and The Windows Registry as well as Selected Files and Folders.
The Script Utilises 7zip for compression.


# Installation

  1 - Create folder C:\JBACKUP and download all files to it.
  
  2 - Edit C:\JBACKUP\jwinbackup.cmd with notepad as you need.
  
  3 - Open Powershell prompt and run *installbackupscriptastask.ps1* to install Backup Schedule Job.
  
  
  
 # Settings (Files)

  For MySQL Databases Edit : C:\JBACKUP\MySQLDBsToBackUp.txt
  Add Databases to backup. 1 on each line.
  NOTE : The Script assumes your XAMP is installed in : C:\xampp. 
         ~If not editthe script variables accordingly.~
 
  
  For Microsoft SQL Server Databases Edit : C:\JBACKUP\DBsToBackUp.txt
  Add Databases to backup. 1 on each line


  For files and Folder to backup Edit : C:\JBACKUP\PathsToSyncUp.txt
  Add full path to backup. 1 on each line

