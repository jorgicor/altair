Intro
=====

Copyright (c) 2016 Jorge Giner Cordero

In 2013, *Ivanzx*, on his blog [El rincón del Spectrum][1], started a contest
to port any game from a spanish arcade machine to the [ZX Spectrum][2].
I decided to port *Altair*, a game from 1981 by the spanish company *CIDELSA*,
which is a shoot 'em up with some interesting gameplay. It was finally the
[winner][5] of the contest.

I released the game under the pseudonym *Inmensa Bola de Manteca*. When
I was I child in Spain, as a joke, my friends used to say that the initials of
the computer company [IBM][3] meant Inmensa Bola de Manteca (Immense Ball of
Butter).

The game is programmed completely in *Z80 assembly*.

Later, I ported it to the [Amstrad CPC][4].

This source package is the full source code of the game, plus required tools
except the Z80 assembler.

To get this package and precompiled TAP and DSK for your Spectum and Amstrad,
visit http://jorgicor.sdfeu.org/altair . 

Compile
=======

First, you need a Z80 assembler compatible with TASM (Telemark Cross
Assembler). You can use `uz80as` which is free software and available here:
http://jorgicor.sdfeu.org/uz80as .

Then, you must build some required tools that are included in this package.
Enter the `tools/`folder and run `make`:

~~~
$ cd tools
$ make
$ cd ..
~~~

Now you are ready to build the game. Run `make` on the top directory of this
package:

~~~
$ make
~~~

It will build by default the TAPs and DSKs for Spectrum and Amstrad in all
languages. They will be generated under `release/`.

As an alternative, you can use:

- `make cpc_nc` or `make zx_nc` to make the DSKs or TAPs without covers.
- `make clean` to clean some generated files.
- `make distclean` to clean all generated files that are not distributed.
- `make dist` to make a distribution source package.

Licenses
========

The game is released as free software. See the file LICENSE.md.

Under `tools/`, there are two packages not written by me:

- `cpcfs` by *Derik van Zuetphen*. It is released under a BSD 2-clause license.
  See the file `tools/cpc/cpcfs/LICENSE` and
  `tools/cpc/cpcfs/README-altair.md`.
- `zxspectrum-utils` by *Michal Jurica*. Relased under a GPL2 license. See the
  file `tools/zx/zxspectrum-utils/LICENCE` and
  `tools/zx/zxspectrum-utils/README-altair.md`.

[1]: http://rincondelspectrum.blogspot.com.es/
[2]: https://en.wikipedia.org/wiki/ZX_Spectrum
[3]: https://en.wikipedia.org/wiki/IBM
[4]: https://en.wikipedia.org/wiki/Amstrad_CPC
[5]: http://rincondelspectrum.blogspot.com.es/2014/03/i-concurso-recreativas-espanolas-en-tu_27.html
