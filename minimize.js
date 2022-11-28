const fs = require("fs")

const filterChangeFailureRate = true;
const score = repo => {
	let s = 0;
	Object.keys(repo).filter(k => k !== "changeFailureRate" || (!filterChangeFailureRate)).forEach((k, i) => {
		if(repo[k] === "Elite"){
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


const removeLeadingZeros = (d, i, arr) => {
	if(d === 0){
		let hasLeading = false;
		let hasTrailing = false;
		for(let j = i; j >=0; j--){
			if(arr[j] !== 0){
				hasLeading = true;
			}
		}
		for(let j = i; j < arr.length; j++){
			if(arr[j] !== 0){
				hasTrailing = true;
			}
		}
		if(hasLeading && hasTrailing){
			return d;
		}
		return undefined;
	}
	return d;
}

const divideTimes = (start, end, scale) => {
	if(scale === -1){
		return [[-1],["Total"]]
	}
	let labels = [];
	let dates = [];
	let d;
	for (let i = end.getTime() + 1; i > start.getTime(); i -= scale){
		dates = [new Date(i), ...dates];
		if(scale === YEAR){
			d = new Date(i).getYear() + 1900;
		}
		else if(scale < MONTH){
			d = new Date(i).toISOString().split("T")[0];
		}
		else{
			d = `${["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"][new Date(i).getMonth()]} ${new Date(i).getYear() + 1900}`;
		}
		labels = [d, ...labels];
	}
	return [dates, labels];
}



const MINUTE = 60 * 1000;
const HOUR = MINUTE * 60;
const DAY = HOUR * 24;
const YEAR = DAY * 365;
const WEEK = YEAR / 52;
const MONTH =  YEAR / 12;
const MONTH4 = YEAR / 3;
const MONTH6 = YEAR / 2;

let data = JSON.parse(fs.readFileSync(process.argv[process.argv.length - 2]));
// const time = "created"
const time = "resolved";

if(!data.results){
	data.results = [data.result];
}

const output = {
	name: data.name,
	start: data.start,
	end: data.end,
	repos: data.results.length,
	deployments: data.results.map(r => Object.keys(r.deployments).length).reduce((acc, nxt) => acc+nxt, 0),
	commits: data.results.map(r => Object.keys(r.deployments).map(t => r.deployments[t].commits.length)).flat().reduce((acc, nxt) => acc+nxt, 0),
	failures: data.results.map(r => r.failures.length).reduce((acc, nxt) => acc+nxt, 0),
	results: data.results.map(result => {

		const derivedResults = {
			repo: result.repo,
			performer: {
				deploymentFrequency: "Terrible",
				leadTimeForChanges: "Terrible",
				meanTimeToRecover: "Terrible",
				changeFailureRate: "Terrible"
			},
			accelerate: {
				deploymentFrequency: "Terrible",
				leadTimeForChanges: "Terrible",
				meanTimeToRecover: "Terrible",
				changeFailureRate: "Terrible"
			}
		};

		[MONTH4, MONTH6, YEAR, -1, -2].forEach((scale, i) => {
			const sorted = Object.keys(result.deployments).map(k => result.deployments[k]).sort((a,b) => a.date - b.date);
			const start = sorted[0].date;
			const end = sorted[sorted.length - 1].date;


			let scaleIndex = scale;
			let dates, labels;
			if(scale === -2){
				scale = (end - start) / 20 * 1000;
				scaleIndex = -2;
				[dates, labels] = divideTimes(new Date(start * 1000), new Date(end * 1000), scale);
			}
			else{
				[dates, labels] = divideTimes(new Date(data.start), new Date(data.end), scale);
			}

			const changeFailureRate = dates.map(d => Object.keys(result.deployments).map(k => result.deployments[k]).filter(dep => (dep.date * 1000 < d && dep.date * 1000 > d - scale) || scale === -1 )).map(g => 100 * g.filter(d => d.failures > 0 || d.hasFailure).length / (g.length || 1)).map(removeLeadingZeros);

			const deploymentFrequency = dates.map(d => Object.keys(result.deployments).map(k => result.deployments[k]).filter(dep => (dep.date * 1000 < d && dep.date * 1000 > d - scale) || scale === -1 ).length).map(d => {
				if(scale === -1 && Object.keys(result.deployments).length > 2){
					return d / (end - start) * YEAR / 1000
				}
				if(scaleIndex === -2){
					return d * (YEAR / scale)
				}
				return d;
			}).map(removeLeadingZeros);

			const leadTimeForChanges = dates.map(d => {
					const versions = Object.keys(result.deployments);
					const deployments = versions.map(k => result.deployments[k]).filter(dep => (dep.date * 1000 < d && dep.date * 1000 > d - scale) || scale === -1 )
					let sum = 0;
					let n = 0;
					deployments.forEach((deployment, i) => {
						sum += deployment.totalDelta;
						n += deployment.commits.length;
					});
					if(n === 0){
						return 0;
					}
					return sum / n / 60 / 60 / 24;
				}).map(removeLeadingZeros);

			const meanTimeToRecover = dates.map(d => {
				const failures = result.failures.filter(fail => (fail[time] * 1000 < d && fail[time] * 1000 > d - scale) || scale === -1 )
				let sum = 0;
				let n = 0;
				failures.forEach((fail, i) => {
					sum += (fail.resolved - fail.created);
					n += 1;
				});
				if(n === 0){
					return 0;
				}
				return sum / n / 60 / 60 / 24;

			}).map(removeLeadingZeros);

			derivedResults[scaleIndex] = {
				...(derivedResults[scaleIndex] ?? {}),
				changeFailureRate,
				deploymentFrequency,
				leadTimeForChanges,
				meanTimeToRecover,
			}
		});

		const d = derivedResults[-1].deploymentFrequency;
		const l = derivedResults[-1].leadTimeForChanges;
		const m = derivedResults[-1].meanTimeToRecover;
		const c = derivedResults[-1].changeFailureRate;


		if(d >= 12) derivedResults.performer.deploymentFrequency = "Low";
		if(d >= 365 / 7) derivedResults.performer.deploymentFrequency = "Medium";
		if(d >= 365 / 7 * 2) derivedResults.performer.deploymentFrequency = "High";
		if(d >= 14/24*365) derivedResults.performer.deploymentFrequency = "Elite";

		if(l <= 365) derivedResults.performer.leadTimeForChanges = "Low";
		if(l <= 30) derivedResults.performer.leadTimeForChanges = "Medium";
		if(l <= 7) derivedResults.performer.leadTimeForChanges = "High";
		if(l <= 3) derivedResults.performer.leadTimeForChanges = "Elite";

		if(m <= 365) derivedResults.performer.meanTimeToRecover = "Low";
		if(m <= 90) derivedResults.performer.meanTimeToRecover = "Medium";
		if(m <= 30) derivedResults.performer.meanTimeToRecover = "High";
		if(m <= 10) derivedResults.performer.meanTimeToRecover = "Elite";

 		if(c <= 90) derivedResults.performer.changeFailureRate = "Low";
		if(c <= 50) derivedResults.performer.changeFailureRate = "Medium";
		if(c <= 30) derivedResults.performer.changeFailureRate = "High";
		if(c <= 10) derivedResults.performer.changeFailureRate = "Elite";


		if(c <= 30) derivedResults.accelerate.changeFailureRate = "Low";
		if(c <= 30) derivedResults.accelerate.changeFailureRate = "Medium";
		if(c <= 30) derivedResults.accelerate.changeFailureRate = "High";
		if(c <= 15) derivedResults.accelerate.changeFailureRate = "Elite";

		if(d >= 0) derivedResults.accelerate.deploymentFrequency = "Low";
		if(d >= 2) derivedResults.accelerate.deploymentFrequency = "Medium";
		if(d >= 12) derivedResults.accelerate.deploymentFrequency = "High";
		if(d >= 365) derivedResults.accelerate.deploymentFrequency = "Elite";

		if(l > 365/2) derivedResults.accelerate.leadTimeForChanges = "Low";
		if(l <= 365/2) derivedResults.accelerate.leadTimeForChanges = "Medium";
		if(l <= 7) derivedResults.accelerate.leadTimeForChanges = "High";
		if(l <= 1/12) derivedResults.accelerate.leadTimeForChanges = "Elite";

		if(m > 365/2) derivedResults.accelerate.meanTimeToRecover = "Low";
		if(m <= 365/2) derivedResults.accelerate.meanTimeToRecover = "Medium";
		if(m <= 1) derivedResults.accelerate.meanTimeToRecover = "High";
		if(m <= 1/2) derivedResults.accelerate.meanTimeToRecover = "Elite";

		derivedResults.accelerate.score = score(derivedResults.accelerate);
		derivedResults.performer.score = score(derivedResults.performer);

		return derivedResults;
	})
};


fs.writeFileSync(process.argv[process.argv.length - 1], JSON.stringify(output));
