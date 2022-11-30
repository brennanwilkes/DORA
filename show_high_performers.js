const fs = require("fs")
let data = JSON.parse(fs.readFileSync(process.argv[process.argv.length - 1]));

// const scale = "performer";
const scale = "accelerate";

data.results.sort((b,a) => a[scale].score - b[scale].score).forEach((r, i) => {
	console.log(`${Object.keys(r[scale]).map(k => `${r[scale][k]}`.padEnd(8, " ")).join(" | ")} | ${r.repo}`);
});
