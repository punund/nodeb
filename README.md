## Packaging node.js application into a .deb file

Use this script to prepare your `node.js` web application for deployment on Debian-based system (only Ubuntu is tested).
You don't need any Debian tools for that, just the shell, `tar` and `ar`.

### Installation

    npm install nodeb

### Invocation

From your project's root:

    nodeb

If all goes well, `<project name>.deb` file will be created.

### Options

    -n don't include node_modules/, bower_components/, components/ in the package
    -o don't generate nginx config for insecure (http) server
    -p <port to monitor> (default 80) 
    -s generate nginx config for secure (https) server
    -t copy templates to nodeb_templates/ for customization and exit
    -u <user to run processes as> (default "node")
    -v show generated files on stdout
    -w <production website address>. If given, nginx config files will be created


### What's included

The package will be installed in `/opt`.

Files for `upstart`, `monit`, `logrotate`, and optionally `nginx` are created.  `npm install`
will be run on target system.

If `-s` option is given, nginx configuration for https reverse proxy server is generated.  Study the
[templates](https://github.com/punund/nodeb/tree/master/templates), or customize them using `-t`.

### References

https://synack.me/blog/deploying-code-with-packages
