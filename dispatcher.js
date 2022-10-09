const fs = require("fs");
const util = require("util");
const exec = util.promisify(require("child_process").exec);

const fn = process.argv[2]

const config = JSON.parse(fs.readFileSync(fn, 'utf8'));
let completed = 0

console.log(`Starting study ${config.name} from ${config.start} to ${config.end}`)
Promise.all(config.repos.map(async (repo, i) => {
	console.log(`Analyzing ${repo.id} with deployment=${repo.deployment === 0 ? "releases" : "tags"}`);
	const startTime = Date.now();
	const { stdout, stderr } = await exec(`./analyze.sh ${repo.id} ${repo.deployment} "${config.end}" "${config.start}"`);
	if(stderr){
		return Promise.reject(new Error(stderr))
	}
	else{
		const data = stdout.split("\n");
		const numDeployments = parseInt(data[0].split(",")[3])
		const deploymentFrequency = parseInt(data[0].split(",")[4])
		const deployments = {}
		let totalCommits = 0;
		let totalDelta = 0;

		data.slice(1).filter(l => l.length > 1).forEach((line, i) => {
			line = line.split(",")
			const tag = line[1]
			const sha = line[2]
			const delta = parseInt(line[5])
			if(!deployments[tag]){
				deployments[tag] = {commits:[], totalDelta: 0, averageDelta: 0}
			}
			deployments[tag].commits = [...deployments[tag].commits, sha]
			deployments[tag].totalDelta += delta;
			deployments[tag].averageDelta = deployments[tag].totalDelta / deployments[tag].commits.length
			totalCommits += 1;
			totalDelta += delta;
		});

		completed += 1
		console.log(`Completed ${repo.id} in ${Math.round((Date.now() - startTime) / 1000)}s (${completed}/${config.repos.length})`);
		return Promise.resolve({
			repo: repo.id,
			numDeployments,
			deploymentFrequency,
			totalCommits,
			totalDelta,
			averageDelta: totalDelta / totalCommits,
			deployments
		});
	}
})).then(results => {
	const output = {name: config.name, start: config.start, end: config.end, results}
	const serialized = JSON.stringify(output, null, 4);
	fs.writeFileSync(config.results, serialized);
});
