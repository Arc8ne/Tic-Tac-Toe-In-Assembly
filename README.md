# Tic-Tac-Toe-In-Assembly
A 64-bit Windows console application that features a Tic Tac Toe game, written in Assembly.

## Requirements for building
- A `gcc` compiler that has already been added to your `$PATH` environment variable.

## Note
Although this application can be built, it is unfortunately not fully useable currently due to segmentation fault errors (that might have been caused by improperly aligned stacks prior to external function calls that do not conform to the stack-alignment requirements of the 64-bit Windows calling conventions) that were introduced during its porting from the 32-bit Windows platform to the 64-bit Windows platform.
