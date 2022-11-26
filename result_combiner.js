const fs = require("fs")
let output = {

}

const banned = [
	// "ethereum/go-ethereum",
	"prometheus/prometheus",
	"apache/superset",
	"appium/appium",
	"betaflight/betaflight",
	"electron-userland/electron-builder",
	"ethereum/go-ethereum",
	"getsentry/sentry",
	"matrix-org/synapse",
	"vitessio/vitess",
	"gravitational/teleport",
	"RIOT-OS/RIOT",
	"pypa/pipenv"
]
let results = [];
for (let i = 2; i < process.argv.length - 1; i++){
	const json = JSON.parse(fs.readFileSync(process.argv[i]));
	const res = (json.results ?? json.result);

	if(banned.indexOf(res.repo) > -1){
		continue;
	}

	output.start = json.start;
	output.end = json.end;
	results = [...(results), ...(json.result ? [json.result] : json.results)];
}

fs.writeFileSync(process.argv[process.argv.length - 1], JSON.stringify({...output, results}));

// let resultsString = `[${results.map(result => JSON.stringify(result)).join(",")}]`;
//
// fs.writeFileSync(process.argv[process.argv.length - 1], `{"start": "${output.start}", "end": "${output.end}", results: ${resultsString}}`);
