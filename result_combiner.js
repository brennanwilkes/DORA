const fs = require("fs")
let output = {
	results: []
}

for (let i = 2; i < process.argv.length - 1; i++){
	const json = JSON.parse(fs.readFileSync(process.argv[i]));
	output.start = json.start;
	output.end = json.end;
	output.results = [...(output.results), ...(json.result ? [json.result] : json.results)];
}

fs.writeFileSync(process.argv[process.argv.length - 1], JSON.stringify(output, null, 4));
