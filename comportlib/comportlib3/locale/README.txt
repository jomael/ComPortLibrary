This translation system uses the GNU gettext for Delphi
translation system. It is very easy to use. If your program
is named myapp.exe, put the files like this:

appdir\myapp.exe
appdir\locale\da\LC_MESSAGES\cport.mo

Here, da means Danish, the only language that is currently supported. The .po files
do not need to be deployed with the application.

The component will automatically find the cport.mo file and use the translations,
if present. If cport.mo is not present, everything will use English.
