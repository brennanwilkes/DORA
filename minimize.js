const fs = require("fs")

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
const time = "created"
// const time = "resolved";

const output = {
	name: data.name,
	start: data.start,
	end: data.end,
	results: data.results.map(result => {


		const derivedResults = {
			repo: result.repo,
		};

		[WEEK, MONTH, MONTH4, MONTH6, YEAR, -1].forEach((scale, i) => {
			const [dates, labels] = divideTimes(new Date(data.start), new Date(data.end), scale);

			const changeFailureRate = dates.map(d => Object.keys(result.deployments).map(k => result.deployments[k]).filter(dep => (dep.date * 1000 < d && dep.date * 1000 > d - scale) || scale === -1 )).map(g => 100 * g.filter(d => d.failures > 0 || d.hasFailure).length / (g.length || 1)).map(removeLeadingZeros);

			const deploymentFrequency = dates.map(d => Object.keys(result.deployments).map(k => result.deployments[k]).filter(dep => (dep.date * 1000 < d && dep.date * 1000 > d - scale) || scale === -1 ).length).map(d => {
				if(scale === -1 && Object.keys(result.deployments).length > 2){
					const sorted = Object.keys(result.deployments).map(k => result.deployments[k]).sort((a,b) => a.date - b.date);
					const start = sorted[0].date;
					const end = sorted[sorted.length - 1].date;
					return d / (end - start) * YEAR / 1000
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

			derivedResults[scale] = {
				...(derivedResults[scale] ?? {}),
				changeFailureRate,
				deploymentFrequency,
				leadTimeForChanges,
				meanTimeToRecover,
			}
		});

		return derivedResults;
	})
};


fs.writeFileSync(process.argv[process.argv.length - 1], JSON.stringify(output));
