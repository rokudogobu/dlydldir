
# dlydldir

Daily archive contents of 'today' download directory to 'YYYY-MM-DD' archive directory in Downloads folder.

__NOTE:__ This program does not change the downloads location of Safari.app any longer.
Because it cannot be changed programatically on Safari 15 or later.

## How to Use

1. install this program, then `today` directory and `YYYY-MM-DD` symbolic link is created in `~/Downloads/`

1. change the default download location to `~/Downloads/today` in your favorite browser

1. when the date have chenged, the program does:

	- archive contents of `today` directory to linked `YYYY-MM-DD` directory
	- create symbolic link `YYYY-MM-DD` to `today` directory
	- trash (not remove) empty archive directories

## Installation

To install, please open Terminal.app and execute:

	$ git clone https://github.com/rokudogobu/dlydldir.git
	$ cd dlydldir
	$ make install

Then, an executable and a service configuration file 
are installed into `~/.local/libexec/io.github.rokudogobu.dlydldir/` 
and `~/Library/LaunchAgents/` respectively.

When a pop-up which asks for a permission is displayed, 
please allow this program to access Downloads folder.

After re-login to your Mac or by executing following command, 
installed agent will be started.

	$ make bootstrap

## License

Copyright (c) 2019-2022 rokudogobu.  
Licensed under the Apache License, Version 2.0.  
See LICENSE for details.



