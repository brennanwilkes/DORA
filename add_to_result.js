const fs = require("fs")

let output = JSON.parse(fs.readFileSync(process.argv[process.argv.length - 1]));

for (let i = 2; i < process.argv.length - 1; i++){
	const json = JSON.parse(fs.readFileSync(process.argv[i]));
	output.results = [...(output.results.filter(r => {
		return (json.result ? [json.result] : json.results).map(rr => rr.repo).indexOf(r.repo) === -1;
	})), ...(json.result ? [json.result] : json.results)];
}

fs.writeFileSync(process.argv[process.argv.length - 1], JSON.stringify(output, null, 4));
