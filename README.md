
# dlydldir for Safari.app

create daily download directory 
and set it as download location of Safari.app.

## Installation

To install, please open Terminal.app and execute:

	$ git clone https://github.com/rokudogobu/dlydldir.git
	$ cd dlydldir
	$ make install

Then, an executable and a service configuration file 
are installed into `~/.local/libexec/io.github.rokudogobu.dlydldir/` 
and `~/Library/LaunchAgents/` respectively, 
but not yet registered as daemon.

When a warning about SIP is displayed, 
please go to `System Preferences` > `Security & Privacy` > `Full Disk Access` 
and add the executable file of `dlydldir` to the list.

After re-login to your Mac 
or by executing following command, 
installed agent is started.

	$ make bootstrap

## License

Copyright (c) 2019-2021 rokudogobu.  
Licensed under the Apache License, Version 2.0.  
See LICENSE for details.



