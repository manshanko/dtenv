A library for running Darktide lua outside of Darktide.

dtenv currently polyfills enough globals to support data extraction (weapons, buffs, talents, etc)
and differential testing of damage ([`DamageCalculation.calculate`](https://github.com/Aussiemon/Darktide-Source-Code/blob/688653a836a6dc8bc35e626b574334afe2ed45c4/scripts/utilities/attack/damage_calculation.lua#L27))
for the [wartide calculator](https://dt.wartide.net/calc).

## Examples

See [`examples`](https://github.com/manshanko/dtenv/blob/main/examples) for code using Darktide interfaces.

To run `examples/flamer.lua`:
```
set DARKTIDE_LUA=<path to darktide source or bytecode>
luajit test.lua flamer
```

## Setup

Get the [Darktide decompiled source code](https://github.com/Aussiemon/Darktide-Source-Code).

Load dtenv with `dofile`:
```lua
local dtenv = dofile(DTENV_PATH_LUA)
dtenv.init(DARKTIDE_LUA)
```

or `require`:
```lua
package.path = package.path .. DTENV_PATH .. "/?.lua;"

local dtenv = require("dtenv")
dtenv.init(DARKTIDE_LUA)
```

[Exported lua bytecode](https://github.com/manshanko/limn) can be loaded if using a luajit built with gc64 disabled.

## JIT

If performance is a concern then make sure to benchmark with luajit's JIT turned off (`jit.off()`).
With default JIT settings `check_damage_distribution` is faster with JIT off.
dtenv sets `maxirconst=100` to improve that case, but other code paths may have slowdowns when JIT is on.
