# KaRL42
A "friendly" robot that writes KRL code... what could go wrong?

```sh
$ npm i -g karl42
$ KaRL42
```
KaRL42 will then ask you what kind of program you would like to him write.

WARNING: KaRL42 obeys orders as he sees fit.

## API
```js
var KaRL42 = require('karl42');

var src = KaRL42();
```

### src = KaRL42(options)
 * `options.grammar` which the nearley grammar to use. (default `new require('krl-parser/src/grammar.js')`)
 * `options.start` which rule name to start with. (default grammar.ParserStart)

## License

The MIT License (MIT)

Copyright (c) 2016 KaRL42

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
