# MAME Score Plugin

A Lua plugin for [MAME](https://www.mamedev.org/) that reads player scores directly from emulated memory and outputs them in a machine-readable format.

The plugin is designed to make arcade game scores accessible to external applications and hardware, such as:
- External LED and 7-segment score displays.
- Score tracking and recording applications.
- Tournament management systems.
- Custom scripts and other integrations.

## Features

- **Memory-based score reading** – reads scores directly from configured CPU memory addresses.
- **Multiple score formats** – supports BCD, binary and individual digit storage.
- **Endianness support** – handles little-endian and big-endian values.
- **Bit addressing** – supports reading scores from bit-addressed memory.
- **Score multipliers** – applies a configurable multiplier to the extracted score.
- **Multiple output modes** – print scores every frame, only when the score changes or when the game exits.

## Installation

1. Download or clone this repository.
2. Copy the plugin directory into your MAME plugins directory.

For example:

```bash
git clone https://github.com/hlad/score.git
cp -r score ~/.mame/plugins/
```

3. Enable the plugin in MAME.

Add the following to your `mame.ini`:

```ini
plugins 1
score 1
```

Alternatively, enable the plugin through MAME's plugin configuration menu.

## Configuration

Score memory locations are configured in `scores.lua`.

Each game is identified by its MAME short name (ROM name).

Example:

```lua
return {
    pooyan = {
        address = 0x88A2,
        length = 3,
        format = "bcd",
        endian = "big"
    },
    bmaster = {
        address = 0xe74f6,
        length = 3,
        format = "bin",
        endian = "big",
        multiplier = 100
    },
    mk = {
        address = 0x10512a0,
        length = 8,
        format = "digits",
        endian = "little",
        addressing = "bit"
    },
}
```

### Configuration options

| Option | Description |
|---|---|
| `address` | Starting memory address of the score |
| `length` | Number of bytes used by the score |
| `format` | Score representation: `bcd`, `bin` or `digits` |
| `endian` | Byte order: `little` or `big` |
| `multiplier` | Optional multiplier applied to the resulting score |
| `addressing` | Optional addressing mode: `byte` or `bit` |
| `device` | Optional MAME CPU device tag (default: `:maincpu`) |
| `space` | Optional memory address space (default: `program`) |

### Supported formats

**BCD (`bcd`)**

Each byte contains two decimal digits, with one digit in each nibble.

For example:

```text
Memory:  0x12 0x34 0x56
Score:   123456
```

**Binary (`bin`)**

The score is stored as a regular binary integer across multiple bytes.

For example:

```text
Memory:  0x40 0x42 0x0F
Endian:  big
Score:   1000000
```

**Individual digits (`digits`)**

Each byte contains a separate decimal digit

For example:

```text
Memory:  0x09 0x08 0x07 0x06
Endian:  little
Score:   9876
```

## Output

The plugin prints scores to the MAME output console using the following format:

```text
MAME_SCORE: {"game":"pooyan","score":123456}
```

The output is deliberately simple so that external applications can easily recognize and parse it.

### Print modes

The plugin supports different output modes:

| Mode | Description |
|---|---|
| `exit` | Print the score only when emulator exits |
| `frame` | Print the current score every emulated frame |
| `change` | Print only when the score changes |

Regardless of the selected mode, the final score is also printed when the emulation session ends.

## License

MIT License