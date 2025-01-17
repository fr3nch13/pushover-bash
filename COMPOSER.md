## Using Pushover-bash with PHP's Composer

To use the pushover-bash script with composer, there are a few changes/additions to the instructions in the [README](README.md).

## Installation

To install it via composer directly, run:

```bash
composer require --dev fr3nch13/pushover-bash
```

Or add it to your composer.json, then run composer update

```json
{
    "require-dev": {
        "fr3nch13/pushover-bash": "dev-main",
    }
}
```

## Configuration

In addition to the default configuration file locations, you can also create the configuration file at the same location as your `vendor` folder.

**Be sure to add it to your `.gitignore` file.
```.gitignore
/pushover-config
```

You can add it to your composer.json, and call it as a script like so:

```json
{
    "scripts": {
        "pushover": "./vendor/bin/pushover",
    }
}
```

Then call it through composer like so:

```bash
$composer pushover -- [script args]

#example
$composer pushover -- -m Message
```

You can also refer to it in `composer.json` like:

```json
{
    "scripts": {
        "pushover": "./vendor/bin/pushover",
        "pushover-test": "@pushover -T Test -m Message Test",
        "pushover-done": "@pushover -T Composer Done -m Composer Done",
        "ci": [
            "./vendor/bin/phpunit",
            "@pushover -T Unit Test -m Unit test complete"
        ],
        "coverage": [
            "php -d xdebug.mode=coverage ./vendor/bin/phpunit --coverage-html coverage --testdox",
            "@pushover -T PROJECT COVERAGE -m COVERAGE is done"
        ],
    }
}
```