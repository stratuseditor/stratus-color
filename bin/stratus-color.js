#!/usr/bin/env node
var fs         = require('fs')
  , path       = require('path')
  , commander  = require('commander')
  , bundle     = require('stratus-bundle')

  , highlight  = require('../lib')
  , standalone = require('../lib/standalone')
  , theme      = require('../lib/theme');


commander
  .version('0.0.1')
  .usage('[options] [code]')
  .option('-f, --file <file>',     'The file to parse')
  .option('-l, --language <lang>', 'Force parsing using the given language')
  .option('-o, --out <file>',      'Write the html to a given file')
  .option('-s, --standalone',      'Write as standalone file')
  .option('-t, --theme <theme>',   'Specify a theme. Only applicable in standalone mode')
  .option('-N, --nonumber',        'Disable line numbering')
  .parse(process.argv);


if (!commander.file && !commander.language) {
  console.log("");
  console.log("  Run `stratus-color --help` for usage");
  console.log("");
  process.exit();
}


var inFile  = commander.file
  , outFile = false;

if (inFile || commander.out) {
  outFile = commander.out || (inFile + ".html");
}


var options        = {};
options.standalone = !!commander.standalone;
options.language   = commander.language;
options.theme      = commander.theme;
options.gutter     = !commander.nonumber

// Use the file for input.
if (inFile) {
  highlight.file(inFile, options, function(err, html) {
    if (err) throw err;
    output(html);
  });
  
// Use STDIN for input.
} else {
  var rawData = "";
  process.stdin.resume();
  process.stdin.setEncoding('utf8');
  
  process.stdin.on('data', function(chunk) {
    rawData += chunk;
  });
  
  process.stdin.on('end', function() {
    html = highlight(rawData, options.language, options);
    output(html);
  });
}


function output(data) {
  if (outFile) {
    fs.writeFileSync(outFile, data);
  } else {
    console.log(data);
  }
  process.exit();
}
