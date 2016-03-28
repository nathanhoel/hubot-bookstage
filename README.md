# hubot-bookstage

Bookstage manages who is currently using your team's staging server

Based on the original code of tinifni: https://github.com/github/hubot-scripts/blob/master/src/scripts/stagehand.coffee

## Installation

First run `npm install hubot-bookstage --save`, then add `hubot-bookstage` to the `external-scripts.json` file.

## Usage

- `hubot bookstage list`: list all staging servers and their availability
- `hubot bookstage who [env]`: show who has booked the staging server and how much time they have left
- `hubot bookstage book [env] [hours]`: book the staging server and optionally specify usage time. Default is 1 hour.
- `hubot bookstage cancel [env]`: cancel the current booking
- `hubot bookstage add [env]`: add a new staging to the list of available staging servers
