# be-cpu-nim
Ben Eater's 8-bit CPU simulator in Nim

## Idea
To see if it can be built in Nim with [Pararules](https://github.com/paranim/pararules).

> Pararules might not be well suited for the task:
> 1. signals in CPU should trigger updates of subsequent gates only on actual change of value
> 2. it would be complicated to connect between outputs and inputs of gates and to use logic specific for gate (for some 'and', for others 'or', etc.)
