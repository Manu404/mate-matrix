const path = require('path');
const args = process.argv.slice(2);

// const config = require(path.resolve('.', args[0]));
const config = require("../lghs-21.json");

const crates = config.matrix.cols * config.matrix.rows;
const ledsByCrate = config.crate.rows * config.crate.cols;

let ledOffset = config.fadecandy.ledOffset;
let output = {
  "nbCrates": crates,
  "spacing": config.processing.spacing,
  "pixelsPerCrate": ledsByCrate,
  "crateH": config.crate.rows,
  "crateW": config.crate.cols,
  "cols": config.matrix.cols,
  "rows": config.matrix.rows,
  "zigzag": !!config.matrix.zigzag,
  "blocks": config.processing.blocks,
  "dmxSerialPort": config.processing.dmxSerialPort
};

console.log(JSON.stringify(output));