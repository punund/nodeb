## Packaging node.js application into a .deb file

### Installation

    npm install nodeb

### Invocation

From your project's root:

    nodeb

If all goes well, `<project name>.deb` file will be created.

### Options

   -p <port to monitor> (default 80) 
   -s also generate nginx config for SSL server
   -t copy templates to nodeb_templates/ for customization and exit
   -u <user to run processes as> (default "node")
   -v show generated files to stdout
   -w <production website address>. If given, nginx config files will be created

### What's included

Files for upstart, monit, ogrotate, and optionally nginx are created.  If node_modules was absent, `npm install`
will be run on target system.

### References

http://blog.coolaj86.com/articles/how-to-create-a-debian-installer.html

https://synack.me/blog/deploying-code-with-packages
