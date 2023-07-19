## Using Pushover-bash with Node Package Manager

**I'm new to node.js and npm, so if you know a better way to call this script from the application perspective, please let me know.**

To use the pushover-bash script with npm, there are a few changes/additions to the instructions in the [README](README.md).

## Installation

To install it via npm directly, run:

```bash
npm install @fr3nch13/pushover-bash
```

Or add it to your package.json, then run composer update

```json
{
    "devDependencies": {
        "@fr3nch13/pushover-bash":">=1.0"
    }
}
```

## Configuration

In addition to the default configuration file locations, you can also create the configuration file at the application root.

**Be sure to add it to your `.gitignore` file.
```.gitignore
/pushover-config
```

You can call it through `npm` like so:

```bash
$npm exec pushover-bash -- [script args]

#examples
$npm exec pushover-bash -- -m Message
```

