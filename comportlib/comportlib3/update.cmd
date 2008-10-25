zip -r sources.zip source -x \*/CVS/\* -x \*.dcu -x \*.cfg -x \*.dof -x \*.dsk -x \*.cvsignore
zip -r examples.zip examples -x \*/CVS/\*  -x \*.dcu -x \*.cfg -x \*.dof -x \*.dsk -x \*.cvsignore
zip -r help.zip help -x \*/CVS/\*
zip -R locale.zip *.po -x \*/CVS/\* -x source/\*
zip cport.zip sources.zip examples.zip help.zip README.txt locale.zip CHANGELOG.txt
