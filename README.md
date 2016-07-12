# hubot-bookstage

Bookstage manages who is currently using your team's staging server

Based on the original code of tinifni: https://github.com/github/hubot-scripts/blob/master/src/scripts/stagehand.coffee

## Installation

First run `npm install hubot-bookstage --save`, then add `hubot-bookstage` to the `external-scripts.json` file.

## Usage

- `hubot bookstage add <env> [category]`: Add a new server. 'bs' is an alias for 'bookstage'.
- `hubot bookstage book <env> [<hours> <reason>]`: Book a server. Default is 1 hour.
- `hubot bookstage cancel <env>`: Cancel a booking.
- `hubot bookstage list`: List status of all staging servers.
- `hubot bookstage who <env>`: Show status of a single server.

## Configuration

If you would like the status to be monospace, set `HUBOT_BOOKSTAGE_MONOSPACE_WRAPPER` env variable to a string that will be used to wrap the status. For instance, slack would be `HUBOT_BOOKSTAGE_MONOSPACE_WRAPPER='\`\`\`'`
