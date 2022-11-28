const fs = require("fs")
let output = {}

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

const lock = {}

let results = [];
for (let i = 2; i < process.argv.length - 1; i++){
	const json = JSON.parse(fs.readFileSync(process.argv[i]));
	const res = (json.results ?? [json.result]);

	if(banned.indexOf(res[0].repo) > -1 || !res[0].repo){
		continue;
	}

	output.start = json.start;
	output.end = json.end;
	results = [...(results), ...(res.filter(r => {
		if(lock[r.repo]){
			console.log(process.argv[i])
			return false;
		}
		lock[r.repo] = true;
		return true;
	}).map(r => {
		if(process.argv.length > 100){
			Object.keys(r.deployments).forEach((k, i) => {
				r.deployments[k].commits = r.deployments[k].commits.map((c, j) => j);
				r.deployments[k].diffs = r.deployments[k].diffs.map((c, j) => j);
			});
		}
		return r;
	}))];
}

fs.writeFileSync(process.argv[process.argv.length - 1], JSON.stringify({...output, results}));

// let resultsString = `[${results.map(result => JSON.stringify(result)).join(",")}]`;
//
// fs.writeFileSync(process.argv[process.argv.length - 1], `{"start": "${output.start}", "end": "${output.end}", results: ${resultsString}}`);
