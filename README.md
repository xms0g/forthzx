# forthzx
A tiny forth interpreter for the ZX Spectrum, written in Z80 assembly.
You can download the `TAP` file from [itch.io](https://xms0g.itch.io/forthzx).

<img src="assets/forthzx.gif" alt="image" width="700" height="auto">


|Command|ZX Spectrum Key|PC Key|
|-|-|-|
|`+`|SYMBOL_SHIFT + K|CONTROL + K|
|`-` |SYMBOL_SHIFT + J|CONTROL + J|
|`*` |SYMBOL_SHIFT + B|CONTROL + B|
|`/`| SYMBOL_SHIFT + V|CONTROL + V|
|`.`| SYMBOL_SHIFT + M|CONTROL + M|
`:`| SYMBOL_SHIFT + Z|CONTROL + Z|
`DUP`|.|.|
`DROP`|.|.|
`SWAP`|.|.|
`OVER`|.|.|
`ROT`|.|.|
`EMIT`|.|.|

Press the key (SYMBOL_SHIFT/CONTROL) only once for the special symbols.

## Technical Details
| Property  | Value |
|------|-------------|
|Target|Sinclair ZX Spectrum|
|Architecture |Zilog Z80|
|Language |Z80 Assembly|
|Assembler| Pasmo|
|Load Address| 0x8000|
|Screen Resolution| 256×192|
|Text Resolution |32×24|
|Video Memory| 0x4000–0x57FF|
|Attribute Memory| 0x5800–0x5AFF|

## Building
```bash
make
```

## License
This project is licensed under the BSD 3-Clause License. See the LICENSE file for details.

