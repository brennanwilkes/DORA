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
	"pypa/pipenv",
	"haiwen/seafile",
	"cyrus-and/gdb-dashboard",
	"DirectoryLister/DirectoryLister",
	"JohnCoates/Aerial",
	"littlecodersh/ItChat",
	"skypjack/entt",
	"WizTeam/WizQTClient",
	"AaronFeng753/Waifu2x-Extension-GUI",
	"open-wa/wa-automate-nodejs",
	"benweet/stackedit",
	"alda-lang/alda",
	"harness/drone",
	"DylanVann/react-native-fast-image",
	"real-logic/aeron",
	"alibaba/lowcode-engine",
	"pattern-lab/patternlab-php",
]

const lock = {}

let duplicates = 0;
let issueFiltered = 0;
let deploymentFiltered = 0;

let results = [];
for (let i = 2; i < process.argv.length - 1; i++){
	const json = JSON.parse(fs.readFileSync(process.argv[i]));
	const res = (json.results ?? [json.result]);

	// if(banned.indexOf(res[0].repo) > -1 || !res[0].repo){
	// 	continue;
	// }

	output.start = json.start;
	output.end = json.end;
	results = [...(results), ...(res.filter(r => {
		if(lock[r.repo]){
			console.log(`Duplicate: ${process.argv[i]}`)
			duplicates += 1;
			return false;
		}
		if(Object.keys(r.deployments).length < (r.checkedDeployments / 2)){
			deploymentFiltered += 1;
			// console.log(`Not enough deployments: ${r.repo}`)
			return false;
		}
		if(r.failures.filter(f => (f.induced_by ?? []).length > 0).length < (r.checkedIssues / 6)){
			issueFiltered += 1;
			// console.log(`Not enough failures: ${r.repo}`)
			return false;
		}
		lock[r.repo] = true;
		return true;
	}).map(r => {
		if(process.argv.length > 100){
			Object.keys(r.deployments).forEach((k, i) => {
				r.deployments[k].commits = r.deployments[k].commits.map((c, j) => 0);
				r.deployments[k].diffs = r.deployments[k].diffs.map((c, j) => 0);
			});
		}
		return r;
	}))];
}

console.log(`Duplicates: ${duplicates}`)
console.log(`Not enough deployments: ${deploymentFiltered}`)
console.log(`Not enough issues: ${issueFiltered}`)

fs.writeFileSync(process.argv[process.argv.length - 1], JSON.stringify({...output, results}));

// let resultsString = `[${results.map(result => JSON.stringify(result)).join(",")}]`;
//
// fs.writeFileSync(process.argv[process.argv.length - 1], `{"start": "${output.start}", "end": "${output.end}", results: ${resultsString}}`);
