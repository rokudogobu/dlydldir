
# dlydldir

Daily archive contents of 'today' download directory to 'YYYY-MM-DD' archive directory in Downloads folder.

__NOTE:__ This program does not change the downloads location of Safari.app any longer.
Because it cannot be changed programatically on Safari 15 or later.

## How to Use

1. install this program, then `today` directory and `YYYY-MM-DD` (e.g. `2023-04-04`) symbolic link is created in `~/Downloads/`

1. change the default download location to `~/Downloads/today` in your favorite browser

1. when you log in, this program does:

	- archive contents of `today` directory to linked `YYYY-MM-DD` directory if the date is the past date
	- create symbolic link `YYYY-MM-DD` to `today` directory if not exists
	- trash (not remove) empty archive directories

## Installation

To install, please open Terminal.app and execute:

	$ git clone https://github.com/rokudogobu/dlydldir.git
	$ cd dlydldir
	$ make install && make bootstrap

Then, an executable and a service configuration file 
are installed into `~/.local/libexec/io.github.rokudogobu.dlydldir/` 
and `~/Library/LaunchAgents/`, respectively.

When a pop-up which asks for a permission is displayed, 
please allow this program to access Downloads folder.

## License

Copyright (c) 2019-2023 rokudogobu.  
Licensed under the Apache License, Version 2.0.  
See LICENSE for details.



