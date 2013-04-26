<!-- -*- mode: markdown; coding: utf-8 -*- -->

# Simple market data IRC bot

This bot is not very useful at the moment.

It connects to [Irssi Proxy](http://www.irssi.org/documentation/proxy)
and monitors topics of IRC channels and keeps the ticker on topic
up-to-date. No other servers work because this bot lacks functionality
to join channels and respond to PING.

Currently it monitors only one channel and handles only
[Mt.Gox](https://mtgox.com/) exchange rate (BTCEUR) Data is downloaded
from [their public API](http://data.mtgox.com/api/1/BTCEUR/ticker).

More market information surces may be expanded to support more if
needed. Just now it is good for me.

**NB!** This is not a good example of well-written Haskell
program. But it has some little
[software transactional memory](http://www.haskell.org/haskellwiki/Software_transactional_memory)
(STM) tricks, which may be useful outside of this program, too.

## License

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

See LICENSE file for more information.

If you want to use parts of my work but you are using incompatible
license, just ask me a permission.

## Installing

Really? If you really want to, I have bad news for you. There is no Cabal file.
But anyway, it requires the following Haskell packages:

- irc
- curl-aeson
- ... plus something from Haskell Platform

Then just compile it with `ghc` or just run with `runghc`

## Running

    runghc Main irc.example.com 6667 password '#channel'

## Contact

Feel free to contact me if you want to develop this further or
anything. Just e-mail to joel.lehtonen+ircmarkets@iki.fi .
