const fs = require("fs");

let data = JSON.parse(fs.readFileSync(process.argv[process.argv.length - 1]));

console.log("======================== Lead Time For Changes ========================")

data.results.forEach((result, i) => {
	const deployments = Object.keys(result.deployments).map(t => ({
		tag: t,
		...(result.deployments[t])
	})).sort((a,b) => a.averageDelta - b.averageDelta);

	const avg = deployments.reduce((acc, cur) => cur.totalDelta + acc, 0) / deployments.reduce((acc, cur) => cur.commits.length + acc, 0);
	const outliers = deployments.filter(d => d.averageDelta > 60 * 60 * 24 * 365 && d.averageDelta > avg * 10).map(d => `${d.tag} - ${Math.round(d.averageDelta / 60 / 60 / 24 / 365 * 10)/10}years (${new Date(d.date * 1000).toISOString().split("T")[0]})`);
	if(outliers.length > 0){
		console.log(result.repo);
		console.log(outliers.join("\n"));
		console.log("");
	}
});
console.log("=======================================================================")
console.log("========================= Change Failure Rate =========================")
data.results.forEach((result, i) => {
	const deployments = Object.keys(result.deployments).map(t => ({
		tag: t,
		...(result.deployments[t])
	})).sort((a,b) => a.failures - b.failures);

	const avg = deployments.reduce((acc, cur) => cur.failures + acc, 0) / deployments.length;
	const outliers = deployments.filter(d => d.failures > 50 && d.failures > avg * 10).map(d => `${d.tag} - ${d.failures} (${new Date(d.date * 1000).toISOString().split("T")[0]})`);
	if(outliers.length > 0){
		console.log(result.repo);
		console.log(outliers.join("\n"));
		console.log("");
	}
});
console.log("=======================================================================")
