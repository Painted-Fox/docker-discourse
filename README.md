# docker-discourse

A Dockerfile that produces a container that will run [Discourse][discourse] ([github repository][discourse-git]).  The installation follows the [Discourse installation instructions][discourse-install] closely.

[discourse]: http://www.discourse.org/
[discourse-git]: https://github.com/discourse/discourse
[discourse-install]: https://github.com/discourse/discourse/blob/master/docs/INSTALL-ubuntu.md

*Thanks to [eugeneware][eugeneware] for the [docker-wordpress-nginx][docker-wordpress-nginx] project that I used as a reference*

[eugeneware]: https://github.com/eugeneware
[docker-wordpress-nginx]: https://github.com/eugeneware/docker-wordpress-nginx

## Installation

```
$ sudo docker build -t="discourse" .
```

## Note

This is still a work in progress!
