#!/usr/bin/env node
var fs         = require('fs')
  , path       = require('path')
  , commander  = require('commander')
  , bundle     = require('stratus-bundle')

  , highlight  = require('../')
  , standalone = require('../lib/standalone')
  , theme      = require('../lib/theme');


commander
  .version('0.0.1')
  .usage('[options]')
  .option('-f, --file <file>',     'The file to parse')
  .option('-l, --language <lang>', 'Force parsing using the given language')
  .option('-o, --out <file>',      'Write the html to a given file')
  .option('-s, --standalone',      'Write as standalone file')
  .option('-t, --theme <theme>',   'Specify a theme. Only applicable in standalone mode')
  .parse(process.argv);


if (!commander.file) {
  console.log("");
  console.log("  Run `stratus-color --help` for usage");
  console.log("");
  process.exit();
}


var inFile  = commander.file
  , outFile = commander.out || (inFile + ".html")
  , text    = fs.readFileSync(inFile).toString();

var options        = {};
options.standalone = !!commander.standalone;
options.language   = commander.language;
options.theme      = commander.theme;


highlight.file(inFile, options, function(err, html) {
  if (err) throw err;
  fs.writeFileSync(outFile, html);
  process.exit();
});
