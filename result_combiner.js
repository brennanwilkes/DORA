const fs = require("fs")
let output = {
	results: []
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

]

for (let i = 2; i < process.argv.length - 1; i++){
	const json = JSON.parse(fs.readFileSync(process.argv[i]));
	const res = (json.results ?? json.result);

	if(banned.indexOf(res.repo) > -1){
		continue;
	}

	// if(Object.keys(res.deployments).some(k => res.deployments[k].commits.length === 0)){
	// 	console.log("----------")
	// 	console.log(res.repo)
	// 	const biggest = Object.keys(res.deployments).sort((b,a) => res.deployments[a].commits.length - res.deployments[b].commits.length)[0]
	// 	console.log(biggest)
	// 	console.log(res.deployments[biggest].commits.length)
	// 	console.log("----------")
	// }
	output.start = json.start;
	output.end = json.end;
	output.results = [...(output.results), ...(json.result ? [json.result] : json.results)];
}

fs.writeFileSync(process.argv[process.argv.length - 1], JSON.stringify(output, null, 4));
