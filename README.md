## Packaging node.js application into a .deb file

### Installation

    npm install nodeb

### Invocation

From your project's root:

    nodeb

If all goes well, `<project name>.deb` file will be created.

### Options

    -p <port to monitor> (default 80) 
    -t copy templates to nodeb_templates/ for customization
    -u <user to run processes as> (default "node")

### What's included

Files for upstart, monit, and logrotate are created.  If node_modules was absent, `npm install`
will be run on target system.

### References

http://blog.coolaj86.com/articles/how-to-create-a-debian-installer.html

https://synack.me/blog/deploying-code-with-packages
