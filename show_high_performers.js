const fs = require("fs")
let data = JSON.parse(fs.readFileSync(process.argv[process.argv.length - 1]));

const score = repo => {
	let s = 0;
	Object.keys(repo).filter(k => k!=="changeFailureRate").forEach((k, i) => {
		if(repo[k] === "Ultra"){
			s += 8;
		}
		else if(repo[k] === "High"){
			s += 5;
		}
		else if(repo[k] === "Medium"){
			s += 3;
		}
		else if(repo[k] === "Low"){
			s += 2;
		}
	});
	return s;
}

data.results.sort((b,a) => score(a.performer) - score(b.performer)).forEach((r, i) => {
	console.log(`${score(r.performer)} | ${Object.keys(r.performer).map(k => r.performer[k].padEnd(8, " ")).join(" | ")} | ${r.repo}`);
});
