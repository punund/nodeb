## Packaging node.js application into a .deb file

### Installation

    npm install nodeb

### Invocation

From your project's root:

    nodeb

If all goes well, `<project name>.deb` file will be created.

### Options

    -n do not include node_modules/, bower_components/, components/ in the package
    -p <port to monitor> (default 80) 
    -s also generate nginx config for SSL server
    -t copy templates to nodeb_templates/ for customization and exit
    -u <user to run processes as> (default "node")
    -v show generated files to stdout
    -w <production website address>. If given, nginx config files will be created

### What's included

The package will be installed in `/opt`.

Files for upstart, monit, logrotate, and optionally nginx are created.  If `node_modules/` was absent, `npm install`
will be run on target system.

If `-s` option is given, nginx configuration for https reverse proxy server is generated.  Study the
[templates](https://github.com/punund/nodeb/tree/master/templates), or customize them using `-t`.

### References

http://blog.coolaj86.com/articles/how-to-create-a-debian-installer.html

https://synack.me/blog/deploying-code-with-packages
