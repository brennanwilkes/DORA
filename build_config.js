const fs = require("fs");

const data = fs.readFileSync(process.argv[2]).toString().split("\n");

const minDate = new Date(data.filter(r => r.length > 0).map(r => parseInt(r.split(",")[4])).sort((a,b) => a-b)[0] * 1000 - 1000 * 60 * 60 * 24).toString().split(" ").slice(1,4).join(" ")
const maxDate = new Date().toString().split(" ").slice(1,4).join(" ")

const hash = {}

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

const output = {
	name: "",
	start: minDate,
	end: maxDate,
	results: "",
	repos: data.filter(r => r.length > 0).map(r => r.split(",")).filter(d => {
		if(hash[d[0]] || banned.indexOf(d[0]) > -1){
			return false;
		}
		hash[d[0]] = true;
		return true;
	}).sort((a,b) => parseInt(a[2]) - parseInt(b[2])).map(r => {
		return {
			id: r[0],
			deployment: 0,
			failures: {type: 1},
			weight: parseInt(r[2]) + Math.round(parseInt(r[1]) / 10),
			stats: {
				issues: parseInt(r[2]),
				deployments: parseInt(r[1])
			}
		};
	}),
	scheduler: {},
	workers: []
};
console.log(JSON.stringify(output, null, 4))
