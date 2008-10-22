This is a Modbus RTU master component for Delphi.

Installation Instructions
-------------------------

	(1) You need Dejan Crnila's ComPort components, not included here.
	    Download them from http://sourceforge.net/projects/comport/

	(2) Click File Open and open ModbusPkg.dpk.

	(3) Click Install button in the package window. 

	(4) If there is any error, perhaps you need to add some directories to your
 	    Library  path, such as the c:\...\cport\source directory (ComPort library)
	    or the path to the modbus library source.

What can it do?
---------------
It can communicate with an rs-232 or rs-485 device that speaks
Modbus protocol, such as many PLCs, or any other compliant modbus 
rtu slave device.


What doesn't it do?
-------------------
 - It is NOT a Modbus TCP Server or Client.
 - It can not do Modbus ASCII mode, only Modbus RTU mode. (Ascii mode is little used.)
 - It can not be a modbus slave.


This software is open-source.

It is licensed under the Mozilla-style MPL.  If anyone really likes it, please speak to the folks at the comport library, 
the web link is above on sourceforge, and I think we should put this component into the basic comport library.


LICENSE
-------

See license.txt (Mozilla Public License 1.1).



Contact Information
-------------------

Warren Postma
Toronto Canada
warrenpstma@hotmail.com
