const fs = require("fs");
const util = require("util");
const exec = util.promisify(require("child_process").exec);

const fn = process.argv[2]

const config = JSON.parse(fs.readFileSync(fn, 'utf8'));
let completed = 0

const MINUTE = 60;
const HOUR = MINUTE * 60;
const DAY = HOUR * 24;
const WEEK = DAY * 7;
const YEAR = DAY * 365;
const MONTH = YEAR / 12;
const DeploymentFrequencyScale = [DAY, WEEK, MONTH, MONTH * 6];
const LeadTimeforChangesScale = [DAY, WEEK, MONTH, MONTH * 6];
const MeanTimetoRecoverScale = [HOUR, DAY, WEEK, MONTH];
const ChangeFailureRateScale = [0.15, 0.3, 0.45, 0.6];
const performer = (val, scale) => {
	if(val < scale[0]){
		return "Elite";
	}
	if(val < scale[1]){
		return "High";
	}
	if(val < scale[2]){
		return "Medium";
	}
	if(val < scale[3]){
		return "Low";
	}
	return "Critically Low";
}

console.log(`Starting study ${config.name} from ${config.start} to ${config.end}`)
Promise.all(config.repos.map(async (repo, i) => {
	console.log(`Analyzing ${repo.id} with deployment=${repo.deployment === 0 ? "releases" : "tags"}`);
	const startTime = Date.now();

	let failures = []
	if(repo.failures?.type === 0){
		const jira = await exec(`./jira.sh "${repo.failures.url}" "${repo.failures.project}"`);
		if(jira.stderr){
			return Promise.reject(new Error(jira.stderr));
		}
		jiraData = JSON.parse(jira.stdout);
		failures = jiraData.issues.map((issue, i) => ({
			id: issue.key,
			critical: issue.fields.priority.name === "High" || issue.fields.priority.name === "Highest",
			version: issue.fields.fixVersions[0].name,
			resolved: new Date(issue.fields.fixVersions[0].releaseDate).getTime() / 1000,
			created: new Date(issue.fields.created).getTime() / 1000
		}));
	}

	const analysis = await exec(`./analyze.sh ${repo.id} ${repo.deployment} "${config.end}" "${config.start}"`);
	if(analysis.stderr){
		return Promise.reject(new Error(analysis.stderr))
	}
	else{
		const data = analysis.stdout.split("\n");
		const numDeployments = parseInt(data[0].split(",")[3])
		const deploymentFrequency = parseInt(data[0].split(",")[4])
		const deployments = {}
		let totalCommits = 0;
		let totalDelta = 0;

		data.slice(1).filter(l => l.length > 1).forEach((line, i) => {
			line = line.split(",")
			const tag = line[1]
			const sha = line[2]
			const date = parseInt(line[3]);
			const delta = parseInt(line[5])
			if(!deployments[tag]){
				deployments[tag] = {commits:[], totalDelta: 0, averageDelta: 0}
			}

			deployments[tag].commits = [...deployments[tag].commits, sha]
			deployments[tag].totalDelta += delta;
			deployments[tag].date = date;
			deployments[tag].averageDelta = deployments[tag].totalDelta / deployments[tag].commits.length
			totalCommits += 1;
			totalDelta += delta;
		});


		failures = failures.map(failure => {
			const tag = failure.version
			let resolved;
			if(deployments[tag]){
				resolved = deployments[tag].date;
			}
			else if(deployments[`v${tag}`]){
				resolved = deployments[`v${tag}`].date;
			}
			else if(deployments[tag.replace(/^v/g, "")]){
				resolved = deployments[tag.replace(/^v/g, "")].date;
			}
			else{
				resolved = failure.resolved;
			}

			return {
				...failure,
				resolved,
				delta: resolved - failure.created
			}
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
			deployments,
			failures,
			totalFailures: failures.length,
			totalCriticalFailures: failures.filter(f => f.critical).length,
			averageFailureDelta: failures.reduce((acc, nxt) => acc + nxt.delta, 0) / (failures.length || 1),
			averageCritialFailureDelta: failures.filter(f => f.critical).reduce((acc, nxt) => acc + nxt.delta, 0) / (failures.filter(f => f.critical).length || 1),
		});
	}
})).then(async results => {
	const output = {name: config.name, start: config.start, end: config.end, results}
	const serialized = JSON.stringify(output, null, 4);
	fs.writeFileSync(config.results, serialized);
	fs.createWriteStream(null, {fd: 3}).write(`${config.results}`);

	console.log("==========REPORT==========");
	await Promise.all(results.map(async (result, i) => {

		const freq = (await exec(`./print_time.sh ${Math.round(result.deploymentFrequency)}`)).stdout.trim();
		const leadTime = (await exec(`./print_time.sh ${Math.round(result.averageDelta)}`)).stdout.trim();
		const meanTime = (await exec(`./print_time.sh ${Math.round(result.averageFailureDelta)}`)).stdout.trim();
		const meanTimeCritical = (await exec(`./print_time.sh ${Math.round(result.averageCritialFailureDelta)}`)).stdout.trim();

		console.log(`----|${result.repo}|----`);
		console.log(`Deployment Frequency: ${performer(result.deploymentFrequency, DeploymentFrequencyScale)} Performer (Average: ${freq})`);
		console.log(`Lead Time for Changes: ${performer(result.averageDelta, LeadTimeforChangesScale)} Performer (Average: ${leadTime})`);
		if(result.failures.length == 0){
			console.log("Mean Time to Recover (Regular): n/a");
			console.log("Mean Time to Recover (Critical): n/a");
			console.log(`Change Failure Rate: n/a`);
		}
		else{
			console.log(`Mean Time to Recover (Regular): ${performer(result.averageFailureDelta, MeanTimetoRecoverScale)} Performer (Average: ${meanTime})`);
			console.log(`Mean Time to Recover (Critical): ${performer(result.averageCritialFailureDelta, MeanTimetoRecoverScale)} Performer (Average: ${meanTimeCritical})`);
			if(result.deployments.length > 0){
				console.log(`Change Failure Rate: ${performer(result.totalCriticalFailures / result.deployments.length, ChangeFailureRateScale)} (${Math.round(result.totalCriticalFailures / result.deployments.length * 100)}%)`);
			}
			else{
				console.log(`Change Failure Rate: n/a`);
			}
		}
	}));
	console.log("==========================");

});
